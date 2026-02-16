import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/ai_integration/gemini_ai_client.dart';
import '/ai_integration/services/voice_chat_database_service.dart';
import '/pages/just_talk/just_talk_widget.dart';

import 'golfchat_model.dart';

export 'golfchat_model.dart';

class GolfChatWidget extends StatefulWidget {
  const GolfChatWidget({super.key});

  static const String routeName = 'golf_chat';
  static const String routePath = '/golf_chat';

  @override
  State<GolfChatWidget> createState() => _GolfChatWidgetState();
}

class _GolfChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;

  const _GolfChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class _GolfChatWidgetState extends State<GolfChatWidget> {
  late GolfChatModel _model;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final VoiceChatDatabaseService _db = VoiceChatDatabaseService();
  final GeminiAIClient _aiClient = GeminiAIClient(apiKey: '');

  bool _isLoading = true;
  bool _isSending = false;
  bool _showBoundary = false;

  String? _sessionId;
  final List<_GolfChatMessage> _messages = <_GolfChatMessage>[];

  static const String _boundaryCopy =
      'GolfChat is for reflection, not in-round coaching.';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GolfChatModel());
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _db.initialize();
      await _loadBoundaryFlag();
      await _ensureSession();
    } catch (e) {
      if (mounted) {
        _showSnack('GolfChat setup failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBoundaryFlag() async {
    if (currentUserUid.isEmpty) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance.doc('user/$currentUserUid').get();
      final data = userDoc.data();
      final uxFlags = data?['uxFlags'] as Map<String, dynamic>?;
      final shown = uxFlags?['golfChatBoundaryShownAt'];

      if (shown == null) {
        _showBoundary = true;
        await FirebaseFirestore.instance.doc('user/$currentUserUid').set({
          'uxFlags': {
            'golfChatBoundaryShownAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Non-blocking: if boundary write fails, still let user chat.
      _showBoundary = true;
    }
  }

  Future<void> _ensureSession() async {
    if (currentUserUid.isEmpty) return;

    VoiceChatSession? session;
    try {
      session = await _db.getActiveSession();
      if (session != null && session.sessionMetadata['surface'] != 'golfchat') {
        session = null;
      }
    } catch (_) {
      session = null;
    }

    if (session == null) {
      session = await _db.startSession(
        title: 'GolfChat Reflection',
        metadata: <String, dynamic>{
          'surface': 'golfchat',
          'tone': 'calm_reflection',
        },
      );
    }

    _sessionId = session.id;

    try {
      final savedMessages =
          await _db.getSessionMessages(sessionId: session.id, limit: 200);
      _messages
        ..clear()
        ..addAll(savedMessages.map((msg) => _GolfChatMessage(
              id: msg.id,
              text: msg.content,
              isUser: msg.isUser,
              time: msg.timestamp,
            )));
    } catch (_) {
      // If loading history fails, keep this session empty.
    }

    if (mounted) setState(() {});
    _scrollToBottom();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            if (_showBoundary) _buildBoundary(theme),
            Expanded(child: _buildConversation(theme)),
            _buildInput(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GolfChat',
                  style: theme.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  'Reflect • Understand • Reset',
                  style: theme.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundary(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFFFC107), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _boundaryCopy,
              style: theme.bodySmall.copyWith(
                color: const Color(0xFFFFF3CD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversation(FlutterFlowTheme theme) {
    if (_messages.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment:
                msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: msg.isUser
                    ? const Color(0xFF2055C8)
                    : Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: msg.isUser
                      ? const Color(0xFF2D6BFF)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                msg.text,
                style: theme.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    final openers = const <String>[
      'What stood out today?',
      'Where did I lose momentum?',
      'What felt different today?',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_rounded,
              size: 44,
              color: Colors.white.withValues(alpha: 0.72),
            ),
            const SizedBox(height: 14),
            Text(
              'Talk it through calmly.',
              style: theme.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            ...openers.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: theme.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141A24),
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: theme.bodyMedium.copyWith(color: Colors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Share what happened...',
                hintStyle: theme.bodySmall.copyWith(color: Colors.white54),
                fillColor: Colors.white.withValues(alpha: 0.06),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _openJustTalkBottomSheet,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
            icon: const Icon(Icons.mic_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF2D6BFF),
            ),
            icon: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    final userMsg = _GolfChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _showBoundary = false;
    });

    _scrollToBottom();

    try {
      await _persistMessage(userMsg);

      final response = await _aiClient.generateConversationResponse(
        userId: currentUserUid,
        conversationId:
            _sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userMessage: text,
        conversationHistory: _messages
            .map((msg) => {
                  'role': msg.isUser ? 'user' : 'assistant',
                  'content': msg.text,
                })
            .toList(growable: false),
        context: _reflectionContext(),
      );

      final aiMsg = _GolfChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: response.response,
        isUser: false,
        time: DateTime.now(),
      );

      setState(() => _messages.add(aiMsg));
      _scrollToBottom();
      await _persistMessage(aiMsg);
    } catch (e) {
      _showSnack('Failed to send message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _reflectionContext() {
    return '''
GolfChat reflection mode:
- Calm, clear, non-judgmental tone.
- Help user reflect on what happened, not shot-by-shot live coaching.
- No medical or therapeutic framing.
- No tables, maps, charts, score breakdowns, or structured analytics lists.
- Keep responses in short natural paragraphs.
- If deep analysis is needed, suggest exploring in the WebApp.
''';
  }

  Future<void> _persistMessage(_GolfChatMessage message) async {
    final sessionId = _sessionId;
    if (sessionId == null || currentUserUid.isEmpty) return;

    await _db.saveMessage(
      VoiceChatMessage(
        id: message.id,
        userId: currentUserUid,
        sessionId: sessionId,
        content: message.text,
        isUser: message.isUser,
        timestamp: message.time,
        messageType: 'text',
        isSystem: false,
      ),
    );
  }

  void _openJustTalkBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const JustTalkWidget(),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
