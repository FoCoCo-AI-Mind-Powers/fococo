import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/services/gemini_key_service.dart';

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
      _applyFirestoreSettings();
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

    // Apply Firestore client settings immediately after init, before any
    // Firestore read/write (RevenueCat, auth listener, etc.) can open a gRPC
    // channel.  Doing it later races with the first query and can crash inside
    // gpr_cv_wait on iOS.
    _applyFirestoreSettings();

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

/// Internal: called once from [initFirebase] right after [Firebase.initializeApp]
/// and before any Firestore read/write opens a gRPC channel.
///
/// The iOS/macOS SDK persists offline data through file-backed caches; stack
/// traces mentioning `LargeItemCacheType` / `NSFileManager` + `saveData` usually
/// originate there. Using an explicit bounded disk cache (40 MiB, the SDK
/// default) avoids unbounded offline cache edge cases and keeps GC predictable.
/// Do not set [Settings.CACHE_SIZE_UNLIMITED] on Apple platforms.
void _applyFirestoreSettings() {
  if (kIsWeb) return;
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 40 * 1024 * 1024,
    );
    if (kDebugMode) {
      print('✅ Firestore: bounded local cache (40 MiB), persistence on');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Firestore settings could not be applied: $e');
    }
  }
}

/// Public alias kept for call-sites that haven't been updated yet.
@Deprecated('Settings are now applied inside initFirebase(). This is a no-op.')
void configureFirestoreClientSettings() {}

/// Firebase AI Logic and Gemini Live must use the real Firebase Web API key from
/// [FirebaseOptions], not the Generative Language API key from Secret Manager.
/// Putting a Gemini key into [FirebaseOptions.apiKey] breaks auth and can surface
/// "API key leaked" / permission errors.
Future<FirebaseApp> getGoogleAIFirebaseApp() async {
  // Preload so [GeminiLiveAPIConfig.apiKey] / voice paths still resolve the key.
  await GeminiKeyService.instance.getKey();
  return Firebase.app();
}
