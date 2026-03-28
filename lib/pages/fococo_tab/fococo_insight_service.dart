import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/schema/round_logs_record.dart';
import '/backend/schema/mindcoach_sessions_record.dart';
import '/services/gemini_key_service.dart';

/// Manages the one AI-generated mental insight shown daily on the FoCoCo Tab.
///
/// Spec: PDF "FoCoCo Tab — Final Implementation Spec" §3
class FoCoCoInsightService {
  FoCoCoInsightService._();
  static final FoCoCoInsightService instance = FoCoCoInsightService._();

  static const _prefKeyText = 'fococo_insight_text';
  static const _prefKeyDate = 'fococo_insight_date';
  static const _prefKeyLastText = 'fococo_insight_last_text'; // any-date cache

  // ─── New-user fallback copy (§3.4) ───────────────────────────────────────

  static const Map<String, String> _newUserFallbacks = {
    'brand_new':
        'The MindGame System is ready. Every round, every session, every conversation builds the picture of your mental game.',
    'one_round':
        'Your first round captured. The picture is starting to form — the more you play, the sharper it gets.',
    'mindcoach_only':
        'You\'ve been working on your mental routines. That consistency alone says something about how you approach the game.',
    'golfchat_only':
        'You started with a conversation — that\'s a good instinct. Your mental game picture is taking shape.',
  };

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Returns today's AI insight for [userId].
  /// - First call of the day: assembles context, calls Gemini, caches result.
  /// - Same-day return: reads from SharedPreferences (zero API calls).
  /// - Timeout / offline: returns last cached insight from any date.
  Future<String> getTodayInsight(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayIso();

    // Same-day cache hit
    final cachedDate = prefs.getString(_prefKeyDate);
    final cachedText = prefs.getString(_prefKeyText);
    if (cachedDate == today && cachedText != null && cachedText.isNotEmpty) {
      return cachedText;
    }

    // Try to generate a new insight
    try {
      final context = await _assembleContext(userId);
      final insight = await _callGemini(context)
          .timeout(const Duration(seconds: 8));

      if (insight.isNotEmpty) {
        await prefs.setString(_prefKeyText, insight);
        await prefs.setString(_prefKeyDate, today);
        await prefs.setString(_prefKeyLastText, insight); // persist as fallback
        return insight;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ FoCoCoInsight: generation failed — $e');
    }

    // Offline / error: return last cached text from any previous date
    final lastText = prefs.getString(_prefKeyLastText);
    if (lastText != null && lastText.isNotEmpty) return lastText;

    // Absolute fallback for brand-new users with zero data
    return _newUserFallbacks['brand_new']!;
  }

  // ─── Context assembly ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _assembleContext(String userId) async {
    final now = DateTime.now();

    // Fetch in parallel
    final results = await Future.wait([
      _fetchRecentRounds(userId, limit: 5),
      _fetchRecentMindCoachSessions(userId, limit: 5),
    ]);

    final rounds = results[0];
    final sessions = results[1];

    final lastRoundDays = rounds.isNotEmpty && rounds.first['date'] != null
        ? now.difference(rounds.first['date'] as DateTime).inDays
        : null;
    final lastSessionDays =
        sessions.isNotEmpty && sessions.first['timestamp'] != null
            ? now.difference(sessions.first['timestamp'] as DateTime).inDays
            : null;

    return {
      'temporal': {
        'timeOfDay': _timeOfDay(now),
        'dayOfWeek': _dayOfWeek(now),
        'season': _season(now),
        'daysSinceLastRound': lastRoundDays,
        'daysSinceLastMindCoach': lastSessionDays,
      },
      'caddyPlay': {
        'totalRounds': rounds.length,
        'recentRounds': rounds.take(3).toList(),
      },
      'mindCoach': {
        'totalSessions': sessions.length,
        'recentSessions': sessions.take(3).toList(),
        'isNewUser': sessions.isEmpty && rounds.isEmpty,
      },
    };
  }

