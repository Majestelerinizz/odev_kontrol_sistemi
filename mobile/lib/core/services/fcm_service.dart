import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

/// FCM token kaydı, yenileme, tap/open ve logout prune.
class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;
  static String? _activeUid;
  static String? _lastToken;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened: ${message.data}');
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('FCM initial: ${initial.data}');
    }

    _messaging.onTokenRefresh.listen((token) async {
      _lastToken = token;
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
      _lastToken = token;
      await _saveToken(uid, token);
    }
    return true;
  }

  static Future<void> syncTokenForUser(String uid) async {
    if (kIsWeb) return;
    _activeUid = uid;
    final settings = await _messaging.getNotificationSettings();
    final authorized = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!authorized) return;

    final token = await _messaging.getToken();
    if (token != null) {
      _lastToken = token;
      await _saveToken(uid, token);
    }
  }

  static Future<void> clearTokenForUser(String uid) async {
    if (kIsWeb) return;
    final token = _lastToken ?? await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .set(
        {
          'fcmTokens': FieldValue.arrayRemove([token]),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }
    _activeUid = null;
    _lastToken = null;
  }

  static Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );
  }
}
