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

/// Şifremi unuttum ekranı
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(passwordResetProvider.notifier)
        .sendResetEmail(_emailController.text.trim());

    if (!mounted) return;
    final state = ref.read(passwordResetProvider);
    if (state.isSuccess) {
      context.showSnackBar(AppStrings.successPasswordReset);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.pop();
      });
    } else if (state.errorMessage != null) {
      context.showSnackBar(state.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.info,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(AppStrings.forgotPassword, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  'E-posta adresinizi girin. Size şifre sıfırlama bağlantısı gönderelim.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: AppStrings.email,
                  hint: 'ornek@okul.com',
                  controller: _emailController,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textSecondary),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
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
                if (state.isSuccess) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.successPasswordReset,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                PrimaryButton(
                  label: AppStrings.resetPassword,
                  onPressed: state.isSuccess ? null : _submit,
                  isLoading: state.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
