import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
// Audio recording will be implemented with platform-specific packages
// import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/shot_logs_record.dart';
import '/backend/schema/golf_rounds_record.dart';
import '/backend/schema/scorecard_record.dart';

/// Advanced FoCo Map Voice Service using only Gemini models
/// Implements the 4-stage pipeline: Audio Capture → STT → NLU → Instruction Generation
class FoCoMapGeminiVoiceService {
  static final FoCoMapGeminiVoiceService _instance =
      FoCoMapGeminiVoiceService._internal();
  factory FoCoMapGeminiVoiceService() => _instance;
  FoCoMapGeminiVoiceService._internal();

  // Gemini API Configuration
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _baseUrl = 'https://generativelanguage.googleapis.com';

  // Gemini Models for different stages
  static const String _audioModel = 'gemini-1.5-flash'; // For audio processing
  static const String _instructionModel =
      'gemini-1.5-pro'; // For instruction generation
  static const String _roboticsModel =
      'gemini-robotics-er-1.5-preview'; // For spatial analysis

  // Audio Recording - Implementation placeholder
  // final AudioRecorder _audioRecorder = AudioRecorder();
  // StreamSubscription<RecordState>? _recordStateSubscription;
  final StreamController<Uint8List> _audioBufferController =
      StreamController<Uint8List>.broadcast();

  // Real-time processing
  Timer? _processingTimer;
  final List<Uint8List> _audioChunks = [];
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;

  // Context and state
  String? _activeRoundId;
  VoiceContext _currentContext = VoiceContext.offCourse;
  Position? _currentLocation;

  // Stream controllers
  final StreamController<VoiceState> _stateController =
      StreamController<VoiceState>.broadcast();
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<VoiceInsight> _insightController =
      StreamController<VoiceInsight>.broadcast();
  final StreamController<Map<String, dynamic>> _instructionController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<VoiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<VoiceInsight> get insightStream => _insightController.stream;
  Stream<Map<String, dynamic>> get instructionStream =>
      _instructionController.stream;

  // Getters
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  VoiceContext get currentContext => _currentContext;

  /// Initialize the Gemini Voice Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      final microphoneStatus = await Permission.microphone.request();
      if (!microphoneStatus.isGranted) {
        throw Exception('Microphone permission denied');
      }

      // Initialize audio recorder - placeholder
      // In production, use platform-specific audio recording packages
      debugPrint('Audio recorder initialization placeholder');

      // Update location
      await _updateLocation();

      _isInitialized = true;
      _stateController.add(VoiceState.initialized);

