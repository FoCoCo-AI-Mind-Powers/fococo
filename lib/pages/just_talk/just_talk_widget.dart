import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '/ai_integration/config/gemini_live_config.dart';
import '/ai_integration/config/just_talk_livekit_config.dart';
import '/ai_integration/gemini_ai_client.dart';
import '/ai_integration/services/cartesia_api_service.dart';
import '/ai_integration/services/gemini_live_service_simple.dart';
import '/ai_integration/services/permission_service.dart';
import '/ai_integration/services/voice_chat_database_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/just_talk_livekit_agent_service.dart';
import '/services/units_preference_service.dart';

import 'just_talk_model.dart';

export 'just_talk_model.dart';

class JustTalkWidget extends StatefulWidget {
  const JustTalkWidget({
    super.key,
    this.autoInitialize = true,
    this.liveKitService,
    this.databaseService,
  });

  static const String routeName = 'just_talk';
  static const String routePath = '/just_talk';

  final bool autoInitialize;
  final JustTalkLiveKitAgentService? liveKitService;
  final VoiceChatDatabaseService? databaseService;

  @override
  State<JustTalkWidget> createState() => _JustTalkWidgetState();
}

class _VoiceTurn {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isTranscript;
  final Map<String, dynamic> metadata;

  const _VoiceTurn({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.isTranscript = false,
    this.metadata = const <String, dynamic>{},
  });

  _VoiceTurn copyWith({
    String? text,
    DateTime? time,
    bool? isTranscript,
    Map<String, dynamic>? metadata,
  }) {
    return _VoiceTurn(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      time: time ?? this.time,
      isTranscript: isTranscript ?? this.isTranscript,
      metadata: metadata ?? this.metadata,
    );
  }
}

