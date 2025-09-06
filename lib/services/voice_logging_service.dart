import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fo_co_co/backend/backend.dart';
import 'package:fo_co_co/flutter_flow/lat_lng.dart';
import '/auth/firebase_auth/auth_util.dart';

class VoiceLoggingService {
  static final VoiceLoggingService _instance = VoiceLoggingService._internal();
  factory VoiceLoggingService() => _instance;
  VoiceLoggingService._internal();

  // Note: Speech recognition and location services will be implemented
  // when proper dependencies are added to pubspec.yaml
  
  bool _isListening = false;
  String _currentTranscription = '';
  LatLng? _currentLocation;
  String? _activeRoundId;
  bool _isInitialized = false;

  // Stream controllers for real-time updates
  final StreamController<String> _transcriptionController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // TODO: Initialize speech recognition when dependencies are added
      // TODO: Initialize location services when dependencies are added
      
      // For now, simulate initialization
      _currentLocation = const LatLng(40.7128, -74.0060); // Default location
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Voice logging initialization error: $e');
      return false;
    }
  }

  Future<void> startListening({String? roundId}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    _activeRoundId = roundId;
    _currentTranscription = '';

    try {
      // TODO: Implement actual speech recognition
      // For now, simulate listening
      _isListening = true;
      _listeningController.add(true);
      
      // Simulate transcription after 3 seconds
      Timer(const Duration(seconds: 3), () {
        _currentTranscription = "Hit a great drive on hole 3, felt confident with my new breathing cue";
        _transcriptionController.add(_currentTranscription);
        _processTranscription(_currentTranscription);
      });
    } catch (e) {
      debugPrint('Error starting voice recognition: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      // TODO: Stop actual speech recognition
      _isListening = false;
      _listeningController.add(false);

      // Process the final transcription
      if (_currentTranscription.isNotEmpty) {
        await _processTranscription(_currentTranscription);
      }
    } catch (e) {
      debugPrint('Error stopping voice recognition: $e');
    }
  }

  void _onSpeechResult(result) {
    // TODO: Implement when speech recognition is added
    _currentTranscription = result.toString();
    _transcriptionController.add(_currentTranscription);
  }

  Future<void> _processTranscription(String transcription) async {
    if (transcription.isEmpty || currentUser == null) return;

    try {
      // TODO: Update location when location service is added
      
      // Use simple parsing to extract data
      final parsedData = await _parseVoiceInput(transcription);
      
      // Save to appropriate collections based on content type
      if (parsedData['type'] == 'mental' || parsedData['type'] == 'mixed') {
        await _saveRoundLog(parsedData, transcription);
      }
      
      if (parsedData['type'] == 'technical' || parsedData['type'] == 'mixed') {
        await _saveShotLog(parsedData, transcription);
      }

    } catch (e) {
      debugPrint('Error processing transcription: $e');
    }
  }

  Future<Map<String, dynamic>> _parseVoiceInput(String transcription) async {
    // For now, use simple keyword-based parsing
    // TODO: Integrate with AI service when available
    return _fallbackParsing(transcription);
  }

  Map<String, dynamic> _parseAIResponse(dynamic aiResponse) {
    // TODO: Implement proper JSON parsing from AI response
    // For now, return a basic structure
    return {
      'type': 'mental',
      'mental_data': {
        'mindset_focus': 7,
        'mindset_confidence': 6,
        'mindset_control': 8,
        'cue_used': 'breathing',
        'recovery_notes': '',
        'mindset_emoji': '😊'
      },
      'technical_data': {}
    };
  }

  Map<String, dynamic> _fallbackParsing(String transcription) {
    // Simple keyword-based parsing as fallback
    final lowerText = transcription.toLowerCase();
    
    bool hasMental = lowerText.contains('feel') || 
                     lowerText.contains('confident') || 
                     lowerText.contains('focus') ||
                     lowerText.contains('calm') ||
                     lowerText.contains('nervous');
    
    bool hasTechnical = lowerText.contains('iron') ||
                       lowerText.contains('driver') ||
                       lowerText.contains('putt') ||
                       lowerText.contains('yard') ||
                       lowerText.contains('hole');

    String type = 'mental';
    if (hasTechnical && hasMental) type = 'mixed';
    else if (hasTechnical) type = 'technical';

    return {
      'type': type,
      'mental_data': hasMental ? {
        'mindset_focus': 7,
        'mindset_confidence': 6,
        'mindset_control': 8,
        'cue_used': 'breathing',
        'recovery_notes': transcription,
        'mindset_emoji': '😊'
      } : {},
      'technical_data': hasTechnical ? {
        'club_used': _extractClub(transcription),
        'hole_number': _extractHoleNumber(transcription),
        'distance_attempted': _extractDistance(transcription),
        'shot_outcome': 'good',
        'shot_shape': 'straight',
        'wind_condition': '',
        'confidence_level': 7
      } : {}
    };
  }

  String _extractClub(String text) {
    final clubs = ['driver', 'iron', 'wedge', 'putter', 'hybrid', 'wood'];
    for (final club in clubs) {
      if (text.toLowerCase().contains(club)) return club;
    }
    return 'iron';
  }

  int _extractHoleNumber(String text) {
    final regex = RegExp(r'hole\s+(\d+)', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
  }

  double _extractDistance(String text) {
    final regex = RegExp(r'(\d+)\s*yard', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match != null ? double.tryParse(match.group(1)!) ?? 150.0 : 150.0;
  }

  Future<void> _saveRoundLog(Map<String, dynamic> data, String transcription) async {
    final mental = data['mental_data'] as Map<String, dynamic>? ?? {};
    if (mental.isEmpty) return;

    final roundId = _activeRoundId ?? _generateRoundId();
    
    final roundLogData = {
      'userId': currentUser!.uid,
      'roundId': roundId,
      'date': DateTime.now(),
      'courseName': 'Voice Logged Course', // TODO: Get from context
      'courseType': 'unknown',
      'coordinates': _currentLocation != null 
          ? GeoPoint(_currentLocation!.latitude, _currentLocation!.longitude)
          : null,
      'mindsetFocus': mental['mindset_focus'] ?? 7,
      'mindsetConfidence': mental['mindset_confidence'] ?? 7,
      'mindsetControl': mental['mindset_control'] ?? 7,
      'bestCue': mental['cue_used'] ?? '',
      'recoveryHoles': [],
      'overallMindsetEmoji': mental['mindset_emoji'] ?? '😊',
      'technicalSummary': '',
      'aiRoundSummary': '',
      'voiceTranscription': transcription,
      'nlpProcessed': true,
      'isLive': true,
      'mindsetColor': _calculateMindsetColor(mental),
      'linkedGolfRoundId': '',
      'createdTime': DateTime.now(),
      'updatedTime': DateTime.now(),
    };

    await FirebaseFirestore.instance
        .collection('round_logs')
        .add(roundLogData);
  }

  Future<void> _saveShotLog(Map<String, dynamic> data, String transcription) async {
    final technical = data['technical_data'] as Map<String, dynamic>? ?? {};
    if (technical.isEmpty) return;

    final roundId = _activeRoundId ?? _generateRoundId();
    final shotId = _generateShotId();
    
    final shotLogData = {
      'userId': currentUser!.uid,
      'roundId': roundId,
      'shotId': shotId,
      'holeNumber': technical['hole_number'] ?? 1,
      'clubUsed': technical['club_used'] ?? 'iron',
      'distanceAttempted': technical['distance_attempted'] ?? 150.0,
      'shotShape': technical['shot_shape'] ?? 'straight',
      'shotOutcome': technical['shot_outcome'] ?? 'good',
      'cueUsed': technical['cue_used'] ?? '',
      'confidenceLevel': technical['confidence_level'] ?? 7,
      'windCondition': technical['wind_condition'] ?? '',
      'coordinates': _currentLocation != null 
          ? GeoPoint(_currentLocation!.latitude, _currentLocation!.longitude)
          : null,
      'aiShotInsight': '',
      'voiceTranscription': transcription,
      'nlpProcessed': true,
      'shotTrend': '',
      'missPattern': '',
      'performanceRating': 7,
      'clubIcon': _getClubIcon(technical['club_used'] ?? 'iron'),
      'timestamp': DateTime.now(),
      'createdTime': DateTime.now(),
      'updatedTime': DateTime.now(),
    };

    await FirebaseFirestore.instance
        .collection('shot_logs')
        .add(shotLogData);
  }

  String _calculateMindsetColor(Map<String, dynamic> mental) {
    final focus = mental['mindset_focus'] ?? 7;
    final confidence = mental['mindset_confidence'] ?? 7;
    final control = mental['mindset_control'] ?? 7;
    final avg = (focus + confidence + control) / 3;
    
    if (avg >= 8) return 'green';
    if (avg >= 5) return 'yellow';
    return 'red';
  }

  String _getClubIcon(String club) {
    switch (club.toLowerCase()) {
      case 'driver': return '🏌️';
      case 'iron': return '⛳';
      case 'wedge': return '🔻';
      case 'putter': return '🥅';
      default: return '⛳';
    }
  }

  String _generateRoundId() {
    return 'round_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateShotId() {
    return 'shot_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _transcriptionController.close();
    _listeningController.close();
  }
}
