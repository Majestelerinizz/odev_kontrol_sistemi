/// Türkiye telefon numarası formatlama ve E.164 dönüşümü.
class PhoneUtils {
  PhoneUtils._();

  /// Ham rakamlardan (5XXXXXXXXX) görüntü formatı: 5XX XXX XX XX
  static String formatDisplay(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < d.length && i < 10; i++) {
      if (i == 3 || i == 6 || i == 8) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  /// Görüntü veya ham girişten yalnızca 10 haneli ulusal numara (5 ile başlar).
  static String extractNationalDigits(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('90') && d.length >= 12) {
      d = d.substring(2);
    }
    if (d.startsWith('0') && d.length == 11) {
      d = d.substring(1);
    }
    if (d.length > 10) d = d.substring(0, 10);
    return d;
  }

  /// E.164: +905XXXXXXXXX
  static String toE164(String nationalDigits) {
    final d = extractNationalDigits(nationalDigits);
    return '+90$d';
  }

  static bool isValidNational(String nationalDigits) {
    final d = extractNationalDigits(nationalDigits);
    return d.length == 10 && d.startsWith('5');
  }
}
