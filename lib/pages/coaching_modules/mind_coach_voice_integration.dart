import 'package:flutter/material.dart';
import '/services/mind_coach_voice_service.dart';
import '/pages/coaching_modules/mind_coach_voice_session_widget.dart';
import '/ai_integration/services/gemini_live_agent_service.dart';

/// Integration helper for MindCoach Voice-First Sessions
/// Provides easy methods to trigger voice sessions from anywhere in the app
class MindCoachVoiceIntegration {
  static final MindCoachVoiceService _voiceService = MindCoachVoiceService();

  /// Show voice-first session widget
  /// Use this for manual voice session triggers
  static Future<void> showVoiceSession({
    required BuildContext context,
    required String templateId,
    required String templateName,
    required String coachingText,
    int durationEstimate = 60,
    MindCoachAgentConfig? config,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MindCoachVoiceSessionWidget(
          templateId: templateId,
          templateName: templateName,
          coachingText: coachingText,
          durationEstimate: durationEstimate,
          config: config,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Auto-trigger voice session based on context
  /// Returns true if session was triggered, false otherwise
  static Future<bool> autoTriggerVoiceSession({
    required BuildContext context,
    String? userVoiceInput,
    int? currentMindsetRating,
    Map<String, dynamic>? sessionContext,
  }) async {
    final config = await _voiceService.autoTriggerSession(
      userVoiceInput: userVoiceInput,
      currentMindsetRating: currentMindsetRating,
      context: sessionContext,
    );

    if (config == null) {
      return false;
    }

    await showVoiceSession(
      context: context,
      templateId: config.templateId,
      templateName: config.templateName,
      coachingText: config.coachingText,
      durationEstimate: config.durationEstimate,
      config: config.config,
    );

    return true;
  }

  /// Set active round for context awareness
  static void setActiveRound(String? roundId) {
    _voiceService.setActiveRound(roundId);
  }

  /// Set user context manually
  static void setContext(UserContext context) {
    _voiceService.setContext(context);
  }

  /// Get current context
  static UserContext get currentContext => _voiceService.currentContext;

  /// Get active round ID
  static String? get activeRoundId => _voiceService.activeRoundId;
}
