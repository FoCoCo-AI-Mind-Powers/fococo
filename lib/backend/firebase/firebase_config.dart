import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  try {
    // Check if Firebase is already initialized to prevent duplicate app error
    if (Firebase.apps.isNotEmpty) {
      if (kDebugMode) {
        print(
            '✅ Firebase already initialized with ${Firebase.apps.length} app(s)');
        print(
            '✅ Existing apps: ${Firebase.apps.map((app) => app.name).join(', ')}');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 Initializing Firebase...');
    }

    if (kIsWeb) {
      await Firebase.initializeApp(
          options: const FirebaseOptions(
              apiKey: "AIzaSyCmVMuyAjN1R30KEAuQelK8h-nizJX5PJ0",
              authDomain: "fo-co-co-89gnf5.firebaseapp.com",
              projectId: "fo-co-co-89gnf5",
              storageBucket: "fo-co-co-89gnf5.firebasestorage.app",
              messagingSenderId: "549026925121",
              appId: "1:549026925121:web:852d7afb0e3105222ad4c0"));
    } else {
      // Try to initialize with default first (in case google-services.json is configured)
      try {
        await Firebase.initializeApp();
        if (kDebugMode) {
          print('✅ Firebase initialized with default configuration');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              '⚠️ Default initialization failed, trying with explicit options: $e');
        }
        // Fall back to explicit configuration
        await Firebase.initializeApp(
            options: const FirebaseOptions(
                apiKey: "AIzaSyB-UzyUTFbJUg28-nm_oTPc0lwlEAJem9k",
                authDomain: "fo-co-co-89gnf5.firebaseapp.com",
                projectId: "fo-co-co-89gnf5",
                storageBucket: "fo-co-co-89gnf5.firebasestorage.app",
                messagingSenderId: "549026925121",
                appId: "1:549026925121:ios:d5554c9723624fd02ad4c0"));
      }
    }

    // On web, set auth persistence to LOCAL so session survives tab close/refresh
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
        if (kDebugMode) {
          print('✅ Firebase Auth persistence set to LOCAL (web)');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not set auth persistence: $e');
        }
      }
    }

    // DO NOT call FirebaseFirestore.instance.settings here.
    // On Apple platforms, touching FirebaseFirestore.instance from Dart during
    // launch can race with the native persistence/gRPC startup. The iOS cache
    // configuration is applied natively in AppDelegate before plugin
    // registration, which avoids reconfiguring Firestore after the client has
    // already started opening its background channels.

    if (kDebugMode) {
      print('✅ Firebase initialized successfully');
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      if (kDebugMode) {
        print('⚠️ Firebase already initialized by another source');
      }
      // Firebase is already initialized, that's fine
      return;
    } else {
      if (kDebugMode) {
        print('❌ Error initializing Firebase: $e');
      }
      rethrow;
    }
  }
}

/// Returns the default Firebase app, which `FirebaseAI.googleAI()` uses for
/// auth. The client no longer fetches any Gemini API key — all generative
/// traffic flows through Firebase AI Logic (App Check authenticated) or
/// Cloud Functions that read `GEMINI_KEY_APP` from Secret Manager.
Future<FirebaseApp> getGoogleAIFirebaseApp() async {
  return Firebase.app();
}