class _JustTalkWidgetState extends State<JustTalkWidget>
    with TickerProviderStateMixin {
  late JustTalkModel _model;
  late GeminiAIClient _aiClient;
  late JustTalkLiveKitAgentService _livekitService;
  late VoiceChatDatabaseService _databaseService;

  final PermissionService _permissionService = PermissionService();
  final SpeechToText _speechToText = SpeechToText();
  final CartesiaAPIService _cartesiaService = CartesiaAPIService.instance;

  final ScrollController _scrollController = ScrollController();
  final List<_VoiceTurn> _turns = <_VoiceTurn>[];
  final Map<String, Timer> _messageSaveDebounceTimers = <String, Timer>{};

  final VarkPreferencesStruct _varkPreferences = VarkPreferencesStruct(
    visual: false,
    aural: true,
    readWrite: false,
    kinesthetic: false,
  );

  LiveKitConnectionState _connectionState = LiveKitConnectionState.disconnected;
  GeminiLiveServiceState _voiceState = GeminiLiveServiceState.disconnected;

  bool _speechReady = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isPaused = false;
  bool _isBusy = false;

  bool _isLiveMode = true;
  bool _isUsingLiveKitFallback = false;
  String? _lastLiveKitFallbackReason;

  String? _sessionId;
  String _unitsAiContextLine = '';

  StreamSubscription<LiveKitConnectionState>? _connectionSub;
  StreamSubscription<VoiceModeState>? _voiceModeSub;
  StreamSubscription<JustTalkLiveKitMessageEvent>? _messageSub;
  StreamSubscription<String>? _fallbackSub;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => JustTalkModel());
    _aiClient = GeminiAIClient();
    _livekitService = widget.liveKitService ?? JustTalkLiveKitAgentService();
    _databaseService = widget.databaseService ?? VoiceChatDatabaseService();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _unitsAiContextLine = await UnitsPreferenceService.aiContextLine();
    } catch (_) {}

    try {
      await _permissionService.initialize();
      _speechReady = await _speechToText.initialize();
    } catch (_) {
      _speechReady = false;
    }

    try {
      await _databaseService.initialize();
      final session = await _databaseService.startSession(
        title: 'JustTalk Session',
        varkPreferences: _varkPreferences,
        metadata: <String, dynamic>{
          'voiceEngine': 'livekit_agent',
          'fallbackEnabled': JustTalkLiveKitConfig.fallbackEnabled,
        },
      );
      _sessionId = session.id;
    } catch (e) {
      if (kDebugMode) {
        print('JustTalk DB init failed: $e');
      }
    }

    try {
      await _cartesiaService.initialize();
      _cartesiaService.setVoiceId(JustTalkLiveKitConfig.defaultCartesiaVoiceId);
    } catch (e) {
      if (kDebugMode) {
        print('JustTalk Cartesia init failed: $e');
      }
    }

    _connectionSub = _livekitService.connectionStateStream.listen(
      (state) {
        if (!mounted) return;
        setState(() => _connectionState = state);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _connectionState = LiveKitConnectionState.disconnected);
      },
    );

    _voiceModeSub = _livekitService.voiceStateStream.listen(
      (state) {
        if (!mounted) return;
        final mapped = _mapLiveKitMode(state);
        setState(() {
          _voiceState = mapped;
          _isListening = mapped == GeminiLiveServiceState.listening;
          _isThinking = mapped == GeminiLiveServiceState.thinking;
          _isPaused = state == VoiceModeState.paused;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _voiceState = GeminiLiveServiceState.error);
      },
    );

    _messageSub = _livekitService.messageStream.listen(
      _handleLiveKitMessage,
      onError: (error) {
        if (kDebugMode) {
          print('JustTalk LiveKit message stream error: $error');
        }
      },
    );

    _fallbackSub = _livekitService.fallbackReasonStream.listen((reason) async {
      if (!mounted || !_isLiveMode || !JustTalkLiveKitConfig.fallbackEnabled) {
        return;
      }
      await _activateLiveKitFallback(reason);
    });

    if (widget.autoInitialize && _isLiveMode) {
      await _ensureConnected();
    }
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _voiceModeSub?.cancel();
    _messageSub?.cancel();
    _fallbackSub?.cancel();

    for (final timer in _messageSaveDebounceTimers.values) {
      timer.cancel();
    }
    _messageSaveDebounceTimers.clear();

    _speechToText.cancel();
    _scrollController.dispose();

    unawaited(_livekitService.endSession());
    if (_sessionId != null) {
      unawaited(_databaseService.endSession(_sessionId!));
    }

    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            _buildStatusBar(theme),
            Expanded(child: _buildConversation(theme)),
            _buildVoiceControls(theme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                color: theme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JustTalk',
                      style: theme.titleLarge
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Voice conversation mode',
                      style:
                          theme.bodySmall.copyWith(color: theme.secondaryText),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.safePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Live Mode',
                style: theme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _isLiveMode,
                onChanged: _isBusy ? null : (value) => _toggleLiveMode(value),
              ),
              const SizedBox(width: 8),
              if (_isUsingLiveKitFallback)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.warning.withValues(alpha: 0.14),
                    border: Border.all(
                      color: theme.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Fallback active',
                    style: theme.bodySmall.copyWith(
                      color: theme.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(FlutterFlowTheme theme) {
    final color = _statusColor(theme);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusText(),
              style: theme.bodySmall.copyWith(color: color),
            ),
          ),
          if (_isBusy)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversation(FlutterFlowTheme theme) {
    if (_turns.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                FontAwesomeIcons.microphone,
                color: theme.primary.withValues(alpha: 0.7),
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                'Tap the mic to start a conversation.',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      itemCount: _turns.length,
      itemBuilder: (context, index) {
        final turn = _turns[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment:
                turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: turn.isUser
                    ? theme.primary
                    : theme.secondaryBackground.withValues(alpha: 0.5),
                border: Border.all(
                  color: turn.isUser
                      ? theme.primary
                      : theme.alternate.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turn.text,
                    style: theme.bodyMedium.copyWith(
                      color: turn.isUser ? Colors.white : theme.primaryText,
                    ),
                  ),
                  if (!turn.isUser)
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => _playTurn(turn),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, left: 8),
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 18,
                            color: turn.isUser
                                ? Colors.white.withValues(alpha: 0.9)
                                : theme.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  if (turn.isTranscript)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'transcript',
                        style: theme.bodySmall.copyWith(
                          color: turn.isUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : theme.secondaryText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceControls(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isBusy ? null : _onMicPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isListening
                      ? [const Color(0xFF10B981), const Color(0xFF047857)]
                      : _isThinking
                          ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                          : [theme.primary, theme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening
                            ? const Color(0xFF10B981)
                            : (_isThinking
                                ? const Color(0xFFF59E0B)
                                : theme.primary))
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                _isListening
                    ? Icons.hearing_rounded
                    : FontAwesomeIcons.microphone,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                theme,
                icon:
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: _isPaused ? 'Resume' : 'Pause',
                onTap: _togglePause,
              ),
              const SizedBox(width: 10),
              _controlButton(
                theme,
                icon: Icons.stop_rounded,
                label: 'Stop',
                onTap: _stopAll,
              ),
              const SizedBox(width: 10),
              _controlButton(
                theme,
                icon: Icons.restart_alt_rounded,
                label: 'Restart',
                onTap: _restartSession,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlButton(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.secondaryBackground,
          border: Border.all(color: theme.alternate.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.primaryText),
            const SizedBox(width: 6),
            Text(label, style: theme.bodySmall),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLiveMode(bool enabled) async {
    if (!mounted) return;

    setState(() {
      _isLiveMode = enabled;
      _isPaused = false;
      _isListening = false;
      _isThinking = false;
      if (!enabled) {
        _isUsingLiveKitFallback = false;
        _lastLiveKitFallbackReason = null;
      }
    });

    if (!enabled) {
      await _speechToText.stop();
      await _livekitService.endSession();
      return;
    }

    _isUsingLiveKitFallback = false;
    _lastLiveKitFallbackReason = null;
    await _ensureConnected();
  }

  Future<void> _onMicPressed() async {
    final granted = await _permissionService.requestMicrophoneWithRetry();
    if (!granted) {
      _showSnack('Microphone permission is required.');
      return;
    }

    if (_isLiveMode && !_isUsingLiveKitFallback) {
      final connected = await _ensureConnected();
      if (!connected) {
        if (!_isUsingLiveKitFallback) {
          _showSnack('Voice service is unavailable.');
        }
        return;
      }

      try {
        if (_livekitService.isMicrophoneEnabled) {
          await _livekitService.setMicrophoneEnabled(false);
          if (mounted) {
            setState(() {
              _isListening = false;
              _isPaused = false;
            });
          }
        } else {
          await _livekitService.setMicrophoneEnabled(true);
          if (mounted) {
            setState(() {
              _isListening = true;
              _isPaused = false;
            });
          }
        }
      } catch (e) {
        _showSnack('Microphone toggle failed. Please try again.');
      }
      return;
    }

    if (_isListening) {
      await _stopLocalListening();
      return;
    }

    if (!_speechReady) {
      _showSnack('Speech recognition is unavailable.');
      return;
    }

    setState(() {
      _isListening = true;
      _voiceState = GeminiLiveServiceState.listening;
    });

    await _speechToText.listen(
      onResult: (result) async {
        if (!result.finalResult) return;
        final transcript = result.recognizedWords.trim();
        await _stopLocalListening();
        if (transcript.isEmpty) {
          _showSnack('No speech captured.');
          return;
        }
        await _handleFallbackTranscript(transcript);
      },
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        partialResults: false,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopLocalListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {
      // Ignore stop failures.
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _voiceState = GeminiLiveServiceState.connected;
      });
    }
  }

  Future<void> _handleFallbackTranscript(String transcript) async {
    _upsertTurn(
      _VoiceTurn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: transcript,
        isUser: true,
        time: DateTime.now(),
        isTranscript: true,
        metadata: <String, dynamic>{
          'voiceEngine': 'fallback_local',
          'isTranscript': true,
        },
      ),
    );

    setState(() {
      _isThinking = true;
      _voiceState = GeminiLiveServiceState.thinking;
    });

    try {
      final aiText = await _generateLocalTextResponse(transcript);
      _upsertTurn(
        _VoiceTurn(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: aiText,
          isUser: false,
          time: DateTime.now(),
          metadata: <String, dynamic>{
            'voiceEngine': 'fallback_local',
            'isTranscript': false,
          },
        ),
      );

      setState(() {
        _voiceState = GeminiLiveServiceState.speaking;
      });

      await _cartesiaService.speakText(
        text: aiText,
        voiceId: JustTalkLiveKitConfig.defaultCartesiaVoiceId,
        contentType: 'coaching',
        varkPreferences: _varkPreferences,
      );

      if (mounted) {
        setState(() {
          _voiceState = GeminiLiveServiceState.connected;
        });
      }
    } catch (e) {
      _showSnack('Fallback response failed: $e');
      setState(() {
        _voiceState = GeminiLiveServiceState.error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isThinking = false;
        });
      }
    }
  }

  Future<String> _generateLocalTextResponse(String input) async {
    final response = await _aiClient.generateConversationResponse(
      userId: currentUserUid.isNotEmpty ? currentUserUid : 'anonymous',
      conversationId:
          _sessionId ?? 'just_talk_${DateTime.now().millisecondsSinceEpoch}',
      userMessage: input,
      conversationHistory: _turns
          .map((turn) => {
                'role': turn.isUser ? 'user' : 'assistant',
                'content': turn.text,
              })
          .toList(growable: false),
      context: _justTalkContext(),
    );

    return response.response.trim();
  }

  Future<void> _playTurn(_VoiceTurn turn) async {
    final text = turn.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      await _cartesiaService.speakText(
        text: text,
        voiceId: JustTalkLiveKitConfig.defaultCartesiaVoiceId,
        contentType: 'coaching',
        varkPreferences: _varkPreferences,
      );
    } catch (e) {
      _showSnack('Playback failed: $e');
    }
  }

  String _justTalkContext() {
    final unitsLine = _unitsAiContextLine;
    return '''
JustTalk live conversation mode:
- Keep responses concise and spoken-language friendly.
- Prioritize practical coaching steps and clear phrasing.
- Avoid long tables and dense formatting.
- Stay within 2-4 short sentences when possible.
${unitsLine.isEmpty ? '' : '\n$unitsLine'}
''';
  }

  Future<bool> _ensureConnected() async {
    if (!_isLiveMode || _isUsingLiveKitFallback) {
      return false;
    }

    if (_connectionState == LiveKitConnectionState.connected &&
        _livekitService.isConnected) {
      return true;
    }

    setState(() => _isBusy = true);
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final uid = currentUserUid.isNotEmpty ? currentUserUid : 'anon';
      final roomName = 'justtalk_${uid}_$nowMs';
      final participantIdentity =
          currentUserUid.isNotEmpty ? currentUserUid : 'anonymous_$nowMs';
      final participantName = currentUserDisplayName.isNotEmpty
          ? currentUserDisplayName
          : (currentUserEmail.isNotEmpty ? currentUserEmail : 'Golfer');

      await _livekitService.startSession(
        roomName: roomName,
        participantName: participantName,
        participantIdentity: participantIdentity,
        agentMetadata: _buildAgentMetadata(),
        participantAttributes: _buildParticipantAttributes(),
      );

      if (mounted) {
        setState(() {
          _connectionState = LiveKitConnectionState.connected;
          _voiceState = GeminiLiveServiceState.connected;
          _isUsingLiveKitFallback = false;
          _lastLiveKitFallbackReason = null;
        });
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('JustTalk LiveKit connect failed: $e');
      }

      if (JustTalkLiveKitConfig.fallbackEnabled) {
        await _activateLiveKitFallback('Voice service unavailable');
      } else if (mounted) {
        setState(() {
          _connectionState = LiveKitConnectionState.disconnected;
          _voiceState = GeminiLiveServiceState.error;
        });
      }

      return false;
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _buildAgentMetadata() {
    final int start = _turns.length > 8 ? _turns.length - 8 : 0;
    final recentTurns = _turns
        .sublist(start)
        .map((turn) => <String, dynamic>{
              'role': turn.isUser ? 'user' : 'assistant',
              'text': turn.text,
            })
        .toList(growable: false);

    return jsonEncode(<String, dynamic>{
      'surface': 'just_talk',
      'voice_id': JustTalkLiveKitConfig.defaultCartesiaVoiceId,
      'deep_thinking': false,
      'vark': _varkPreferences.toMap(),
      'fallback_enabled': JustTalkLiveKitConfig.fallbackEnabled,
      'recent_turns': recentTurns,
    });
  }

  Map<String, String> _buildParticipantAttributes() {
    return <String, String>{
      'surface': 'just_talk',
      'voice_id': JustTalkLiveKitConfig.defaultCartesiaVoiceId,
      'fallback_enabled': JustTalkLiveKitConfig.fallbackEnabled.toString(),
      'vark_aural': (_varkPreferences.aural).toString(),
    };
  }

  Future<void> _activateLiveKitFallback(String reason) async {
    if (!JustTalkLiveKitConfig.fallbackEnabled) {
      return;
    }

    if (_isUsingLiveKitFallback && _lastLiveKitFallbackReason == reason) {
      return;
    }

    await _livekitService.endSession();

    if (mounted) {
      setState(() {
        _isUsingLiveKitFallback = true;
        _lastLiveKitFallbackReason = reason;
        _isListening = false;
        _isPaused = false;
        _connectionState = LiveKitConnectionState.disconnected;
        _voiceState = GeminiLiveServiceState.connected;
      });
    }

    _showSnack('Switched to local voice mode.');
  }

  Future<void> _togglePause() async {
    setState(() => _isBusy = true);
    try {
      if (_isLiveMode && !_isUsingLiveKitFallback) {
        if (_isPaused) {
          await _livekitService.resume();
        } else {
          await _livekitService.pause();
        }
      } else {
        if (_isListening) {
          await _stopLocalListening();
        }
      }

      if (mounted) {
        setState(() => _isPaused = !_isPaused);
      }
    } catch (e) {
      _showSnack('Pause/Resume failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _stopAll() async {
    setState(() => _isBusy = true);
    try {
      await _speechToText.stop();
      if (_isLiveMode && !_isUsingLiveKitFallback) {
        await _livekitService.stop();
      }

      if (mounted) {
        setState(() {
          _isListening = false;
          _isPaused = false;
          _isThinking = false;
          _voiceState = GeminiLiveServiceState.connected;
        });
      }
    } catch (e) {
      _showSnack('Stop failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _restartSession() async {
    setState(() => _isBusy = true);
    try {
      await _speechToText.stop();

      if (_isLiveMode && !_isUsingLiveKitFallback) {
        await _livekitService.restart();
      } else if (_isLiveMode && _isUsingLiveKitFallback) {
        _isUsingLiveKitFallback = false;
        _lastLiveKitFallbackReason = null;
        await _ensureConnected();
      }

      if (mounted) {
        setState(() {
          _isListening = false;
          _isPaused = false;
          _isThinking = false;
          if (_connectionState == LiveKitConnectionState.connected) {
            _voiceState = GeminiLiveServiceState.connected;
          }
        });
      }
    } catch (e) {
      _showSnack('Restart failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _handleLiveKitMessage(JustTalkLiveKitMessageEvent event) {
    if (!mounted) {
      return;
    }

    final text = event.content.trim();
    if (text.isEmpty) {
      return;
    }

    _upsertTurn(
      _VoiceTurn(
        id: event.id,
        text: text,
        isUser: event.isUser,
        time: event.timestamp,
        isTranscript: event.isTranscript,
        metadata: <String, dynamic>{
          'voiceEngine': 'livekit_agent',
          'isTranscript': event.isTranscript,
          ...event.metadata,
        },
      ),
    );

    if (!event.isUser) {
      setState(() {
        _isThinking = false;
      });
    }
  }

  void _upsertTurn(_VoiceTurn turn) {
    final index = _turns.indexWhere((existing) => existing.id == turn.id);

    setState(() {
      if (index == -1) {
        _turns.add(turn);
      } else {
        _turns[index] = turn;
      }
    });

    _scheduleTurnSave(turn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 40,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _scheduleTurnSave(_VoiceTurn turn) {
    if (_sessionId == null || currentUserUid.isEmpty) {
      return;
    }

    final shouldDebounce = turn.isTranscript ||
        turn.metadata['isTranscript'] == true ||
        turn.metadata['voiceEngine'] == 'livekit_agent';

    if (!shouldDebounce) {
      unawaited(_persistTurn(turn));
      return;
    }

    _messageSaveDebounceTimers[turn.id]?.cancel();
    _messageSaveDebounceTimers[turn.id] = Timer(
      const Duration(milliseconds: 1200),
      () {
        _messageSaveDebounceTimers.remove(turn.id);
        unawaited(_persistTurn(turn));
      },
    );
  }

  Future<void> _persistTurn(_VoiceTurn turn) async {
    if (_sessionId == null || currentUserUid.isEmpty) {
      return;
    }

    try {
      final metadata = <String, dynamic>{
        'voiceEngine': turn.metadata['voiceEngine'] ??
            (_isUsingLiveKitFallback ? 'fallback_local' : 'livekit_agent'),
        'isTranscript': turn.isTranscript,
        'livekitState': _voiceState.name,
        if (_lastLiveKitFallbackReason != null)
          'fallbackReason': _lastLiveKitFallbackReason,
        ...turn.metadata,
      };

      final messageType = turn.isTranscript
          ? (turn.isUser ? 'user_transcript' : 'agent_transcript')
          : (turn.isUser ? 'text' : 'ai_response');

      final dbMessage = VoiceChatMessage(
        id: turn.id,
        userId: currentUserUid,
        sessionId: _sessionId!,
        content: turn.text,
        isUser: turn.isUser,
        timestamp: turn.time,
        messageType: messageType,
        metadata: metadata,
      );

      await _databaseService.saveMessage(dbMessage);
    } catch (e) {
      if (kDebugMode) {
        print('JustTalk persist failed (${turn.id}): $e');
      }
    }
  }

  GeminiLiveServiceState _mapLiveKitMode(VoiceModeState state) {
    switch (state) {
      case VoiceModeState.listening:
        return GeminiLiveServiceState.listening;
      case VoiceModeState.speaking:
        return GeminiLiveServiceState.speaking;
      case VoiceModeState.thinking:
        return GeminiLiveServiceState.thinking;
      case VoiceModeState.error:
      case VoiceModeState.fallbackRequired:
        return GeminiLiveServiceState.error;
      case VoiceModeState.assistant:
      case VoiceModeState.ready:
      case VoiceModeState.paused:
        return GeminiLiveServiceState.connected;
    }
  }

  Color _statusColor(FlutterFlowTheme theme) {
    if (_isUsingLiveKitFallback) {
      return theme.warning;
    }

    if (_isLiveMode && _connectionState != LiveKitConnectionState.connected) {
      return theme.error;
    }

    switch (_voiceState) {
      case GeminiLiveServiceState.listening:
        return theme.success;
      case GeminiLiveServiceState.thinking:
        return theme.warning;
      case GeminiLiveServiceState.speaking:
        return theme.primary;
      case GeminiLiveServiceState.error:
        return theme.error;
      default:
        return theme.secondary;
    }
  }

  IconData _statusIcon() {
    if (_isUsingLiveKitFallback) {
      return Icons.swap_horiz_rounded;
    }

    if (_isLiveMode && _connectionState != LiveKitConnectionState.connected) {
      return Icons.link_off_rounded;
    }

    switch (_voiceState) {
      case GeminiLiveServiceState.listening:
        return Icons.hearing_rounded;
      case GeminiLiveServiceState.thinking:
        return Icons.psychology_alt_rounded;
      case GeminiLiveServiceState.speaking:
        return Icons.volume_up_rounded;
      case GeminiLiveServiceState.error:
        return Icons.error_outline_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  String _statusText() {
    if (_isUsingLiveKitFallback) {
      return 'Voice mode active (local).';
    }

    if (_isLiveMode && _connectionState != LiveKitConnectionState.connected) {
      return 'Connecting voice service...';
    }

    switch (_voiceState) {
      case GeminiLiveServiceState.listening:
        return 'Listening...';
      case GeminiLiveServiceState.thinking:
        return 'Thinking...';
      case GeminiLiveServiceState.speaking:
        return 'Speaking...';
      case GeminiLiveServiceState.error:
        return 'Voice service error. Try again.';
      default:
        return _isLiveMode
            ? 'Ready. Tap mic to start talking.'
            : 'Local mode. Tap mic to start.';
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
