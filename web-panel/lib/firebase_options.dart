import 'package:firebase_core/firebase_core.dart';

/// Mobil uygulama ile aynı Firebase projesi.
/// Yalnızca web yapılandırması tutulur.
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDZ80PElxFSEjX8G5-LhM36H-UOWO0SJUM',
    appId: '1:763956808451:web:37b5b0f6a85848b240b736',
    messagingSenderId: '763956808451',
    projectId: 'eduly-server',
    authDomain: 'eduly-server.firebaseapp.com',
    storageBucket: 'eduly-server.firebasestorage.app',
    measurementId: 'G-6WVK3D5NWE',
  );
}
