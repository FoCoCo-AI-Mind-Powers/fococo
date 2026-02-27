import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../ai_integration/config/just_talk_livekit_config.dart';

/// Connection state exposed to JustTalk widget.
enum LiveKitConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Voice mode state exposed to JustTalk widget.
enum VoiceModeState {
  assistant,
  ready,
  listening,
  thinking,
  speaking,
  paused,
  error,
  fallbackRequired,
}

/// Internal coarse service state for LiveKit + agent flow.
enum JustTalkLiveKitServiceState {
  disconnected,
  connecting,
  connected,
  listening,
  thinking,
  speaking,
  error,
  fallbackRequired,
}

class JustTalkLiveKitMessageEvent {
  const JustTalkLiveKitMessageEvent({
    required this.id,
    required this.content,
    required this.isUser,
    required this.isTranscript,
    required this.timestamp,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String content;
  final bool isUser;
  final bool isTranscript;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}

/// Session-based LiveKit agent service for JustTalk voice interactions.
class JustTalkLiveKitAgentService {
  static final JustTalkLiveKitAgentService _instance =
      JustTalkLiveKitAgentService._internal();
  factory JustTalkLiveKitAgentService() => _instance;
  JustTalkLiveKitAgentService._internal();

  Session? _session;
  VoidCallback? _sessionListener;

  bool _isSessionEnding = false;
  bool _isMicrophoneEnabled = false;
  bool _isPaused = false;

  String? _currentRoomName;
  String? _currentParticipantName;
  String? _currentParticipantIdentity;
  String? _currentAgentMetadata;
  Map<String, String>? _currentParticipantAttributes;

  LiveKitConnectionState _connectionState = LiveKitConnectionState.disconnected;
  VoiceModeState _voiceState = VoiceModeState.assistant;
  JustTalkLiveKitServiceState _serviceState =
      JustTalkLiveKitServiceState.disconnected;

  final Map<String, String> _lastMessageSignatures = <String, String>{};

  final StreamController<LiveKitConnectionState> _connectionStateController =
      StreamController<LiveKitConnectionState>.broadcast();
  final StreamController<VoiceModeState> _voiceStateController =
      StreamController<VoiceModeState>.broadcast();
  final StreamController<JustTalkLiveKitServiceState> _serviceStateController =
      StreamController<JustTalkLiveKitServiceState>.broadcast();
  final StreamController<JustTalkLiveKitMessageEvent> _messageController =
      StreamController<JustTalkLiveKitMessageEvent>.broadcast();
  final StreamController<String> _fallbackReasonController =
      StreamController<String>.broadcast();

  Stream<LiveKitConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<VoiceModeState> get voiceStateStream => _voiceStateController.stream;
  Stream<JustTalkLiveKitServiceState> get stateStream =>
      _serviceStateController.stream;
  Stream<JustTalkLiveKitMessageEvent> get messageStream =>
      _messageController.stream;
  Stream<String> get fallbackReasonStream => _fallbackReasonController.stream;

  LiveKitConnectionState get connectionState => _connectionState;
  VoiceModeState get voiceState => _voiceState;
  JustTalkLiveKitServiceState get serviceState => _serviceState;

  bool get isConnected {
    final state = _session?.connectionState;
    return state == ConnectionState.connected;
  }

  bool get isMicrophoneEnabled => _isMicrophoneEnabled;
  bool get isPaused => _isPaused;

  Future<void> connect({
    required String roomName,
    required String participantName,
    String? participantIdentity,
    String? agentMetadata,
    Map<String, String>? participantAttributes,
  }) {
    return startSession(
      roomName: roomName,
      participantName: participantName,
      participantIdentity: participantIdentity,
      agentMetadata: agentMetadata,
      participantAttributes: participantAttributes,
    );
  }

  Future<void> startSession({
    required String roomName,
    required String participantName,
    String? participantIdentity,
    String? agentMetadata,
    Map<String, String>? participantAttributes,
  }) async {
    if (_session != null && isConnected && _currentRoomName == roomName) {
      return;
    }

    // Ensure the user is authenticated before attempting to start a session.
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError(
        'Cannot start voice session: user is not authenticated.',
      );
    }

    await endSession();

    JustTalkLiveKitConfig.logConfig();

    _currentRoomName = roomName;
    _currentParticipantName = participantName;
    _currentParticipantIdentity = participantIdentity ??
        FirebaseAuth.instance.currentUser?.uid ??
        'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    _currentAgentMetadata = agentMetadata;
    _currentParticipantAttributes = participantAttributes;
    _isPaused = false;
    _isMicrophoneEnabled = false;

    _setConnectionState(LiveKitConnectionState.connecting);
    _setVoiceState(VoiceModeState.ready);

    final tokenSource = CustomTokenSource(
      (options) => _fetchToken(
        options: options,
        roomName: _currentRoomName!,
        participantName: _currentParticipantName!,
        participantIdentity: _currentParticipantIdentity!,
        agentMetadata: _currentAgentMetadata,
        participantAttributes: _currentParticipantAttributes,
      ),
    ).cached();

    try {
      final session = Session.withAgent(
        JustTalkLiveKitConfig.agentName,
        agentMetadata: _currentAgentMetadata,
        tokenSource: tokenSource,
        options: SessionOptions(
          preConnectAudio: false,
          agentConnectTimeout: JustTalkLiveKitConfig.agentConnectTimeout,
        ),
      );

      _session = session;
      _sessionListener = _onSessionChanged;
      session.addListener(_sessionListener!);

      await session.start();

      // Start with mic muted until user explicitly taps the voice button.
      await session.room.localParticipant?.setMicrophoneEnabled(false);
      _isMicrophoneEnabled = false;
      _setVoiceState(VoiceModeState.ready);

      _emitMessagesFromSession(force: true);
      _onSessionChanged();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ LiveKit startSession failed: $e');
        print(stackTrace);
      }
      _setVoiceState(VoiceModeState.error);
      _setServiceState(JustTalkLiveKitServiceState.error);
      _emitFallbackRequired('Failed to start LiveKit session: $e');
      rethrow;
    }
  }

