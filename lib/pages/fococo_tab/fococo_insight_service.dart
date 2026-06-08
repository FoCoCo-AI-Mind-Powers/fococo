import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/ai_integration/config/gemini_config.dart';
import '/services/units_preference_service.dart';

class FoCoCoDailyInsight {
  const FoCoCoDailyInsight({
    required this.insightId,
    required this.insightText,
    required this.insightDate,
    required this.playedAudio,
    required this.opened,
    required this.timeOnScreenSec,
    required this.generationVersion,
  });

  final String insightId;
  final String insightText;
  final String insightDate;
  final bool playedAudio;
  final bool opened;
  final double timeOnScreenSec;
  final String generationVersion;

  bool get hasRemoteRecord => insightId.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'insightId': insightId,
      'insightText': insightText,
      'insightDate': insightDate,
      'playedAudio': playedAudio,
      'opened': opened,
      'timeOnScreenSec': timeOnScreenSec,
      'generationVersion': generationVersion,
    };
  }

  factory FoCoCoDailyInsight.fromMap(Map<String, dynamic> map) {
    return FoCoCoDailyInsight(
      insightId: (map['insightId'] ?? '').toString(),
      insightText: (map['insightText'] ?? '').toString(),
      insightDate: (map['insightDate'] ?? '').toString(),
      playedAudio: map['playedAudio'] == true,
      opened: map['opened'] == true,
      timeOnScreenSec: _parseDouble(map['timeOnScreenSec']),
      generationVersion:
          (map['generationVersion'] ?? 'fococo_tab_v1').toString(),
    );
  }

  factory FoCoCoDailyInsight.fallback({
    required String insightDate,
    required String insightText,
  }) {
    return FoCoCoDailyInsight(
      insightId: '',
      insightText: insightText,
      insightDate: insightDate,
      playedAudio: false,
      opened: false,
      timeOnScreenSec: 0,
      generationVersion: 'fallback',
    );
  }

  FoCoCoDailyInsight copyWith({
    String? insightId,
    String? insightText,
    String? insightDate,
    bool? playedAudio,
    bool? opened,
    double? timeOnScreenSec,
    String? generationVersion,
  }) {
    return FoCoCoDailyInsight(
      insightId: insightId ?? this.insightId,
      insightText: insightText ?? this.insightText,
      insightDate: insightDate ?? this.insightDate,
      playedAudio: playedAudio ?? this.playedAudio,
      opened: opened ?? this.opened,
      timeOnScreenSec: timeOnScreenSec ?? this.timeOnScreenSec,
      generationVersion: generationVersion ?? this.generationVersion,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// Backend-owned FoCoCo tab insight service.
class FoCoCoInsightService {
  FoCoCoInsightService._();
  static final FoCoCoInsightService instance = FoCoCoInsightService._();

  static const _prefKeyCurrentDate = 'fococo_insight_date';
  static const _prefKeyCurrentJson = 'fococo_insight_json';
  static const _prefKeyLastJson = 'fococo_insight_last_json';

  static const _brandNewFallback =
      'Your first rounds will sharpen what repeats under pressure.\n\nBefore you tee off, pick one thought and stay with it for three holes.';
  static const Duration _callTimeout = Duration(seconds: 16);
  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// Ensures Cloud Functions and Firestore requests carry a fresh ID token.
  /// See [User.getIdToken](https://pub.dev/documentation/firebase_auth/latest/firebase_auth/User/getIdToken.html).
  Future<void> _ensureFreshIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    await user.getIdToken(true);
  }

  Future<FoCoCoDailyInsight> getTodayInsight() async {
    final prefs = await SharedPreferences.getInstance();
    final today = await _todayIso();

    final cachedDate = prefs.getString(_prefKeyCurrentDate);
    final cachedJson = prefs.getString(_prefKeyCurrentJson);
    if (cachedDate == today && cachedJson != null && cachedJson.isNotEmpty) {
      final cachedInsight = _decodeInsight(cachedJson);
      if (cachedInsight != null) {
        return cachedInsight;
      }
    }

    try {
      final insight = await _fetchRemoteInsight();
      await _cacheCurrentInsight(prefs, insight);
      return insight;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo insight fetch failed: ${_errorLabel(error)}');
      }
      if (FirebaseAuth.instance.currentUser != null) {
        try {
          await _ensureFreshIdToken();
          final clientInsight = await _generateClientFallbackInsight();
          await _cacheCurrentInsight(prefs, clientInsight);
          if (kDebugMode) {
            debugPrint('✅ FoCoCo tab: used on-device Firebase AI fallback insight');
          }
          return clientInsight;
        } catch (fallbackError) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ FoCoCo client AI fallback failed: ${_errorLabel(fallbackError)}');
          }
        }
      }
    }

    final lastJson = prefs.getString(_prefKeyLastJson);
    final lastInsight = _decodeInsight(lastJson);
    if (lastInsight != null) {
      return lastInsight;
    }

    return FoCoCoDailyInsight.fallback(
      insightDate: today,
      insightText: _brandNewFallback,
    );
  }

  Future<void> markOpened(FoCoCoDailyInsight? insight) async {
    if (insight == null || !insight.hasRemoteRecord || insight.opened) {
      return;
    }

    try {
      await _ensureFreshIdToken();
      await _mergeIntoInsightDoc(insight.insightId, {
        'opened': true,
        'updatedTime': FieldValue.serverTimestamp(),
      });

      await _updateCachedInsight(
        insight.insightDate,
        (existing) => existing.copyWith(opened: true),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo insight markOpened failed: $error');
      }
    }
  }

  Future<void> markAudioPlayed(FoCoCoDailyInsight? insight) async {
    if (insight == null || !insight.hasRemoteRecord || insight.playedAudio) {
      return;
    }

    try {
      await _ensureFreshIdToken();
      await _mergeIntoInsightDoc(insight.insightId, {
        'playedAudio': true,
        'updatedTime': FieldValue.serverTimestamp(),
      });

      await _updateCachedInsight(
        insight.insightDate,
        (existing) => existing.copyWith(playedAudio: true),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo insight markAudioPlayed failed: $error');
      }
    }
  }

  Future<void> addTimeOnScreen(
    FoCoCoDailyInsight? insight,
    Duration duration,
  ) async {
    if (insight == null || !insight.hasRemoteRecord) {
      return;
    }

    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0) return;

    try {
      await _ensureFreshIdToken();
      await _mergeIntoInsightDoc(insight.insightId, {
        'timeOnScreenSec': FieldValue.increment(seconds),
        'updatedTime': FieldValue.serverTimestamp(),
      });

      await _updateCachedInsight(
        insight.insightDate,
        (existing) => existing.copyWith(
          timeOnScreenSec: existing.timeOnScreenSec + seconds,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo insight addTimeOnScreen failed: $error');
      }
    }
  }

  Future<void> _mergeIntoInsightDoc(
    String insightId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance
        .collection('ai_insights')
        .doc(insightId)
        .set(data, SetOptions(merge: true));
  }

  Future<FoCoCoDailyInsight> _fetchRemoteInsight() async {
    await _ensureFreshIdToken();

    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('getOrCreateFoCoCoDailyInsight');

    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await callable.call().timeout(_callTimeout);
        final raw = result.data;
        if (raw is! Map) {
          throw Exception('Invalid FoCoCo insight payload');
        }
        return FoCoCoDailyInsight.fromMap(Map<String, dynamic>.from(raw));
      } catch (error) {
        lastError = error;
        final isUnauth = error is FirebaseFunctionsException &&
            error.code == 'unauthenticated';

        if (attempt == 0 && isUnauth) {
          await _ensureFreshIdToken();
          await Future<void>.delayed(_retryDelay);
          continue;
        }
        if (attempt == 0 && _isRetryable(error)) {
          await Future<void>.delayed(_retryDelay);
          continue;
        }
        rethrow;
      }
    }
    throw lastError ?? Exception('FoCoCo insight fetch failed');
  }

  /// When the callable fails (e.g. backend Gemini key / deploy), generate a short
  /// FoCoCo-style line via Firebase AI Logic on-device (still requires sign-in).
  Future<FoCoCoDailyInsight> _generateClientFallbackInsight() async {
    final today = await _todayIso();
    final unitsLine = await UnitsPreferenceService.aiContextLine();
    final model = GeminiConfig.createModel(
      modelName: GeminiConfig.insightModel,
      generationConfig: GenerationConfig(
        temperature: 0.55,
        maxOutputTokens: 280,
        topP: 0.9,
      ),
      systemInstruction:
          'You write one FoCoCo Tab daily insight for golfers. '
          'Exactly two complete sentences on two lines separated by one blank line. '
          'Line 1: one personal observation. Line 2: one practical direction for today. '
          'No medical claims, marketing copy, generic motivation, numbers, or exclamation marks. '
          'No greetings or cliché openers. Plain text only. $unitsLine',
    );

    final response = await model.generateContent([
      Content.text(
        'Generate today\'s FoCoCo tab insight. Date: $today. '
        'Ground on focus, confidence, and control patterns—not swing mechanics.',
      ),
    ]);

    final text =
        response.text?.trim().isNotEmpty == true ? response.text!.trim() : '';

    final safe = text.isNotEmpty ? text : _brandNewFallback;

    return FoCoCoDailyInsight(
      insightId: '',
      insightText: safe,
      insightDate: today,
      playedAudio: false,
      opened: false,
      timeOnScreenSec: 0,
      generationVersion: 'client_firebase_ai_v2',
    );
  }

  bool _isRetryable(Object error) {
    if (error is TimeoutException) {
      return true;
    }
    if (error is FirebaseFunctionsException) {
      return error.code == 'internal' ||
          error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'resource-exhausted';
    }
    final message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('internal') ||
        message.contains('unavailable');
  }

  String _errorLabel(Object error) {
    if (error is FirebaseFunctionsException) {
      return '[firebase_functions/${error.code}] ${error.message ?? 'unknown'}';
    }
    return error.toString();
  }

  Future<void> _cacheCurrentInsight(
    SharedPreferences prefs,
    FoCoCoDailyInsight insight,
  ) async {
    final encoded = jsonEncode(insight.toMap());
    await prefs.setString(_prefKeyCurrentDate, insight.insightDate);
    await prefs.setString(_prefKeyCurrentJson, encoded);
    await prefs.setString(_prefKeyLastJson, encoded);
  }

  Future<void> _updateCachedInsight(
    String insightDate,
    FoCoCoDailyInsight Function(FoCoCoDailyInsight current) transform,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getString(_prefKeyCurrentJson);
    final currentInsight = _decodeInsight(currentJson);
    if (currentInsight != null && currentInsight.insightDate == insightDate) {
      await _cacheCurrentInsight(prefs, transform(currentInsight));
      return;
    }

    final lastJson = prefs.getString(_prefKeyLastJson);
    final lastInsight = _decodeInsight(lastJson);
    if (lastInsight != null && lastInsight.insightDate == insightDate) {
      await prefs.setString(
        _prefKeyLastJson,
        jsonEncode(transform(lastInsight).toMap()),
      );
    }
  }

  FoCoCoDailyInsight? _decodeInsight(String? jsonValue) {
    if (jsonValue == null || jsonValue.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonValue);
      if (decoded is! Map) return null;
      return FoCoCoDailyInsight.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<String> _todayIso() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('user')
            .doc(uid)
            .get();
        final tzName = snap.data()?['timezone'] as String?;
        if (tzName != null && tzName.isNotEmpty) {
          final now = DateTime.now().toUtc();
          return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        }
      }
    } catch (_) {}
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> warmTodayInsight() => getTodayInsight();
}
