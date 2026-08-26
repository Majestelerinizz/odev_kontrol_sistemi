import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text_styles.dart';

/// Uygulama tema tanımları.
/// Öğretmen ve Veli için ayrı renk varyantları içerir.
class AppTheme {
  AppTheme._();

  /// Öğretmen teması (lacivert-mavi)
  static ThemeData teacherTheme() => _buildTheme(
        seedColor: AppColors.teacherPrimary,
        primaryColor: AppColors.teacherPrimary,
        primarySurface: AppColors.teacherSurface,
      );

  /// Veli teması (yeşil)
  static ThemeData parentTheme() => _buildTheme(
        seedColor: AppColors.parentPrimary,
        primaryColor: AppColors.parentPrimary,
        primarySurface: AppColors.parentSurface,
      );

  /// Genel uygulama teması (öğretmen varsayılan)
  static ThemeData get light => teacherTheme();

  static ThemeData _buildTheme({
    required Color seedColor,
    required Color primaryColor,
    required Color primarySurface,
  }) {
    // Tek kaynak: AppTextStyles → ThemeData.textTheme
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.h1,
      displayMedium: AppTextStyles.h2,
      displaySmall: AppTextStyles.h3,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,
      titleLarge: AppTextStyles.h3,
      titleMedium: AppTextStyles.h4,
      titleSmall: AppTextStyles.labelLarge,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.buttonMedium,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: primaryColor,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
      ),

      // ── Scaffold ──────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.shadow,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: AppSizes.iconMd,
        ),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: primarySurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryColor,
            );
          }
          return AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: AppSizes.iconMd);
          }
          return const IconThemeData(
            color: AppColors.textSecondary,
            size: AppSizes.iconMd,
          );
        }),
        elevation: 0,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        height: AppSizes.bottomNavHeight,
      ),

      // ── ElevatedButton ─────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize:
              const Size(double.infinity, AppSizes.primaryButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          elevation: 0,
          textStyle: AppTextStyles.buttonLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // ── OutlinedButton ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize:
              const Size(double.infinity, AppSizes.primaryButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          side: BorderSide(color: primaryColor, width: 1.5),
          textStyle: AppTextStyles.buttonLarge.copyWith(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(0, AppSizes.minimumTouchTarget),
          textStyle: AppTextStyles.labelLarge.copyWith(color: primaryColor),
        ),
      ),

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTextStyles.inputHint,
        labelStyle: AppTextStyles.inputLabel,
        errorStyle: AppTextStyles.inputError,
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: primarySurface,
        labelStyle: AppTextStyles.labelMedium,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Dialog ─────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
        ),
        titleTextStyle: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
        contentTextStyle: AppTextStyles.bodyMedium,
        elevation: 8,
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),

      // ── ListTile ───────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        minLeadingWidth: 0,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        tileColor: Colors.transparent,
        titleTextStyle: AppTextStyles.h4,
        subtitleTextStyle: AppTextStyles.bodySmall,
        iconColor: AppColors.textSecondary,
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primarySurface;
          return AppColors.border;
        }),
      ),

      // ── ProgressIndicator ──────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primarySurface,
        circularTrackColor: primarySurface,
      ),
    );
  }
}
