// ═══════════════════════════════════════════════════════════════
// lib/core/services/postgres_api_service.dart
//
// Flutter'dan Node.js sync backend'ine HTTP istekleri gönderir.
// Firebase birincil veri kaynağı olmaya devam eder.
// Bu servis sadece yedek sorguları ve manuel sync için kullanılır.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:http/http.dart' as http;

class PostgresApiService {
  PostgresApiService._();
  static final PostgresApiService instance = PostgresApiService._();

  // ── Yapılandırma ────────────────────────────────────────────
  // Geliştirme: Android emülatör → host PC'ye ulaşmak için 10.0.2.2
  // Gerçek cihaz: bilgisayarınızın yerel IP adresi (örn: 192.168.1.x)
  static const String _baseUrl = 'http://10.0.2.2:3001/api';
  static const String _apiKey  = 'odev_takip_secret_key_2026'; // .env ile eşleşmeli

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      };

  // ── Sync servisi sağlık kontrolü ────────────────────────────
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Backend çalışmıyorsa Firebase'e devam et
    }
    return null;
  }

  // ── Sync istatistiklerini getir ──────────────────────────────
  Future<Map<String, dynamic>?> getSyncStats() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/sync/stats'), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Manuel tam sync tetikle ─────────────────────────────────
  Future<bool> triggerFullSync() async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/sync/full'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── PostgreSQL'den öğrenci listesi al (yedek sorgu) ─────────
  Future<List<Map<String, dynamic>>> fetchStudentsFromPostgres({
    String? teacherId,
    String? classId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (teacherId != null) queryParams['teacherId'] = teacherId;
      if (classId != null) queryParams['classId'] = classId;

      final uri = Uri.parse('$_baseUrl/data/students')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data'] as List);
      }
    } catch (_) {}
    return [];
  }

  // ── PostgreSQL'den sınav sonuçları al (yedek sorgu) ─────────
  Future<List<Map<String, dynamic>>> fetchExamResultsFromPostgres(
      String studentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/data/exam-results')
          .replace(queryParameters: {'studentId': studentId});

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data'] as List);
      }
    } catch (_) {}
    return [];
  }

  // ── Son sync loglarını getir ────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchSyncLog({int limit = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/data/sync-log')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(body['data'] as List);
      }
    } catch (_) {}
    return [];
  }

  // ── Backend çalışıyor mu? ────────────────────────────────────
  Future<bool> isBackendAlive() async {
    final health = await checkHealth();
    return health != null;
  }
}
