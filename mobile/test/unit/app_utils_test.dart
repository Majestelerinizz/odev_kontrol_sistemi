import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/core/utils/app_utils.dart';
import 'package:odev_takip/core/extensions/extensions.dart';

void main() {
  group('NetCalculator', () {
    test('doğru net hesaplar (4 yanlış = 1 doğru)', () {
      expect(NetCalculator.calculate(20, 4), 19.0);
      expect(NetCalculator.calculate(16, 4), 15.0);
      expect(NetCalculator.calculate(40, 0), 40.0);
      expect(NetCalculator.calculate(0, 0), 0.0);
    });

    test('negatif sayı hata fırlatır', () {
      expect(
        () => NetCalculator.calculate(-1, 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => NetCalculator.calculate(0, -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('soru sayısı kontrolü çalışır', () {
      // 40 soruluk sınav
      expect(
        NetCalculator.isValid(
            correct: 20, wrong: 10, blank: 10, totalQuestions: 40),
        true,
      );
      expect(
        NetCalculator.isValid(
            correct: 30, wrong: 20, blank: 0, totalQuestions: 40),
        false, // 50 > 40
      );
    });

    test('başarı yüzdesi doğru hesaplanır', () {
      expect(NetCalculator.successPercentage(20, 40), 50.0);
      expect(NetCalculator.successPercentage(40, 40), 100.0);
      expect(NetCalculator.successPercentage(0, 40), 0.0);
    });

    test('sıfır soru sayısında hata vermez', () {
      expect(NetCalculator.successPercentage(0, 0), 0.0);
    });
  });

  group('HomeworkStatusCalculator', () {
    test('completed durumu doğru döner', () {
      final dueDate = DateTime.now().add(const Duration(days: 2));
      expect(
        HomeworkStatusCalculator.calculateDisplayStatus('completed', dueDate),
        'completed',
      );
    });

    test('missed durumu doğru döner', () {
      final dueDate = DateTime.now().add(const Duration(days: 2));
      expect(
        HomeworkStatusCalculator.calculateDisplayStatus('missed', dueDate),
        'missed',
      );
    });

    test('süresi geçmiş pending -> overdue olur', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      expect(
        HomeworkStatusCalculator.calculateDisplayStatus('pending', pastDate),
        'overdue',
      );
    });

    test('süresi geçmemiş pending -> pending kalır', () {
      final futureDate = DateTime.now().add(const Duration(days: 3));
      expect(
        HomeworkStatusCalculator.calculateDisplayStatus('pending', futureDate),
        'pending',
      );
    });

    test('durum etiketleri Türkçe döner', () {
      expect(HomeworkStatusCalculator.statusLabel('completed'), 'Tamamlandı');
      expect(HomeworkStatusCalculator.statusLabel('missed'), 'Yapılmadı');
      expect(HomeworkStatusCalculator.statusLabel('overdue'), 'Gecikti');
      expect(HomeworkStatusCalculator.statusLabel('pending'), 'Bekliyor');
    });
  });

  group('StringExtensions', () {
    test('e-posta geçerliliği', () {
      expect('test@example.com'.isValidEmail, true);
      expect('invalid-email'.isValidEmail, false);
      expect(''.isValidEmail, false);
      expect('user@'.isValidEmail, false);
    });

    test('şifre geçerliliği (min 8 karakter)', () {
      expect('12345678'.isValidPassword, true);
      expect('1234567'.isValidPassword, false);
      expect(''.isValidPassword, false);
    });

    test('capitalize çalışır', () {
      expect('flutter'.capitalize, 'Flutter');
      expect('FLUTTER'.capitalize, 'Flutter');
    });
  });

  group('DateTimeExtensions', () {
    test('isToday bugün için true döner', () {
      expect(DateTime.now().isToday, true);
    });

    test('geçmiş tarih isPast true döner', () {
      expect(
        DateTime.now().subtract(const Duration(days: 1)).isPast,
        true,
      );
    });

    test('gelecek tarih isPast false döner', () {
      expect(
        DateTime.now().add(const Duration(days: 1)).isPast,
        false,
      );
    });

    test('Türkçe tarih formatı doğru üretilir', () {
      final date = DateTime(2026, 7, 22);
      expect(date.toTurkishDate(), '22 Temmuz 2026');
    });
  });
}
