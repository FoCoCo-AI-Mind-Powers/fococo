import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// LiveKit Service with Gemini Live Integration
/// Handles real-time voice communication using LiveKit and Gemini AI
class LiveKitGeminiService {
  static final LiveKitGeminiService _instance = LiveKitGeminiService._internal();
  factory LiveKitGeminiService() => _instance;
  LiveKitGeminiService._internal();

  // LiveKit Configuration
  static const String _livekitUrl = 'wss://fococo-45unq6sj.livekit.cloud';
  static const String _apiKey = 'APIhqsNFhwph9pU';
  static const String _apiSecret = 'ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F';

  Room? _room;
  LocalParticipant? _localParticipant;
  bool _isConnected = false;
  bool _isMicrophoneEnabled = false;

  // State management
  final _connectionStateController = StreamController<LiveKitConnectionState>.broadcast();
  final _audioTrackController = StreamController<RemoteAudioTrack?>.broadcast();
  final _transcriptionController = StreamController<String>.broadcast();

  // Getters
  Room? get room => _room;
  bool get isConnected => _isConnected;
  bool get isMicrophoneEnabled => _isMicrophoneEnabled;
  Stream<LiveKitConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<RemoteAudioTrack?> get audioTrackStream => _audioTrackController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;

  /// Generate LiveKit access token
  /// Note: In production, this should be done on your backend server
  /// For now, using a simple approach - you should implement backend token generation
  Future<String> _generateToken({
    required String roomName,
    required String participantName,
    required String participantIdentity,
  }) async {
    try {
      // TODO: Implement proper token generation on your backend
      // For now, this is a placeholder - you need to call your backend API
      // that generates LiveKit tokens using the API key and secret
      
      // Example backend call (uncomment and implement):
      // final response = await http.post(
      //   Uri.parse('YOUR_BACKEND_URL/generate-livekit-token'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'room': roomName,
      //     'identity': participantIdentity,
      //     'name': participantName,
      //   }),
      // );
      // return jsonDecode(response.body)['token'];
      
      // Temporary: Return empty string - you must implement backend token generation
      throw Exception('Token generation must be implemented on backend. See _generateToken method.');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to generate LiveKit token: $e');
        print('⚠️ You must implement token generation on your backend server');
      }
      rethrow;
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

      // Connect to room
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
      );

      _localParticipant = _room!.localParticipant;
      _isConnected = true;

      // Set up participant listeners
      _setupParticipantListeners();

      _connectionStateController.add(LiveKitConnectionState.connected);

      if (kDebugMode) {
        print('✅ Connected to LiveKit room: $roomName');
      }
    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(LiveKitConnectionState.disconnected);
      if (kDebugMode) {
        print('❌ Failed to connect to LiveKit: $e');
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
        if (participant is RemoteParticipant) {
          participant.addListener(() {
            _onParticipantChanged(participant);
          });
        }
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
        
        // Process audio for Gemini Live transcription
        _processAudioForGemini(audioTrack);
        return;
      }
    }
    _audioTrackController.add(null);
  }

  /// Process audio track for Gemini Live
  Future<void> _processAudioForGemini(RemoteAudioTrack audioTrack) async {
    // This would integrate with Gemini Live API
    // For now, this is a placeholder for the integration
    if (kDebugMode) {
      print('🎵 Processing audio for Gemini Live');
    }

    // TODO: Implement Gemini Live audio processing
    // This would involve:
    // 1. Capturing audio samples from the track
    // 2. Sending to Gemini Live API
    // 3. Receiving transcriptions and responses
    // 4. Emitting transcriptions via _transcriptionController
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
      await _room!.disconnect();
      _room = null;
      _localParticipant = null;
      _isConnected = false;
      _isMicrophoneEnabled = false;

      _connectionStateController.add(LiveKitConnectionState.disconnected);

      if (kDebugMode) {
        print('👋 Disconnected from LiveKit room');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting: $e');
      }
    }
  }

  /// Send data message (for Gemini Live integration)
  Future<void> sendDataMessage(String message) async {
    if (!_isConnected || _localParticipant == null) {
      throw Exception('Not connected to room');
    }

    try {
      await _localParticipant!.publishData(
        utf8.encode(message),
        topic: 'gemini-live',
      );

      if (kDebugMode) {
        print('📤 Sent data message: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send data message: $e');
      }
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _audioTrackController.close();
    _transcriptionController.close();
  }
}

/// LiveKit connection state enum
enum LiveKitConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}
