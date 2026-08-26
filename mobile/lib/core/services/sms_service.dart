/// SMS OTP servisi — üretimde kapalı (Phone Auth bu sürümde yok).
class SmsService {
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    return {
      'success': false,
      'message':
          'SMS doğrulama bu sürümde desteklenmiyor. Davet kodu ve e-posta/şifre kullanın.',
    };
  }

  static Future<bool> verifyOtp(String phone, String code) async {
    return false;
  }
}
