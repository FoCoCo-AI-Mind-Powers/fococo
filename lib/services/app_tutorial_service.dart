import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Comprehensive Tutorial Service for FoCoCo App
/// Provides interactive tutorials and onboarding for all app features
class AppTutorialService {
  static final AppTutorialService _instance = AppTutorialService._internal();
  factory AppTutorialService() => _instance;
  AppTutorialService._internal();

  TutorialCoachMark? _tutorialCoachMark;
  List<TargetFocus> _targets = [];

  // Tutorial completion tracking keys
  static const String _dashboardTutorialKey = 'dashboard_tutorial_completed';
  static const String _golfRoundsTutorialKey = 'golf_rounds_tutorial_completed';
  static const String _aiInsightsTutorialKey = 'ai_insights_tutorial_completed';
  static const String _coachingModulesTutorialKey =
      'coaching_modules_tutorial_completed';
  static const String _progressTutorialKey = 'progress_tutorial_completed';
  static const String _achievementsTutorialKey =
      'achievements_tutorial_completed';
  static const String _profileTutorialKey = 'profile_tutorial_completed';
  static const String _settingsTutorialKey = 'settings_tutorial_completed';
  static const String _subscriptionTutorialKey =
      'subscription_tutorial_completed';
  static const String _varkTutorialKey = 'vark_tutorial_completed';

  /// Check if a specific tutorial has been completed
  Future<bool> hasCompletedTutorial(String tutorialKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(tutorialKey) ?? false;
  }