      debugPrint('FoCo Map Gemini Voice Service initialized');
    } catch (e) {
      debugPrint('Error initializing Gemini Voice Service: $e');
      _stateController.add(VoiceState.error);
      rethrow;
    }
  }

  /// Start real-time listening with continuous processing
  Future<void> startListening({
    VoiceContext? context,
    String? roundId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized || _isListening) return;

    try {
      _isListening = true;
      _activeRoundId = roundId;
      if (context != null) _currentContext = context;

      _stateController.add(VoiceState.listening);

      // Start recording - placeholder implementation
      // In production, implement with actual audio recording
      debugPrint('Starting audio recording (placeholder)');

      // Simulate audio chunks for demo
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isListening) {
          // Simulate audio data
          final simulatedAudio = Uint8List(1600); // 100ms of 16kHz audio
          _handleAudioChunk(simulatedAudio);
        } else {
          timer.cancel();
        }
      });

      // Start processing timer for continuous analysis
      _processingTimer = Timer.periodic(
        const Duration(
            milliseconds: 500), // Process every 500ms for low latency
        (_) => _processAccumulatedAudio(),
      );

      debugPrint(
          'Started real-time listening in context: ${_currentContext.name}');
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _stateController.add(VoiceState.error);
      await stopListening();
    }
  }

  /// Stop listening and process final audio
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    _processingTimer?.cancel();
    // await _recordStateSubscription?.cancel();

    // Stop recording - placeholder
    debugPrint('Stopping audio recording (placeholder)');

    // Process any remaining audio
    if (_audioChunks.isNotEmpty) {
      await _processAccumulatedAudio(isFinal: true);
    }

    _audioChunks.clear();
    _stateController.add(VoiceState.idle);

    debugPrint('Stopped listening');
  }

  /// Handle incoming audio chunks
  void _handleAudioChunk(Uint8List chunk) {
    _audioChunks.add(chunk);
    _audioBufferController.add(chunk);

    // Implement voice activity detection (VAD)
    if (_detectVoiceActivity(chunk)) {
      _stateController.add(VoiceState.voiceDetected);
    }
  }

  /// Process accumulated audio chunks using Gemini
  Future<void> _processAccumulatedAudio({bool isFinal = false}) async {
    if (_audioChunks.isEmpty || _isProcessing) return;

    _isProcessing = true;
    _stateController.add(VoiceState.processing);

    try {
      // Combine audio chunks
      final combinedAudio = _combineAudioChunks(_audioChunks);

      // Clear processed chunks (keep last chunk for continuity)
      if (!isFinal) {
        _audioChunks.clear();
        _audioChunks.add(combinedAudio.sublist(combinedAudio.length ~/ 2));
      } else {
        _audioChunks.clear();
      }

      // Stage 1 & 2: Audio to Text using Gemini multimodal
      final transcription = await _performSpeechToText(combinedAudio);
      if (transcription.isNotEmpty) {
        _transcriptionController.add(transcription);

        // Stage 3: Natural Language Understanding
        final understanding = await _performNLU(transcription);

        // Stage 4: Generate Custom Instructions
        final instructions = await _generateInstructions(understanding);

        // Execute instructions and save data
        await _executeInstructions(instructions, transcription);
      }
    } catch (e) {
      debugPrint('Error processing audio: $e');
      _stateController.add(VoiceState.error);
    } finally {
      _isProcessing = false;
      if (_isListening) {
        _stateController.add(VoiceState.listening);
      }
    }
  }

  /// Stage 1 & 2: Speech-to-Text using Gemini multimodal
  Future<String> _performSpeechToText(Uint8List audioData) async {
    try {
      // Convert audio to base64 for Gemini API
      final audioBase64 = base64Encode(audioData);

      // Use Gemini Flash for fast audio transcription
      final response = await http.post(
        Uri.parse('$_baseUrl/v1beta/models/$_audioModel:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': 'audio/wav',
                    'data': audioBase64,
                  }
                },
                {
                  'text':
                      'Transcribe this golf-related audio. Focus on: mental state, club selection, shot outcomes, course conditions, and any golf-specific terminology. Return only the transcription.'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transcription =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        return transcription.trim();
      }

      return '';
    } catch (e) {
      debugPrint('STT Error: $e');
      return '';
    }
  }

  /// Stage 3: Natural Language Understanding using Gemini
  Future<Map<String, dynamic>> _performNLU(String transcription) async {
    try {
      // Create context-aware prompt
      final contextPrompt = _buildContextPrompt();

      final response = await http.post(
        Uri.parse('$_baseUrl/v1beta/models/$_instructionModel:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
$contextPrompt

Analyze this golf voice input and extract structured information:
"$transcription"

Return a JSON object with:
{
  "intent": "mental_log|shot_log|round_summary|query|course_navigation|practice_drill",
  "entities": {
    "mental_state": {
      "focus": 1-10,
      "confidence": 1-10,
      "control": 1-10,
      "emotion": "calm|confident|nervous|frustrated|focused",
      "cue": "extracted mental cue if mentioned"
    },
    "shot_details": {
      "club": "driver|3wood|5wood|4-9iron|PW|SW|LW|putter",
      "distance": number,
      "outcome": "fairway|green|rough|bunker|water|OB",
      "shape": "straight|draw|fade|hook|slice",
      "quality": 1-10
    },
    "course_info": {
      "hole": number,
      "conditions": "wind|rain|sun|calm",
      "terrain": "uphill|downhill|sidehill|flat"
    },
    "temporal": {
      "when": "now|earlier|yesterday|lastweek",
      "duration": "practice|round|session"
    }
  },
  "confidence": 0.0-1.0,
  "context_relevance": "pre_round|active_round|post_round|practice|off_course"
}
'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1000,
            'response_mime_type': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
        return jsonDecode(content);
      }

      return {};
    } catch (e) {
      debugPrint('NLU Error: $e');
      return {};
    }
  }

  /// Stage 4: Generate Custom Instructions using Gemini
  Future<Map<String, dynamic>> _generateInstructions(
      Map<String, dynamic> understanding) async {
    try {
      final intent = understanding['intent'] ?? 'unknown';
      final entities = understanding['entities'] ?? {};

      // Use Gemini to generate personalized instructions
      final response = await http.post(
        Uri.parse('$_baseUrl/v1beta/models/$_instructionModel:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Based on this golf voice input analysis, generate custom instructions:

Intent: $intent
Entities: ${jsonEncode(entities)}
Context: ${_currentContext.name}
Active Round: ${_activeRoundId ?? 'none'}
Location: ${_currentLocation != null ? 'lat: ${_currentLocation!.latitude}, lng: ${_currentLocation!.longitude}' : 'unknown'}

Generate a JSON response with:
{
  "actions": [
    {
      "type": "save_mental_log|save_shot_log|update_round|query_response|navigate|start_drill",
      "data": { /* specific data for the action */ },
      "priority": "high|medium|low"
    }
  ],
  "feedback": {
    "message": "Conversational response to user",
    "suggestions": ["suggestion1", "suggestion2"],
    "insights": {
      "pattern": "any pattern detected",
      "recommendation": "coaching recommendation"
    }
  },
  "spatial_analysis": {
    "should_analyze": boolean,
    "focus_area": "shot_dispersion|course_strategy|wind_patterns"
  }
}
'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1500,
            'response_mime_type': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
        final instructions = jsonDecode(content);

        // If spatial analysis is needed, use robotics model
        if (instructions['spatial_analysis']?['should_analyze'] == true) {
          instructions['spatial_data'] = await _performSpatialAnalysis(
              entities, instructions['spatial_analysis']['focus_area']);
        }

        return instructions;
      }

      return {};
    } catch (e) {
      debugPrint('Instruction Generation Error: $e');
      return {};
    }
  }

  /// Perform spatial analysis using Gemini Robotics model
  Future<Map<String, dynamic>> _performSpatialAnalysis(
    Map<String, dynamic> entities,
    String focusArea,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1beta/models/$_roboticsModel:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Analyze golf spatial data for enhanced map visualization:

Focus Area: $focusArea
Shot Data: ${jsonEncode(entities['shot_details'] ?? {})}
Course Info: ${jsonEncode(entities['course_info'] ?? {})}
Current Location: ${_currentLocation != null ? 'lat: ${_currentLocation!.latitude}, lng: ${_currentLocation!.longitude}' : 'unknown'}

Provide spatial analysis including:
{
  "trajectory": {
    "start": {"lat": number, "lng": number},
    "end": {"lat": number, "lng": number},
    "apex": {"height": number, "distance": number},
    "curve": "straight|draw|fade"
  },
  "dispersion": {
    "pattern": "consistent|scattered|trending_left|trending_right",
    "confidence_radius": number,
    "suggested_aim_adjustment": {"direction": degrees, "distance": yards}
  },
  "environmental": {
    "wind_effect": {"direction": degrees, "strength": mph, "impact": yards},
    "elevation_change": feet,
    "landing_area": "fairway|rough|hazard"
  },
  "visualization": {
    "heatmap_intensity": 0.0-1.0,
    "trajectory_color": "hex_color",
    "marker_size": "small|medium|large"
  }
}
'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1000,
            'response_mime_type': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
        return jsonDecode(content);
      }

      return {};
    } catch (e) {
      debugPrint('Spatial Analysis Error: $e');
      return {};
    }
  }

  /// Execute generated instructions
  Future<void> _executeInstructions(
    Map<String, dynamic> instructions,
    String transcription,
  ) async {
    final actions = instructions['actions'] ?? [];
    final feedback = instructions['feedback'] ?? {};

    // Send feedback to user immediately
    if (feedback['message'] != null) {
      _insightController.add(VoiceInsight(
        message: feedback['message'],
        suggestions: List<String>.from(feedback['suggestions'] ?? []),
        insights: feedback['insights'] ?? {},
        spatialData: instructions['spatial_data'],
      ));
    }

    // Execute actions in priority order
    final sortedActions = List<Map<String, dynamic>>.from(actions)
      ..sort((a, b) => _getPriorityValue(b['priority'])
          .compareTo(_getPriorityValue(a['priority'])));

    for (final action in sortedActions) {
      await _executeAction(action, transcription);
    }

    // Update instruction stream
    _instructionController.add(instructions);
  }

  /// Execute a single action
  Future<void> _executeAction(
      Map<String, dynamic> action, String transcription) async {
    final type = action['type'];
    final data = action['data'] ?? {};

    switch (type) {
      case 'save_mental_log':
        await _saveMentalLog(data, transcription);
        break;
      case 'save_shot_log':
        await _saveShotLog(data, transcription);
        break;
      case 'update_round':
        await _updateRound(data);
        break;
      case 'query_response':
        await _handleQuery(data);
        break;
      case 'navigate':
        await _handleNavigation(data);
        break;
      case 'start_drill':
        await _startPracticeDrill(data);
        break;
    }
  }

  /// Save mental performance log
  Future<void> _saveMentalLog(
      Map<String, dynamic> data, String transcription) async {
    final user = currentUser;
    if (user?.uid == null) return;

    final mentalState = data['mental_state'] ?? {};
    final timestamp = DateTime.now();
    final coordinates = _currentLocation != null
        ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
        : null;

    final roundLogData = {
      'userId': user!.uid,
      'roundId': _activeRoundId ?? 'voice_${timestamp.millisecondsSinceEpoch}',
      'date': timestamp,
      'coordinates': coordinates,
      'courseName': data['course_name'] ?? 'Voice Session',
      'courseType': 'championship',
      'mindsetFocus': mentalState['focus'] ?? 5,
      'mindsetConfidence': mentalState['confidence'] ?? 5,
      'mindsetControl': mentalState['control'] ?? 5,
      'bestCue': mentalState['cue'] ?? 'Voice-detected cue',
      'overallMindsetEmoji': _getEmoji(mentalState),
      'emotionalState': mentalState['emotion'] ?? 'neutral',
      'voiceTranscription': transcription,
      'nlpProcessed': true,
      'isLive': _currentContext == VoiceContext.activeRound,
      'createdTime': timestamp,
      'updatedTime': timestamp,
    };

    await FirebaseFirestore.instance.collection('round_logs').add(roundLogData);

    debugPrint('Mental log saved via Gemini voice');
  }

  /// Save shot log
  Future<void> _saveShotLog(
      Map<String, dynamic> data, String transcription) async {
    final user = currentUser;
    if (user?.uid == null) return;

    final shotDetails = data['shot_details'] ?? {};
    final timestamp = DateTime.now();
    final coordinates = _currentLocation != null
        ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
        : null;

    final shotLogData = {
      'userId': user!.uid,
      'roundId': _activeRoundId ?? 'voice_${timestamp.millisecondsSinceEpoch}',
      'shotId': 'shot_${timestamp.millisecondsSinceEpoch}',
      'holeNumber': data['hole_number'] ?? 1,
      'clubUsed': shotDetails['club'] ?? 'Unknown',
      'distanceAttempted': shotDetails['distance']?.toDouble() ?? 150.0,
      'shotShape': shotDetails['shape'] ?? 'straight',
      'shotOutcome': shotDetails['outcome'] ?? 'fairway',
      'cueUsed': data['mental_state']?['cue'] ?? 'Voice-detected',
      'confidenceLevel': shotDetails['quality'] ?? 5,
      'windCondition': data['course_info']?['conditions'] ?? 'calm',
      'coordinates': coordinates,
      'voiceTranscription': transcription,
      'nlpProcessed': true,
      'timestamp': timestamp,
      'createdTime': timestamp,
      'updatedTime': timestamp,
    };

    await FirebaseFirestore.instance.collection('shot_logs').add(shotLogData);

    debugPrint('Shot log saved via Gemini voice');
  }

  /// Helper methods
  String _buildContextPrompt() {
    final prompts = {
      VoiceContext.preRound: '''
Context: Pre-round preparation phase
User is preparing mentally and strategically for their round.
Focus on: intentions, mental cues, course strategy, warm-up, confidence building.
Recent topics: goal setting, visualization, course management planning.
''',
      VoiceContext.activeRound: '''
Context: Active golf round in progress
User is playing and needs real-time logging and insights.
Focus on: shot execution, mental state changes, course conditions, scoring.
Recent topics: club selection, shot outcomes, mental adjustments, recovery shots.
Round ID: ${_activeRoundId ?? 'not set'}
''',
      VoiceContext.postRound: '''
Context: Post-round reflection and analysis
User is reviewing their performance and learning.
Focus on: round summary, key moments, lessons learned, improvement areas.
Recent topics: best shots, challenges faced, mental breakthroughs, scoring patterns.
''',
      VoiceContext.practice: '''
Context: Practice session at range or course
User is working on specific skills and techniques.
Focus on: drill execution, swing thoughts, repetition quality, skill development.
Recent topics: technique adjustments, consistency, target practice, mental routine.
''',
      VoiceContext.offCourse: '''
Context: Off-course mental training or planning
User is doing mental work away from the course.
Focus on: visualization, goal setting, mental training, course preparation.
Recent topics: mental exercises, course strategy planning, confidence building.
''',
    };

    return prompts[_currentContext] ?? prompts[VoiceContext.offCourse]!;
  }

  bool _detectVoiceActivity(Uint8List audioChunk) {
    // Simple VAD based on amplitude
    int sum = 0;
    for (int i = 0; i < audioChunk.length; i += 2) {
      final sample = (audioChunk[i + 1] << 8) | audioChunk[i];
      sum += sample.abs();
    }
    final average = sum / (audioChunk.length / 2);
    return average > 500; // Threshold for voice detection
  }

  Uint8List _combineAudioChunks(List<Uint8List> chunks) {
    final totalLength = chunks.fold(0, (sum, chunk) => sum + chunk.length);
    final combined = Uint8List(totalLength);
    int offset = 0;
    for (final chunk in chunks) {
      combined.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return combined;
  }

  int _getPriorityValue(String? priority) {
    switch (priority) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  String _getEmoji(Map<String, dynamic> mentalState) {
    final avg = ((mentalState['focus'] ?? 5) +
            (mentalState['confidence'] ?? 5) +
            (mentalState['control'] ?? 5)) /
        3;

    if (avg >= 8) return '🔥';
    if (avg >= 7) return '😊';
    if (avg >= 5) return '😐';
    if (avg >= 3) return '😟';
    return '😣';
  }

  Future<void> _updateLocation() async {
    try {
      _currentLocation = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Location update error: $e');
    }
  }

  Future<void> _updateRound(Map<String, dynamic> data) async {
    // Implement round update logic
    debugPrint('Updating round with data: $data');
  }

  Future<void> _handleQuery(Map<String, dynamic> data) async {
    // Implement query handling
    debugPrint('Handling query: $data');
  }

  Future<void> _handleNavigation(Map<String, dynamic> data) async {
    // Implement navigation logic
    debugPrint('Navigation request: $data');
  }

  Future<void> _startPracticeDrill(Map<String, dynamic> data) async {
    // Implement practice drill logic
    debugPrint('Starting practice drill: $data');
  }

  void _handleError(dynamic error) {
    debugPrint('Audio stream error: $error');
    _stateController.add(VoiceState.error);
  }

  /// Dispose resources
  Future<void> dispose() async {
    _processingTimer?.cancel();
    // await _recordStateSubscription?.cancel();
    // await _audioRecorder.dispose();
    await _audioBufferController.close();
    await _stateController.close();
    await _transcriptionController.close();
    await _insightController.close();
    await _instructionController.close();
  }
}

/// Voice processing states
enum VoiceState {
  uninitialized,
  initialized,
  idle,
  listening,
  voiceDetected,
  processing,
  error,
}

/// Voice context for enhanced understanding
enum VoiceContext {
  preRound,
  activeRound,
  postRound,
  practice,
  offCourse,
}

/// Voice insight structure
class VoiceInsight {
  final String message;
  final List<String> suggestions;
  final Map<String, dynamic> insights;
  final Map<String, dynamic>? spatialData;

  VoiceInsight({
    required this.message,
    this.suggestions = const [],
    this.insights = const {},
    this.spatialData,
  });
}
