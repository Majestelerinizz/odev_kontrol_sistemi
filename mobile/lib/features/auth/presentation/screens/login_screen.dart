import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eduly_logo.dart';
import '../../../../core/extensions/extensions.dart';

/// Giriş ekranı — öğretmen ve veli e-posta/şifre.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _teacherFormKey = GlobalKey<FormState>();
  final _parentFormKey = GlobalKey<FormState>();

  final _teacherEmailController = TextEditingController();
  final _teacherPasswordController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPasswordController = TextEditingController();

  bool _isTeacherRole = true;

  @override
  void dispose() {
    _teacherEmailController.dispose();
    _teacherPasswordController.dispose();
    _parentEmailController.dispose();
    _parentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitTeacherLogin() async {
    context.unfocus();
    if (!_teacherFormKey.currentState!.validate()) return;

    await ref.read(teacherAuthProvider.notifier).signIn(
          email: _teacherEmailController.text.trim(),
          password: _teacherPasswordController.text,
        );

    if (!mounted) return;
    final state = ref.read(teacherAuthProvider);
    if (state.isSuccess) {
      context.go('/teacher/home');
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
      ref.read(teacherAuthProvider.notifier).clearError();
    }
  }

  Future<void> _submitParentLogin() async {
    context.unfocus();
    if (!_parentFormKey.currentState!.validate()) return;

    await ref.read(parentAuthProvider.notifier).signIn(
          email: _parentEmailController.text.trim(),
          password: _parentPasswordController.text,
        );

    if (!mounted) return;
    final state = ref.read(parentAuthProvider);
    if (state.isSuccess) {
      context.go('/parent/home');
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
      ref.read(parentAuthProvider.notifier).clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherAuthProvider);
    final parentState = ref.watch(parentAuthProvider);
    final isLoading = teacherState.isLoading || parentState.isLoading;

    final activeColor =
        _isTeacherRole ? AppColors.teacherPrimary : AppColors.parentPrimary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pagePadding * 1.2,
            vertical: AppSizes.pagePadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    const EdulyLogo(size: 84),
                    const SizedBox(height: 12),
                    Text(
                      'Eduly',
                      style: AppTextStyles.h1.copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ödev & Eğitim Takip Platformu',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleTabButton(
                        title: 'Öğretmen',
                        icon: Icons.school_rounded,
                        isSelected: _isTeacherRole,
                        activeColor: AppColors.teacherPrimary,
                        onTap: () => setState(() => _isTeacherRole = true),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _RoleTabButton(
                        title: 'Veli',
                        icon: Icons.family_restroom_rounded,
                        isSelected: !_isTeacherRole,
                        activeColor: AppColors.parentPrimary,
                        onTap: () => setState(() => _isTeacherRole = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isTeacherRole)
                _buildEmailPasswordForm(
                  formKey: _teacherFormKey,
                  emailController: _teacherEmailController,
                  passwordController: _teacherPasswordController,
                  isLoading: isLoading,
                  accent: AppColors.teacherPrimary,
                  submitLabel: 'Öğretmen Girişi Yap',
                  onSubmit: _submitTeacherLogin,
                  registerLabel: 'Öğretmen Kaydı Oluştur',
                  onRegister: () => context.push('/register/teacher'),
                )
              else
                _buildEmailPasswordForm(
                  formKey: _parentFormKey,
                  emailController: _parentEmailController,
                  passwordController: _parentPasswordController,
                  isLoading: isLoading,
                  accent: AppColors.parentPrimary,
                  submitLabel: 'Veli Girişi Yap',
                  onSubmit: _submitParentLogin,
                  registerLabel: 'Davet Koduyla Kayıt Ol',
                  onRegister: () => context.push('/register/parent'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPasswordForm({
    required GlobalKey<FormState> formKey,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required bool isLoading,
    required Color accent,
    required String submitLabel,
    required VoidCallback onSubmit,
    required String registerLabel,
    required VoidCallback onRegister,
  }) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            label: 'E-posta',
            hint: 'ornek@okul.com',
            controller: emailController,
            prefixIcon: Icon(Icons.email_outlined, color: accent),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty || !v.contains('@')) {
                return 'Geçerli bir e-posta giriniz';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSizes.itemSpacing),
          AppTextField(
            label: 'Şifre',
            hint: 'Şifrenizi girin',
            controller: passwordController,
            isPassword: true,
            prefixIcon: Icon(Icons.lock_outline_rounded, color: accent),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Lütfen şifrenizi girin';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'Şifremi Unuttum?',
                style: AppTextStyles.labelLarge.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: submitLabel,
            onPressed: onSubmit,
            isLoading: isLoading,
            backgroundColor: accent,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hesabınız yok mu? ', style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: onRegister,
                child: Text(
                  registerLabel,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  const _RoleTabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
