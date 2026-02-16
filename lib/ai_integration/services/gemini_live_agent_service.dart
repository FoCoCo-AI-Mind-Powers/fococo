/// Gemini Live Agent Service for LiveKit Agents Integration
/// This service connects to LiveKit rooms where a backend agent (Python/Node.js)
/// handles Gemini Live API integration via LiveKit Agents framework
/// 
/// Backend agent uses: livekit-agents[google] with google.realtime.RealtimeModel
/// Documentation: https://docs.livekit.io/agents/models/realtime/plugins/gemini/

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Connection state for LiveKit Agent
enum LiveKitAgentState {
  disconnected,
  connecting,
  connected,
  agentJoining,
  ready,
  listening,
  agentSpeaking,
  error,
}

/// MindCoach-specific configuration for Gemini Live Agent
class MindCoachAgentConfig {
  final String templateId;
  final String? scenarioTag;
  final String varkMode;
  final String level;
  final String length;
  final Map<String, dynamic> context;
  final String? systemInstructionOverride;

  const MindCoachAgentConfig({
    required this.templateId,
    this.scenarioTag,
    required this.varkMode,
    this.level = 'Foundation',
    this.length = 'standard',
    this.context = const {},
    this.systemInstructionOverride,
  });

  Map<String, dynamic> toJson() => {
        'template_id': templateId,
        if (scenarioTag != null) 'scenario_tag': scenarioTag,
        'vark_mode': varkMode,
        'level': level,
        'length': length,
        'context': context,
        if (systemInstructionOverride != null)
          'system_instruction': systemInstructionOverride,
      };
}

/// Service for connecting to LiveKit rooms with Gemini Live Agent
class GeminiLiveAgentService {
  static final GeminiLiveAgentService _instance =
      GeminiLiveAgentService._internal();
  factory GeminiLiveAgentService() => _instance;
  GeminiLiveAgentService._internal();

  // LiveKit Configuration
  static const String _livekitUrl = 'wss://fococo-45unq6sj.livekit.cloud';

  Room? _room;
  LocalParticipant? _localParticipant;
  RemoteParticipant? _agentParticipant;

  // State management
  LiveKitAgentState _currentState = LiveKitAgentState.disconnected;
  final StreamController<LiveKitAgentState> _stateController =
      StreamController<LiveKitAgentState>.broadcast();
  final StreamController<String> _transcriptionController =
      StreamController<String>.broadcast();
  final StreamController<String> _responseTextController =
      StreamController<String>.broadcast();
  final StreamController<RemoteAudioTrack?> _audioTrackController =
      StreamController<RemoteAudioTrack?>.broadcast();

  // Session management
  Timer? _connectionTimeout;

  // Getters
  Room? get room => _room;
  bool get isConnected =>
      _currentState == LiveKitAgentState.ready ||
      _currentState == LiveKitAgentState.listening ||
      _currentState == LiveKitAgentState.agentSpeaking;
  bool get isListening => _currentState == LiveKitAgentState.listening;
  bool get isAgentSpeaking => _currentState == LiveKitAgentState.agentSpeaking;
  Stream<LiveKitAgentState> get stateStream => _stateController.stream;
  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<String> get responseTextStream => _responseTextController.stream;
  Stream<RemoteAudioTrack?> get audioTrackStream =>
      _audioTrackController.stream;
  LiveKitAgentState get currentState => _currentState;

