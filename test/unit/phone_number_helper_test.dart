import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/core/utils/phone_number_helper.dart';

void main() {
  group('PhoneNumberHelper Tests', () {
    test('0 ile başlayan Türkiye numarasını E.164 formatına çevirir', () {
      expect(PhoneNumberHelper.normalizeToE164('05315635049'), equals('+905315635049'));
      expect(PhoneNumberHelper.normalizeToE164('0542 123 45 67'), equals('+905421234567'));
    });

    test('0 olmadan girilen 10 haneli numarayı E.164 formatına çevirir', () {
      expect(PhoneNumberHelper.normalizeToE164('5315635049'), equals('+905315635049'));
    });

    test('+90 ile başlayan numarayı korur ve boşlukları temizler', () {
      expect(PhoneNumberHelper.normalizeToE164('+90 531 563 50 49'), equals('+905315635049'));
    });

    test('isValidTurkishMobile doğru operatörleri doğrular', () {
      expect(PhoneNumberHelper.isValidTurkishMobile('05315635049'), isTrue); // Turkcell
      expect(PhoneNumberHelper.isValidTurkishMobile('05421234567'), isTrue); // Vodafone
      expect(PhoneNumberHelper.isValidTurkishMobile('05051234567'), isTrue); // Türk Telekom
      expect(PhoneNumberHelper.isValidTurkishMobile('02121234567'), isFalse); // Sabit Hat (Geçersiz)
      expect(PhoneNumberHelper.isValidTurkishMobile('12345'), isFalse);
    });

    test('maskPhoneNumber hassas numarayı doğru maskeler', () {
      final masked = PhoneNumberHelper.maskPhoneNumber('05315635049');
      expect(masked, equals('+90 531 *** ** 49'));
    });
  });
}
