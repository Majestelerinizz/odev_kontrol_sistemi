import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/services/sms_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/step_progress_indicator.dart';
import '../../../students/data/models/invite_code_model.dart';
import '../providers/auth_providers.dart';
import '../utils/phone_utils.dart';
import '../widgets/auth_step_footer.dart';
import '../widgets/auth_welcome_header.dart';
import '../widgets/otp_input_field.dart';
import '../widgets/phone_input_field.dart';

enum _ParentStep { phone, otp, name, classCode, studentPick }

/// Veli giriş/kayıt — telefon + SMS OTP akışı.
class ParentAuthFlowScreen extends ConsumerStatefulWidget {
  const ParentAuthFlowScreen({super.key});

  @override
  ConsumerState<ParentAuthFlowScreen> createState() =>
      _ParentAuthFlowScreenState();
}

class _ParentAuthFlowScreenState extends ConsumerState<ParentAuthFlowScreen> {
  _ParentStep _step = _ParentStep.phone;
  bool _isReturningUser = false;
  String? _returningName;
  String _phoneE164 = '';

  String? _validatedCode;
  String? _className;
  List<InviteStudentOption> _students = const [];
  InviteStudentOption? _selectedStudent;
  String? _prefilledStudentId;

  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _nameFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  int _resendSeconds = 0;
  bool _phoneAuthHandled = false;
  StreamSubscription<User?>? _autoVerifySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInvitePrefill());
  }

  void _applyInvitePrefill() {
    final prefill = ref.read(invitePrefillProvider);
    if (prefill.hasCode) {
      _validatedCode = prefill.code;
      _codeController.text = prefill.code!;
      _prefilledStudentId = prefill.studentId;
    }
  }

  @override
  void dispose() {
    _autoVerifySub?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  int get _totalSteps {
    if (_isReturningUser) return 2;
    var steps = 4; // phone, otp, name, classCode
    if (_needsStudentPick) steps++;
    if (_validatedCode != null && _step.index > _ParentStep.classCode.index) {
      steps--;
    }
    return steps.clamp(2, 5);
  }

  int get _stepIndex {
    switch (_step) {
      case _ParentStep.phone:
        return 0;
      case _ParentStep.otp:
        return 1;
      case _ParentStep.name:
        return 2;
      case _ParentStep.classCode:
        return 3;
      case _ParentStep.studentPick:
        return 4;
    }
  }

  bool get _needsStudentPick {
    if (_students.length <= 1) return false;
    if (_prefilledStudentId != null && _prefilledStudentId!.isNotEmpty) {
      return false;
    }
    return true;
  }

  bool get _skipClassCode =>
      _validatedCode != null && _validatedCode!.isNotEmpty;

  void _prevStep() {
    context.unfocus();
    switch (_step) {
      case _ParentStep.phone:
        context.pop();
      case _ParentStep.otp:
        _autoVerifySub?.cancel();
        _phoneAuthHandled = false;
        setState(() => _step = _ParentStep.phone);
      case _ParentStep.name:
        setState(() => _step = _ParentStep.otp);
      case _ParentStep.classCode:
        setState(() => _step = _ParentStep.name);
      case _ParentStep.studentPick:
        if (_skipClassCode) {
          setState(() => _step = _ParentStep.name);
        } else {
          setState(() => _step = _ParentStep.classCode);
        }
    }
  }

  Future<void> _sendOtp() async {
    context.unfocus();
    if (!_phoneFormKey.currentState!.validate()) return;

    final digits = PhoneUtils.extractNationalDigits(_phoneController.text);
    _phoneE164 = PhoneUtils.toE164(digits);

    setState(() => _isLoading = true);
    _phoneAuthHandled = false;
    try {
      final session = await SmsService.sendOtp(_phoneE164);
      if (!mounted) return;
      if (session.autoVerified) {
        await _continueAfterPhoneAuth();
        return;
      }
      setState(() {
        _step = _ParentStep.otp;
        _resendSeconds = 60;
      });
      _watchLateAutoVerify();
      _startResendTimer();
    } on AuthException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('SMS gönderilemedi.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds = (_resendSeconds - 1).clamp(0, 60));
      return _resendSeconds > 0;
    });
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    setState(() => _isLoading = true);
    try {
      await SmsService.resendOtp(_phoneE164);
      setState(() => _resendSeconds = 60);
      _startResendTimer();
    } on AuthException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    context.unfocus();
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await SmsService.verifyOtp(
        smsCode: _otpController.text.trim(),
      );
      await _continueAfterPhoneAuth(uid: user.uid);
    } on AuthException catch (e) {
      if (mounted) context.showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Doğrulama başarısız.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _watchLateAutoVerify() {
    _autoVerifySub?.cancel();
    _autoVerifySub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user == null || _phoneAuthHandled) return;
      if (_step != _ParentStep.otp) return;
      _continueAfterPhoneAuth(uid: user.uid).catchError((Object e) {
        if (!mounted) return;
        final message = e is AuthException ? e.message : 'Doğrulama başarısız.';
        context.showSnackBar(message, isError: true);
      });
    });
  }

  Future<void> _continueAfterPhoneAuth({String? uid}) async {
    if (_phoneAuthHandled) return;
    _phoneAuthHandled = true;
    await _autoVerifySub?.cancel();

    final resolvedUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUid == null) {
      _phoneAuthHandled = false;
      throw const AuthException('Oturum açılamadı.');
    }

    final profile =
        await ref.read(parentAuthProvider.notifier).loadCurrentProfile(resolvedUid);

    if (!mounted) return;

    if (profile != null && profile.isParent && profile.isActive) {
      setState(() {
        _isReturningUser = true;
        _returningName = profile.name;
      });
      context.showSnackBar('Tekrar hoş geldiniz, ${profile.name}');
      context.go('/parent/home');
      return;
    }

    if (profile != null && profile.isTeacher) {
      await FirebaseAuth.instance.signOut();
      _phoneAuthHandled = false;
      throw const AuthException(
        'Bu telefon bir öğretmen hesabına bağlı.',
      );
    }

    setState(() {
      _isReturningUser = false;
      _step = _ParentStep.name;
    });
  }

  void _submitName() {
    context.unfocus();
    if (!_nameFormKey.currentState!.validate()) return;

    if (_skipClassCode) {
      _loadStudentsFromPrefilledCode();
    } else {
      setState(() => _step = _ParentStep.classCode);
    }
  }

  Future<void> _loadStudentsFromPrefilledCode() async {
    if (_validatedCode == null) {
      setState(() => _step = _ParentStep.classCode);
      return;
    }

    setState(() => _isLoading = true);
    final ok = await ref
        .read(parentAuthProvider.notifier)
        .validateInviteCode(_validatedCode!);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!ok) return;
    _applyInviteData();
    _advanceAfterCodeValidated();
  }

  Future<void> _validateClassCode() async {
    context.unfocus();
    if (!_codeFormKey.currentState!.validate()) return;

    final code = _codeController.text.trim().toUpperCase();
    setState(() => _isLoading = true);

    final ok =
        await ref.read(parentAuthProvider.notifier).validateInviteCode(code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!ok) {
      final err = ref.read(parentAuthProvider).errorMessage;
      if (err != null) context.showSnackBar(err, isError: true);
      return;
    }

    _validatedCode = code;
    _applyInviteData();
    _advanceAfterCodeValidated();
  }

  void _applyInviteData() {
    final data = ref.read(parentAuthProvider.notifier).inviteCodeData;
    final type = data?['type'] as String? ?? 'student';
    _className = data?['className'] as String?;

    if (type == 'class') {
      final raw = data?['students'] as List<dynamic>? ?? [];
      _students = raw
          .whereType<Map>()
          .map((e) => InviteStudentOption.fromMap(Map<String, dynamic>.from(e)))
          .where((s) => s.id.isNotEmpty)
          .toList();

      if (_prefilledStudentId != null && _prefilledStudentId!.isNotEmpty) {
        for (final s in _students) {
          if (s.id == _prefilledStudentId) {
            _selectedStudent = s;
            break;
          }
        }
        _selectedStudent ??= _students.isNotEmpty ? _students.first : null;
      } else if (_students.length == 1) {
        _selectedStudent = _students.first;
      }
    } else {
      final studentId = data?['studentId'] as String? ?? '';
      final studentName = data?['studentName'] as String? ?? 'Öğrenci';
      _students = [InviteStudentOption(id: studentId, name: studentName)];
      _selectedStudent = _students.first;
    }
  }

  void _advanceAfterCodeValidated() {
    if (_needsStudentPick) {
      setState(() => _step = _ParentStep.studentPick);
    } else {
      _completeRegistration();
    }
  }

  Future<void> _completeRegistration() async {
    if (_validatedCode == null) {
      context.showSnackBar(AppStrings.errorInviteCodeRequired, isError: true);
      return;
    }

    final studentId = _selectedStudent?.id ?? _prefilledStudentId ?? '';
    if (studentId.isEmpty) {
      context.showSnackBar('Lütfen çocuğunuzu seçin.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await ref.read(parentAuthProvider.notifier).registerParentWithPhone(
          name: _nameController.text.trim(),
          phone: _phoneE164,
          inviteCode: _validatedCode!,
          studentId: studentId,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final state = ref.read(parentAuthProvider);
    if (state.isSuccess) {
      ref.read(invitePrefillProvider.notifier).clear();
      context.go('/parent/home');
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
      ref.read(parentAuthProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: _isLoading ? null : _prevStep,
        ),
        title: Text('Veli', style: AppTextStyles.h4),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isReturningUser)
                StepProgressIndicator(
                  currentStep: _stepIndex,
                  totalSteps: _totalSteps,
                  stepTitles: const [
                    'Telefon',
                    'Doğrulama',
                    'İsim',
                    'Sınıf Kodu',
                    'Öğrenci',
                  ],
                  primaryColor: AppColors.parentPrimary,
                ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _ParentStep.phone:
        return _buildPhoneStep();
      case _ParentStep.otp:
        return _buildOtpStep();
      case _ParentStep.name:
        return _buildNameStep();
      case _ParentStep.classCode:
        return _buildClassCodeStep();
      case _ParentStep.studentPick:
        return _buildStudentPickStep();
    }
  }

  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        key: const ValueKey('phone'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthWelcomeHeader(
            title: 'Telefon numaranız',
            subtitle: 'Size SMS ile doğrulama kodu göndereceğiz.',
          ),
          const SizedBox(height: 24),
          PhoneInputField(controller: _phoneController, autofocus: true),
          const SizedBox(height: 28),
          AuthStepFooter(
            onBack: _prevStep,
            onContinue: _sendOtp,
            continueLabel: 'Kod Gönder',
            isLoading: _isLoading,
            primaryColor: AppColors.parentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('otp'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthWelcomeHeader(
            title: 'Doğrulama kodu',
            subtitle: '$_phoneE164 numarasına gönderilen 6 haneli kodu girin.',
          ),
          const SizedBox(height: 24),
          OtpInputField(
            controller: _otpController,
            onCompleted: (_) => _verifyOtp(),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed:
                  _resendSeconds > 0 || _isLoading ? null : _resendOtp,
              child: Text(
                _resendSeconds > 0
                    ? 'Yeniden gönder ($_resendSeconds sn)'
                    : 'Kodu yeniden gönder',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.parentPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          AuthStepFooter(
            onBack: _prevStep,
            onContinue: _verifyOtp,
            continueLabel: 'Doğrula',
            isLoading: _isLoading,
            primaryColor: AppColors.parentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Form(
      key: _nameFormKey,
      child: Column(
        key: const ValueKey('name'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthWelcomeHeader(
            title: 'Merhaba, sizi tanıyalım',
            subtitle: 'Veli hesabınız için adınızı girin.',
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.fullName,
            hint: 'Ad Soyad',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textSecondary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppStrings.errorNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          AuthStepFooter(
            onBack: _prevStep,
            onContinue: _submitName,
            isLoading: _isLoading,
            primaryColor: AppColors.parentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCodeStep() {
    return Form(
      key: _codeFormKey,
      child: Column(
        key: const ValueKey('code'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthWelcomeHeader(
            title: 'Sınıf davet kodu',
            subtitle: 'Öğretmeninizin paylaştığı kodu girin.',
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.inviteCode,
            hint: AppStrings.inviteCodeHint,
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            prefixIcon: const Icon(Icons.vpn_key_outlined,
                color: AppColors.textSecondary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppStrings.errorInviteCodeRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          AuthStepFooter(
            onBack: _prevStep,
            onContinue: _validateClassCode,
            isLoading: _isLoading,
            primaryColor: AppColors.parentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPickStep() {
    return Column(
      key: const ValueKey('student'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthWelcomeHeader(
          title: 'Çocuğunuzu seçin',
          subtitle: _className != null
              ? '$_className sınıfındaki öğrenciler'
              : 'Sınıf listesinden çocuğunuzu seçin.',
        ),
        const SizedBox(height: 20),
        ..._students.map(
          (s) => RadioListTile<InviteStudentOption>(
            value: s,
            groupValue: _selectedStudent,
            activeColor: AppColors.parentPrimary,
            title: Text(s.name, style: AppTextStyles.bodyLarge),
            onChanged: (v) => setState(() => _selectedStudent = v),
          ),
        ),
        const SizedBox(height: 28),
        AuthStepFooter(
          onBack: _prevStep,
          onContinue: _completeRegistration,
          continueLabel: 'Kaydı Tamamla',
          isLoading: _isLoading,
          primaryColor: AppColors.parentPrimary,
          continueEnabled: _selectedStudent != null,
        ),
      ],
    );
  }
}
