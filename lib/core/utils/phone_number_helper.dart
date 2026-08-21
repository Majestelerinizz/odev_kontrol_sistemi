/// Uluslararası ve Türkiye E.164 Telefon Numarası Formatlayıcı & Doğrulayıcı
class PhoneNumberHelper {
  PhoneNumberHelper._();

  /// Telefon numarasını standart E.164 formatına dönüştürür.
  /// Örnekler:
  /// - '05315635049' -> '+905315635049'
  /// - '5315635049'  -> '+905315635049'
  /// - '+90 531 563 50 49' -> '+905315635049'
  static String normalizeToE164(String input, {String defaultCountryCode = '+90'}) {
    final digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      throw ArgumentError('Telefon numarası boş olamaz.');
    }

    // Zaten uluslararası kodla başlıyorsa (+90...)
    if (input.trim().startsWith('+')) {
      return '+$digits';
    }

    // 0 ile başlıyorsa (Örn: 0532...) -> Türkiye (+90)
    if (digits.startsWith('0') && digits.length == 11) {
      return '+90${digits.substring(1)}';
    }

    // 10 haneli Türkiye cep numarası (Örn: 5321234567)
    if (digits.length == 10 && (digits.startsWith('5'))) {
      return '+90$digits';
    }

    // 90 ile başlayan 12 haneli numara (Örn: 905321234567)
    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }

    // Diğer durumlar için defaultCountryCode ekle
    final cleanCountryCode = defaultCountryCode.replaceAll(RegExp(r'\D'), '');
    return '+$cleanCountryCode$digits';
  }

  /// Telefon numarasının geçerli bir cep telefonu formatında olup olmadığını denetler.
  static bool isValidTurkishMobile(String input) {
    try {
      final e164 = normalizeToE164(input);
      // +905XXXXXXXXX formatı (13 karakter: +90 ve ardından 10 hane, ilk hane 5)
      final regex = RegExp(r'^\+905[0-9]{9}$');
      return regex.hasMatch(e164);
    } catch (_) {
      return false;
    }
  }

  /// Genel E.164 sözdizim denetimi
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
  /// Örnek: '+90 531 563 50 49' -> '+90 531 *** ** 49'
  static String maskPhoneNumber(String phone) {
    try {
      final e164 = normalizeToE164(phone);
      if (e164.length < 10) return '***';
      final country = e164.substring(0, 3); // +90
      final operatorCode = e164.substring(3, 6); // 531
      final lastTwo = e164.substring(e164.length - 2); // 49
      return '$country $operatorCode *** ** $lastTwo';
    } catch (_) {
      return '***';
    }
  }
}
