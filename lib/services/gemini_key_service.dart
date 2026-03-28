import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Fetches and caches the Gemini API key from Cloud Functions (Secret Manager).
class GeminiKeyService {
  GeminiKeyService._();
  static final GeminiKeyService instance = GeminiKeyService._();

  String? cachedKey;
  bool _fetching = false;

  /// Returns the cached key, or fetches it from the Cloud Function.
  /// Falls back to --dart-define GEMINI_API_KEY if the function call fails.
  Future<String> getKey() async {
    if (cachedKey != null && cachedKey!.isNotEmpty) return cachedKey!;

    // Fall back to compile-time key if set
    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');

    if (_fetching) {
      // Another call is in progress — wait briefly then return what we have
      await Future.delayed(const Duration(milliseconds: 500));
      return cachedKey ?? dartDefineKey;
    }

    _fetching = true;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('getGeminiKey');
      final result = await callable.call();
      final key = (result.data as Map)['key'] as String?;
      if (key != null && key.isNotEmpty) {
        cachedKey = key;
        if (kDebugMode) {
          print('✅ Gemini key fetched from Secret Manager');
        }
        return key;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to fetch Gemini key from Secret Manager: $e');
      }
    } finally {
      _fetching = false;
    }

    // Fall back
    if (dartDefineKey.isNotEmpty) {
      cachedKey = dartDefineKey;
      return dartDefineKey;
    }

    return '';
  }

  /// Pre-warm the key cache. Call after Firebase Auth sign-in.
  Future<void> preload() async {
    await getKey();
  }

  /// Clear the cached key (e.g. on sign-out).
  void clear() {
    cachedKey = null;
  }
}
