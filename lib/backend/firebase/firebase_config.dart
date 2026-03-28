import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/services/gemini_key_service.dart';

const String _googleAIOverrideAppName = 'google_ai_override';

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

Future<FirebaseApp> getGoogleAIFirebaseApp() async {
  // 1. Try fetching from Secret Manager via Cloud Function
  final secretKey = await GeminiKeyService.instance.getKey();

  // 2. Fall back to --dart-define
  const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
  final overrideApiKey =
      secretKey.isNotEmpty ? secretKey : dartDefineKey;

  if (overrideApiKey.isEmpty) {
    return Firebase.app();
  }

  // Re-use an existing override app if the key matches
  for (final app in Firebase.apps) {
    if (app.name == _googleAIOverrideAppName) {
      if (app.options.apiKey == overrideApiKey) return app;
      // Key changed — delete stale app and recreate
      await app.delete();
      break;
    }
  }

  final baseApp = Firebase.app();
  return Firebase.initializeApp(
    name: _googleAIOverrideAppName,
    options: baseApp.options.copyWith(apiKey: overrideApiKey),
  );
}
