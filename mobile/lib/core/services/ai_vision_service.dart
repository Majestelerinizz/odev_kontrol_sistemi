/// AI Vision sınav analizi — üretimde kapalı (sahte başarı yok).
class AiVisionService {
  static Future<Map<String, dynamic>> analyzeExamPhoto({
    required String imageBase64,
    String subject = 'Matematik',
  }) async {
    return {
      'success': false,
      'error':
          'AI fotoğraf analizi şu an kullanılamıyor. Sonuçları manuel girin.',
      'subject': subject,
    };
  }
}