  Future<List<Map<String, dynamic>>> _fetchRecentRounds(
    String userId, {
    required int limit,
  }) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('round_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((d) {
        final r = RoundLogsRecord.fromSnapshot(d);
        return {
          'date': r.date,
          'courseName': r.courseName,
          'courseType': r.courseType,
          'mindsetFocus': r.mindsetFocus,
          'mindsetConfidence': r.mindsetConfidence,
          'mindsetControl': r.mindsetControl,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentMindCoachSessions(
    String userId, {
    required int limit,
  }) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('mindcoach_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((d) {
        final s = MindcoachSessionsRecord.fromSnapshot(d);
        return {
          'timestamp': s.timestamp,
          'routineType': s.routineType,
          'scenarioTag': s.scenarioTag,
          'deliveryLength': s.deliveryLength,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Gemini call ─────────────────────────────────────────────────────────

  Future<String> _callGemini(Map<String, dynamic> contextData) async {
    final apiKey = await GeminiKeyService.instance.getKey();
    if (apiKey.isEmpty) throw Exception('No API key available');

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': _systemPrompt()}],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': _userMessage(contextData)}],
        },
      ],
      'generationConfig': {
        'temperature': 0.8,
        'maxOutputTokens': 120,
        'topP': 0.95,
      },
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini HTTP ${response.statusCode}');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = map['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates in response');
    }
    final parts = (candidates.first as Map)['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) throw Exception('Empty parts');
    final text = (parts.first as Map)['text'] as String? ?? '';
    return text.trim();
  }

  // ─── System prompt (§3.2 — implement exactly as written) ─────────────────

  String _systemPrompt() => '''
You are the MindGame System™, the AI intelligence engine inside FoCoCo — a golf mental performance app. Your job right now is to generate a single insight for the user\'s home screen. It should feel like it comes from something that genuinely knows their mental game.

RULES:
- One or two sentences only. Never more.
- Write in second person ("your", "you"). Direct and personal.
- Tone: calm, warm, observational. Like a great caddie between holes.
- Always grounded in the context data. Never generic. Never invented.
- Reference a specific pattern, trend, or observation from their data.
- Never use numbers, scores, percentages, or metrics. Qualitative only.
- Never start with "Your MindGame System" or any self-reference. Just speak.
- If data is thin (new user, <2 rounds): warm and curious, not observational.
- Never use exclamation marks.
- The insight should make the user feel understood. That is the only goal.
''';

  // ─── User message (§3.3 context payload) ─────────────────────────────────

  String _userMessage(Map<String, dynamic> ctx) {
    final temporal = ctx['temporal'] as Map<String, dynamic>? ?? {};
    final caddy = ctx['caddyPlay'] as Map<String, dynamic>? ?? {};
    final mc = ctx['mindCoach'] as Map<String, dynamic>? ?? {};

    final lastRound = temporal['daysSinceLastRound'];
    final lastSession = temporal['daysSinceLastMindCoach'];
    final rounds = caddy['recentRounds'] as List? ?? [];
    final sessions = mc['recentSessions'] as List? ?? [];

    return '''
Context for today\'s insight:

Time signals:
- Time of day: ${temporal['timeOfDay']}
- Day: ${temporal['dayOfWeek']}, ${temporal['season']}
- Days since last round: ${lastRound ?? 'unknown (no rounds yet)'}
- Days since last MindCoach session: ${lastSession ?? 'unknown (no sessions yet)'}

CaddyPlay history (last ${rounds.length} rounds):
${rounds.isEmpty ? '  No rounds recorded yet.' : rounds.map((r) => '  • ${_formatRound(r as Map)}').join('\n')}

MindCoach training (last ${sessions.length} sessions):
${sessions.isEmpty ? '  No sessions recorded yet.' : sessions.map((s) => '  • ${_formatSession(s as Map)}').join('\n')}

Is new user: ${(mc['isNewUser'] as bool?) == true}

Generate the insight now.
''';
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _formatRound(Map r) {
    final name = r['courseName'] ?? 'Unknown course';
    final type = r['courseType'] ?? '';
    final date = r['date'] is DateTime
        ? _relativeDate(r['date'] as DateTime)
        : 'Unknown date';
    return '$name ($type) — $date';
  }

  String _formatSession(Map s) {
    final type = s['routineType'] ?? 'session';
    final tag = s['scenarioTag'];
    final date = s['timestamp'] is DateTime
        ? _relativeDate(s['timestamp'] as DateTime)
        : 'Unknown date';
    return '$type${tag != null ? ' ($tag)' : ''} — $date';
  }

  String _relativeDate(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    if (days < 14) return 'last week';
    return '${(days / 7).round()} weeks ago';
  }

  String _todayIso() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _timeOfDay(DateTime t) {
    if (t.hour < 6) return 'early morning';
    if (t.hour < 12) return 'morning';
    if (t.hour < 17) return 'afternoon';
    if (t.hour < 21) return 'evening';
    return 'night';
  }

  String _dayOfWeek(DateTime t) =>
      ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][t.weekday - 1];

  String _season(DateTime t) {
    final m = t.month;
    if (m >= 3 && m <= 5) return 'spring';
    if (m >= 6 && m <= 8) return 'summer';
    if (m >= 9 && m <= 11) return 'autumn';
    return 'winter';
  }
}
