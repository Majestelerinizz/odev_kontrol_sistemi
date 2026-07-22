import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Uygulama boyut sabitleri.
/// Master Reference §17.3 doğrultusunda tanımlanmıştır.
class AppSizes {
  AppSizes._();

  // ── Butonlar ──────────────────────────────────────────────────────────────
  static const double primaryButtonHeight = 56.0;
  static const double secondaryButtonHeight = 48.0;
  static const double minimumTouchTarget = 48.0;

  // ── Köşe yarıçapları ─────────────────────────────────────────────────────
  static const double cardRadius = 14.0;
  static const double inputRadius = 12.0;
  static const double buttonRadius = 14.0;
  static const double chipRadius = 20.0;
  static const double dialogRadius = 20.0;
  static const double bottomSheetRadius = 24.0;

  // ── Boşluklar ─────────────────────────────────────────────────────────────
  static const double pagePadding = 16.0;
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double itemSpacing = 12.0;
  static const double smallSpacing = 8.0;
  static const double tinySpacing = 4.0;

  // ── Liste öğeleri ─────────────────────────────────────────────────────────
  static const double listItemMinHeight = 72.0;
  static const double listItemSmallHeight = 56.0;

  // ── İkonlar ───────────────────────────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Avatar ────────────────────────────────────────────────────────────────
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;

  // ── AppBar ────────────────────────────────────────────────────────────────
  static const double appBarHeight = 64.0;

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  static const double bottomNavHeight = 72.0;
}

/// Uygulama gölge tanımları
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];
}
