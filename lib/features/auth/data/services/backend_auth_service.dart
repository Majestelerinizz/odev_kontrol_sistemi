// ═══════════════════════════════════════════════════════════════
// lib/features/auth/data/services/backend_auth_service.dart
//
// Firebase ID Token'ı Bearer Token olarak Node.js API'ye iletir.
// PostgreSQL 'users' tablosu ile güvenli kullanıcı senkronizasyonu sağlar.
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendAuthResult {
  final bool isSuccess;
  final String? message;
  final Map<String, dynamic>? userData;
  final String? error;

  const BackendAuthResult._({
    required this.isSuccess,
    this.message,
    this.userData,
    this.error,
  });

  factory BackendAuthResult.success({
    required String message,
    Map<String, dynamic>? userData,
  }) =>
      BackendAuthResult._(
        isSuccess: true,
        message: message,
        userData: userData,
      );

  factory BackendAuthResult.failure(String error) => BackendAuthResult._(
        isSuccess: false,
        error: error,
      );
}

class BackendAuthService {
  final String _baseUrl;

  BackendAuthService({String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  static final BackendAuthService instance = BackendAuthService();

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3001/api';
    }
    // Android Emülatör için 10.0.2.2, fiziksel cihazda backend IP
    return 'http://10.0.2.2:3001/api';
  }

  /// Firebase ID Token'ı backend'e iletir ve PostgreSQL users kaydı ile eşitler
  Future<BackendAuthResult> verifySession({
    required String idToken,
    String? name,
    String? role,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/verify-session');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              if (name != null && name.isNotEmpty) 'name': name,
              if (role != null && role.isNotEmpty) 'role': role,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = (data['data'] != null && data['data']['user'] != null)
            ? data['data']['user'] as Map<String, dynamic>
            : data['user'] as Map<String, dynamic>?;

        return BackendAuthResult.success(
          message: data['message'] as String? ?? 'Oturum başarıyla doğrulandı.',
          userData: userData,
        );
      } else if (response.statusCode == 401) {
        return BackendAuthResult.failure(
            data['message'] as String? ?? 'Geçersiz veya süresi dolmuş Firebase oturumu.');
      } else {
        return BackendAuthResult.failure(
            data['message'] as String? ?? 'Sunucu oturum senkronizasyonu başarısız oldu.');
      }
    } catch (e) {
      // Backend offline olsa bile Firebase authentication tamamlandığı için yumuşak hata yönetimi
      debugPrint('⚠️ BackendAuthService sync uyarısı: $e');
      return BackendAuthResult.success(
        message: 'Firebase doğrulaması başarılı (Backend offline senkronizasyon modunda).',
      );
    }
  }

  /// Giriş yapan kullanıcının PostgreSQL profilini sorgular
  Future<Map<String, dynamic>?> getMe({required String idToken}) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/me');
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data']['user'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      debugPrint('⚠️ BackendAuthService getMe uyarısı: $e');
    }
    return null;
  }
}