  /// Mark a specific tutorial as completed
  Future<void> markTutorialCompleted(String tutorialKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tutorialKey, true);
  }

  /// Reset all tutorials (useful for testing or user request)
  Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dashboardTutorialKey, false);
    await prefs.setBool(_golfRoundsTutorialKey, false);
    await prefs.setBool(_aiInsightsTutorialKey, false);
    await prefs.setBool(_coachingModulesTutorialKey, false);
    await prefs.setBool(_progressTutorialKey, false);
    await prefs.setBool(_achievementsTutorialKey, false);
    await prefs.setBool(_profileTutorialKey, false);
    await prefs.setBool(_settingsTutorialKey, false);
    await prefs.setBool(_subscriptionTutorialKey, false);
    await prefs.setBool(_varkTutorialKey, false);
  }

  /// Dashboard Tutorial
  Future<void> startDashboardTutorial(
    BuildContext context, {
    required GlobalKey pillarCardsKey,
    required GlobalKey quickActionsKey,
    required GlobalKey statsKey,
    required GlobalKey aiCoachKey,
    required GlobalKey recentActivityKey,
  }) async {
    if (await hasCompletedTutorial(_dashboardTutorialKey)) return;

    _targets.clear();

    // Welcome to Dashboard
    _targets.add(
      TargetFocus(
        identify: "dashboard_welcome",
        keyTarget: pillarCardsKey,
        alignSkip: Alignment.bottomRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Welcome to Your Dashboard! 🎯',
              description:
                  'This is your mental performance command center. Track your Focus, Confidence, and Control pillars here.',
              primaryButtonText: 'Next',
              onPrimary: controller.next,
              icon: Icons.dashboard,
              color: const Color(0xFF00FF88),
            ),
          ),
        ],
      ),
    );

    // Quick Actions
    _targets.add(
      TargetFocus(
        identify: "quick_actions",
        keyTarget: quickActionsKey,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Quick Actions ⚡',
              description:
                  'Access your most-used features instantly. Log rounds, get AI insights, or start coaching sessions with one tap.',
              primaryButtonText: 'Got it',
              onPrimary: controller.next,
              icon: Icons.flash_on,
              color: const Color(0xFFFFB800),
            ),
          ),
        ],
      ),
    );

    // AI Coach
    _targets.add(
      TargetFocus(
        identify: "ai_coach",
        keyTarget: aiCoachKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Your AI Coach 🤖',
              description:
                  'Get personalized insights and recommendations based on your performance data. Tap to chat with your AI coach anytime.',
              primaryButtonText: 'Continue',
              onPrimary: controller.next,
              icon: Icons.psychology,
              color: const Color(0xFF00AAFF),
            ),
          ),
        ],
      ),
    );

    _showTutorial(context, _dashboardTutorialKey);
  }

  /// Golf Rounds Tutorial
  Future<void> startGolfRoundsTutorial(
    BuildContext context, {
    required GlobalKey roundsListKey,
    required GlobalKey addRoundKey,
    required GlobalKey filterKey,
    required GlobalKey statsKey,
  }) async {
    if (await hasCompletedTutorial(_golfRoundsTutorialKey)) return;

    _targets.clear();

    // Rounds List
    _targets.add(
      TargetFocus(
        identify: "rounds_list",
        keyTarget: roundsListKey,
        alignSkip: Alignment.bottomRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Your Golf Rounds 🏌️',
              description:
                  'View all your logged rounds here. Each card shows your mental performance scores and key stats.',
              primaryButtonText: 'Next',
              onPrimary: controller.next,
              icon: Icons.golf_course,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );

    // Add Round Button
    _targets.add(
      TargetFocus(
        identify: "add_round",
        keyTarget: addRoundKey,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Log New Round ➕',
              description:
                  'Tap here to log a new round. You can use voice input or manual entry to capture your mental state and performance.',
              primaryButtonText: 'Got it',
              onPrimary: controller.next,
              icon: Icons.add_circle,
              color: const Color(0xFF00FF88),
            ),
          ),
        ],
      ),
    );

    _showTutorial(context, _golfRoundsTutorialKey);
  }

  /// AI Insights Tutorial
  Future<void> startAIInsightsTutorial(
    BuildContext context, {
    required GlobalKey chatAreaKey,
    required GlobalKey suggestionsKey,
    required GlobalKey voiceInputKey,
    required GlobalKey insightTypesKey,
  }) async {
    if (await hasCompletedTutorial(_aiInsightsTutorialKey)) return;

    _targets.clear();

    // Chat Area
    _targets.add(
      TargetFocus(
        identify: "chat_area",
        keyTarget: chatAreaKey,
        alignSkip: Alignment.bottomRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'AI Conversation 💬',
              description:
                  'Chat naturally with your AI coach. Ask questions about your game, get personalized tips, or discuss mental strategies.',
              primaryButtonText: 'Next',
              onPrimary: controller.next,
              icon: Icons.chat,
              color: const Color(0xFF00AAFF),
            ),
          ),
        ],
      ),
    );

    // Voice Input
    _targets.add(
      TargetFocus(
        identify: "voice_input",
        keyTarget: voiceInputKey,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Voice Input 🎤',
              description:
                  'Tap to speak your thoughts. Perfect for quick insights during or after your round.',
              primaryButtonText: 'Continue',
              onPrimary: controller.next,
              icon: Icons.mic,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );

    _showTutorial(context, _aiInsightsTutorialKey);
  }

  /// Coaching Modules Tutorial
  Future<void> startCoachingModulesTutorial(
    BuildContext context, {
    required GlobalKey modulesGridKey,
    required GlobalKey filterPillarsKey,
    required GlobalKey progressTrackerKey,
    required GlobalKey varkIndicatorKey,
  }) async {
    if (await hasCompletedTutorial(_coachingModulesTutorialKey)) return;

    _targets.clear();

    // Modules Grid
    _targets.add(
      TargetFocus(
        identify: "modules_grid",
        keyTarget: modulesGridKey,
        alignSkip: Alignment.bottomRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Coaching Library 📚',
              description:
                  'Explore modules tailored to your learning style. Each module focuses on specific mental skills for golf.',
              primaryButtonText: 'Next',
              onPrimary: controller.next,
              icon: Icons.library_books,
              color: const Color(0xFFFF00FF),
            ),
          ),
        ],
      ),
    );

    // VARK Indicator
    _targets.add(
      TargetFocus(
        identify: "vark_indicator",
        keyTarget: varkIndicatorKey,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Your Learning Style 🎯',
              description:
                  'Content is adapted to your VARK learning preference. Look for this indicator to find modules that match your style.',
              primaryButtonText: 'Got it',
              onPrimary: controller.next,
              icon: Icons.psychology,
              color: const Color(0xFFFFB800),
            ),
          ),
        ],
      ),
    );

    _showTutorial(context, _coachingModulesTutorialKey);
  }

  /// Progress Tutorial
  Future<void> startProgressTutorial(
    BuildContext context, {
    required GlobalKey chartsKey,
    required GlobalKey metricsKey,
    required GlobalKey milestonesKey,
    required GlobalKey exportKey,
  }) async {
    if (await hasCompletedTutorial(_progressTutorialKey)) return;

    _targets.clear();

    // Charts
    _targets.add(
      TargetFocus(
        identify: "progress_charts",
        keyTarget: chartsKey,
        alignSkip: Alignment.bottomRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Performance Trends 📈',
              description:
                  'Visualize your mental game improvement over time. Track patterns and identify areas for growth.',
              primaryButtonText: 'Next',
              onPrimary: controller.next,
              icon: Icons.trending_up,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );

    // Milestones
    _targets.add(
      TargetFocus(
        identify: "milestones",
        keyTarget: milestonesKey,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Milestones 🏆',
              description:
                  'Celebrate your achievements! Complete challenges and reach new levels in your mental game journey.',
              primaryButtonText: 'Continue',
              onPrimary: controller.next,
              icon: Icons.emoji_events,
              color: const Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );

    _showTutorial(context, _progressTutorialKey);
  }

  /// VARK Onboarding Tutorial
  Future<void> startVARKTutorial(
    BuildContext context, {
    required GlobalKey questionKey,
    required GlobalKey optionsKey,
    required GlobalKey progressKey,
  }) async {
    if (await hasCompletedTutorial(_varkTutorialKey)) return;

    _targets.clear();

    // VARK Introduction
    _targets.add(
      TargetFocus(
        identify: "vark_intro",
        keyTarget: questionKey,
        alignSkip: Alignment.bottomCenter,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialCard(
              context,
              title: 'Discover Your Learning Style 🧠',
              description:
                  'This quick assessment helps us personalize your coaching experience. Answer honestly - there are no wrong answers!',
              primaryButtonText: 'Start',
              onPrimary: controller.next,
              icon: Icons.school,
              color: const Color(0xFF00FF88),
            ),
          ),
        ],
      ),
    );

    _showTutorial(context, _varkTutorialKey);
  }

  /// Show tutorial with common configuration
  void _showTutorial(BuildContext context, String tutorialKey) {
    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withValues(alpha: 0.8),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.9,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () {
        markTutorialCompleted(tutorialKey);
      },
      onSkip: () {
        markTutorialCompleted(tutorialKey);
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  /// Build consistent tutorial card design
  Widget _buildTutorialCard(
    BuildContext context, {
    required String title,
    required String description,
    required String primaryButtonText,
    required VoidCallback onPrimary,
    IconData? icon,
    Color? color,
    String? secondaryButtonText,
    VoidCallback? onSecondary,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color?.withValues(alpha: 0.5) ??
              Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.white).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (color ?? Colors.white).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color ?? Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Inter',
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (secondaryButtonText != null && onSecondary != null) ...[
                TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondaryButtonText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      color ?? FlutterFlowTheme.of(context).primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show quick tooltip
  void showQuickTooltip(
    BuildContext context, {
    required GlobalKey targetKey,
    required String message,
    ContentAlign align = ContentAlign.bottom,
  }) {
    _targets.clear();
    _targets.add(
      TargetFocus(
        identify: "quick_tooltip",
        keyTarget: targetKey,
        contents: [
          TargetContent(
            align: align,
            builder: (context, controller) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.transparent,
      hideSkip: true,
      onFinish: () {},
    ).show(context: context);
  }

  /// Dispose of any active tutorials
  void dispose() {
    _tutorialCoachMark?.finish();
  }
}
