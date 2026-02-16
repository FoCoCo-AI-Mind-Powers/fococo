import 'package:flutter/foundation.dart';
import '/ai_integration/services/gemini_live_agent_service.dart';
import '/ai_integration/services/mind_coach_content_selector.dart';
import '/ai_integration/services/mind_coach_scenario_detector.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/user_record.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';

/// User context for voice sessions
enum UserContext {
  preRound,
  duringRound,
  postRound,
  offCourse,
}

/// MindCoach Voice Service
/// Orchestrates voice-first sessions with context detection and auto-triggering
class MindCoachVoiceService {
  static final MindCoachVoiceService _instance =
      MindCoachVoiceService._internal();
  factory MindCoachVoiceService() => _instance;
  MindCoachVoiceService._internal();

  final MindCoachContentSelector _contentSelector =
      MindCoachContentSelector.instance;
  final MindCoachScenarioDetector _scenarioDetector =
      MindCoachScenarioDetector.instance;

  // Context tracking
  String? _activeRoundId;
  UserContext _currentContext = UserContext.offCourse;
  DateTime? _lastSessionTime;

  // Auto-trigger settings
  static const Duration _minTimeBetweenSessions = Duration(minutes: 5);
  static const int _stressThreshold = 2; // Mindset rating <= 2

  /// Set active round for context awareness
  void setActiveRound(String? roundId) {
    _activeRoundId = roundId;
    if (roundId != null) {
      _currentContext = UserContext.duringRound;
    } else {
      _currentContext = UserContext.offCourse;
    }
    debugPrint('MindCoach Voice: Active round set: $roundId');
  }

  /// Set user context manually
  void setContext(UserContext context) {
    _currentContext = context;
    debugPrint('MindCoach Voice: Context set to: $context');
  }

  /// Detect if voice session should be auto-triggered
  Future<bool> shouldAutoTrigger({
    String? userVoiceInput,
    int? currentMindsetRating,
    Map<String, dynamic>? context,
  }) async {
    // Check time since last session
    if (_lastSessionTime != null) {
      final timeSinceLastSession =
          DateTime.now().difference(_lastSessionTime!);
      if (timeSinceLastSession < _minTimeBetweenSessions) {
        return false;
      }
    }

    // During round + stress detected
    if (_currentContext == UserContext.duringRound) {
      // Check mindset rating
      if (currentMindsetRating != null &&
          currentMindsetRating <= _stressThreshold) {
        return true;
      }

      // Check voice input for trigger phrases
      if (userVoiceInput != null) {
        final triggerPhrases = [
          "i'm rushed",
          "i need help",
          "i'm stressed",
          "i'm struggling",
          "help me",
          "reset",
        ];
        final lowerInput = userVoiceInput.toLowerCase();
        if (triggerPhrases.any((phrase) => lowerInput.contains(phrase))) {
          return true;
        }
      }
    }

    return false;
  }

