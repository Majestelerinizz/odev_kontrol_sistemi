import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_buttons.dart';

/// Hoş geldiniz ekranı.
/// Uygulama açıldığında gösterilir; giriş veya kayıt seçenekleri sunar.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.teacherPrimary,
              Color(0xFF1A4FA0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding * 1.5),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // ── Logo ──────────────────────────────────────────────
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 40,
                        color: AppColors.teacherPrimary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Başlık ────────────────────────────────────────────
                    Text(
                      'Ödev Takip',
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Öğretmenler için merkezi sınıf yönetimi,\nveliler için şeffaf çocuk takibi.',
                      style:
                          AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                    ),

                    // ── Özellik listesi ───────────────────────────────────
                    const SizedBox(height: 40),
                    const _FeatureItem(
                      icon: Icons.assignment_rounded,
                      text: 'Ödev takibi ve durum güncellemesi',
                    ),
                    const SizedBox(height: 16),
                    const _FeatureItem(
                      icon: Icons.bar_chart_rounded,
                      text: 'Deneme sonuçları ve grafikler',
                    ),
                    const SizedBox(height: 16),
                    const _FeatureItem(
                      icon: Icons.track_changes_rounded,
                      text: 'Konu analizi ve hedef takibi',
                    ),
                    const SizedBox(height: 16),
                    const _FeatureItem(
                      icon: Icons.notifications_rounded,
                      text: 'Anlık bildirimler ve mesajlaşma',
                    ),

                    const Spacer(),

                    // ── Butonlar ──────────────────────────────────────────
                    PrimaryButton(
                      label: 'Başlayalım',
                      onPressed: () => context.push('/role-selection'),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.teacherPrimary,
                      icon: Icons.arrow_forward_rounded,
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Giriş Yap',
                      onPressed: () => context.push('/login'),
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
