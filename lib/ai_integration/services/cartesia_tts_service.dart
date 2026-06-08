import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/structs/vark_preferences_struct.dart';
import 'package:just_audio/just_audio.dart';

import '../models/ai_models.dart';
import 'cartesia_api_service.dart';

/// Voice configuration for Cartesia TTS
class VoiceConfig {
  final String id;
  final String name;
  final String description;
  final String language;
  final String gender;
  final String style;

  const VoiceConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.gender,
    this.style = 'natural',
  });

  /// Predefined voice configurations optimized for golf coaching
  static const List<VoiceConfig> predefinedVoices = [
    VoiceConfig(
      id: 'coach_male_confident',
      name: 'Coach Marcus',
      description: 'Confident male coach voice',
      language: 'en-US',
      gender: 'male',
    ),
    VoiceConfig(
      id: 'coach_female_encouraging',
      name: 'Coach Sarah',
      description: 'Encouraging female coach voice',
      language: 'en-US',
      gender: 'female',
    ),
    VoiceConfig(
      id: 'mentor_calm',
      name: 'Mentor Alex',
      description: 'Calm and reassuring mentor voice',
      language: 'en-US',
      gender: 'neutral',
    ),
  ];

  static VoiceConfig getDefaultVoice() => predefinedVoices.first;

  static VoiceConfig? getVoiceById(String id) {
    try {
      return predefinedVoices.firstWhere((voice) => voice.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// App-wide Cartesia TTS facade — delegates to [CartesiaAPIService] for
/// instant WebSocket synthesis (`max_buffer_delay_ms: 0`) everywhere.
class CartesiaTTSService {
  CartesiaTTSService._();

  static CartesiaTTSService? _instance;
  static CartesiaTTSService get instance =>
      _instance ??= CartesiaTTSService._();

  final CartesiaAPIService _api = CartesiaAPIService.instance;
  VoiceConfig _currentVoice = VoiceConfig.getDefaultVoice();

  bool get isInitialized => _api.isInitialized;
  bool get isSpeaking => _api.isSpeaking;
  VoiceConfig get currentVoice => _currentVoice;
  Stream<bool> get speakingStream => _api.speakingStream;
  Stream<String> get errorStream => _api.errorStream;
  Stream<PlayerState> get playerStateStream => _api.playerStateStream;
  Stream<Duration> get positionStream => _api.positionStream;
  Duration get currentPosition => _api.currentPosition;
  Duration? get duration => _api.duration;

  Future<void> initialize() => _api.initialize();

  Future<AIInsightWithAudioResponse> generateInsightWithSpeech({
    required String insightText,
    required VarkPreferencesStruct varkPreferences,
    VoiceConfig? voiceConfig,
  }) async {
    if (!_api.isInitialized) {
      await initialize();
    }

    if (voiceConfig != null) {
      _currentVoice = voiceConfig;
    }

    final audioData = await _api.generateSpeech(
      text: insightText,
      varkPreferences: varkPreferences,
      contentType: 'coaching',
    );

    final textInsight = AIInsightResponse(
      insightTitle: 'Golf Performance Insight',
      category: 'Performance',
      priority: 'Medium',
      keyPoints: [insightText],
      recommendations: [],
      personalizedElements: ['VARK-adapted content'],
      summaryText: insightText,
      timestamp: DateTime.now(),
      model: 'cartesia-tts',
    );

    return AIInsightWithAudioResponse(
      textInsight: textInsight,
      audioData: {
        'audioSize': audioData.length,
        'voiceId': _currentVoice.id,
        'generatedAt': DateTime.now().toIso8601String(),
        'varkAdapted': true,
        'originalText': insightText,
        'adaptedText': insightText,
      },
    );
  }

  Future<void> speakText({
    required String text,
    required VarkPreferencesStruct varkPreferences,
    VoiceConfig? voiceConfig,
    String contentType = 'coaching',
  }) async {
    if (!_api.isInitialized) {
      await initialize();
    }
    if (voiceConfig != null) {
      _currentVoice = voiceConfig;
    }
    await _api.speakText(
      text: text,
      varkPreferences: varkPreferences,
      contentType: contentType,
      voiceProfileKey: _currentVoice.id,
    );
  }

  Future<void> stopSpeaking() => _api.stopSpeaking();

  Future<void> pausePlayback() => _api.pausePlayback();

  Future<void> resumePlayback() => _api.resumePlayback();

  Future<Uint8List> generateSpeech({
    required String text,
    String? contentType,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    if (!_api.isInitialized) {
      await initialize();
    }

    final bytes = await _api.generateSpeech(
      text: text,
      contentType: contentType,
      varkPreferences: varkPreferences,
      voiceProfileKey: _currentVoice.id,
    );
    return Uint8List.fromList(bytes);
  }

  Future<void> playAudioData(
    Uint8List audioData, {
    VoidCallback? onComplete,
  }) =>
      _api.playAudioData(audioData, onComplete: onComplete);

  void dispose() {
    // Shared singleton — lifecycle owned by [CartesiaAPIService].
  }
}