  Future<void> endSession() async {
    final session = _session;
    if (session == null) {
      _setConnectionState(LiveKitConnectionState.disconnected);
      _setVoiceState(VoiceModeState.assistant);
      _setServiceState(JustTalkLiveKitServiceState.disconnected);
      return;
    }

    _isSessionEnding = true;
    try {
      final listener = _sessionListener;
      if (listener != null) {
        session.removeListener(listener);
      }

      try {
        await session.end();
      } catch (_) {
        // Ignore disconnect failures during teardown.
      }

      try {
        await session.dispose();
      } catch (_) {
        // Ignore disposal failures.
      }
    } finally {
      _sessionListener = null;
      _session = null;
      _isSessionEnding = false;
      _isMicrophoneEnabled = false;
      _isPaused = false;
      _currentRoomName = null;
      _currentParticipantName = null;
      _currentParticipantIdentity = null;
      _currentAgentMetadata = null;
      _currentParticipantAttributes = null;
      _lastMessageSignatures.clear();
      _setConnectionState(LiveKitConnectionState.disconnected);
      _setVoiceState(VoiceModeState.assistant);
      _setServiceState(JustTalkLiveKitServiceState.disconnected);
    }
  }

  Future<void> disconnect() => endSession();

  Future<void> sendText(String text) async {
    final session = _session;
    if (session == null) {
      throw StateError('LiveKit session is not initialized.');
    }

    final sent = await session.sendText(text);
    if (sent == null) {
      throw StateError('LiveKit failed to send text message.');
    }

    _emitMessagesFromSession();
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    final localParticipant = _session?.room.localParticipant;
    if (localParticipant == null) {
      throw StateError('LiveKit local participant is not available.');
    }

    await localParticipant.setMicrophoneEnabled(enabled);
    _isMicrophoneEnabled = enabled;

    if (enabled) {
      _isPaused = false;
      _setVoiceState(VoiceModeState.listening);
    } else if (_isPaused) {
      _setVoiceState(VoiceModeState.paused);
    } else {
      _setVoiceState(VoiceModeState.ready);
    }
  }

