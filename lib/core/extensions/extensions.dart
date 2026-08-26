import 'package:flutter/material.dart';

/// Tarih formatlama uzantıları
extension DateTimeExtensions on DateTime {
  /// Türkçe tarih formatı: "22 Temmuz 2026"
  String toTurkishDate() {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '$day ${months[month - 1]} $year';
  }

  /// Kısa format: "22 Tem 2026"
  String toShortTurkishDate() {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '$day ${months[month - 1]} $year';
  }

  /// Saat dahil format: "22 Tem 2026, 14:30"
  String toTurkishDateTime() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '${toShortTurkishDate()}, $h:$m';
  }

  /// Bugün mü?
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Geçmiş mi?
  bool get isPast => isBefore(DateTime.now());

  /// Kaç gün kaldı?
  int daysUntil() {
    final now = DateTime.now();
    final diff = difference(DateTime(now.year, now.month, now.day));
    return diff.inDays;
  }

  /// "X gün önce / X gün sonra" gibi göreceli metin
  String get relativeTime {
    final days = daysUntil();
    if (days == 0) return 'Bugün';
    if (days == 1) return 'Yarın';
    if (days == -1) return 'Dün';
    if (days > 1) return '$days gün sonra';
    return '${days.abs()} gün önce';
  }
}

/// String uzantıları
extension StringExtensions on String {
  /// İlk harfi büyük yap
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// E-posta geçerliliği
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// Davet kodu formatı (OT-8A-XXXXXX)
  bool get isValidInviteCode {
    return RegExp(r'^OT-[0-9]{1,2}[A-Z]-[A-Z0-9]{6}$').hasMatch(this);
  }

  /// Şifre geçerliliği (min 8 karakter)
  bool get isValidPassword => length >= 8;
}

/// Color uzantıları
extension ColorExtensions on Color {
  /// Rengin alpha değerini değiştir
  Color withOpacityValue(double opacity) => withAlpha((opacity * 255).round());
}

/// BuildContext uzantıları
extension BuildContextExtensions on BuildContext {
  /// Tema
  ThemeData get theme => Theme.of(this);

  /// Renk şeması
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Metin temaları
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Ekran boyutu
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Ekran genişliği
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Ekran yüksekliği
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Klavye yüksekliği
  double get keyboardHeight => MediaQuery.viewInsetsOf(this).bottom;

  /// Klavye açık mı?
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// SnackBar göster
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }

  /// Focus kapat
  void unfocus() => FocusScope.of(this).unfocus();
}

/// int / double uzantıları
extension DoubleExtensions on double {
  /// Net hesaplama (4 yanlış 1 doğruyu götürür)
  static double calculateNet(int correct, int wrong, {double penalty = 4.0}) {
    return correct - (wrong / penalty);
  }

  /// 2 ondalık basamaklı string
  String toNetString() => toStringAsFixed(2);
}
