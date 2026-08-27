import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/step_progress_indicator.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../students/data/models/invite_code_model.dart';

/// Veli kaydı: 1) Sınıf davet kodu 2) Öğrenci seçimi 3) Hesap bilgileri.
class ParentRegisterScreen extends ConsumerStatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  ConsumerState<ParentRegisterScreen> createState() =>
      _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends ConsumerState<ParentRegisterScreen> {
  int _currentStep = 0;

  final _codeController = TextEditingController();
  final _step2FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _termsAccepted = true;

  String? _validatedCode;
  String? _className;
  List<InviteStudentOption> _students = const [];
  InviteStudentOption? _selectedStudent;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    context.unfocus();
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      context.showSnackBar(AppStrings.errorInviteCodeRequired, isError: true);
      return;
    }

    final notifier = ref.read(parentAuthProvider.notifier);
    final isValid = await notifier.validateInviteCode(code);

    if (!mounted) return;
    if (!isValid) {
      final error = ref.read(parentAuthProvider).errorMessage;
      if (error != null) context.showSnackBar(error, isError: true);
      return;
    }

    final data = notifier.inviteCodeData;
    final type = data?['type'] as String? ?? 'student';
    _validatedCode = code;
    _className = data?['className'] as String?;
    _selectedStudent = null;

    if (type == 'class') {
      final raw = data?['students'] as List<dynamic>? ?? [];
      _students = raw
          .whereType<Map>()
          .map((e) => InviteStudentOption.fromMap(Map<String, dynamic>.from(e)))
          .where((s) => s.id.isNotEmpty)
          .toList();
      if (_students.isEmpty) {
        context.showSnackBar(
          'Bu sınıfta henüz öğrenci yok. Öğretmeninizle iletişime geçin.',
          isError: true,
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else {
      // Eski öğrenci kodu uyumluluğu
      final studentId = data?['studentId'] as String? ?? '';
      final studentName = data?['studentName'] as String? ?? 'Öğrenci';
      _students = [
        InviteStudentOption(id: studentId, name: studentName),
      ];
      _selectedStudent = _students.first;
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    context.unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _confirmStudentSelection() {
    if (_selectedStudent == null) {
      context.showSnackBar('Lütfen çocuğunuzu seçin.', isError: true);
      return;
    }
    setState(() => _currentStep = 2);
  }

  Future<void> _submitRegister() async {
    context.unfocus();
    if (!_step2FormKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      context.showSnackBar(AppStrings.errorTermsRequired, isError: true);
      return;
    }
    if (_validatedCode == null || _selectedStudent == null) {
      context.showSnackBar(AppStrings.errorInviteCodeRequired, isError: true);
      return;
    }

    await ref.read(parentAuthProvider.notifier).registerParent(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          inviteCode: _validatedCode!,
          studentId: _selectedStudent!.id,
        );

    if (!mounted) return;
    final state = ref.read(parentAuthProvider);
    if (state.isSuccess) {
      context.showSnackBar('Kayıt tamamlandı.');
      context.go('/parent/home');
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _prevStep,
        ),
        title: Text(
          'Veli Kaydı',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepProgressIndicator(
                currentStep: _currentStep,
                totalSteps: 3,
                stepTitles: const ['Sınıf Kodu', 'Öğrenci', 'Hesap'],
                primaryColor: AppColors.parentPrimary,
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: switch (_currentStep) {
                  0 => _buildStep0(),
                  1 => _buildStep1(),
                  _ => _buildStep2(),
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Zaten kayıtlı mısınız? '),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(
                      'Giriş Yap',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.parentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    final authState = ref.watch(parentAuthProvider);

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. Sınıf Davet Kodu', style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Text(
          'Öğretmeninizden aldığınız sınıf kodunu girin. '
          'Aynı kodu sınıfın tüm velileri kullanabilir.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppTextField(
          label: 'Sınıf Davet Kodu',
          hint: 'OT-XXXXXX',
          controller: _codeController,
          prefixIcon:
              const Icon(Icons.qr_code_rounded, color: AppColors.textSecondary),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Kodu Doğrula',
          onPressed: _validateCode,
          isLoading: authState.isLoading,
          backgroundColor: AppColors.parentPrimary,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2. Çocuğunuzu Seçin', style: AppTextStyles.h3),
        const SizedBox(height: 6),
        Text(
          _className != null
              ? '$_className sınıfındaki öğrencilerden çocuğunuzu seçin.'
              : 'Listeden çocuğunuzu seçin.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        ..._students.map((student) {
          final selected = _selectedStudent?.id == student.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected
                  ? AppColors.parentPrimary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => setState(() => _selectedStudent = student),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.parentPrimary
                          : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.parentPrimary
                            .withValues(alpha: 0.15),
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.h4
                              .copyWith(color: AppColors.parentPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name, style: AppTextStyles.h4),
                            if (student.schoolNumber != null)
                              Text(
                                'Okul No: ${student.schoolNumber}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? AppColors.parentPrimary
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(label: 'Geri', onPressed: _prevStep),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'Devam',
                onPressed: _confirmStudentSelection,
                backgroundColor: AppColors.parentPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final authState = ref.watch(parentAuthProvider);

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedStudent != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.parentSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.parentPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.parentPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seçilen Öğrenci',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.parentPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(_selectedStudent!.name, style: AppTextStyles.h4),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.parentPrimary,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('3. Hesap Bilgileri', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'E-posta ve şifrenizle giriş yapabileceksiniz.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.fullName,
            hint: 'Ad Soyad',
            controller: _nameController,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppStrings.errorNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          AppTextField(
            label: 'E-posta',
            hint: 'ornek@mail.com',
            controller: _emailController,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppColors.textSecondary,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty || !v.contains('@')) {
                return 'Geçerli bir e-posta giriniz.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          AppTextField(
            label: 'Şifre',
            hint: 'En az 6 karakter',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
            ),
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? true),
                activeColor: AppColors.parentPrimary,
              ),
              Expanded(
                child: Text(
                  'Kullanım şartlarını ve KVKK gizlilik politikalarını onaylıyorum.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Geri',
                  onPressed: _prevStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Kaydı Tamamla',
                  onPressed: _submitRegister,
                  isLoading: authState.isLoading,
                  backgroundColor: AppColors.parentPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