  Future<void> pause() async {
    _isPaused = true;
    await setMicrophoneEnabled(false);
    _setVoiceState(VoiceModeState.paused);
  }

  Future<void> resume() async {
    _isPaused = false;
    await setMicrophoneEnabled(true);
  }

  Future<void> stop() async {
    await endSession();
  }

  Future<void> restart() async {
    final roomName = _currentRoomName;
    final participantName = _currentParticipantName;
    final participantIdentity = _currentParticipantIdentity;
    final agentMetadata = _currentAgentMetadata;
    final participantAttributes = _currentParticipantAttributes;

    if (roomName == null || participantName == null) {
      throw StateError('Cannot restart LiveKit session before initial start.');
    }

    await endSession();
    await startSession(
      roomName: roomName,
      participantName: participantName,
      participantIdentity: participantIdentity,
      agentMetadata: agentMetadata,
      participantAttributes: participantAttributes,
    );
  }

  Future<TokenSourceResponse> _fetchToken({
    required TokenRequestOptions options,
    required String roomName,
    required String participantName,
    required String participantIdentity,
    String? agentMetadata,
    Map<String, String>? participantAttributes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        'Cannot fetch LiveKit token: user is not authenticated.',
      );
    }

    // Force-refresh the Firebase ID token so the Functions call carries
    // a valid credential even if the cached token has expired.
    await user.getIdToken(true);

    final callable =
        FirebaseFunctions.instance.httpsCallable('generateLiveKitToken');

    final payload = <String, dynamic>{
      // Legacy request fields.
      'room': roomName,
      'identity': participantIdentity,
      'name': participantName,

      // Modern request fields.
      'room_name': roomName,
      'participant_identity': participantIdentity,
      'participant_name': participantName,

      // Agent and participant context.
      'agentName': options.agentName ?? JustTalkLiveKitConfig.agentName,
      if (agentMetadata != null && agentMetadata.isNotEmpty)
        'agentMetadata': agentMetadata,
      if (participantAttributes != null && participantAttributes.isNotEmpty)
        'participantAttributes': participantAttributes,
    };

    final result = await callable.call(payload);
    final data = (result.data as Map).cast<String, dynamic>();

    final participantToken = _firstString(<dynamic>[
      data['participant_token'],
      data['participantToken'],
      data['token'],
    ]);

    if (participantToken == null || participantToken.isEmpty) {
      throw StateError('generateLiveKitToken returned an empty token.');
    }

    final serverUrl = _firstString(<dynamic>[
          data['server_url'],
          data['serverUrl'],
        ]) ??
        JustTalkLiveKitConfig.liveKitUrl;

