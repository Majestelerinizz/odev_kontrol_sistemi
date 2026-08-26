import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Uygulama metin stilleri.
/// Font: Nunito (Google Fonts) — aile korunur; weight / tracking / kontrast iyileştirilir.
class AppTextStyles {
  AppTextStyles._();

  // ── Başlıklar ─────────────────────────────────────────────────────────────

  static TextStyle get h1 => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.4,
      );

  static TextStyle get h2 => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get h4 => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
        letterSpacing: -0.2,
      );

  // ── Gövde metni ───────────────────────────────────────────────────────────

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ── Etiket ────────────────────────────────────────────────────────────────

  static TextStyle get labelLarge => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelSmall => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // ── Buton ─────────────────────────────────────────────────────────────────

  static TextStyle get buttonLarge => GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
        height: 1.2,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonMedium => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
        height: 1.2,
        letterSpacing: 0.2,
      );

  // ── Özel ──────────────────────────────────────────────────────────────────

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  static TextStyle get overline => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
        height: 1.4,
      );

  // ── Input ─────────────────────────────────────────────────────────────────

  static TextStyle get inputText => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get inputHint => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  static TextStyle get inputLabel => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get inputError => GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.error,
        height: 1.4,
      );
}
