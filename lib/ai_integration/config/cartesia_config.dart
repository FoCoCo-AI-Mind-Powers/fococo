import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for Cartesia voice constants, shared by every
/// client voice call. Implements §0 of the migration guide
/// (`Docs/AI Voice/cartesia-voice-migration-prompt.md`).
///
/// SECURITY: the Cartesia API key is NOT here and never ships in the client
/// binary. It lives in Google Cloud Secret Manager as `CARTESIA_API` and is
/// only read server-side by the `synthesizeSpeech` Cloud Function
/// (firebase/functions/cartesia_tts.js). Clients reach Cartesia exclusively
/// through that callable — same model as GEMINI_KEY_APP.
class CartesiaConfig {
  CartesiaConfig._();

  // ── Pinned constants (§0) ────────────────────────────────────────────────
  static const String ttsModel = 'sonic-3-2026-01-12';

  /// Emulator / pre-auth fallback. Production value comes from Secret Manager
  /// `CARTESIA_VOICE_ID` via [runtimeConfigFunctionName].
  static const String fallbackVoiceId = 'fee439a9-751d-4d14-9974-a09de45bd053';

  static String _resolvedVoiceId = fallbackVoiceId;

  /// Active Cartesia voice — updated when [CartesiaVoiceRuntime.load] succeeds.
  static String get voiceId => _resolvedVoiceId;

  static void applyResolvedVoiceId(String? id) {
    final trimmed = id?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      _resolvedVoiceId = trimmed;
    }
  }

  /// Provenance only — used with `GET /fine-tunes/{id}/voices`. Never passed
  /// on a per-call TTS request.
  static const String fineTuneId = 'fine_tune_WyfawYF7uFdFJdRTia8rG5';

  /// `Cartesia-Version` date header. Pinned; only the weekly sync job (§7) may
  /// bump it, and only behind the `auto_adopt_cartesia_version` flag.
  static const String version = '2025-04-16';

  /// Name of the callable that proxies TTS through Secret Manager.
  static const String synthesizeFunctionName = 'synthesizeSpeech';

  /// Name of the callable that proxies STT through Secret Manager.
  static const String transcribeFunctionName = 'transcribeSpeech';

  /// Name of the callable that runs the §2 voice-ID self-check.
  static const String verifyFunctionName = 'verifyVoice';

  /// Non-secret Line agent + pronunciation dict ids for authenticated clients.
  static const String runtimeConfigFunctionName = 'getCartesiaVoiceRuntimeConfig';

  /// Short-lived token for Line WebSocket (`wss://api.cartesia.ai/agents/stream/...`).
  static const String mintAccessTokenFunctionName = 'mintCartesiaAccessToken';

  /// Short-lived token for low-latency TTS WebSocket (`/tts/websocket`).
  static const String mintTtsAccessTokenFunctionName = 'mintCartesiaTtsAccessToken';

  static const String ttsWebSocketUrl = 'wss://api.cartesia.ai/tts/websocket';

  static const String lineWebSocketBase = 'wss://api.cartesia.ai';

  /// Optional — loaded from [runtimeConfigFunctionName] after deploy.
  static String lineAgentId = '';

  /// Optional pronunciation dictionary (sonic-3.5 / sonic-3).
  static String pronunciationDictId = '';

  /// §2 boot self-check. Calls the `verifyVoice` Cloud Function (which holds
  /// the key) to confirm the pinned [voiceId] exists in Cartesia. Logs a clear
  /// message and returns false on any failure — never throws, so it can't
  /// block app boot. Requires the user to be authenticated.
  static Future<bool> verifyVoiceId({FirebaseFunctions? functions}) async {
    try {
      final fns = functions ?? FirebaseFunctions.instance;
      final result = await fns
          .httpsCallable(verifyFunctionName)
          .call<Map<String, dynamic>>({'voice_id': voiceId});
      final data = Map<String, dynamic>.from(result.data as Map);
      final valid = data['valid'] == true;
      if (valid) {
        if (kDebugMode) {
          debugPrint('🎙 Cartesia voice verified: $voiceId (${data['name']})');
        }
      } else {
        debugPrint(
          '❌ Cartesia voice self-check failed for $voiceId '
          '(status ${data['status']}): ${data['reason']} — re-copy the voice '
          'ID from the Cartesia dashboard (see migration guide §9.1).',
        );
      }
      return valid;
    } catch (e) {
      debugPrint('❌ Cartesia voice self-check threw: $e');
      return false;
    }
  }
}