  /// Generate LiveKit token via Firebase Cloud Function
  Future<String> _generateToken({
    required String roomName,
    required String participantIdentity,
    required String participantName,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateLiveKitToken');

      final result = await callable.call({
        'room': roomName,
        'identity': participantIdentity,
        'name': participantName,
      });

      final data = result.data as Map<String, dynamic>;
      return data['token'] as String;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to generate LiveKit token: $e');
      }
      rethrow;
    }
  }

  /// Connect to LiveKit room and wait for agent to join
  Future<void> connect({
    required String roomName,
    required MindCoachAgentConfig config,
    String? participantName,
  }) async {
    if (_currentState != LiveKitAgentState.disconnected) {
      if (kDebugMode) {
        print('⚠️ Already connected or connecting');
      }
      return;
    }

    try {
      _updateState(LiveKitAgentState.connecting);

      // Get current user for identity
      final user = FirebaseAuth.instance.currentUser;
      final identity = user?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final name = participantName ?? user?.displayName ?? user?.email ?? 'User';

      // Generate token
      final token = await _generateToken(
        roomName: roomName,
        participantIdentity: identity,
        participantName: name,
      );

      // Create and connect to room
      _room = Room();
      _room!.addListener(_onRoomChanged);

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
      _updateState(LiveKitAgentState.connected);

      // Set up event listeners
      _setupEventListeners();

      // Enable microphone
      await _localParticipant!.setMicrophoneEnabled(true);

      // Send configuration to agent via data channel
      await _sendConfigToAgent(config);

      // Wait for agent to join (with timeout)
      _connectionTimeout = Timer(const Duration(seconds: 10), () {
        if (_currentState == LiveKitAgentState.connected) {
          _updateState(LiveKitAgentState.error);
          if (kDebugMode) {
            print('❌ Agent did not join within timeout');
          }
        }
      });

      if (kDebugMode) {
        print('✅ Connected to LiveKit room: $roomName');
        print('⏳ Waiting for agent to join...');
      }
    } catch (e) {
      _updateState(LiveKitAgentState.error);
      if (kDebugMode) {
        print('❌ Failed to connect to LiveKit: $e');
      }
      rethrow;
    }
  }

  /// Send configuration to agent via data channel
  Future<void> _sendConfigToAgent(MindCoachAgentConfig config) async {
    if (_localParticipant == null) return;

    try {
      final configData = jsonEncode({
        'type': 'mindcoach_config',
        'config': config.toJson(),
      });

      await _localParticipant!.publishData(
        Uint8List.fromList(configData.codeUnits),
        topic: 'agent-config',
        reliable: true,
      );

      if (kDebugMode) {
        print('📤 Sent config to agent: ${config.templateId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send config to agent: $e');
      }
    }
  }

  /// Set up event listeners for room and participants
  void _setupEventListeners() {
    if (_room == null) return;

    // Listen for participant events
    _room!.events.listen((event) {
      if (event is ParticipantConnectedEvent) {
        final participant = event.participant;
        // Only handle remote participants (agents)
        if (participant is! LocalParticipant) {
          _onAgentJoined(participant);
        }
      } else if (event is ParticipantDisconnectedEvent) {
        if (event.participant == _agentParticipant) {
          _onAgentLeft();
        }
      } else if (event is DataReceivedEvent) {
        _onDataReceived(event);
      } else if (event is TrackSubscribedEvent) {
        _onTrackSubscribed(event);
      } else if (event is TrackUnsubscribedEvent) {
        _onTrackUnsubscribed(event);
      }
    });
  }

  /// Handle agent joining the room
  void _onAgentJoined(RemoteParticipant participant) {
    if (_agentParticipant != null) return;

    _agentParticipant = participant;
    _connectionTimeout?.cancel();
    _updateState(LiveKitAgentState.agentJoining);

    // Set up participant listener
    participant.addListener(() {
      _onAgentParticipantChanged(participant);
    });

    // Check for existing audio tracks
    for (final publication in participant.trackPublications.values) {
      if (publication.kind == TrackType.AUDIO && publication.subscribed) {
        final track = publication.track;
        if (track != null && track is RemoteAudioTrack) {
          _onAudioTrackReceived(track);
        }
      }
    }

    _updateState(LiveKitAgentState.ready);
    if (kDebugMode) {
      print('✅ Agent joined the room');
    }
  }

  /// Handle agent leaving
  void _onAgentLeft() {
    _agentParticipant = null;
    _updateState(LiveKitAgentState.connected);
    if (kDebugMode) {
      print('👋 Agent left the room');
    }
  }

  /// Handle agent participant changes
  void _onAgentParticipantChanged(RemoteParticipant participant) {
    // Check for new audio tracks
    for (final publication in participant.trackPublications.values) {
      if (publication.kind == TrackType.AUDIO && 
          publication.subscribed && 
          publication.track != null) {
        final track = publication.track as RemoteAudioTrack;
        _onAudioTrackReceived(track);
      }
    }
  }

  /// Handle audio track subscription
  void _onTrackSubscribed(TrackSubscribedEvent event) {
    if (event.participant == _agentParticipant &&
        event.track.kind == TrackType.AUDIO) {
      final audioTrack = event.track as RemoteAudioTrack;
      _onAudioTrackReceived(audioTrack);
    }
  }

  /// Handle audio track unsubscription
  void _onTrackUnsubscribed(TrackUnsubscribedEvent event) {
    if (event.participant == _agentParticipant &&
        event.track.kind == TrackType.AUDIO) {
      _audioTrackController.add(null);
      if (_currentState == LiveKitAgentState.agentSpeaking) {
        _updateState(LiveKitAgentState.ready);
      }
    }
  }

  /// Handle received audio track from agent
  void _onAudioTrackReceived(RemoteAudioTrack audioTrack) {
    _audioTrackController.add(audioTrack);
    _updateState(LiveKitAgentState.agentSpeaking);

    // Attach audio track to audio renderer
    audioTrack.addListener(() {
      // Track is playing
    });

    if (kDebugMode) {
      print('🎵 Received audio track from agent');
    }
  }

  /// Handle data received from agent
  void _onDataReceived(DataReceivedEvent event) {
    try {
      final data = utf8.decode(event.data);
      final json = jsonDecode(data) as Map<String, dynamic>;

      final type = json['type'] as String?;

      switch (type) {
        case 'transcription':
          final text = json['text'] as String?;
          if (text != null) {
            _transcriptionController.add(text);
          }
          break;

        case 'response_text':
          final text = json['text'] as String?;
          if (text != null) {
            _responseTextController.add(text);
          }
          break;

        case 'state':
          final state = json['state'] as String?;
          if (state == 'listening') {
            _updateState(LiveKitAgentState.listening);
          } else if (state == 'speaking') {
            _updateState(LiveKitAgentState.agentSpeaking);
          } else if (state == 'ready') {
            _updateState(LiveKitAgentState.ready);
          }
          break;

        case 'error':
          final error = json['error'] as String?;
          if (kDebugMode) {
            print('❌ Agent error: $error');
          }
          _updateState(LiveKitAgentState.error);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to parse agent data: $e');
      }
    }
  }

  /// Enable/disable microphone
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_localParticipant == null) {
      throw Exception('Not connected to room');
    }

    try {
      await _localParticipant!.setMicrophoneEnabled(enabled);
      if (enabled && _currentState == LiveKitAgentState.ready) {
        _updateState(LiveKitAgentState.listening);
      } else if (!enabled && _currentState == LiveKitAgentState.listening) {
        _updateState(LiveKitAgentState.ready);
      }

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

  /// Send text message to agent (for testing or fallback)
  Future<void> sendTextMessage(String text) async {
    if (_localParticipant == null) {
      throw Exception('Not connected to room');
    }

    try {
      final message = jsonEncode({
        'type': 'user_message',
        'text': text,
      });

      await _localParticipant!.publishData(
        Uint8List.fromList(message.codeUnits),
        topic: 'user-input',
        reliable: true,
      );

      if (kDebugMode) {
        print('📤 Sent text message to agent: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send text message: $e');
      }
      rethrow;
    }
  }

  /// Handle room state changes
  void _onRoomChanged() {
    if (_room == null) return;

    final state = _room!.connectionState;
    switch (state) {
      case ConnectionState.disconnected:
        _updateState(LiveKitAgentState.disconnected);
        _agentParticipant = null;
        break;
      case ConnectionState.connecting:
        _updateState(LiveKitAgentState.connecting);
        break;
      case ConnectionState.connected:
        if (_agentParticipant == null) {
          _updateState(LiveKitAgentState.connected);
        }
        break;
      case ConnectionState.reconnecting:
        _updateState(LiveKitAgentState.connecting);
        break;
    }
  }

  /// Disconnect from room
  Future<void> disconnect() async {
    if (_currentState == LiveKitAgentState.disconnected) return;

    try {
      _connectionTimeout?.cancel();
      await _room?.disconnect();
      _room = null;
      _localParticipant = null;
      _agentParticipant = null;
      _updateState(LiveKitAgentState.disconnected);

      if (kDebugMode) {
        print('👋 Disconnected from LiveKit room');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting: $e');
      }
    }
  }

  /// Update state and notify listeners
  void _updateState(LiveKitAgentState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      if (kDebugMode) {
        print('🔄 State changed: $newState');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _stateController.close();
    _transcriptionController.close();
    _responseTextController.close();
    _audioTrackController.close();
  }
}

