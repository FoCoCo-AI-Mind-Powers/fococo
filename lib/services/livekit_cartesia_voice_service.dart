import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../ai_integration/services/cartesia_api_service.dart';
import '../backend/schema/structs/vark_preferences_struct.dart';

/// LiveKit Service with Cartesia Voice Integration
/// Handles real-time voice communication using LiveKit and Cartesia TTS
class LiveKitCartesiaVoiceService {
  static final LiveKitCartesiaVoiceService _instance = LiveKitCartesiaVoiceService._internal();
  factory LiveKitCartesiaVoiceService() => _instance;
  LiveKitCartesiaVoiceService._internal();

  // LiveKit Configuration
  static const String _livekitUrl = 'wss://fococo-45unq6sj.livekit.cloud';
  static const String _apiKey = 'APIhqsNFhwph9pU';
  static const String _apiSecret = 'ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F';

  // Cartesia Configuration - Carter Voice
  // TODO: Replace with actual Carter voice ID when available
  static const String _carterVoiceId = 'da3224fe-d8d1-4774-8902-e6a7115f5132'; // Default voice, update to Carter ID

  Room? _room;
  LocalParticipant? _localParticipant;
  bool _isConnected = false;
  bool _isMicrophoneEnabled = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  // Cartesia service
  final CartesiaAPIService _cartesiaService = CartesiaAPIService.instance;

  // State management
  final _connectionStateController = StreamController<LiveKitConnectionState>.broadcast();
  final _audioTrackController = StreamController<RemoteAudioTrack?>.broadcast();
  final _transcriptionController = StreamController<String>.broadcast();
  final _voiceStateController = StreamController<VoiceModeState>.broadcast();

  // Getters
  Room? get room => _room;
  bool get isConnected => _isConnected;
  bool get isMicrophoneEnabled => _isMicrophoneEnabled;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  Stream<LiveKitConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<RemoteAudioTrack?> get audioTrackStream => _audioTrackController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<VoiceModeState> get voiceStateStream => _voiceStateController.stream;

  /// Generate LiveKit access token using Firebase Cloud Functions
  /// This calls the generateLiveKitToken Firebase Function
  Future<String> _generateToken({
    required String roomName,
    required String participantName,
    required String participantIdentity,
  }) async {
    try {
      // Call Firebase Cloud Function to generate token
      final callable = FirebaseFunctions.instance.httpsCallable('generateLiveKitToken');
      
      final result = await callable.call({
        'room': roomName,
        'identity': participantIdentity,
        'name': participantName,
      }).timeout(const Duration(seconds: 10));

      final data = result.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          print('✅ Generated LiveKit token from Firebase Function');
        }
        return token;
      }
      
