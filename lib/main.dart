import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app/app.dart';
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
  // Yapılandırma, `flutterfire configure` tarafından üretilen
  // firebase_options.dart dosyasından gelir. Elle gömülü config KULLANILMAZ:
  // Phone Auth'un çalışması için platform başına doğru appId/apiKey zorunludur
  // (Web reCAPTCHA, Android Play Integrity, iOS APNs bu kimliklere bağlıdır).
  //
  // Burada bilinçli olarak try/catch YOK: Firebase başlatılamazsa Auth ve
  // Firestore'un tamamı çalışmaz, hatanın sessizce yutulması yerine görünür
  // olması gerekir.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // SMS doğrulama mesajlarının ve reCAPTCHA arayüzünün Türkçe gelmesi için
  await FirebaseAuth.instance.setLanguageCode('tr');

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