    return TokenSourceResponse(
      serverUrl: serverUrl,
      participantToken: participantToken,
      participantName: participantName,
      roomName: roomName,
    );
  }

  void _onSessionChanged() {
    final session = _session;
    if (session == null) {
      return;
    }

    final connection = session.connectionState;
    switch (connection) {
      case ConnectionState.connecting:
        _setConnectionState(LiveKitConnectionState.connecting);
        break;
      case ConnectionState.reconnecting:
        _setConnectionState(LiveKitConnectionState.reconnecting);
        break;
      case ConnectionState.connected:
        _setConnectionState(LiveKitConnectionState.connected);
        break;
      case ConnectionState.disconnected:
        _setConnectionState(LiveKitConnectionState.disconnected);
        if (!_isSessionEnding && _voiceState != VoiceModeState.assistant) {
          _emitFallbackRequired('LiveKit disconnected unexpectedly.');
        }
        break;
    }

    if (session.error != null) {
      _setVoiceState(VoiceModeState.error);
      _setServiceState(JustTalkLiveKitServiceState.error);
      _emitFallbackRequired('LiveKit session error: ${session.error!.message}');
      return;
    }

    if (session.agent.error != null) {
      final failure = session.agent.error!;
      _setVoiceState(VoiceModeState.error);
      _setServiceState(JustTalkLiveKitServiceState.error);
      _emitFallbackRequired('LiveKit agent error: ${failure.message}');
      return;
    }

    if (connection == ConnectionState.connected) {
      if (_isPaused) {
        _setVoiceState(VoiceModeState.paused);
      } else {
        switch (session.agent.agentState) {
          case AgentState.listening:
            _setVoiceState(VoiceModeState.listening);
            break;
          case AgentState.thinking:
            _setVoiceState(VoiceModeState.thinking);
            break;
          case AgentState.speaking:
            _setVoiceState(VoiceModeState.speaking);
            break;
          case AgentState.idle:
          case AgentState.initializing:
          case null:
            _setVoiceState(VoiceModeState.ready);
            break;
        }
      }
    }

    _emitMessagesFromSession();
  }

  void _emitMessagesFromSession({bool force = false}) {
    final session = _session;
    if (session == null) {
      return;
    }

    for (final message in session.messages) {
      final text = message.content.text.trim();
      if (text.isEmpty) {
        continue;
      }

      final isUser =
          message.content is UserInput || message.content is UserTranscript;
      final isTranscript = message.content is AgentTranscript ||
          message.content is UserTranscript;
      final signature = '${message.content.runtimeType}:$text';

      if (!force && _lastMessageSignatures[message.id] == signature) {
        continue;
      }
      _lastMessageSignatures[message.id] = signature;

      _messageController.add(
        JustTalkLiveKitMessageEvent(
          id: message.id,
          content: text,
          isUser: isUser,
          isTranscript: isTranscript,
          timestamp: message.timestamp,
          metadata: <String, dynamic>{
            'voiceEngine': 'livekit_agent',
            'isTranscript': isTranscript,
            'livekitState': _voiceState.name,
            'contentType': message.content.runtimeType.toString(),
          },
        ),
      );
    }
  }

  void _emitFallbackRequired(String reason) {
    if (_isSessionEnding || _fallbackReasonController.isClosed) {
      return;
    }

    _setVoiceState(VoiceModeState.fallbackRequired);
    _setServiceState(JustTalkLiveKitServiceState.fallbackRequired);
    _fallbackReasonController.add(reason);
  }

  void _setConnectionState(LiveKitConnectionState next) {
    if (_connectionState == next) {
      return;
    }
    _connectionState = next;
    _connectionStateController.add(next);

    if (next == LiveKitConnectionState.disconnected &&
        _serviceState != JustTalkLiveKitServiceState.fallbackRequired &&
        _serviceState != JustTalkLiveKitServiceState.error) {
      _setServiceState(JustTalkLiveKitServiceState.disconnected);
    } else if (next == LiveKitConnectionState.connecting ||
        next == LiveKitConnectionState.reconnecting) {
      _setServiceState(JustTalkLiveKitServiceState.connecting);
    }
  }

  void _setVoiceState(VoiceModeState next) {
    if (_voiceState == next) {
      return;
    }
    _voiceState = next;
    _voiceStateController.add(next);

    switch (next) {
      case VoiceModeState.assistant:
        _setServiceState(JustTalkLiveKitServiceState.disconnected);
        break;
      case VoiceModeState.ready:
      case VoiceModeState.paused:
        _setServiceState(JustTalkLiveKitServiceState.connected);
        break;
      case VoiceModeState.listening:
        _setServiceState(JustTalkLiveKitServiceState.listening);
        break;
      case VoiceModeState.thinking:
        _setServiceState(JustTalkLiveKitServiceState.thinking);
        break;
      case VoiceModeState.speaking:
        _setServiceState(JustTalkLiveKitServiceState.speaking);
        break;
      case VoiceModeState.error:
        _setServiceState(JustTalkLiveKitServiceState.error);
        break;
      case VoiceModeState.fallbackRequired:
        _setServiceState(JustTalkLiveKitServiceState.fallbackRequired);
        break;
    }
  }

  void _setServiceState(JustTalkLiveKitServiceState next) {
    if (_serviceState == next) {
      return;
    }
    _serviceState = next;
    _serviceStateController.add(next);
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  void dispose() {
    unawaited(endSession());
    _connectionStateController.close();
    _voiceStateController.close();
    _serviceStateController.close();
    _messageController.close();
    _fallbackReasonController.close();
  }
}
