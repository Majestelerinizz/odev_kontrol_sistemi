import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Sistem UI ayarları ────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Yalnızca dikey yönlendirme
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase başlatma ─────────────────────────────────────────────────────
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDZ80PElxFSEjX8G5-LhM36H-UOWO0SJUM",
          appId: "1:763956808451:web:37b5b0f6a85848b240b736",
          messagingSenderId: "763956808451",
          projectId: "eduly-server",
          authDomain: "eduly-server.firebaseapp.com",
          storageBucket: "eduly-server.firebasestorage.app",
          measurementId: "G-6WVK3D5NWE",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialize warning: $e');
  }

  // Crashlytics: web'de yok; debug'da kapalı (gürültüyü önle)
  if (!kIsWeb) {
    final crashlyticsEnabled = !kDebugMode;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(crashlyticsEnabled);
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (crashlyticsEnabled) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (crashlyticsEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  await FcmService.initialize();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