      throw Exception('Firebase Function returned empty token');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to generate LiveKit token: $e');
        print('⚠️ Make sure Firebase Functions are deployed and generateLiveKitToken function exists');
      }
      rethrow;
    }
  }

  /// Initialize Cartesia with Carter voice
  Future<void> _initializeCartesia() async {
    try {
      await _cartesiaService.initialize();
      _cartesiaService.setVoiceId(_carterVoiceId);
      
      // Listen to speaking state
      _cartesiaService.speakingStream.listen((isSpeaking) {
        _isSpeaking = isSpeaking;
        _voiceStateController.add(
          isSpeaking ? VoiceModeState.speaking : VoiceModeState.listening,
        );
      });

      if (kDebugMode) {
        print('✅ Cartesia initialized with Carter voice');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Cartesia: $e');
      }
    }
  }

  /// Connect to LiveKit room
  Future<void> connect({
    required String roomName,
    String? participantName,
  }) async {
    if (_isConnected) {
      if (kDebugMode) {
        print('⚠️ Already connected to room');
      }
      return;
    }

    try {
      _connectionStateController.add(LiveKitConnectionState.connecting);
      
      // Initialize Cartesia first (don't fail if this fails)
      try {
        await _initializeCartesia();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Cartesia initialization failed, continuing anyway: $e');
        }
      }

      // Get current user for identity
      final user = FirebaseAuth.instance.currentUser;
      final identity = user?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      final name = participantName ?? user?.displayName ?? user?.email ?? 'User';

      // Generate token
      final token = await _generateToken(
        roomName: roomName,
        participantName: name,
        participantIdentity: identity,
      );

      // Create room
      _room = Room();

      // Set up event listeners
      _room!.addListener(_onRoomChanged);

      // Connect to room with timeout
      await _room!.connect(
        _livekitUrl,
        token,
        roomOptions: RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioCaptureOptions: AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          ),
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout after 15 seconds');
        },
      );

      _localParticipant = _room!.localParticipant;
      _isConnected = true;

      // Set up participant listeners
      try {
        _setupParticipantListeners();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to setup participant listeners: $e');
        }
      }

      _connectionStateController.add(LiveKitConnectionState.connected);
      _voiceStateController.add(VoiceModeState.ready);

      if (kDebugMode) {
        print('✅ Connected to LiveKit room: $roomName');
      }
    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(LiveKitConnectionState.disconnected);
      _voiceStateController.add(VoiceModeState.assistant);
      
      // Clean up room if it was created
      try {
        if (_room != null) {
          await _room!.disconnect();
          _room = null;
          _localParticipant = null;
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      
      if (kDebugMode) {
        print('❌ Failed to connect to LiveKit: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Error message: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Enable/disable microphone
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (!_isConnected || _localParticipant == null) {
      throw Exception('Not connected to room');
    }

    try {
      await _localParticipant!.setMicrophoneEnabled(enabled);
      _isMicrophoneEnabled = enabled;
      
      _voiceStateController.add(
        enabled ? VoiceModeState.listening : VoiceModeState.ready,
      );

      if (kDebugMode) {
        print('🎤 Microphone ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to ${enabled ? 'enable' : 'disable'} microphone: $e');
      }
      rethrow;
    }
  }

  /// Pause voice playback
  Future<void> pause() async {
    try {
      await _cartesiaService.pausePlayback();
      _isPaused = true;
      _voiceStateController.add(VoiceModeState.paused);

      if (kDebugMode) {
        print('⏸️ Voice playback paused');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to pause: $e');
      }
    }
  }

  /// Resume voice playback
  Future<void> resume() async {
    try {
      await _cartesiaService.resumePlayback();
      _isPaused = false;
      // Check if actually speaking after resume
      if (_cartesiaService.isSpeaking) {
        _voiceStateController.add(VoiceModeState.speaking);
      } else {
        _voiceStateController.add(VoiceModeState.ready);
      }

      if (kDebugMode) {
        print('▶️ Voice playback resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to resume: $e');
      }
    }
  }

  /// Stop voice and return to assistant mode
  Future<void> stop() async {
    try {
      await _cartesiaService.stopSpeaking();
      await setMicrophoneEnabled(false);
      _isPaused = false;
      _voiceStateController.add(VoiceModeState.assistant);

      if (kDebugMode) {
        print('🛑 Voice stopped, returned to assistant mode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop: $e');
      }
    }
  }

  /// Restart voice session
  Future<void> restart() async {
    try {
      await stop();
      await Future.delayed(const Duration(milliseconds: 300));
      await setMicrophoneEnabled(true);
      
      if (kDebugMode) {
        print('🔄 Voice session restarted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to restart: $e');
      }
    }
  }

  /// Speak text using Cartesia Carter voice
  Future<void> speakText({
    required String text,
    VarkPreferencesStruct? varkPreferences,
  }) async {
    try {
      await _cartesiaService.speakText(
        text: text,
        voiceId: _carterVoiceId,
        contentType: 'coaching',
        varkPreferences: varkPreferences,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to speak text: $e');
      }
      rethrow;
    }
  }

  /// Set up participant event listeners
  void _setupParticipantListeners() {
    if (_room == null) return;

    // Listen for remote participants
    _room!.addListener(() {
      for (final participant in _room!.remoteParticipants.values) {
        participant.addListener(() {
          _onParticipantChanged(participant);
        });
      }
    });

    // Listen for new participants using events
    _room!.events.listen((event) {
      if (event is ParticipantConnectedEvent) {
        final participant = event.participant;
        participant.addListener(() {
          _onParticipantChanged(participant);
        });
      }
    });
  }

  /// Handle participant changes
  void _onParticipantChanged(RemoteParticipant participant) {
    // Find audio track
    for (final publication in participant.trackPublications.values) {
      if (publication.kind == TrackType.AUDIO && 
          publication.subscribed && 
          publication.track != null) {
        final audioTrack = publication.track as RemoteAudioTrack;
        _audioTrackController.add(audioTrack);
        
        // Process audio for transcription
        _processAudioForTranscription(audioTrack);
        return;
      }
    }
    _audioTrackController.add(null);
  }

  /// Process audio track for transcription
  Future<void> _processAudioForTranscription(RemoteAudioTrack audioTrack) async {
    // TODO: Implement audio transcription processing
    // This would send audio to Gemini Live API for transcription
    if (kDebugMode) {
      print('🎵 Processing audio for transcription');
    }
  }

  /// Handle room state changes
  void _onRoomChanged() {
    if (_room == null) return;

    final state = _room!.connectionState;
    LiveKitConnectionState livekitState;
    
    switch (state) {
      case ConnectionState.disconnected:
        livekitState = LiveKitConnectionState.disconnected;
        _isConnected = false;
        _isMicrophoneEnabled = false;
        break;
      case ConnectionState.connecting:
        livekitState = LiveKitConnectionState.connecting;
        break;
      case ConnectionState.connected:
        livekitState = LiveKitConnectionState.connected;
        break;
      case ConnectionState.reconnecting:
        livekitState = LiveKitConnectionState.reconnecting;
        break;
    }
    
    _connectionStateController.add(livekitState);
  }

  /// Disconnect from room
  Future<void> disconnect() async {
    if (!_isConnected || _room == null) return;

    try {
      await stop();
      await _room!.disconnect();
      _room = null;
      _localParticipant = null;
      _isConnected = false;
      _isMicrophoneEnabled = false;

      _connectionStateController.add(LiveKitConnectionState.disconnected);
      _voiceStateController.add(VoiceModeState.assistant);

      if (kDebugMode) {
        print('👋 Disconnected from LiveKit room');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _audioTrackController.close();
    _transcriptionController.close();
    _voiceStateController.close();
  }
}

/// LiveKit connection state enum
enum LiveKitConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Voice mode state enum
enum VoiceModeState {
  assistant,  // Assistant mode (default)
  ready,      // Ready to listen
  listening,  // Listening to user
  thinking,   // Processing/thinking
  speaking,   // Speaking response
  paused,     // Paused
}
