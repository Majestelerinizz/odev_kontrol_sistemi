import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
// import 'firebase_options.dart'; // Firebase yapılandırıldıktan sonra aktif et

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
  // NOT: Firebase Console'dan google-services.json (Android) ve
  //      GoogleService-Info.plist (iOS) dosyalarını ekledikten sonra
  //      aşağıdaki satırı aktif edin ve 'firebase_options.dart' import'u açın.
  //
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
