// GENERATED FILE — replace by running: flutterfire configure
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members, unused_shown_name
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1-Vni1CbxQKeZsjFggZBxckLPzPZT8kI',
    appId: '1:1053657394907:android:203f31de6eac49244666fe',
    messagingSenderId: '1053657394907',
    projectId: 'toka-dd241',
    storageBucket: 'toka-dd241.firebasestorage.app',
  );

  // TODO: Replace with real values from flutterfire configure

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBX4KnoaQC66dXynrTLBptkM1cKmPpC4D0',
    appId: '1:1053657394907:ios:70a8f5ad16b4ee444666fe',
    messagingSenderId: '1053657394907',
    projectId: 'toka-dd241',
    storageBucket: 'toka-dd241.firebasestorage.app',
    iosClientId: '1053657394907-kgg8fgcmrn4gfht8uvpchk775k483ktn.apps.googleusercontent.com',
    iosBundleId: 'com.toka.toka',
  );

}