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

/// Öğretmen kayıt ekranı
class TeacherRegisterScreen extends ConsumerStatefulWidget {
  const TeacherRegisterScreen({super.key});

  @override
  ConsumerState<TeacherRegisterScreen> createState() =>
      _TeacherRegisterScreenState();
}

class _TeacherRegisterScreenState extends ConsumerState<TeacherRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      context.showSnackBar(AppStrings.errorTermsRequired, isError: true);
      return;
    }

    await ref.read(teacherAuthProvider.notifier).registerTeacher(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final authState = ref.read(teacherAuthProvider);
    if (authState.isSuccess) {
      context.go('/teacher/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(teacherAuthProvider);

    // Hata mesajı göster
    ref.listen(teacherAuthProvider, (_, next) {
      if (next.errorMessage != null) {
        context.showSnackBar(next.errorMessage!, isError: true);
        ref.read(teacherAuthProvider.notifier).clearError();
      }
    });

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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.teacherSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.teacherPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Öğretmen Hesabı',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bilgilerinizi girerek kayıt olun.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),

                // ── Form alanları ─────────────────────────────────────────
                AppTextField(
                  label: AppStrings.fullName,
                  hint: 'Ad Soyad',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: AppColors.textSecondary),
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

                AppTextField(
                  label: AppStrings.password,
                  hint: 'En az 8 karakter',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textSecondary),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.errorPasswordRequired;
                    }
                    if (!v.isValidPassword) {
                      return AppStrings.errorPasswordMin;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.itemSpacing),

                AppTextField(
                  label: AppStrings.passwordConfirm,
                  hint: 'Şifrenizi tekrar girin',
                  controller: _passwordConfirmController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textSecondary),
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return AppStrings.errorPasswordMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Kullanım koşulları ────────────────────────────────────
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (v) =>
                          setState(() => _termsAccepted = v ?? false),
                      activeColor: AppColors.teacherPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        children: [
                          Text(
                            'Okudum, kabul ediyorum: ',
                            style: AppTextStyles.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              AppStrings.termsOfService,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.teacherPrimary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            ' ve ',
                            style: AppTextStyles.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              AppStrings.privacyPolicy,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.teacherPrimary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Kayıt butonu ──────────────────────────────────────────
                PrimaryButton(
                  label: AppStrings.register,
                  onPressed: _submit,
                  isLoading: authState.isLoading,
                  backgroundColor: AppColors.teacherPrimary,
                ),
                const SizedBox(height: 16),

                // ── Giriş bağlantısı ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount + '? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.push('/login'),
                      child: Text(
                        AppStrings.login,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.teacherPrimary,
                        ),
                      ),
                    ),
                  ],
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
