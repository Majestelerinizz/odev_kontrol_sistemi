import 'package:flutter_test/flutter_test.dart';
import 'package:odev_takip/features/auth/presentation/utils/phone_utils.dart';

void main() {
  group('PhoneUtils', () {
    test('formatDisplay formats 10 digits', () {
      expect(PhoneUtils.formatDisplay('5321234567'), '532 123 45 67');
    });

    test('extractNationalDigits strips country code', () {
      expect(PhoneUtils.extractNationalDigits('+905321234567'), '5321234567');
    });

    test('toE164 produces +90 prefix', () {
      expect(PhoneUtils.toE164('5321234567'), '+905321234567');
    });

    test('isValidNational accepts Turkish mobile', () {
      expect(PhoneUtils.isValidNational('5321234567'), isTrue);
      expect(PhoneUtils.isValidNational('4321234567'), isFalse);
      expect(PhoneUtils.isValidNational('53212'), isFalse);
    });
  });
}
