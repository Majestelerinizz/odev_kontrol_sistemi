import 'package:firebase_core/firebase_core.dart';

/// Firebase Console veya `flutterfire configure` ile oluşturulur.
/// Bu dosyayı kopyalayın: `firebase_options.dart`
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:web:YOUR_APP_ID',
    messagingSenderId: 'YOUR_PROJECT_NUMBER',
    projectId: 'eduly-server',
    authDomain: 'eduly-server.firebaseapp.com',
    storageBucket: 'eduly-server.firebasestorage.app',
    measurementId: 'YOUR_MEASUREMENT_ID',
  );
}
