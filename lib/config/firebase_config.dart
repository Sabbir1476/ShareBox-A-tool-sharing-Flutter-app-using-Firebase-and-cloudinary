import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ✅ Web config (from your screenshot)
  static const FirebaseOptions web = FirebaseOptions(
  apiKey: "AIzaSyDabv-Fh_Wa8yJRaZDlt7qyA0sXdNVsPwA",
  authDomain: "sharebox-bangladesh-6aa2e.firebaseapp.com",
  projectId: "sharebox-bangladesh-6aa2e",
  storageBucket: "sharebox-bangladesh-6aa2e.firebasestorage.app",
  messagingSenderId: "751610731713",
  appId: "1:751610731713:web:7706097cddb0713a80c840",
  measurementId: "G-R7KK4EP9BZ"
  );

  // ✅ Android config (from your json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIJBy7yT3Bh6S8szntS_iC-hL4qZMObJw',
    appId: '1:246323136837:android:3ad34dafebd917ced0962c',
    messagingSenderId: '246323136837',
    projectId: 'sharebox-flutter',
    storageBucket: 'sharebox-flutter.firebasestorage.app',
  );

  // ✅ iOS (optional for now — safe placeholder)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy',
    appId: 'dummy',
    messagingSenderId: '246323136837',
    projectId: 'sharebox-flutter',
    storageBucket: 'sharebox-flutter.firebasestorage.app',
    iosBundleId: 'com.sharebox.bd',
  );
}