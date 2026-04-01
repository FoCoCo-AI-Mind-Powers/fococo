import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      'The MindGame System is ready. Every round, every session, every conversation builds the picture of your mental game.';

  Future<FoCoCoDailyInsight> getTodayInsight() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayIso();

    final cachedDate = prefs.getString(_prefKeyCurrentDate);
    final cachedJson = prefs.getString(_prefKeyCurrentJson);
    if (cachedDate == today && cachedJson != null && cachedJson.isNotEmpty) {
      final cachedInsight = _decodeInsight(cachedJson);
      if (cachedInsight != null) {
        return cachedInsight;
      }
    }

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('getOrCreateFoCoCoDailyInsight');
      final result = await callable.call().timeout(const Duration(seconds: 12));
      final raw = result.data;
      if (raw is! Map) {
        throw Exception('Invalid FoCoCo insight payload');
      }

      final insight = FoCoCoDailyInsight.fromMap(
        Map<String, dynamic>.from(raw),
      );
      await _cacheCurrentInsight(prefs, insight);
      return insight;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo insight fetch failed: $error');
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

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
