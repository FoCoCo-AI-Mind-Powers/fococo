import 'package:flutter/foundation.dart';

/// Runtime configuration for JustTalk LiveKit agent integration.
class JustTalkLiveKitConfig {
  JustTalkLiveKitConfig._();

  /// LiveKit server URL.
  static const String liveKitUrl = String.fromEnvironment(
    'LIVEKIT_URL',
    defaultValue: 'wss://fococo-45unq6sj.livekit.cloud',
  );

  /// LiveKit agent name for JustTalk voice sessions.
  static const String agentName = String.fromEnvironment(
    'LIVEKIT_JUST_TALK_AGENT_NAME',
    defaultValue: 'justtalk-cartesia',
  );

  /// Default Cartesia voice clone ID requested for agent speech.
  static const String defaultCartesiaVoiceId = String.fromEnvironment(
    'JUST_TALK_CARTESIA_VOICE_ID',
    defaultValue: '7442d6b8-ff51-4477-bd30-0c0d16df84eb',
  );

  /// Whether JustTalk can automatically fall back to legacy voice services.
  static const bool fallbackEnabled = bool.fromEnvironment(
    'JUST_TALK_LIVEKIT_FALLBACK_ENABLED',
    defaultValue: true,
  );

  static const int _agentTimeoutSeconds = int.fromEnvironment(
    'JUST_TALK_LIVEKIT_AGENT_TIMEOUT_SECONDS',
    defaultValue: 20,
  );

  /// Timeout used while waiting for the agent to join/become ready.
  static Duration get agentConnectTimeout {
    final safeSeconds = _agentTimeoutSeconds.clamp(5, 120);
    return Duration(seconds: safeSeconds);
  }

  static void logConfig() {
    if (!kDebugMode) {
      return;
    }
    print('🎛️ JustTalk LiveKit Config');
    print('   URL: $liveKitUrl');
    print('   Agent: $agentName');
    print('   Voice: $defaultCartesiaVoiceId');
    print('   Fallback Enabled: $fallbackEnabled');
    print('   Agent Timeout: ${agentConnectTimeout.inSeconds}s');
  }
}
