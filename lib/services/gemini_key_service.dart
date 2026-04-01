import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Fetches and caches the Gemini API key from Cloud Functions (Secret Manager).
class GeminiKeyService {
  GeminiKeyService._();
  static final GeminiKeyService instance = GeminiKeyService._();

  String? cachedKey;
  Completer<String>? _inflight;

  /// Returns the cached key, or fetches it from the Cloud Function.
  /// Falls back to --dart-define GEMINI_API_KEY if the function call fails.
  Future<String> getKey() async {
    if (cachedKey != null && cachedKey!.isNotEmpty) return cachedKey!;

    // If another call is already in flight, wait for the same result instead
    // of returning a potentially empty fallback after an arbitrary delay.
    if (_inflight != null) return _inflight!.future;

    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');

    final completer = Completer<String>();
    _inflight = completer;

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
        completer.complete(key);
        return key;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to fetch Gemini key from Secret Manager: $e');
      }
    } finally {
      _inflight = null;
    }

    if (dartDefineKey.isNotEmpty) {
      cachedKey = dartDefineKey;
      if (!completer.isCompleted) completer.complete(dartDefineKey);
      return dartDefineKey;
    }

    const empty = '';
    if (!completer.isCompleted) completer.complete(empty);
    return empty;
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