  /// Auto-trigger voice session based on detected context
  Future<VoiceSessionConfig?> autoTriggerSession({
    String? userVoiceInput,
    int? currentMindsetRating,
    Map<String, dynamic>? context,
  }) async {
    if (!await shouldAutoTrigger(
      userVoiceInput: userVoiceInput,
      currentMindsetRating: currentMindsetRating,
      context: context,
    )) {
      return null;
    }

    // Detect scenarios
    final scenarioTags = await _scenarioDetector.detectScenarios(
      userMessage: userVoiceInput,
      context: context ?? {},
      mindsetRating: currentMindsetRating,
    );

    // Select appropriate template based on context
    final templateId = _selectTemplateForContext(
      context: context,
      scenarioTags: scenarioTags,
      mindsetRating: currentMindsetRating,
    );

    if (templateId == null) {
      return null;
    }

    // Get user VARK preferences
    final userId = currentUserUid;
    if (userId.isEmpty) {
      return null;
    }

    final userDoc = await UserRecord.collection.doc(userId).get();
    final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

    String determineVarkMode(VarkPreferencesStruct? prefs) {
      if (prefs == null) return 'Aural'; // Default for voice sessions
      if (prefs.aural) return 'Aural';
      if (prefs.visual) return 'Visual';
      if (prefs.readWrite) return 'ReadWrite';
      if (prefs.kinesthetic) return 'Kinesthetic';
      return 'Aural';
    }

    final varkMode = determineVarkMode(user?.varkPreferences);

    // Select content
    final content = await _contentSelector.selectContent(
      templateId: templateId,
      varkMode: varkMode,
      level: 'Foundation',
      length: 'standard',
      scenarioTags: scenarioTags.isNotEmpty ? scenarioTags : null,
    );

    if (content == null) {
      return null;
    }

    // Estimate duration (rough calculation: ~15 words per second)
    final wordCount = content.scriptText.split(' ').length;
    final durationEstimate = (wordCount / 15 * 60).round().clamp(30, 180);

    // Create agent config
    final agentConfig = MindCoachAgentConfig(
      templateId: templateId,
      scenarioTag: scenarioTags.isNotEmpty ? scenarioTags.first : null,
      varkMode: varkMode,
      level: 'Foundation',
      length: 'standard',
      context: {
        ...?context,
        'auto_triggered': true,
        'user_context': _currentContext.toString(),
        if (userVoiceInput != null) 'user_voice_input': userVoiceInput,
        if (currentMindsetRating != null)
          'mindset_rating': currentMindsetRating,
      },
    );

    _lastSessionTime = DateTime.now();

    return VoiceSessionConfig(
      templateId: templateId,
      templateName: _getTemplateName(templateId),
      coachingText: content.scriptText,
      durationEstimate: durationEstimate,
      config: agentConfig,
    );
  }

  /// Select template based on context and scenarios
  String? _selectTemplateForContext({
    Map<String, dynamic>? context,
    List<String>? scenarioTags,
    int? mindsetRating,
  }) {
    // Priority 1: Scenario-based selection
    if (scenarioTags != null && scenarioTags.isNotEmpty) {
      if (scenarioTags.contains('rushed') ||
          scenarioTags.contains('fast_group_behind')) {
        return 'MC_T03_POST_SHOT_RECOVERY'; // Reset/Recovery
      }
      if (scenarioTags.contains('high_pressure')) {
        return 'MC_T05_PRESSURE_MOMENT';
      }
      if (scenarioTags.contains('struggling')) {
        return 'MC_T07_EMOTIONAL_CONTROL';
      }
    }

    // Priority 2: Mindset-based selection
    if (mindsetRating != null && mindsetRating <= 2) {
      return 'MC_T03_POST_SHOT_RECOVERY'; // Recovery/Reset
    }

    // Priority 3: Context-based selection
    if (_currentContext == UserContext.duringRound) {
      // During round - default to recovery/reset
      return 'MC_T03_POST_SHOT_RECOVERY';
    }

    if (_currentContext == UserContext.preRound) {
      return 'MC_T01_PRE_ROUND_CLARITY';
    }

    // Default fallback
    return 'MC_T03_POST_SHOT_RECOVERY';
  }

  /// Get human-readable template name
  String _getTemplateName(String templateId) {
    final names = {
      'MC_T01_PRE_ROUND_CLARITY': 'Pre-Round Clarity',
      'MC_T02_PRE_SHOT_FOCUS': 'Pre-Shot Focus',
      'MC_T03_POST_SHOT_RECOVERY': 'Reset',
      'MC_T04_ROUND_MANAGEMENT': 'Round Management',
      'MC_T05_PRESSURE_MOMENT': 'Pressure Moment',
      'MC_T06_CONFIDENCE_BUILD': 'Confidence Build',
      'MC_T07_EMOTIONAL_CONTROL': 'Emotional Control',
      'MC_T08_POST_ROUND_REFLECT': 'Post-Round Reflection',
    };
    return names[templateId] ?? 'MindCoach Session';
  }

  /// Get current context
  UserContext get currentContext => _currentContext;

  /// Get active round ID
  String? get activeRoundId => _activeRoundId;
}

/// Configuration for voice session
class VoiceSessionConfig {
  final String templateId;
  final String templateName;
  final String coachingText;
  final int durationEstimate;
  final MindCoachAgentConfig config;

  VoiceSessionConfig({
    required this.templateId,
    required this.templateName,
    required this.coachingText,
    required this.durationEstimate,
    required this.config,
  });
}
