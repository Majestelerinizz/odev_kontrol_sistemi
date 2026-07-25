import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/extensions/extensions.dart';

/// MatPusula Şık Giriş Ekranı (Panel 1 Tasarımı)
/// Öğretmen ve Veli için esnek Telefon / E-posta / Kullanıcı Adı ile giriş desteği
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isTeacherRole = true; // true = Öğretmen, false = Veli
  bool _isParentPhoneMode = true; // Veli için: true = Telefon, false = E-posta

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    context.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final input = _identityController.text.trim();
    final password = _passwordController.text;

    if (_isTeacherRole) {
      await ref.read(teacherAuthProvider.notifier).signIn(
            email: input,
            password: password,
          );
      if (!mounted) return;
      final state = ref.read(teacherAuthProvider);
      if (state.errorMessage != null) {
        context.showSnackBar(state.errorMessage!, isError: true);
        ref.read(teacherAuthProvider.notifier).clearError();
      }
    } else {
      await ref.read(parentAuthProvider.notifier).signIn(
            email: input,
            password: password,
          );
      if (!mounted) return;
      final state = ref.read(parentAuthProvider);
      if (state.errorMessage != null) {
        context.showSnackBar(state.errorMessage!, isError: true);
        ref.read(parentAuthProvider.notifier).clearError();
      }
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ── MatPusula Logo & Slogan Header ─────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: activeColor.withAlpha(20),
                          shape: BoxShape.circle,
                          border: Border.all(color: activeColor, width: 2),
                        ),
                        child: Icon(
                          Icons.explore_rounded,
                          size: 44,
                          color: activeColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'MatPusula',
                        style: AppTextStyles.h1.copyWith(
                          color: activeColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Geleceğini Matematikle Şekillendir',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Kullanıcı Türü Seçimi (Rol Kartları) ────────────────────
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
                          onTap: () {
                            setState(() {
                              _isTeacherRole = true;
                              _identityController.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _RoleTabButton(
                          title: 'Veli',
                          icon: Icons.family_restroom_rounded,
                          isSelected: !_isTeacherRole,
                          activeColor: AppColors.parentPrimary,
                          onTap: () {
                            setState(() {
                              _isTeacherRole = false;
                              _identityController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Veli İçin Giriş Türü Seçici (Telefon / E-posta) ────────
                if (!_isTeacherRole) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Row(
                          children: [
                            Icon(Icons.phone_android_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Telefon No ile Giriş'),
                          ],
                        ),
                        selected: _isParentPhoneMode,
                        selectedColor: AppColors.parentPrimary.withAlpha(40),
                        labelStyle: TextStyle(
                          color: _isParentPhoneMode
                              ? AppColors.parentPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _isParentPhoneMode = true;
                            _identityController.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Row(
                          children: [
                            Icon(Icons.email_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('E-posta ile Giriş'),
                          ],
                        ),
                        selected: !_isParentPhoneMode,
                        selectedColor: AppColors.parentPrimary.withAlpha(40),
                        labelStyle: TextStyle(
                          color: !_isParentPhoneMode
                              ? AppColors.parentPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _isParentPhoneMode = false;
                            _identityController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Dinamik Giriş Alanı (Girdi Kutusu) ─────────────────────
                AppTextField(
                  label: _isTeacherRole
                      ? 'Kullanıcı Adı, E-posta veya Telefon'
                      : (_isParentPhoneMode
                          ? 'Telefon Numarası'
                          : 'Veli E-posta Adresi'),
                  hint: _isTeacherRole
                      ? 'ahmet@okul.com / 05XX... / ahmet123'
                      : (_isParentPhoneMode
                          ? '05XX XXX XX XX'
                          : 'veli@email.com'),
                  controller: _identityController,
                  prefixIcon: Icon(
                    _isTeacherRole
                        ? Icons.person_outline_rounded
                        : (_isParentPhoneMode
                            ? Icons.phone_android_rounded
                            : Icons.email_outlined),
                    color: activeColor,
                  ),
                  keyboardType: !_isTeacherRole && _isParentPhoneMode
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Lütfen bu alanı doldurun';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.itemSpacing),

                // ── Şifre Alanı ───────────────────────────────────────────
                AppTextField(
                  label: 'Şifre',
                  hint: 'Şifrenizi girin',
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon:
                      Icon(Icons.lock_outline_rounded, color: activeColor),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Lütfen şifrenizi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // ── Şifremi Unuttum ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Şifremi Unuttum?',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Giriş Yap Butonu ──────────────────────────────────────
                PrimaryButton(
                  label: 'Giriş Yap 🚀',
                  onPressed: _submit,
                  isLoading: isLoading,
                  backgroundColor: activeColor,
                ),
                const SizedBox(height: 24),

                // ── Kayıt Yönlendirmesi ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabınız yok mu?',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        if (_isTeacherRole) {
                          context.push('/register/teacher');
                        } else {
                          context.push('/register/parent');
                        }
                      },
                      child: Text(
                        'Hemen Kayıt Ol',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: activeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kullanıcı Türü Seçim Butonu Component
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
