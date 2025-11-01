// Generated-like Firebase options file.
// This file was created from values found in `firebase.json`.
// It contains placeholders (REPLACE_ME) for missing keys. Replace the
// placeholders with real values from your Firebase console or run
// `flutterfire configure` to generate a complete file.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Default Firebase options for all platforms. Replace the REPLACE_ME
/// entries with your real Firebase project values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  // Values partially taken from firebase.json in the repository.
  static const FirebaseOptions web = FirebaseOptions(
    // Values copied from your Firebase Console (Web app)
    apiKey: 'AIzaSyAjGMiPw9N033PON75fQo2bWMTWu8nwitg',
    authDomain: 'tamil-quiz-app.firebaseapp.com',
    projectId: 'tamil-quiz-app',
    storageBucket: 'tamil-quiz-app.firebasestorage.app',
    messagingSenderId: '109091643107',
    appId: '1:109091643107:web:fbeee3f4426d7bc2116fd6',
    measurementId: 'G-JYSWGDQD87',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '109091643107',
    projectId: 'tamil-quiz-app',
    storageBucket: 'tamil-quiz-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '109091643107',
    projectId: 'tamil-quiz-app',
    iosBundleId: 'REPLACE_ME',
    storageBucket: 'tamil-quiz-app.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '109091643107',
    projectId: 'tamil-quiz-app',
    storageBucket: 'tamil-quiz-app.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '109091643107',
    projectId: 'tamil-quiz-app',
    storageBucket: 'tamil-quiz-app.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: '109091643107',
    projectId: 'tamil-quiz-app',
    storageBucket: 'tamil-quiz-app.firebasestorage.app',
  );
}

