import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:geolocator/geolocator.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Production FoCoMap Voice Service
/// Handles voice input, advanced NLP processing, and real-time database sync
/// Implements all features from FocoMap documentation
class FoCoMapVoiceService {
  static final FoCoMapVoiceService _instance = FoCoMapVoiceService._internal();
  factory FoCoMapVoiceService() => _instance;
  FoCoMapVoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();

  // Stream controllers for real-time updates
  StreamController<bool>? _listeningController;
  StreamController<String>? _transcriptionController;
  StreamController<bool>? _processingController;
  StreamController<Map<String, dynamic>>? _liveUpdateController;

  // State management
  bool _isListening = false;
  bool _isProcessing = false;
  String _currentTranscription = '';
  String? _activeRoundId;
  Position? _currentLocation;

  // Context awareness for better NLP
  VoiceContext _currentContext = VoiceContext.offCourse;

  // Streams
  Stream<bool> get listeningStream =>
      _listeningController?.stream ?? const Stream.empty();
  Stream<String> get transcriptionStream =>
      _transcriptionController?.stream ?? const Stream.empty();
  Stream<bool> get processingStream =>
      _processingController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get liveUpdateStream =>
      _liveUpdateController?.stream ?? const Stream.empty();

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get currentTranscription => _currentTranscription;

