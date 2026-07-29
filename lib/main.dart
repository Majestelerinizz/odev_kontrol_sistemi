import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';

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
          apiKey: "AIzaSyDx03qPyKBzQUb97dW_j2cN1kbBbQL0sZM",
          appId: "1:1063947496038:web:c424f96a4fa7ed77711ba7",
          messagingSenderId: "1063947496038",
          projectId: "odevtakipsistemi-b93b2",
          authDomain: "odevtakipsistemi-b93b2.firebaseapp.com",
          storageBucket: "odevtakipsistemi-b93b2.firebasestorage.app",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialize warning: $e');
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
