import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// FCM token kaydı ve yenileme.
class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static String? _activeUid;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    });

    _messaging.onTokenRefresh.listen((token) async {
      final uid = _activeUid;
      if (uid != null) await _saveToken(uid, token);
    });
  }

  static Future<bool> requestPermissionAndSaveToken(String uid) async {
    if (kIsWeb) return false;
    _activeUid = uid;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final authorized = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!authorized) return false;

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }
    return true;
  }

  static Future<void> syncTokenForUser(String uid) async {
    if (kIsWeb) return;
    _activeUid = uid;
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);
  }

  static Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}
