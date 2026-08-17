/// Net hesaplama yardımcısı.
/// Türkiye'deki 4 yanlış 1 doğruyu götürür sistemi baz alınmıştır.
class NetCalculator {
  NetCalculator._();

  /// Net hesapla
  /// [correct] - Doğru sayısı
  /// [wrong] - Yanlış sayısı
  /// [wrongPenalty] - Yanlış cezası (varsayılan 4)
  static double calculate(int correct, int wrong, {double wrongPenalty = 4.0}) {
    if (correct < 0 || wrong < 0) {
      throw ArgumentError('Doğru ve yanlış sayısı negatif olamaz.');
    }
    return correct - (wrong / wrongPenalty);
  }

  /// Toplam soru sayısını aş kontrolü
  static bool isValid({
    required int correct,
    required int wrong,
    required int blank,
    required int totalQuestions,
  }) {
    return (correct + wrong + blank) <= totalQuestions &&
        correct >= 0 &&
        wrong >= 0 &&
        blank >= 0;
  }

  /// Başarı yüzdesini hesapla
  static double successPercentage(int correct, int totalQuestions) {
    if (totalQuestions == 0) return 0;
    return (correct / totalQuestions) * 100;
  }
}

/// Ödev durum hesaplayıcı
class HomeworkStatusCalculator {
  HomeworkStatusCalculator._();

  /// Ödev durumunu hesapla
  /// status: veritabanındaki durum (pending, completed, missed)
  /// dueDate: teslim tarihi
  static String calculateDisplayStatus(String status, DateTime dueDate) {
    if (status == 'completed') return 'completed';
    if (status == 'missed') return 'missed';
    if (status == 'pending' && DateTime.now().isAfter(dueDate)) {
      return 'overdue';
    }
    return 'pending';
  }

  /// Durum rengi (hex string yerine durum adı döner)
  static String statusLabel(String status) {
    return switch (status) {
      'completed' => 'Tamamlandı',
      'missed' => 'Yapılmadı',
      'overdue' => 'Gecikti',
      _ => 'Bekliyor',
    };
  }
}

/// Davet kodu oluşturucu
class InviteCodeGenerator {
  InviteCodeGenerator._();

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Davet kodu oluştur: OT-{grade}{className}-{6 karakter}
  static String generate(int gradeLevel, String className) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    var seed = random;
    for (var i = 0; i < 6; i++) {
      buffer.write(_chars[seed % _chars.length]);
      seed = seed ~/ _chars.length + (seed % 7 + 1) * 31;
    }
    final classInitial = className.isNotEmpty
        ? className[0].toUpperCase()
        : 'A';
    return 'OT-$gradeLevel$classInitial-$buffer';
  }
}
