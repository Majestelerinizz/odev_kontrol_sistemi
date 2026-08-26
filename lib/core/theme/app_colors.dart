import 'package:flutter/material.dart';

/// Uygulamanın tüm renk sabitlerini içerir.
/// Master Reference §17.1 doğrultusunda tanımlanmıştır.
class AppColors {
  AppColors._();

  // ── Öğretmen & Ana tema renkleri (MatPusula Moru & İndigo) ───────────
  static const Color teacherPrimary = Color(0xFF4F46E5);
  static const Color teacherLight = Color(0xFF6366F1);
  static const Color teacherSurface = Color(0xFFEEF2FF);

  // ── Veli renkleri (MatPusula Zümrüt Yeşili) ─────────────────────────
  static const Color parentPrimary = Color(0xFF0D9488);
  static const Color parentLight = Color(0xFF14B8A6);
  static const Color parentSurface = Color(0xFFF0FDFA);

  // ── Vurgu (MatPusula Pusula İğnesi Altını) ───────────────────────────
  static const Color accent = Color(0xFFD97706);

  // ── Durum renkleri ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Ödev durum renkleri ───────────────────────────────────────────────────
  static const Color statusPending = Color(0xFFF59E0B); // Bekliyor
  static const Color statusCompleted = Color(0xFF16A34A); // Tamamlandı
  static const Color statusMissed = Color(0xFFDC2626); // Yapılmadı
  static const Color statusOverdue = Color(0xFF991B1B); // Gecikti

  // ── Nötr / zemin ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // ── Metin ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textDisabled = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Gölge ─────────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x1A0F172A);
}