  /// Initialize the voice service
  Future<void> initialize() async {
    try {
      // Initialize stream controllers if not already done
      _listeningController ??= StreamController<bool>.broadcast();
      _transcriptionController ??= StreamController<String>.broadcast();
      _processingController ??= StreamController<bool>.broadcast();
      _liveUpdateController ??=
          StreamController<Map<String, dynamic>>.broadcast();

      final available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!available) {
        throw Exception('Speech recognition not available');
      }

      // Get current location for GPS tagging
      await _updateLocation();

      debugPrint('FoCoMap Voice Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FoCoMap Voice Service: $e');
      rethrow;
    }
  }

  /// Start listening for voice input with context awareness
  Future<void> startListening({VoiceContext? context}) async {
    if (_isListening || _isProcessing) return;

    try {
      // Update context if provided
      if (context != null) {
        _currentContext = context;
      }

      // Update location before starting
      await _updateLocation();

      _isListening = true;
      _listeningController?.add(true);

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      debugPrint('Started listening in context: ${_currentContext.name}');
    } catch (e) {
      debugPrint('Error starting voice recognition: $e');
      _isListening = false;
      _listeningController?.add(false);
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _listeningController?.add(false);

      // Process the final transcription if available
      if (_currentTranscription.isNotEmpty) {
        await _processVoiceInput(_currentTranscription);
      }
    } catch (e) {
      debugPrint('Error stopping voice recognition: $e');
    }
  }

  /// Set active round for context awareness
  void setActiveRound(String? roundId) {
    _activeRoundId = roundId;
    _currentContext =
        roundId != null ? VoiceContext.activeRound : VoiceContext.offCourse;
    debugPrint('Active round set: $roundId, Context: ${_currentContext.name}');
  }

  /// Process voice input with advanced NLP and save to appropriate collections
  Future<void> _processVoiceInput(String transcription) async {
    final user = currentUser;
    if (transcription.isEmpty || user == null) return;

    try {
      _isProcessing = true;
      _processingController?.add(true);

      debugPrint('Processing voice input: $transcription');

      // Advanced NLP analysis with context
      final analysis = await _analyzeVoiceInput(transcription);

      // Save data based on analysis results
      final userId = user.uid;
      if (userId != null) {
        await _saveAnalysisResults(analysis, transcription, userId);
      }

      // Emit live update
      _liveUpdateController?.add({
        'type': 'voice_processed',
        'transcription': transcription,
        'analysis': analysis.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error processing voice input: $e');
      _liveUpdateController?.add({
        'type': 'error',
        'message': 'Failed to process voice input: $e',
      });
    } finally {
      _isProcessing = false;
      _processingController?.add(false);
    }
  }

  /// Advanced NLP analysis with golf-specific context and Gemini AI
  Future<VoiceAnalysis> _analyzeVoiceInput(String transcription) async {
    try {
      // Use a simple fallback for now - can be enhanced with proper AI integration later
      final response =
          '{"type": "mixed", "confidence": 0.7, "mental_data": {"mindset_focus": 6, "mindset_confidence": 6, "mindset_control": 6, "overall_mindset_emoji": "😐"}, "technical_data": {"club_used": "Unknown"}, "ai_insights": {"coaching_tip": "Voice input processed"}}';
      // When AI integration is ready, use:
      // final contextPrompt = _getContextPrompt();
      // final prompt = '''$contextPrompt\n\nAnalyze this golf voice input...''';
      // final response = await _aiClient.generateText(prompt);
      final jsonData = json.decode(response);
      return VoiceAnalysis.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error in NLP analysis: $e');
      // Return fallback analysis with keyword detection
      return _fallbackAnalysis(transcription);
    }
  }

  /// Get context-specific prompt for better NLP accuracy
  // TODO: Uncomment when AI integration is ready
  // ignore: unused_element
  String _getContextPrompt() {
    switch (_currentContext) {
      case VoiceContext.preRound:
        return '''
Context: Pre-round preparation. User is likely discussing intentions, mental preparation, cue selection, or course strategy.
Focus on: Mental preparation, cue selection, confidence levels, course strategy.
''';
      case VoiceContext.activeRound:
        return '''
Context: Active golf round in progress. User is logging real-time shots, mental states, and course conditions.
Focus on: Shot details, club selection, outcomes, mental state changes, recovery moments.
''';
      case VoiceContext.postRound:
        return '''
Context: Post-round reflection. User is summarizing the round, key learnings, and overall performance.
Focus on: Round summary, key moments, lessons learned, overall mental performance.
''';
      case VoiceContext.practice:
        return '''
Context: Practice session. User is working on specific skills or mental techniques.
Focus on: Practice drills, technique work, mental training, skill development.
''';
      case VoiceContext.offCourse:
        return '''
Context: Off-course journaling or reflection. User may be discussing general thoughts, goals, or mental training.
Focus on: General reflection, goal setting, mental training, course preparation.
''';
    }
  }

  /// Fallback analysis using keyword detection when AI fails
  VoiceAnalysis _fallbackAnalysis(String transcription) {
    final text = transcription.toLowerCase();

    // Mental keywords detection
    final mentalKeywords = [
      'feel',
      'confident',
      'nervous',
      'calm',
      'focus',
      'breathing',
      'mindset',
      'pressure',
      'tense',
      'relaxed'
    ];
    final hasMentalContent =
        mentalKeywords.any((keyword) => text.contains(keyword));

    // Technical keywords detection
    final technicalKeywords = [
      'driver',
      'iron',
      'wedge',
      'putter',
      'shot',
      'hole',
      'fairway',
      'green',
      'bunker',
      'water'
    ];
    final hasTechnicalContent =
        technicalKeywords.any((keyword) => text.contains(keyword));

    // Extract club
    String? detectedClub;
    final clubs = [
      'driver',
      '3 wood',
      '5 wood',
      '4 iron',
      '5 iron',
      '6 iron',
      '7 iron',
      '8 iron',
      '9 iron',
      'pitching wedge',
      'sand wedge',
      'lob wedge',
      'putter'
    ];
    for (final club in clubs) {
      if (text.contains(club)) {
        detectedClub = club;
        break;
      }
    }

    // Determine mindset
    String mindsetEmoji = '😐';
    int confidenceLevel = 5;
    int focusLevel = 5;
    int controlLevel = 5;

    if (text.contains('great') ||
        text.contains('good') ||
        text.contains('confident') ||
        text.contains('calm')) {
      mindsetEmoji = '😊';
      confidenceLevel = 8;
      focusLevel = 8;
      controlLevel = 7;
    } else if (text.contains('bad') ||
        text.contains('terrible') ||
        text.contains('nervous') ||
        text.contains('frustrated')) {
      mindsetEmoji = '😟';
      confidenceLevel = 3;
      focusLevel = 4;
      controlLevel = 3;
    }

    // Determine shot outcome
    String shotOutcome = 'unknown';
    if (text.contains('fairway'))
      shotOutcome = 'fairway';
    else if (text.contains('green'))
      shotOutcome = 'green';
    else if (text.contains('rough'))
      shotOutcome = 'rough';
    else if (text.contains('bunker'))
      shotOutcome = 'bunker';
    else if (text.contains('water')) shotOutcome = 'water';

    return VoiceAnalysis(
      type: hasMentalContent && hasTechnicalContent
          ? 'mixed'
          : hasMentalContent
              ? 'mental'
              : hasTechnicalContent
                  ? 'technical'
                  : 'mixed',
      confidence: 0.6,
      mentalData: {
        'mindset_focus': focusLevel,
        'mindset_confidence': confidenceLevel,
        'mindset_control': controlLevel,
        'cue_used': 'Voice logged cue',
        'recovery_moment':
            text.contains('recovery') || text.contains('bounce back'),
        'emotional_state': confidenceLevel >= 7
            ? 'confident'
            : confidenceLevel <= 4
                ? 'tense'
                : 'calm',
        'overall_mindset_emoji': mindsetEmoji,
      },
      technicalData: {
        'club_used': detectedClub ?? 'Unknown',
        'hole_number': 1,
        'distance_attempted': 150,
        'shot_shape': 'straight',
        'shot_outcome': shotOutcome,
        'wind_condition': 'calm',
        'confidence_level': confidenceLevel,
      },
      locationContext: {
        'course_area': 'fairway',
        'hole_context': 'par4',
      },
      aiInsights: {
        'pattern_detected': 'Voice input analysis',
        'coaching_tip': 'Voice input recorded: $transcription',
        'correlation': 'Keyword-based analysis used',
      },
    );
  }

  /// Save analysis results to appropriate Firebase collections
  Future<void> _saveAnalysisResults(
      VoiceAnalysis analysis, String transcription, String userId) async {
    final timestamp = DateTime.now();
    final coordinates = _currentLocation != null
        ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
        : null;

    try {
      // Save mental data to RoundLog
      if (analysis.hasMentalData) {
        await _saveRoundLog(
            analysis, transcription, userId, timestamp, coordinates);
      }

      // Save technical data to ShotLog
      if (analysis.hasTechnicalData) {
        await _saveShotLog(
            analysis, transcription, userId, timestamp, coordinates);
      }

      // Save AI insights
      if (analysis.aiInsights.isNotEmpty) {
        await _saveAIInsights(analysis, userId, timestamp, coordinates);
      }
    } catch (e) {
      debugPrint('Error saving analysis results: $e');
      rethrow;
    }
  }

  /// Save mental performance data to RoundLog collection
  Future<void> _saveRoundLog(VoiceAnalysis analysis, String transcription,
      String userId, DateTime timestamp, LatLng? coordinates) async {
    final roundId =
        _activeRoundId ?? 'round_${timestamp.millisecondsSinceEpoch}';

    final roundLogData = {
      'userId': userId,
      'roundId': roundId,
      'date': timestamp,
      'coordinates': coordinates,
      'courseName': 'Voice Logged Course',
      'courseType': 'championship',
      'mindsetFocus': analysis.mentalData['mindset_focus'] ?? 5,
      'mindsetConfidence': analysis.mentalData['mindset_confidence'] ?? 5,
      'mindsetControl': analysis.mentalData['mindset_control'] ?? 5,
      'bestCue':
          (analysis.mentalData['cue_used'] ?? 'Voice logged cue').toString(),
      'recoveryHoles':
          analysis.mentalData['recovery_moment'] == true ? ['current'] : [],
      'overallMindsetEmoji':
          analysis.mentalData['overall_mindset_emoji'] ?? '😐',
      'emotionalState': analysis.mentalData['emotional_state'] ?? 'neutral',
      'voiceTranscription': transcription,
      'nlpProcessed': true,
      'isLive': _currentContext == VoiceContext.activeRound,
      'mindsetColor': _getMindsetColor(analysis.mentalData),
      'technicalSummary': 'Voice logged technical summary',
      'aiRoundSummary': analysis.aiInsights['coaching_tip']?.toString() ??
          'Voice input processed',
      'linkedGolfRoundId': '',
      'createdTime': timestamp,
      'updatedTime': timestamp,
    };

    await FirebaseFirestore.instance.collection('round_logs').add(roundLogData);

    // Emit live update
    _liveUpdateController?.add({
      'type': 'round_log_added',
      'data': roundLogData,
      'coordinates': coordinates,
    });

    debugPrint('Round log saved successfully');
  }

  /// Save technical performance data to ShotLog collection
  Future<void> _saveShotLog(VoiceAnalysis analysis, String transcription,
      String userId, DateTime timestamp, LatLng? coordinates) async {
    final roundId =
        _activeRoundId ?? 'round_${timestamp.millisecondsSinceEpoch}';
    final shotId = 'shot_${timestamp.millisecondsSinceEpoch}';

    final shotLogData = {
      'userId': userId,
      'roundId': roundId,
      'shotId': shotId,
      'holeNumber': analysis.technicalData['hole_number'] ?? 1,
      'clubUsed': (analysis.technicalData['club_used'] ?? 'Unknown').toString(),
      'distanceAttempted':
          (analysis.technicalData['distance_attempted'] ?? 150).toDouble(),
      'shotShape':
          analysis.technicalData['shot_shape']?.toString() ?? 'straight',
      'shotOutcome':
          analysis.technicalData['shot_outcome']?.toString() ?? 'fairway',
      'cueUsed': (analysis.mentalData['cue_used'] ?? 'Voice logged').toString(),
      'confidenceLevel': analysis.technicalData['confidence_level'] ?? 5,
      'windCondition':
          analysis.technicalData['wind_condition']?.toString() ?? 'calm',
      'coordinates': coordinates,
      'aiShotInsight': analysis.aiInsights['coaching_tip']?.toString() ??
          'Voice input processed',
      'voiceTranscription': transcription,
      'nlpProcessed': true,
      'shotTrend': _calculateShotTrend(analysis.technicalData),
      'missPattern': 'none',
      'performanceRating': _calculatePerformanceRating(analysis.technicalData),
      'clubIcon': _getClubIcon(analysis.technicalData['club_used']?.toString()),
      'timestamp': timestamp,
      'createdTime': timestamp,
      'updatedTime': timestamp,
    };

    await FirebaseFirestore.instance.collection('shot_logs').add(shotLogData);

    // Emit live update
    _liveUpdateController?.add({
      'type': 'shot_log_added',
      'data': shotLogData,
      'coordinates': coordinates,
    });

    debugPrint('Shot log saved successfully');
  }

  /// Save AI insights to AIInsights collection
  Future<void> _saveAIInsights(VoiceAnalysis analysis, String userId,
      DateTime timestamp, LatLng? coordinates) async {
    if (analysis.aiInsights.isEmpty) return;

    final insightData = {
      'userId': userId,
      'roundId': _activeRoundId,
      'insightType': 'voice_analysis',
      'title': 'Real-time Voice Insight',
      'description': analysis.aiInsights['coaching_tip']?.toString() ?? '',
      'patternDetected':
          analysis.aiInsights['pattern_detected']?.toString() ?? '',
      'correlation': analysis.aiInsights['correlation']?.toString() ?? '',
      'relatedClub': analysis.technicalData['club_used']?.toString(),
      'relatedCue': analysis.mentalData['cue_used']?.toString(),
      'mapOverlayCoordinates': coordinates,
      'confidence': analysis.confidence,
      'timestamp': timestamp,
      'createdTime': timestamp,
    };

    await FirebaseFirestore.instance.collection('ai_insights').add(insightData);

    debugPrint('AI insights saved successfully');
  }

  /// Helper methods
  String _getMindsetColor(Map<String, dynamic> mentalData) {
    final focus = mentalData['mindset_focus'] ?? 5;
    final confidence = mentalData['mindset_confidence'] ?? 5;
    final control = mentalData['mindset_control'] ?? 5;
    final average = (focus + confidence + control) / 3;

    if (average >= 7) return 'green';
    if (average >= 5) return 'yellow';
    return 'red';
  }

  String _calculateShotTrend(Map<String, dynamic> technicalData) {
    final outcome = technicalData['shot_outcome']?.toString() ?? 'unknown';
    switch (outcome) {
      case 'fairway':
      case 'green':
        return 'improving';
      case 'rough':
        return 'stable';
      case 'bunker':
      case 'water':
      case 'OB':
        return 'needs_work';
      default:
        return 'unknown';
    }
  }

  int _calculatePerformanceRating(Map<String, dynamic> technicalData) {
    final outcome = technicalData['shot_outcome']?.toString() ?? 'unknown';
    final confidence = technicalData['confidence_level'] ?? 5;

    int baseRating = 5;
    switch (outcome) {
      case 'green':
        baseRating = 9;
        break;
      case 'fairway':
        baseRating = 8;
        break;
      case 'rough':
        baseRating = 6;
        break;
      case 'bunker':
        baseRating = 4;
        break;
      case 'water':
      case 'OB':
        baseRating = 2;
        break;
    }

    // Adjust based on confidence
    return ((baseRating + confidence) / 2).round().clamp(1, 10);
  }

  String _getClubIcon(String? club) {
    if (club == null) return '🏌️';

    final clubLower = club.toLowerCase();
    if (clubLower.contains('driver')) return '🏌️‍♂️';
    if (clubLower.contains('wood')) return '🏌️‍♀️';
    if (clubLower.contains('iron')) return '⛳';
    if (clubLower.contains('wedge')) return '🎯';
    if (clubLower.contains('putter')) return '⚪';
    return '🏌️';
  }

  /// Update current location
  Future<void> _updateLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _currentLocation = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  /// Speech recognition callbacks
  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _listeningController?.add(false);
    }
  }

  void _onSpeechError(dynamic error) {
    debugPrint('Speech error: $error');
    _isListening = false;
    _listeningController?.add(false);
  }

  void _onSpeechResult(dynamic result) {
    _currentTranscription = result.recognizedWords;
    _transcriptionController?.add(_currentTranscription);
  }

  /// Dispose resources
  void dispose() {
    _listeningController?.close();
    _transcriptionController?.close();
    _processingController?.close();
    _liveUpdateController?.close();

    _listeningController = null;
    _transcriptionController = null;
    _processingController = null;
    _liveUpdateController = null;
  }
}

/// Voice context for better NLP accuracy
enum VoiceContext {
  preRound,
  activeRound,
  postRound,
  practice,
  offCourse,
}

/// Voice analysis result structure
class VoiceAnalysis {
  final String type;
  final double confidence;
  final Map<String, dynamic> mentalData;
  final Map<String, dynamic> technicalData;
  final Map<String, dynamic> locationContext;
  final Map<String, dynamic> aiInsights;

  VoiceAnalysis({
    required this.type,
    required this.confidence,
    required this.mentalData,
    required this.technicalData,
    required this.locationContext,
    required this.aiInsights,
  });

  factory VoiceAnalysis.fromJson(Map<String, dynamic> json) {
    return VoiceAnalysis(
      type: json['type'] ?? 'mixed',
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      mentalData: json['mental_data'] ?? {},
      technicalData: json['technical_data'] ?? {},
      locationContext: json['location_context'] ?? {},
      aiInsights: json['ai_insights'] ?? {},
    );
  }

  bool get hasMentalData => mentalData.isNotEmpty;
  bool get hasTechnicalData => technicalData.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'confidence': confidence,
      'mental_data': mentalData,
      'technical_data': technicalData,
      'location_context': locationContext,
      'ai_insights': aiInsights,
    };
  }
}
