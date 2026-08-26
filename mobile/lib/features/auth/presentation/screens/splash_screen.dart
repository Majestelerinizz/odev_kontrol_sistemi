import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odev_takip/features/auth/presentation/providers/auth_providers.dart';
import 'package:odev_takip/core/theme/app_colors.dart';
import 'package:odev_takip/core/theme/app_text_styles.dart';
import 'package:odev_takip/core/widgets/eduly_logo.dart';

/// Splash ekranı.
/// Logo gösterir; auth/profil hazır olunca hoş geldiniz veya ana ekrana yönlendirir.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  Timer? _timer;
  Timer? _profileWaitTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && !_navigated) {
        _performNavigation();
      }
    });
  }

  void _performNavigation() {
    if (_navigated || !mounted) return;

    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Firebase oturumu var, profil henüz stream'de değil — bekle
    if (firebaseUser != null && user == null) {
      _profileWaitTimer ??= Timer(const Duration(seconds: 8), () async {
        if (!mounted || _navigated) return;
        // Profil gelmedi: bozuk hesap — çıkış yap, welcome'a git
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (_) {}
        if (!mounted || _navigated) return;
        _navigated = true;
        context.go('/welcome');
      });
      return;
    }

    _navigated = true;
    _profileWaitTimer?.cancel();

    if (user != null) {
      context.go(user.isTeacher ? '/teacher/home' : '/parent/home');
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _profileWaitTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (next is AsyncData && !_navigated) {
        _performNavigation();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.teacherPrimary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EdulyLogo(size: 104),
                const SizedBox(height: 20),
                Text(
                  'Eduly',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ödev & Eğitim Takip Platformu',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textOnPrimaryMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
