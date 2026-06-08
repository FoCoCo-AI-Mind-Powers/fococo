import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import '../domain/models/mindcoach_v2_models.dart';

/// Local cache for Play Again — avoids regeneration.
class MindCoachReplayCache {
  MindCoachReplayCache._();

  static String _key(String sessionId) => 'mindcoach_replay_$sessionId';

  static Future<void> saveFromResponse(MindCoachV2GenerateResponse response) async {
    final session = response.session;
    final payload = {
      'sessionId': response.sessionId,
      'contextMode': response.contextMode.wireValue,
      'uiMode': response.uiMode.wireValue,
      'runId': response.runId,
      'session': session.toMap(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(response.sessionId), jsonEncode(payload));
  }

  static Future<MindCoachV2GenerateResponse?> load(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(sessionId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final sessionMap = map['session'] as Map<String, dynamic>? ?? {};
      final sid = (map['sessionId'] ?? sessionId).toString();
      final ctx = MindCoachV2ContextModeX.fromWire(
        (map['contextMode'] ?? 'off_day').toString(),
      );
      return MindCoachV2GenerateResponse(
        sessionId: sid,
        contextMode: ctx,
        uiMode: MindCoachV2UiModeX.fromWire(
          (map['uiMode'] ?? 'guided_extended').toString(),
        ),
        session: MindCoachV2Session.fromApi(
          sessionMap,
          sessionId: sid,
          userId: currentUserUid,
          contextMode: ctx,
        ),
        runId: map['runId']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
