import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/step_progress_indicator.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_step_footer.dart';
import '../widgets/auth_welcome_header.dart';

enum _TeacherStep { email, name, password }

/// Öğretmen giriş/kayıt — e-posta önce akışı.
class TeacherAuthFlowScreen extends ConsumerStatefulWidget {
  const TeacherAuthFlowScreen({super.key});

  @override
  ConsumerState<TeacherAuthFlowScreen> createState() =>
      _TeacherAuthFlowScreenState();
}

class _TeacherAuthFlowScreenState extends ConsumerState<TeacherAuthFlowScreen> {
  _TeacherStep _step = _TeacherStep.email;
  bool _isLogin = false;
  String? _displayName;

  final _emailFormKey = GlobalKey<FormState>();
  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int get _stepIndex {
    switch (_step) {
      case _TeacherStep.email:
        return 0;
      case _TeacherStep.name:
        return 1;
      case _TeacherStep.password:
        return _isLogin ? 1 : 2;
    }
  }

  int get _totalSteps => _isLogin ? 2 : 3;

  void _prevStep() {
    context.unfocus();
    switch (_step) {
      case _TeacherStep.email:
        context.pop();
      case _TeacherStep.name:
        setState(() => _step = _TeacherStep.email);
      case _TeacherStep.password:
        if (_isLogin) {
          setState(() => _step = _TeacherStep.email);
        } else {
          setState(() => _step = _TeacherStep.name);
        }
    }
  }

  Future<void> _submitEmail() async {
    context.unfocus();
    if (!_emailFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final preview =
        await ref.read(teacherAuthProvider.notifier).checkEmail(email);

    if (!mounted) return;
    if (preview == null) return;

    setState(() {
      _isLogin = preview.exists;
      _displayName = preview.name;
      if (_isLogin) {
        _step = _TeacherStep.password;
      } else {
        _step = _TeacherStep.name;
      }
    });
  }

  void _submitName() {
    context.unfocus();
    if (!_nameFormKey.currentState!.validate()) return;
    setState(() => _step = _TeacherStep.password);
  }

  Future<void> _submitPassword() async {
    context.unfocus();
    if (!_passwordFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final notifier = ref.read(teacherAuthProvider.notifier);

    if (_isLogin) {
      await notifier.signIn(email: email, password: password);
    } else {
      await notifier.registerTeacher(
        name: _nameController.text.trim(),
        email: email,
        password: password,
      );
    }

    if (!mounted) return;
    final authState = ref.read(teacherAuthProvider);
    if (authState.isSuccess) {
      context.go('/teacher/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(teacherAuthProvider, (_, next) {
      if (next.errorMessage != null) {
        context.showSnackBar(next.errorMessage!, isError: true);
        ref.read(teacherAuthProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(teacherAuthProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: isLoading ? null : _prevStep,
        ),
        title: Text('Öğretmen', style: AppTextStyles.h4),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepProgressIndicator(
                currentStep: _stepIndex,
                totalSteps: _totalSteps,
                stepTitles: _isLogin
                    ? const ['E-posta', 'Şifre']
                    : const ['E-posta', 'İsim', 'Şifre'],
                primaryColor: AppColors.teacherPrimary,
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStep(isLoading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isLoading) {
    switch (_step) {
      case _TeacherStep.email:
        return _buildEmailStep(isLoading);
      case _TeacherStep.name:
        return _buildNameStep(isLoading);
      case _TeacherStep.password:
        return _buildPasswordStep(isLoading);
    }
  }

  Widget _buildEmailStep(bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthWelcomeHeader(
            title: 'E-posta adresiniz',
            subtitle: 'Öğretmen hesabınızla devam edin.',
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.email,
            hint: 'ornek@okul.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.email_outlined,
                color: AppColors.textSecondary),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return AppStrings.errorEmailRequired;
              }
              if (!v.trim().isValidEmail) {
                return AppStrings.errorEmailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          AuthStepFooter(
            onBack: _prevStep,
            onContinue: _submitEmail,
            isLoading: isLoading,
            primaryColor: AppColors.teacherPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep(bool isLoading) {
    return Form(
      key: _nameFormKey,
      child: Column(
        key: const ValueKey('name'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthWelcomeHeader(
            title: 'Eduly\'ye hoş geldiniz',
            subtitle: 'Öğretmen hesabınızı oluşturalım. Adınızı girin.',
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
            isLoading: isLoading,
            primaryColor: AppColors.teacherPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(bool isLoading) {
    final welcomeTitle = _isLogin
        ? 'Tekrar hoş geldiniz${_displayName != null && _displayName!.isNotEmpty ? ', $_displayName' : ''}'
        : 'Son adım';
    final welcomeSubtitle = _isLogin
        ? 'Şifrenizle giriş yapın.'
        : 'Hesabınız için güçlü bir şifre belirleyin.';

    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey('password'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthWelcomeHeader(title: welcomeTitle, subtitle: welcomeSubtitle),
          const SizedBox(height: 24),
          AppTextField(
            label: AppStrings.password,
            hint: 'En az 8 karakter',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textSecondary),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return AppStrings.errorPasswordRequired;
              }
              if (!_isLogin && !v.isValidPassword) {
                return AppStrings.errorPasswordMin;
              }
              return null;
            },
          ),
          if (_isLogin) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(
                  '/forgot-password',
                  extra: _emailController.text.trim(),
                ),
                child: Text(
                  AppStrings.forgotPassword,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.teacherPrimary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          AuthStepFooter(
            onBack: _prevStep,
            onContinue: _submitPassword,
            continueLabel: _isLogin ? 'Giriş Yap' : 'Kaydol ve Başla',
            isLoading: isLoading,
            primaryColor: AppColors.teacherPrimary,
          ),
        ],
      ),
    );
  }
}
