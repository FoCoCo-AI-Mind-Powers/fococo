/// Voice Coach Overlay Widget
/// Full-screen overlay for voice coaching sessions with transcript and controls

import 'package:flutter/material.dart';

import '/services/voice_coach_service.dart';
import '/models/voice_session_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Voice Coach Overlay Widget
class VoiceCoachOverlay extends StatefulWidget {
  const VoiceCoachOverlay({super.key});

  @override
  State<VoiceCoachOverlay> createState() => _VoiceCoachOverlayState();
}

class _VoiceCoachOverlayState extends State<VoiceCoachOverlay> {
  final ScrollController _transcriptScrollController = ScrollController();

  @override
  void dispose() {
    _transcriptScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VoiceCoachService(),
      builder: (context, _) {
        final voiceService = VoiceCoachService();
        final isActive = voiceService.isSessionActive;

        if (!isActive) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Main overlay background (semi-transparent)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // Transcript overlay (top)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: SafeArea(
                child: TranscriptOverlay(
                  scrollController: _transcriptScrollController,
                ),
              ),
            ),

            // Session stats (top left)
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: SessionStats(),
              ),
            ),

            // Voice control panel (bottom center)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SafeArea(
                child: VoiceControlPanel(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Transcript Overlay Widget
class TranscriptOverlay extends StatefulWidget {
  final ScrollController scrollController;

  const TranscriptOverlay({
    super.key,
    required this.scrollController,
  });

  @override
  State<TranscriptOverlay> createState() => _TranscriptOverlayState();
}

class _TranscriptOverlayState extends State<TranscriptOverlay> {
  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceCoachService();
    final interactions = voiceService.interactions;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice Transcript',
            style: FlutterFlowTheme.of(context).titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: interactions.length,
              itemBuilder: (context, index) {
                final interaction = interactions[index];
                return _buildTranscriptItem(interaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptItem(VoiceInteraction interaction) {
    final isUser = interaction.speaker == 'user';
    final color = isUser
        ? FlutterFlowTheme.of(context).primary
        : FlutterFlowTheme.of(context).tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUser ? Icons.person : Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? 'You' : 'AI Coach',
                  style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                if (interaction.text != null)
                  Text(
                    interaction.text!,
                    style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Session Stats Widget
class SessionStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceCoachService();
    final session = voiceService.currentSession;
    
    if (session == null) {
      return const SizedBox.shrink();
    }

    final duration = session.duration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: FlutterFlowTheme.of(context).primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: FlutterFlowTheme.of(context).titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.message,
            color: FlutterFlowTheme.of(context).tertiary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${session.interactions.length}',
            style: FlutterFlowTheme.of(context).titleMedium.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}

/// Voice Control Panel Widget
class VoiceControlPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceCoachService();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // End Session Button
          ElevatedButton.icon(
            onPressed: () async {
              await voiceService.stopVoiceCoaching();
              if (context.mounted) {
                Navigator.of(context).pop(); // Close overlay if needed
              }
            },
            icon: const Icon(Icons.stop_circle),
            label: const Text('End Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}