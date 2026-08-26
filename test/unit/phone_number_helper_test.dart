import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/core/utils/phone_number_helper.dart';

void main() {
  group('PhoneNumberHelper Tests — Türkiye E.164 Standartları', () {
    test(
        'Tüm geçerli Türkiye giriş formatlarını canonical +905315635049 formatına dönüştürür',
        () {
      // 1. 0 ile başlayan standart format
      expect(PhoneNumberHelper.normalizeToE164('05315635049'),
          equals('+905315635049'));
      // 2. 0 olmadan 10 hane
      expect(PhoneNumberHelper.normalizeToE164('5315635049'),
          equals('+905315635049'));
      // 3. +90 ile başlayan
      expect(PhoneNumberHelper.normalizeToE164('+905315635049'),
          equals('+905315635049'));
      // 4. Boşluklu +90
      expect(PhoneNumberHelper.normalizeToE164('+90 531 563 50 49'),
          equals('+905315635049'));
      // 5. 90 ile başlayan 12 hane
      expect(PhoneNumberHelper.normalizeToE164('905315635049'),
          equals('+905315635049'));
      // 6. Karışık parantez ve tireli girişler
      expect(PhoneNumberHelper.normalizeToE164('(0531) 563-50-49'),
          equals('+905315635049'));
    });

    test('isValidTurkishMobile tüm Türkiye GSM operatörlerini doğrular', () {
      // Turkcell (53X)
      expect(PhoneNumberHelper.isValidTurkishMobile('05315635049'), isTrue);
      expect(PhoneNumberHelper.isValidTurkishMobile('5321112233'), isTrue);
      // Vodafone (54X)
      expect(PhoneNumberHelper.isValidTurkishMobile('05421234567'), isTrue);
      expect(PhoneNumberHelper.isValidTurkishMobile('5449998877'), isTrue);
      // Türk Telekom (50X, 55X)
      expect(PhoneNumberHelper.isValidTurkishMobile('05051234567'), isTrue);
      expect(PhoneNumberHelper.isValidTurkishMobile('5551234567'), isTrue);
      expect(
          PhoneNumberHelper.isValidTurkishMobile('+90 507 000 00 00'), isTrue);
    });

    test('isValidTurkishMobile geçersiz girişleri ve sabit hatları reddeder',
        () {
      // Sabit hat (0212, 0312, 0216 vb.)
      expect(PhoneNumberHelper.isValidTurkishMobile('02121234567'), isFalse);
      expect(PhoneNumberHelper.isValidTurkishMobile('03124445566'), isFalse);
      // Eksik hane
      expect(PhoneNumberHelper.isValidTurkishMobile('0531563'), isFalse);
      expect(PhoneNumberHelper.isValidTurkishMobile('12345'), isFalse);
      // Fazla hane
      expect(PhoneNumberHelper.isValidTurkishMobile('0531563504999'), isFalse);
      // Boş / harf içeren giriş
      expect(PhoneNumberHelper.isValidTurkishMobile(''), isFalse);
      expect(PhoneNumberHelper.isValidTurkishMobile('telefon_no'), isFalse);
    });

    test('maskPhoneNumber hassas PII verisini doğru maskeler', () {
      expect(PhoneNumberHelper.maskPhoneNumber('05315635049'),
          equals('+90 531 *** ** 49'));
      expect(PhoneNumberHelper.maskPhoneNumber('+905321234567'),
          equals('+90 532 *** ** 67'));
      expect(PhoneNumberHelper.maskPhoneNumber('+90 542 987 65 43'),
          equals('+90 542 *** ** 43'));
    });

    test('Geçersiz formatta normalizeToE164 ArgumentError fırlatır', () {
      expect(() => PhoneNumberHelper.normalizeToE164(''), throwsArgumentError);
      expect(
          () => PhoneNumberHelper.normalizeToE164('    '), throwsArgumentError);
      expect(
          () => PhoneNumberHelper.normalizeToE164('abc'), throwsArgumentError);
    });
  });
}
