import 'package:shared_preferences/shared_preferences.dart';

/// Global AI voice on/off (replaces visual/voice/visual_voice tri-state).
class AiVoicePreferenceService {
  AiVoicePreferenceService._();

  static const String prefsKey = 'fococo_ai_voice_enabled';
  static const String legacyModeKey = 'fococo_ai_response_mode';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefsKey)) {
      return prefs.getBool(prefsKey) ?? true;
    }
    final legacy = prefs.getString(legacyModeKey) ?? 'visual_voice';
    return legacy == 'voice' || legacy == 'visual_voice';
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, enabled);
    await prefs.setString(
      legacyModeKey,
      enabled ? 'visual_voice' : 'visual',
    );
  }
}
