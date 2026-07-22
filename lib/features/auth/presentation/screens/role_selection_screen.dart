import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// Öğretmen / Veli rol seçimi ekranı.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.roleSelectionTitle,
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.roleSelectionSubtitle,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 40),

                // ── Öğretmen kartı ────────────────────────────────────────
                _RoleCard(
                  title: AppStrings.roleTeacher,
                  description: AppStrings.teacherRoleDesc,
                  icon: Icons.person_rounded,
                  primaryColor: AppColors.teacherPrimary,
                  surfaceColor: AppColors.teacherSurface,
                  features: const [
                    'Sınıf ve öğrenci yönetimi',
                    'Ödev ve deneme takibi',
                    'Veli bilgilendirme',
                  ],
                  onTap: () => context.push('/register/teacher'),
                ),
                const SizedBox(height: 20),

                // ── Veli kartı ────────────────────────────────────────────
                _RoleCard(
                  title: AppStrings.roleParent,
                  description: AppStrings.parentRoleDesc,
                  icon: Icons.family_restroom_rounded,
                  primaryColor: AppColors.parentPrimary,
                  surfaceColor: AppColors.parentSurface,
                  features: const [
                    'Çocuğunun ödev durumunu görün',
                    'Deneme sonuçlarını takip edin',
                    'Öğretmen mesajlarını okuyun',
                  ],
                  onTap: () => context.push('/register/parent'),
                ),

                const Spacer(),

                // ── Giriş bağlantısı ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zaten hesabınız var mı? ',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.surfaceColor,
    required this.features,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color surfaceColor;
  final List<String> features;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHovered ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(
              color: _isHovered ? widget.primaryColor : AppColors.border,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.primaryColor.withAlpha(26),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: AppTextStyles.h3),
                        const SizedBox(height: 2),
                        Text(
                          widget.description,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: widget.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              ...widget.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: widget.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(f, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
