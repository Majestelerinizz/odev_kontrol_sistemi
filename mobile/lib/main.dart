import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';

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
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
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
