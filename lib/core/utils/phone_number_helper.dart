/// Uluslararası ve Türkiye E.164 Telefon Numarası Formatlayıcı & Doğrulayıcı
class PhoneNumberHelper {
  PhoneNumberHelper._();

  /// Telefon numarasını standart E.164 formatına dönüştürür.
  /// Desteklenen Giriş Biçimleri:
  /// - '05315635049' -> '+905315635049'
  /// - '5315635049'  -> '+905315635049'
  /// - '+905315635049' -> '+905315635049'
  /// - '+90 531 563 50 49' -> '+905315635049'
  /// - '905315635049' -> '+905315635049'
  static String normalizeToE164(String input,
      {String defaultCountryCode = '+90'}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Telefon numarası boş olamaz.');
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      throw ArgumentError('Telefon numarası geçerli rakam içermelidir.');
    }

    // 1. Zaten + ile başlıyorsa
    if (trimmed.startsWith('+')) {
      return '+$digits';
    }

    // 2. 90 ile başlayan 12 haneli Türkiye numarası (905XXXXXXXXX)
    if (digits.length == 12 && digits.startsWith('905')) {
      return '+$digits';
    }

    // 3. 0 ile başlayan 11 haneli Türkiye numarası (05XXXXXXXXX)
    if (digits.length == 11 && digits.startsWith('05')) {
      return '+90${digits.substring(1)}';
    }

    // 4. 10 haneli Türkiye cep numarası (5XXXXXXXXX)
    if (digits.length == 10 && digits.startsWith('5')) {
      return '+90$digits';
    }

    // 5. 90 ile başlayan diğer 12 haneli numaralar
    if (digits.length == 12 && digits.startsWith('90')) {
      return '+$digits';
    }

    // 6. 0 ile başlayan diğer 11 haneli sabit veya özel numaralar
    if (digits.length == 11 && digits.startsWith('0')) {
      return '+90${digits.substring(1)}';
    }

    // 7. Diğer uluslararası veya yerel numaralar için defaultCountryCode ekle
    final cleanCountryCode = defaultCountryCode.replaceAll(RegExp(r'\D'), '');
    return '+$cleanCountryCode$digits';
  }

  /// Telefon numarasının geçerli bir Türkiye mobil cep telefonu formatında (+905XXXXXXXXX) olup olmadığını denetler.
  /// Turkcell (53X), Vodafone (54X), Türk Telekom (50X, 55X) ve tüm geçerli Türkiye mobil bloklarını kapsar.
  static bool isValidTurkishMobile(String input) {
    try {
      final e164 = normalizeToE164(input);
      // Canonical format: +905XXXXXXXXX (Toplam 13 karakter, +90 ve 5 ile başlayan 10 hane)
      final regex = RegExp(r'^\+905\d{9}$');
      return regex.hasMatch(e164);
    } catch (_) {
      return false;
    }
  }

  /// Genel E.164 sözdizim denetimi (ITU-T E.164: + ve 8-15 rakam)
  static bool isValidE164(String input) {
    try {
      final e164 = normalizeToE164(input);
      final regex = RegExp(r'^\+[1-9]\d{7,14}$');
      return regex.hasMatch(e164);
    } catch (_) {
      return false;
    }
  }

  /// Kullanıcı arayüzü ve loglar için gizlenmiş (maskelenmiş) numara üretir.
  /// Örnek: '+905315635049' veya '0531 563 50 49' -> '+90 531 *** ** 49'
  static String maskPhoneNumber(String phone) {
    try {
      final e164 = normalizeToE164(phone);
      if (e164.length < 10) return '***';
      if (e164.startsWith('+90') && e164.length == 13) {
        final country = e164.substring(0, 3); // +90
        final operatorCode = e164.substring(3, 6); // 531
        final lastTwo = e164.substring(e164.length - 2); // 49
        return '$country $operatorCode *** ** $lastTwo';
      }
      final start = e164.substring(0, (e164.length > 5 ? 5 : 2));
      final end = e164.substring(e164.length - 2);
      return '$start *** ** $end';
    } catch (_) {
      return '***';
    }
  }
}
