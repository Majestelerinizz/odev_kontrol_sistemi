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
import '../../../../core/extensions/extensions.dart';

/// Giriş ekranı (öğretmen ve veli için ortak)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Önce öğretmen girişi dene; başarısız olursa veli dene
    await ref.read(teacherAuthProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final state = ref.read(teacherAuthProvider);
    if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
      ref.read(teacherAuthProvider.notifier).clearError();
    }
    // Yönlendirme router'daki authStateProvider tarafından yapılır
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(teacherAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Başlık ────────────────────────────────────────────────
                Text(AppStrings.welcomeBack, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  'Hesabınıza giriş yapın.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 40),

                // ── E-posta ───────────────────────────────────────────────
                AppTextField(
                  label: AppStrings.email,
                  hint: 'ornek@okul.com',
                  controller: _emailController,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textSecondary),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: AppSizes.itemSpacing),

                // ── Şifre ─────────────────────────────────────────────────
                AppTextField(
                  label: AppStrings.password,
                  hint: 'Şifrenizi girin',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textSecondary),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.errorPasswordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Şifremi unuttum ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, AppSizes.minimumTouchTarget),
                    ),
                    child: Text(
                      AppStrings.forgotPassword,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.teacherPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Giriş butonu ──────────────────────────────────────────
                PrimaryButton(
                  label: AppStrings.login,
                  onPressed: _submit,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 24),

                // ── Ayırıcı ───────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('veya', style: AppTextStyles.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Kayıt ol ──────────────────────────────────────────────
                SecondaryButton(
                  label: 'Hesap Oluştur',
                  onPressed: () => context.push('/role-selection'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
