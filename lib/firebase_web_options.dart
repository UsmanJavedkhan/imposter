import 'package:firebase_core/firebase_core.dart';

/// Firebase config for the WEB build only.
///
/// On Android/iOS the native config files (google-services.json /
/// GoogleService-Info.plist) are used automatically, so we don't need options
/// there. The web build has no such native file, so we pass these explicitly.
///
/// Note: these values are not secrets — Firebase web config is meant to ship
/// in the client. Access is protected by the Firestore security rules.
const FirebaseOptions kWebFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCSOefxaOjlTEbaGc9TSDio9f_PjZ1d72Q',
  appId: '1:263511560172:web:a913af3aba484df6efbac9',
  messagingSenderId: '263511560172',
  projectId: 'imposter-game-89391',
  authDomain: 'imposter-game-89391.firebaseapp.com',
  storageBucket: 'imposter-game-89391.firebasestorage.app',
);
