import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/ai_integration/services/ai_coaching_service.dart';
import '/ai_integration/models/gemini_models.dart';
import '/backend/backend.dart';
import '/backend/schema/coaching_modules_record.dart';
import '/backend/schema/mental_sessions_record.dart';
import '/backend/schema/training_plans_record.dart';
import '/backend/schema/mindcoach_sessions_record.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/app_tutorial_service.dart';
import '/services/training_plan_service.dart';
import '/services/training_streak_service.dart';
import '/services/mind_balance_service.dart';
import '/ai_integration/services/mind_coach_analysis_service.dart';
import '/ai_integration/models/mind_coach_models.dart';
import '/ai_integration/services/mind_coach_session_service.dart';
import '/ai_integration/services/mind_coach_content_selector.dart';
import '/ai_integration/services/mind_coach_scenario_detector.dart';
import '/ai_integration/services/gemini_interactions_service.dart';
import 'mind_coach_ai_session_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'mind_coach_model.dart';
export 'mind_coach_model.dart';

class MindCoachWidget extends StatefulWidget {
  const MindCoachWidget({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  static String routeName = 'mind_coach';
  static String routePath = '/mind_coach';

  @override
  State<MindCoachWidget> createState() => _MindCoachWidgetState();
}

class _MindCoachWidgetState extends State<MindCoachWidget>
    with TickerProviderStateMixin {
  late MindCoachModel _model;
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // late Animation<double> _pulseAnimation; // Removed unused animation

  final AppTutorialService _tutorialService = AppTutorialService();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Tutorial keys
  final GlobalKey _modulesGridKey = GlobalKey();
  final GlobalKey _filterPillarsKey = GlobalKey();
  final GlobalKey _progressTrackerKey = GlobalKey();
  final GlobalKey _varkIndicatorKey = GlobalKey();

  // AI Coaching Services
  final AICoachingService _aiCoachingService = AICoachingService.instance;
  final TrainingPlanService _trainingPlanService = TrainingPlanService();
  final TrainingStreakService _streakService = TrainingStreakService.instance;
  final MindBalanceService _balanceService = MindBalanceService.instance;
  final MindCoachAnalysisService _mindCoachAnalysis =
      MindCoachAnalysisService.instance;
  final MindCoachSessionService _sessionService =
      MindCoachSessionService.instance;
  final MindCoachContentSelector _contentSelector =
      MindCoachContentSelector.instance;
  final MindCoachScenarioDetector _scenarioDetector =
      MindCoachScenarioDetector.instance;
  bool _isLoadingAIRecommendations = false;
  String? _aiRecommendationError;

  // AI Generation Results
  bool _showGeneratedContent = false;
  String? _generatedContentTitle;
  String? _generatedContentText;
  bool _isGeneratingContent = false;

  // Current user's VARK preferences
  String _selectedVarkFilter = 'all';
  String _selectedPillar = 'all';
  String _selectedDifficulty = 'all';

  // Shared streams to avoid "Stream has already been listened to" errors
  Stream<UserRecord>? _userRecordStream;
  Stream<List<MentalSessionsRecord>>? _userSessionsStream;
  Stream<List<MindcoachSessionsRecord>>? _mindcoachSessionsStream;
  Stream<GeminiRecommendationResponse?>? _todayRecommendationStream;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MindCoachModel());
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex:
          widget.initialTabIndex.clamp(0, 3), // Ensure valid tab index
    );

    // Initialize animations - matching dashboard style
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    // _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
    //   CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    // );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);

    _loadAIRecommendations();

    // Initialize shared streams
    _initializeSharedStreams();

    // Ensure sample data exists
    _ensureSampleDataExists();

    // Check and show tutorial
    _checkAndShowTutorial();
  }

  /// Initialize shared streams to avoid duplicate subscriptions
  void _initializeSharedStreams() {
    if (currentUser != null) {
      // Create broadcast streams to avoid "Stream has already been listened to" errors
      _userRecordStream = UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/${currentUserUid}'))
          .asBroadcastStream();

      _userSessionsStream = _getUserSessionsStream().asBroadcastStream();

      // Initialize MindCoach sessions stream
      _mindcoachSessionsStream =
          _getMindcoachSessionsStream().asBroadcastStream();
    }
  }

  Future<void> _checkAndShowTutorial() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    _tutorialService.startCoachingModulesTutorial(
      context,
      modulesGridKey: _modulesGridKey,
      filterPillarsKey: _filterPillarsKey,
      progressTrackerKey: _progressTrackerKey,
      varkIndicatorKey: _varkIndicatorKey,
    );
  }

  /// Load AI-powered coaching recommendations
  Future<void> _loadAIRecommendations() async {
    if (currentUser == null) return;

    setState(() {
      _isLoadingAIRecommendations = true;
      _aiRecommendationError = null;
    });

    try {
      // First check if user profile exists
      final userDoc = await UserRecord.collection.doc(currentUser?.uid).get();

      if (!userDoc.exists) {
        // Create a basic user profile if it doesn't exist
        await _createBasicUserProfile();
      }

      await _aiCoachingService.generateCoachingRecommendations(
        userId: currentUser?.uid ?? '',
        includeWeeklyPlan: true,
      );

      if (mounted) {
        setState(() {
          _isLoadingAIRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAIRecommendations = false;
          _aiRecommendationError = e.toString();
        });
      }
    }
  }

  /// Create a basic user profile if it doesn't exist
  Future<void> _createBasicUserProfile() async {
    if (currentUser == null) return;

    try {
      await UserRecord.collection.doc(currentUser?.uid).set({
        'uid': currentUser?.uid,
        'email': currentUser?.email ?? '',
        'display_name': currentUser?.displayName ?? 'Golfer',
        'photo_url': '',
        'created_time': FieldValue.serverTimestamp(),
        'phone_number': currentUser?.phoneNumber ?? '',
        'handicap': 0.0,
        'golf_experience': 'beginner',
        'home_club': '',
        'current_membership_tier': 'FREE',
        'tokens_remaining': 100,
        'vark_preferences': {
          'visual': false,
          'aural': false,
          'read_write': false,
          'kinesthetic': false,
          'dominant_style': '',
          'is_multi_modal': false,
        },
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Created basic user profile for ${currentUser?.uid}');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _model.dispose();
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        drawer: currentUser != null && _userRecordStream != null
            ? StreamBuilder<UserRecord>(
                stream: _userRecordStream,
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  return FoCoCoDrawer(
                    currentUser: userData,
                    currentRoute: 'mind_coach',
                    onNavigate: (route) => context.goNamed(route),
                  );
                },
              )
            : null,
        body: Stack(
          children: [
            // Main content with glassmorphic design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryBackground,
                    theme.secondaryBackground.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Custom App Bar
                        _buildCustomAppBar(theme),

                        // Tab Bar
                        _buildTabBar(theme),

                        // Main Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 0: Studio Tab (NEW)
                              _buildStudioTab(theme),

                              // Tab 1: Learn Tab (renamed from Library)
                              _buildLearnTab(theme),

                              // Tab 2: Train Tab (renamed from Training)
                              _buildTrainTab(theme),

                              // Tab 3: Journey Tab (renamed from Progress)
                              _buildJourneyTab(theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'mind_coach',
          barBackgroundColor: theme.primaryBackground,
          onTap: (route) => context.goNamed(route),
          currentUser: null, // Will be handled by the navbar internally
        ),
      ),
    );
  }

  /// Custom App Bar matching dashboard design
  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: currentUser != null ? _userRecordStream : null,
      builder: (context, userSnapshot) {
        // final user = userSnapshot.data; // Removed unused variable

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Menu button
              GestureDetector(
                onTap: () => scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.glassBackground.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.glassBorder.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: theme.primaryText,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Page title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MindCoach',
                      style: theme.headlineSmall.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Where Focus, Confidence, and Control are built.',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // VARK filter button with FILTER text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.glassBackground.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.glassBorder.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => _showVarkFilterDialog(theme),
                      icon: Icon(
                        Icons.tune,
                        color: theme.primaryText,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FILTER',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab Bar with glassmorphic design
  Widget _buildTabBar(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors
                  .transparent, // No indicator, tabs handle their own background
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: theme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            unselectedLabelStyle: theme.bodyMedium.copyWith(
              fontWeight: FontWeight.w400,
            ),
            tabs: [
              _buildFilledTab(
                'Studio',
                Icons.dashboard,
                theme.aiPrimary,
                _tabController.index == 0,
              ),
              _buildFilledTab(
                'Learn',
                Icons.library_books,
                theme.info,
                _tabController.index == 1,
              ),
              _buildFilledTab(
                'Train',
                Icons.play_circle_filled,
                theme.success,
                _tabController.index == 2,
              ),
              _buildFilledTab(
                'Journey',
                Icons.trending_up,
                theme.warning,
                _tabController.index == 3,
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: theme.secondaryText,
          );
        },
      ),
    );
  }

  /// Build filled tab with background color
  Widget _buildFilledTab(
    String text,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Studio Tab (NEW Landing Page)
  Widget _buildStudioTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Section 1: Training Streak
          _buildTrainingStreakSection(theme),

          const SizedBox(height: 24),

          // Section 2: AI Insights
          _buildAIInsightsSection(theme),

          const SizedBox(height: 24),

          // Section 3: Your Mind in Balance
          _buildMindInBalanceSection(theme),

          const SizedBox(height: 24),

          // Section 4: Recent Training Sessions
          _buildRecentTrainingSessionsSection(theme),

          const SizedBox(height: 24),

          // Section 5: Recommended Next Steps
          _buildRecommendedNextStepsSection(theme),

          const SizedBox(height: 100), // Space for navbar
        ],
      ),
    );
  }

  /// Learn Tab (Renamed from Library)
  Widget _buildLearnTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Section 1: Your Learning Path
          _buildLearningPath(theme),

          const SizedBox(height: 24),

          // Section 2: Your Current Plan
          _buildCurrentPlan(theme),

          const SizedBox(height: 24),

          // Section 3: Recommended for Your Learning Style
          _buildVarkRecommendations(theme),

          const SizedBox(height: 24),

          // Section 4: Master the Three Performance Pillars
          _buildPerformancePillars(theme),

          const SizedBox(height: 100), // Space for navbar
        ],
      ),
    );
  }

  /// Build Learning Path section
  Widget _buildLearningPath(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Your Learning Path',
      subtitle: 'Personalized lessons based on performance & mindset trends',
      children: [
        StreamBuilder<List<CoachingModulesRecord>>(
          stream: _getFilteredModulesStream(),
          builder: (context, snapshot) {
            final modules = snapshot.data ?? [];

            // Get top modules for each pillar
            final focusModules =
                modules.where((m) => m.pillar == 'focus').take(1).toList();
            final confidenceModules =
                modules.where((m) => m.pillar == 'confidence').take(1).toList();
            final controlModules =
                modules.where((m) => m.pillar == 'control').take(1).toList();

            return Column(
              children: [
                if (focusModules.isNotEmpty)
                  _buildLearningPathCard(
                      theme, focusModules.first, 'Focus', theme.mentalFocus),
                if (confidenceModules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildLearningPathCard(theme, confidenceModules.first,
                      'Confidence', theme.mentalStrength),
                ],
                if (controlModules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildLearningPathCard(
                      theme, controlModules.first, 'Control', theme.mentalCalm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// Build learning path card
  Widget _buildLearningPathCard(
    FlutterFlowTheme theme,
    CoachingModulesRecord module,
    String pillar,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPillarIcon(pillar.toLowerCase()),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            module.title,
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'HIGH',
                            style: theme.bodySmall.copyWith(
                              color: theme.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI Summary: Perfect for ${pillar.toLowerCase()} development based on your recent progress',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startModuleSession(module),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.play_arrow, size: 16),
              label: Text('Start Learning'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Current Plan section
  Widget _buildCurrentPlan(FlutterFlowTheme theme) {
    if (!loggedIn) {
      return const SizedBox.shrink();
    }

    return GlassDashboardCard(
      title: 'Your Current Plan',
      subtitle: 'Structured lessons tailored to your progress',
      children: [
        StreamBuilder<TrainingPlansRecord?>(
          stream: _trainingPlanService.getCurrentPlanStream(currentUserUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                ),
              );
            }

            final plan = snapshot.data;

            if (plan == null) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: theme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active plan',
                      style: theme.titleMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate a personalized training plan to get started',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _generateNewPlan(theme),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.aiPrimary,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.auto_awesome, size: 18),
                      label: Text('Generate Plan'),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.success.withValues(alpha: 0.1),
                    theme.success.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.success.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: theme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.completedModules.length}/${plan.totalModules} modules completed',
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _refreshPlan(theme),
                        icon: Icon(
                          Icons.refresh,
                          color: theme.primary,
                          size: 20,
                        ),
                        tooltip: 'Refresh Plan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: plan.completedModules.length / plan.totalModules,
                    backgroundColor: theme.alternate.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.success),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _continuePlan(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(Icons.play_arrow, size: 20),
                      label: Text('Continue Plan'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build Performance Pillars section (updated from Coaching Pillars)
  Widget _buildPerformancePillars(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Master the Three Performance Pillars',
      subtitle: '',
      children: [
        Column(
          children: [
            _buildEnhancedPillarCard(
              theme,
              'Focus',
              Icons.center_focus_strong,
              theme.mentalFocus,
              'Deeper attention, clarity, pre-shot presence',
              [
                '• Pre-shot routines',
                '• Visualization techniques',
                '• Attention control drills',
              ],
            ),
            const SizedBox(height: 16),
            _buildEnhancedPillarCard(
              theme,
              'Confidence',
              Icons.psychology,
              theme.mentalStrength,
              'Trust, self-belief, preparation',
              [
                '• Positive self-talk',
                '• Success visualization',
                '• Achievement tracking',
              ],
            ),
            const SizedBox(height: 16),
            _buildEnhancedPillarCard(
              theme,
              'Control',
              Icons.self_improvement,
              theme.mentalCalm,
              'Recovery, emotional balance, pressure response',
              [
                '• Breathing exercises',
                '• Pressure management',
                '• Recovery techniques',
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Generate new training plan
  Future<void> _generateNewPlan(FlutterFlowTheme theme) async {
    try {
      // Check if user's email is verified
      final user = currentUser;
      if (user == null || !user.emailVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Please verify your email address to generate a training plan.'),
              backgroundColor: theme.error,
              action: SnackBarAction(
                label: 'Resend',
                textColor: Colors.white,
                onPressed: () {
                  // Resend verification email logic can be added here
                },
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoadingAIRecommendations = true;
      });

      await _trainingPlanService.generateNewPlan(
        userId: currentUserUid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Training plan generated successfully!'),
              ],
            ),
            backgroundColor: theme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating plan: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAIRecommendations = false;
        });
      }
    }
  }

  /// Refresh training plan
  Future<void> _refreshPlan(FlutterFlowTheme theme) async {
    try {
      await _trainingPlanService.refreshPlan(currentUserUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan refreshed successfully!'),
            backgroundColor: theme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing plan: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    }
  }

  /// Continue with current plan
  Future<void> _continuePlan(TrainingPlansRecord plan) async {
    try {
      final nextModule = await _trainingPlanService.getNextModuleInPlan(plan);
      if (nextModule != null) {
        await _startModuleSession(nextModule);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan completed! Generate a new plan to continue.'),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );
      }
    } catch (e) {
      // Log error to user record if it's a JSON parsing error
      if (e.toString().contains('FormatException') ||
          e.toString().contains('JSON') ||
          e.toString().contains('parsing')) {
        try {
          await UserRecord.collection.doc(currentUserUid).update({
            'lastAIError': e.toString().length > 500
                ? e.toString().substring(0, 500)
                : e.toString(),
            'lastAIErrorTimestamp': FieldValue.serverTimestamp(),
            'aiErrorCount': FieldValue.increment(1),
          });
        } catch (logError) {
          if (kDebugMode) {
            print('⚠️ Failed to log error to user record: $logError');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error continuing plan. Please try again.'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }

      if (kDebugMode) {
        print('❌ Error continuing plan: $e');
      }
    }
  }

  /// Build Generated Content Card
  Widget _buildGeneratedContentCard(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.success.withValues(alpha: 0.1),
            theme.aiPrimary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.success, theme.aiPrimary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _generatedContentTitle ?? 'AI Generated Content',
                      style: theme.titleMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tailored specifically for your golf mental game',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showGeneratedContent = false;
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: theme.secondaryText,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.glassBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              _generatedContentText ?? '',
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Copy to clipboard
                    Clipboard.setData(
                        ClipboardData(text: _generatedContentText ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Training plan copied to clipboard!'),
                        backgroundColor: theme.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.success.withValues(alpha: 0.1),
                    foregroundColor: theme.success,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: theme.success.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  icon: Icon(Icons.copy, size: 16),
                  label: Text('Copy Plan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generatePersonalizedContent(theme),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.aiPrimary.withValues(alpha: 0.1),
                    foregroundColor: theme.aiPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: theme.aiPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('New Plan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual AI recommendation card
  Widget _buildAIRecommendationCard(
    FlutterFlowTheme theme,
    String title,
    String description,
    String priority,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priority.contains('High')
                            ? theme.error.withValues(alpha: 0.1)
                            : theme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priority,
                        style: theme.bodySmall.copyWith(
                          color: priority.contains('High')
                              ? theme.error
                              : theme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// VARK-Based Module Recommendations
  Widget _buildVarkRecommendations(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: currentUser != null ? _userRecordStream : null,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final varkPrefs = user?.varkPreferences;

        return GlassDashboardCard(
          title: 'Recommended for Your Learning Style',
          subtitle: varkPrefs != null
              ? 'Optimized for ${_getPrimaryVarkStyle(varkPrefs)} learners'
              : 'Complete VARK assessment to get personalized recommendations',
          children: [
            if (varkPrefs != null)
              _buildVarkModulesList(theme, varkPrefs)
            else
              _buildVarkAssessmentPrompt(theme),
          ],
        );
      },
    );
  }

  /// Get active filters description
  String _getActiveFiltersDescription() {
    List<String> activeFilters = [];

    if (_selectedPillar != 'all') {
      activeFilters.add(_selectedPillar.toUpperCase());
    }
    if (_selectedVarkFilter != 'all') {
      activeFilters.add(_selectedVarkFilter.toUpperCase());
    }
    if (_selectedDifficulty != 'all') {
      activeFilters.add(_selectedDifficulty.toUpperCase());
    }

    return activeFilters.join(' • ');
  }

  /// Train Tab (Renamed from Training)
  Widget _buildTrainTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Section 1: Your Smart Training Session
          _buildSmartTrainingSession(theme),

          const SizedBox(height: 24),

          // Section 2: Additional Recommendations
          _buildAdditionalRecommendations(theme),

          const SizedBox(height: 24),

          // Section 3: Quick Mind Tools
          _buildQuickMindTools(theme),

          const SizedBox(height: 24),

          // Section 4: Adaptive Mode
          _buildAdaptiveMode(theme),

          const SizedBox(height: 100), // Space for navbar
        ],
      ),
    );
  }

  /// Build Smart Training Session section
  Widget _buildSmartTrainingSession(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Your Smart Training Session',
      subtitle: 'Adaptive AI-crafted routine',
      children: [
        StreamBuilder<GeminiRecommendationResponse?>(
          stream: _getTodayRecommendationStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                ),
              );
            }

            final recommendation = snapshot.data;
            if (recommendation != null &&
                recommendation.recommendations.isNotEmpty) {
              final session = recommendation.recommendations.first;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.aiPrimary.withValues(alpha: 0.15),
                      theme.aiSecondary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.aiPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: theme.aiGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${session.estimatedDuration}-minute routine',
                                style: theme.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText,
                                ),
                              ),
                              Text(
                                'Centering & rhythm',
                                style: theme.bodyMedium.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                              Text(
                                'Based on last two sessions',
                                style: theme.bodySmall.copyWith(
                                  color: theme.aiPrimary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _startTrainingSessionFromRecommendation(session),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.aiPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(Icons.play_arrow, size: 20),
                        label: Text('Start Session'),
                      ),
                    ),
                  ],
                ),
              );
            }

            return _buildDefaultTodayRecommendation(theme);
          },
        ),
      ],
    );
  }

  /// Build Additional Recommendations section
  Widget _buildAdditionalRecommendations(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Additional Recommendations',
      subtitle: 'More training options for you',
      children: [
        StreamBuilder<GeminiRecommendationResponse?>(
          stream: _getTodayRecommendationStream(),
          builder: (context, snapshot) {
            final recommendations = snapshot.data?.recommendations ?? [];

            if (recommendations.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: recommendations.skip(1).take(3).map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.glassBackground.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.glassBorder.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.moduleTitle,
                                style: theme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText,
                                ),
                              ),
                              Text(
                                '${rec.estimatedDuration} min',
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _startTrainingSessionFromRecommendation(rec),
                          icon: Icon(
                            Icons.play_arrow,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Build Quick Mind Tools section (renamed and updated)
  Widget _buildQuickMindTools(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Quick Mind Tools',
      subtitle: 'Fast mental exercises for immediate use',
      children: [
        Column(
          children: [
            _buildQuickToolCard(
              theme,
              'Breathing',
              Icons.air,
              theme.breathingActive,
              '2 min',
              onTap: () => context.pushNamed('breathing_tool'),
            ),
            const SizedBox(height: 12),
            _buildQuickToolCard(
              theme,
              'Visualize',
              Icons.visibility,
              theme.mentalFocus,
              '5 min',
              onTap: () => context.pushNamed('visualize_tool'),
            ),
            const SizedBox(height: 12),
            _buildQuickToolCard(
              theme,
              'Reset',
              Icons.refresh,
              theme.mentalCalm,
              '3 min',
              onTap: () => context.pushNamed('reset_tool'),
            ),
            const SizedBox(height: 12),
            _buildQuickToolCard(
              theme,
              'Rebalance',
              Icons.balance,
              theme.warning,
              'Adaptive',
              onTap: () => context.pushNamed('rebalance_tool'),
            ),
          ],
        ),
      ],
    );
  }

  /// Build Adaptive Mode section
  Widget _buildAdaptiveMode(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: currentUser != null ? _userRecordStream : null,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final currentMode = user?.currentAdaptiveMode ?? 'AI-Reactive';

        return GlassDashboardCard(
          title: 'Adaptive Mode',
          subtitle: 'Choose your training context',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAdaptiveModeChip(
                  theme,
                  'Pre-Round',
                  Icons.golf_course,
                  currentMode == 'Pre-Round',
                  () => _setAdaptiveMode('Pre-Round'),
                ),
                _buildAdaptiveModeChip(
                  theme,
                  'Post-Round',
                  Icons.flag,
                  currentMode == 'Post-Round',
                  () => _setAdaptiveMode('Post-Round'),
                ),
                _buildAdaptiveModeChip(
                  theme,
                  'Off-Day',
                  Icons.spa,
                  currentMode == 'Off-Day',
                  () => _setAdaptiveMode('Off-Day'),
                ),
                _buildAdaptiveModeChip(
                  theme,
                  'AI-Reactive',
                  Icons.auto_awesome,
                  currentMode == 'AI-Reactive',
                  () => _setAdaptiveMode('AI-Reactive'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build adaptive mode chip
  Widget _buildAdaptiveModeChip(
    FlutterFlowTheme theme,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.3),
                    theme.primary.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color:
              isSelected ? null : theme.glassBackground.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primary
                : theme.glassBorder.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.primary : theme.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.bodyMedium.copyWith(
                color: isSelected ? theme.primary : theme.primaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Set adaptive mode and trigger AI recommendations
  Future<void> _setAdaptiveMode(String mode) async {
    try {
      await UserRecord.collection.doc(currentUserUid).update({
        'currentAdaptiveMode': mode,
      });
      setState(() {});

      // Trigger AI recommendations refresh when adaptive mode changes
      if (mounted) {
        await _refreshAIRecommendationsForAdaptiveMode(mode);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting adaptive mode: $e');
      }
    }
  }

  /// Refresh AI recommendations based on adaptive mode
  Future<void> _refreshAIRecommendationsForAdaptiveMode(
      String adaptiveMode) async {
    if (currentUser == null) return;

    try {
      // Get user context for AI recommendations
      final userDoc = await UserRecord.collection.doc(currentUserUid).get();
      final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

      if (user == null) return;

      // Generate AI recommendations using Interactions API
      final interactionsService = GeminiInteractionsService();

      final userContext = {
        'userId': currentUserUid,
        'adaptiveMode': adaptiveMode,
        'varkPreferences': user.varkPreferences?.toMap() ?? {},
        'golfExperience': user.golfExperience,
        'handicap': user.handicap,
        'currentMembershipTier': user.currentMembershipTier,
      };

      final recommendations = await interactionsService.generateRecommendations(
        userId: currentUserUid,
        userContext: userContext,
        adaptiveMode: adaptiveMode,
        count: 5,
      );

      // Update recommendations in Firestore
      if (recommendations.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUserUid)
            .collection('ai_recommendations')
            .doc('current')
            .set({
          'recommendations': recommendations,
          'adaptiveMode': adaptiveMode,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing recommendations for adaptive mode: $e');
      }
    }
  }

  /// Trigger rebalance tool
  Future<void> _triggerRebalance(FlutterFlowTheme theme) async {
    try {
      // Check for stress indicators
      final recentSessions = await MentalSessionsRecord.collection
          .where('userId', isEqualTo: currentUserUid)
          .orderBy('dateCompleted', descending: true)
          .limit(5)
          .get();

      bool stressDetected = false;
      if (recentSessions.docs.isNotEmpty) {
        // Simple stress detection logic
        final sessions = recentSessions.docs
            .map((doc) => MentalSessionsRecord.fromSnapshot(doc))
            .toList();

        // Check for low perceived value or negative mood changes
        stressDetected = sessions.any((s) =>
            (s.perceivedValue < 3) ||
            (s.userMoodAfter.isNotEmpty &&
                s.userMoodBefore.isNotEmpty &&
                s.userMoodAfter.contains('stress')));
      }

      // Create rebalance session
      await MentalSessionsRecord.collection.add({
        'userId': currentUserUid,
        'moduleTitle': 'Rebalance Drill',
        'moduleId': 'rebalance_adaptive',
        'sessionType': 'rebalance',
        'dateStarted': FieldValue.serverTimestamp(),
        'isCompleted': false,
        'pillar': 'control',
        'adaptiveMode': 'AI-Reactive',
        'rebalanceTriggered': true,
        'estimatedDuration': 5,
        'difficulty': 'beginner',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.balance, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(stressDetected
                    ? 'Stress detected. Starting rebalance drill...'
                    : 'Starting rebalance drill...'),
              ],
            ),
            backgroundColor: theme.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error triggering rebalance: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
    }
  }

  /// Journey Tab (Renamed from Progress)
  Widget _buildJourneyTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Section 1: Mind Power Index
          _buildMindPowerIndex(theme),

          const SizedBox(height: 24),

          // Section 2: Learning Progress (with pillar breakdown)
          _buildLearningProgressWithPillars(theme),

          const SizedBox(height: 24),

          // Section 3: Achievements
          _buildAchievements(theme),

          const SizedBox(height: 100), // Space for navbar
        ],
      ),
    );
  }

  /// Build Mind Power Index section
  Widget _buildMindPowerIndex(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: currentUser != null ? _userRecordStream : null,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final mpi = _calculateMPI(user);
        final mpiColor = _getMPIColor(theme, mpi);

        // Generate dynamic AI phrase
        String aiPhrase = 'Confidence rising steadily. Focus dipped slightly.';
        if (mpi >= 85) {
          aiPhrase = 'Excellent mental performance! You\'re in the zone.';
        } else if (mpi >= 70) {
          aiPhrase = 'Good mental game. Keep building consistency.';
        }

        return GlassDashboardCard(
          title: 'Mind Power Index',
          subtitle: 'Track your mental game development',
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          mpiColor,
                          mpiColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        mpi.toString(),
                        style: theme.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mental Performance Index',
                    style: theme.titleMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.aiPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.aiPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: theme.aiPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            aiPhrase,
                            style: theme.bodySmall.copyWith(
                              color: theme.primaryText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMPIComponent(theme, 'Focus',
                          _calculateFocusScore(user), theme.mentalFocus),
                      _buildMPIComponent(
                          theme,
                          'Confidence',
                          _calculateConfidenceScore(user),
                          theme.mentalStrength),
                      _buildMPIComponent(theme, 'Control',
                          _calculateControlScore(user), theme.mentalCalm),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build Learning Progress with Pillar Breakdown
  Widget _buildLearningProgressWithPillars(FlutterFlowTheme theme) {
    return StreamBuilder<List<MentalSessionsRecord>>(
      stream: _userSessionsStream,
      builder: (context, sessionsSnapshot) {
        final sessions = sessionsSnapshot.data ?? [];
        final completedSessions = sessions.where((s) => s.isCompleted).toList();

        // Calculate pillar progress
        final focusCompleted = completedSessions
            .where((s) => s.pillar == 'focus')
            .map((s) => s.moduleId)
            .toSet()
            .length;
        final confidenceCompleted = completedSessions
            .where((s) => s.pillar == 'confidence')
            .map((s) => s.moduleId)
            .toSet()
            .length;
        final controlCompleted = completedSessions
            .where((s) => s.pillar == 'control')
            .map((s) => s.moduleId)
            .toSet()
            .length;

        final totalModules = 24; // Total modules available
        final completedModules =
            completedSessions.map((s) => s.moduleId).toSet().length;
        final progressPercentage =
            (completedModules / totalModules * 100).clamp(0, 100);

        // Generate AI phrase
        String aiPhrase = 'Start your first lesson';
        if (completedModules > 0) {
          aiPhrase = 'You\'re building a balanced foundation';
        }

        return GlassDashboardCard(
          title: 'Learning Progress',
          subtitle: 'Your journey through the mental training modules',
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.success,
                              theme.success.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${progressPercentage.toInt()}%',
                            style: theme.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modules Completed: $completedModules/$totalModules',
                              style: theme.titleMedium.copyWith(
                                color: theme.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progressPercentage / 100,
                              backgroundColor: theme.alternate,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(theme.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Pillar progress breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.glassBackground.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildPillarProgressRow(theme, 'Focus', focusCompleted,
                            8, theme.mentalFocus),
                        const SizedBox(height: 12),
                        _buildPillarProgressRow(theme, 'Confidence',
                            confidenceCompleted, 8, theme.mentalStrength),
                        const SizedBox(height: 12),
                        _buildPillarProgressRow(theme, 'Control',
                            controlCompleted, 8, theme.mentalCalm),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.aiPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.aiPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: theme.aiPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            aiPhrase,
                            style: theme.bodySmall.copyWith(
                              color: theme.primaryText,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build pillar progress row
  Widget _buildPillarProgressRow(
    FlutterFlowTheme theme,
    String pillar,
    int completed,
    int total,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          _getPillarIcon(pillar.toLowerCase()),
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            pillar,
            style: theme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
        ),
        Text(
          '$completed/$total',
          style: theme.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get filtered modules stream based on current filters with error handling
  Stream<List<CoachingModulesRecord>> _getFilteredModulesStream() {
    try {
      Query query =
          CoachingModulesRecord.collection.where('isActive', isEqualTo: true);

      // Apply pillar filter first (most selective)
      if (_selectedPillar != 'all') {
        query = query.where('pillar', isEqualTo: _selectedPillar);
      }

      // Apply difficulty filter
      if (_selectedDifficulty != 'all') {
        query = query.where('difficulty', isEqualTo: _selectedDifficulty);
      }

      // Apply ordering
      query = query.orderBy('averageRating', descending: true);

      return query.snapshots().asyncMap((snapshot) async {
        List<CoachingModulesRecord> modules = snapshot.docs
            .map((doc) => CoachingModulesRecord.fromSnapshot(doc))
            .toList();

        // Apply VARK filter in memory to avoid complex Firestore queries
        if (_selectedVarkFilter != 'all') {
          modules = modules.where((module) {
            return module.varkTags.contains(_selectedVarkFilter);
          }).toList();
        }

        print('✅ Loaded ${modules.length} coaching modules with filters: '
            'pillar=$_selectedPillar, vark=$_selectedVarkFilter, difficulty=$_selectedDifficulty');

        return modules;
      });
    } catch (e) {
      print('❌ Error loading coaching modules: $e');
      return Stream.value([]);
    }
  }

  /// Force refresh modules stream
  void _refreshModules() {
    setState(() {
      // This will trigger a rebuild and refresh the stream
    });
  }

  /// Get primary VARK style from preferences
  String _getPrimaryVarkStyle(dynamic varkPrefs) {
    if (varkPrefs.visual) return 'Visual';
    if (varkPrefs.aural) return 'Auditory';
    if (varkPrefs.readWrite) return 'Reading/Writing';
    if (varkPrefs.kinesthetic) return 'Kinesthetic';
    return 'Mixed';
  }

  /// Show enhanced filter dialog with improved UI
  void _showVarkFilterDialog(FlutterFlowTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: theme.glassBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primary.withValues(alpha: 0.1),
                      theme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.primary, theme.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Modules',
                            style: theme.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                          Text(
                            'Customize your MindCoach experience',
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.primaryText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Suggestions Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.aiPrimary.withValues(alpha: 0.1),
                              theme.aiSecondary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.aiPrimary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 20,
                                  color: theme.aiPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI generated smart suggestions based on history',
                                  style: theme.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Confidence routines worked great last time. Now explore the Control modules.',
                              style: theme.bodyMedium.copyWith(
                                color: theme.secondaryText,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Apply AI suggestions
                                      setDialogState(() {
                                        _selectedPillar = 'control';
                                        _selectedVarkFilter = 'all';
                                        _selectedDifficulty = 'all';
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.aiPrimary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Apply Suggestions'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // User will select manually
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.aiPrimary,
                                      side: BorderSide(color: theme.aiPrimary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Select manually'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Learning Style Section
                      Text(
                        'VARK Learning Style',
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip(
                            theme,
                            'All',
                            _selectedVarkFilter == 'all',
                            () => setDialogState(
                                () => _selectedVarkFilter = 'all'),
                            theme.primary,
                          ),
                          _buildFilterChip(
                            theme,
                            'Visual',
                            _selectedVarkFilter == 'visual',
                            () => setDialogState(
                                () => _selectedVarkFilter = 'visual'),
                            theme.info,
                          ),
                          _buildFilterChip(
                            theme,
                            'Auditory',
                            _selectedVarkFilter == 'aural',
                            () => setDialogState(
                                () => _selectedVarkFilter = 'aural'),
                            theme.success,
                          ),
                          _buildFilterChip(
                            theme,
                            'Reading',
                            _selectedVarkFilter == 'readwrite',
                            () => setDialogState(
                                () => _selectedVarkFilter = 'readwrite'),
                            theme.warning,
                          ),
                          _buildFilterChip(
                            theme,
                            'Kinesthetic',
                            _selectedVarkFilter == 'kinesthetic',
                            () => setDialogState(
                                () => _selectedVarkFilter = 'kinesthetic'),
                            theme.error,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Performance Pillars Section
                      Text(
                        'Performance Pillars',
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip(
                            theme,
                            'All Pillars',
                            _selectedPillar == 'all',
                            () => setDialogState(() => _selectedPillar = 'all'),
                            theme.primary,
                          ),
                          _buildFilterChip(
                            theme,
                            '🎯 Focus',
                            _selectedPillar == 'focus',
                            () =>
                                setDialogState(() => _selectedPillar = 'focus'),
                            theme.mentalFocus,
                          ),
                          _buildFilterChip(
                            theme,
                            '💪 Confidence',
                            _selectedPillar == 'confidence',
                            () => setDialogState(
                                () => _selectedPillar = 'confidence'),
                            theme.mentalStrength,
                          ),
                          _buildFilterChip(
                            theme,
                            '🧘 Control',
                            _selectedPillar == 'control',
                            () => setDialogState(
                                () => _selectedPillar = 'control'),
                            theme.mentalCalm,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Difficulty Level Section
                      Text(
                        'Difficulty Level',
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip(
                            theme,
                            'All Levels',
                            _selectedDifficulty == 'all',
                            () => setDialogState(
                                () => _selectedDifficulty = 'all'),
                            theme.primary,
                          ),
                          _buildFilterChip(
                            theme,
                            '⭐ Beginner',
                            _selectedDifficulty == 'beginner',
                            () => setDialogState(
                                () => _selectedDifficulty = 'beginner'),
                            theme.success,
                          ),
                          _buildFilterChip(
                            theme,
                            '⭐⭐ Intermediate',
                            _selectedDifficulty == 'intermediate',
                            () => setDialogState(
                                () => _selectedDifficulty = 'intermediate'),
                            theme.warning,
                          ),
                          _buildFilterChip(
                            theme,
                            '⭐⭐ Intermediate',
                            _selectedDifficulty == 'intermediate',
                            () => setDialogState(
                                () => _selectedDifficulty = 'intermediate'),
                            theme.warning,
                          ),
                          _buildFilterChip(
                            theme,
                            '⭐⭐⭐ Advanced',
                            _selectedDifficulty == 'advanced',
                            () => setDialogState(
                                () => _selectedDifficulty = 'advanced'),
                            theme.error,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Current Filter Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.alternate.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Filters:',
                              style: theme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• VARK Learning Style: ${_selectedVarkFilter.toUpperCase()}\n'
                              '• Performance Pillar: ${_selectedPillar.toUpperCase()}\n'
                              '• Difficulty: ${_selectedDifficulty.toUpperCase()}',
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.glassBorder.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedVarkFilter = 'all';
                            _selectedPillar = 'all';
                            _selectedDifficulty = 'all';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.secondaryText,
                          side: BorderSide(color: theme.glassBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Apply filters
                          Navigator.pop(context);

                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.filter_alt,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Filters applied successfully!'),
                                ],
                              ),
                              backgroundColor: theme.success,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show Quick Mind Tools bottom sheet after session preparation
  void _showQuickMindToolsSheet(FlutterFlowTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: theme.glassBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.aiPrimary.withValues(alpha: 0.15),
                    theme.aiSecondary.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: theme.aiGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Mind Tools',
                          style: theme.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText,
                          ),
                        ),
                        Text(
                          'Fast mental exercises for immediate use',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.primaryText),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Tools Grid
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickToolCard(
                        theme,
                        'Breathing',
                        Icons.air,
                        theme.breathingActive,
                        '2 min',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.pushNamed('breathing_tool');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickToolCard(
                        theme,
                        'Visualize',
                        Icons.visibility,
                        theme.mentalFocus,
                        '5 min',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.pushNamed('visualize_tool');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickToolCard(
                        theme,
                        'Reset',
                        Icons.refresh,
                        theme.mentalCalm,
                        '3 min',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.pushNamed('reset_tool');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickToolCard(
                        theme,
                        'Rebalance',
                        Icons.balance,
                        theme.warning,
                        'Adaptive',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.pushNamed('rebalance_tool');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build enhanced filter chip with better colors and animations
  Widget _buildFilterChip(
    FlutterFlowTheme theme,
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color:
              isSelected ? null : theme.glassBackground.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color:
                isSelected ? color : theme.glassBorder.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.bodyMedium.copyWith(
                color: isSelected ? color : theme.primaryText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build VARK modules list with AI-generated recommendations
  Widget _buildVarkModulesList(FlutterFlowTheme theme, dynamic varkPrefs) {
    return FutureBuilder<List<dynamic>>(
      future: _generateVarkBasedRecommendations(varkPrefs),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Personalizing recommendations...',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final recommendations = snapshot.data ?? [];

        if (recommendations.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 48,
                  color: theme.aiPrimary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No recommendations yet',
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete more sessions to get personalized recommendations',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: recommendations
              .take(3)
              .map<Widget>(
                  (rec) => _buildAIRecommendationModuleCard(theme, rec))
              .toList(),
        );
      },
    );
  }

  /// Generate VARK-based AI recommendations
  Future<List<Map<String, dynamic>>> _generateVarkBasedRecommendations(
      dynamic varkPrefs) async {
    try {
      final primaryStyle = _getPrimaryVarkStyle(varkPrefs).toLowerCase();

      // Get modules that match the user's VARK preference
      final modulesSnapshot = await CoachingModulesRecord.collection
          .where('isActive', isEqualTo: true)
          .where('varkTags',
              arrayContains: primaryStyle == 'mixed' ? 'visual' : primaryStyle)
          .orderBy('averageRating', descending: true)
          .limit(5)
          .get();

      final modules = modulesSnapshot.docs
          .map((doc) => CoachingModulesRecord.fromSnapshot(doc))
          .toList();

      // Generate AI-based recommendations with reasoning
      return modules
          .map((module) => {
                'module': module,
                'aiReasoning': _generateAIReasoning(module, primaryStyle),
                'personalizedTitle':
                    _generatePersonalizedTitle(module, primaryStyle),
                'varkAlignment': _calculateVarkAlignment(module, primaryStyle),
              })
          .toList();
    } catch (e) {
      print('❌ Error generating VARK recommendations: $e');
      return [];
    }
  }

  /// Generate AI reasoning for module recommendation
  String _generateAIReasoning(CoachingModulesRecord module, String varkStyle) {
    final reasonings = {
      'visual':
          'Perfect for visual learners - uses diagrams and imagery to enhance understanding',
      'aural':
          'Ideal for auditory learners - includes guided audio sessions and verbal instructions',
      'readwrite':
          'Great for reading/writing learners - features detailed notes and written exercises',
      'kinesthetic':
          'Designed for hands-on learners - includes practical exercises and movement-based techniques',
    };

    return reasonings[varkStyle] ??
        'Tailored to your unique learning preferences';
  }

  /// Generate personalized title based on VARK
  String _generatePersonalizedTitle(
      CoachingModulesRecord module, String varkStyle) {
    final prefixes = {
      'visual': '👁️ Visualize:',
      'aural': '🎧 Listen:',
      'readwrite': '📝 Study:',
      'kinesthetic': '🤸 Practice:',
    };

    return '${prefixes[varkStyle] ?? '🎯'} ${module.title}';
  }

  /// Calculate VARK alignment score
  double _calculateVarkAlignment(
      CoachingModulesRecord module, String varkStyle) {
    if (module.primaryVarkStyle == varkStyle) return 1.0;
    if (module.varkTags.contains(varkStyle)) return 0.8;
    return 0.6;
  }

  /// Build AI recommendation module card
  Widget _buildAIRecommendationModuleCard(
      FlutterFlowTheme theme, Map<String, dynamic> recommendation) {
    final module = recommendation['module'] as CoachingModulesRecord;
    final aiReasoning = recommendation['aiReasoning'] as String;
    final personalizedTitle = recommendation['personalizedTitle'] as String;
    final varkAlignment = recommendation['varkAlignment'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.aiPrimary.withValues(alpha: 0.05),
            theme.aiSecondary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.aiPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with AI indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: theme.aiGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personalizedTitle,
                        style: theme.titleSmall.copyWith(
                          color: theme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: theme.secondaryText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${module.duration} min',
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.psychology,
                                size: 12,
                                color: _getPillarColor(theme, module.pillar),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                module.pillar.toUpperCase(),
                                style: theme.bodySmall.copyWith(
                                  color: _getPillarColor(theme, module.pillar),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: theme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(varkAlignment * 100).toInt()}% Match',
                        style: theme.bodySmall.copyWith(
                          color: theme.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // AI Reasoning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.aiPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.aiPrimary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: theme.aiPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aiReasoning,
                      style: theme.bodySmall.copyWith(
                        color: theme.primaryText,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Module description
            Text(
              module.description,
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startModuleSession(module),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.aiPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: Icon(Icons.play_arrow, size: 16),
                label: Text(
                  'Start Learning',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ensure sample coaching modules exist in Firestore
  Future<void> _ensureSampleDataExists() async {
    try {
      // Check if any modules exist
      final existingModules = await CoachingModulesRecord.collection
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingModules.docs.isEmpty) {
        print('⚠️ No coaching modules found, creating sample data...');
        await _createSampleModulesData();
      }
    } catch (e) {
      print('❌ Error checking for sample data: $e');
    }
  }

  /// Create sample coaching modules data
  Future<void> _createSampleModulesData() async {
    try {
      final sampleModules = [
        // Focus Modules
        {
          'moduleId': 'focus_intro',
          'title': 'Introduction to Mental Focus',
          'description':
              'Learn the fundamentals of maintaining focus during your golf game. Master concentration techniques that will help you stay present on every shot.',
          'pillar': 'focus',
          'difficulty': 'beginner',
          'duration': 6,
          'varkTags': ['visual', 'aural'],
          'primaryVarkStyle': 'visual',
          'tierRequirement': 'FREE',
          'prerequisites': [],
          'learningObjectives': [
            'Understand focus basics',
            'Learn concentration techniques'
          ],
          'tags': ['beginner', 'fundamentals', 'concentration'],
          'thumbnailUrl': '',
          'isActive': true,
          'order': 1,
          'completionCount': 247,
          'averageRating': 4.5,
          'createdTime': FieldValue.serverTimestamp(),
          'updatedTime': FieldValue.serverTimestamp(),
        },
        {
          'moduleId': 'focus_breathing',
          'title': 'Focus Through Breathing',
          'description':
              'Master breathing techniques to enhance concentration on the course. Learn 4-7-8 breathing and other proven methods.',
          'pillar': 'focus',
          'difficulty': 'intermediate',
          'duration': 6,
          'varkTags': ['kinesthetic', 'aural'],
          'primaryVarkStyle': 'kinesthetic',
          'tierRequirement': 'FREE',
          'prerequisites': ['focus_intro'],
          'learningObjectives': [
            'Master breathing techniques',
            'Apply during play'
          ],
          'tags': ['breathing', 'techniques', 'intermediate'],
          'thumbnailUrl': '',
          'isActive': true,
          'order': 2,
          'completionCount': 189,
          'averageRating': 4.3,
          'createdTime': FieldValue.serverTimestamp(),
          'updatedTime': FieldValue.serverTimestamp(),
        },

        // Confidence Modules
        {
          'moduleId': 'confidence_basics',
          'title': 'Building Golf Confidence',
          'description':
              'Develop unshakeable confidence in your golf abilities. Learn to build self-belief that transfers to better performance.',
          'pillar': 'confidence',
          'difficulty': 'beginner',
          'duration': 6,
          'varkTags': ['visual', 'readwrite'],
          'primaryVarkStyle': 'visual',
          'tierRequirement': 'FREE',
          'prerequisites': [],
          'learningObjectives': [
            'Build self-belief',
            'Create confidence routines'
          ],
          'tags': ['confidence', 'mindset', 'beginner'],
          'thumbnailUrl': '',
          'isActive': true,
          'order': 3,
          'completionCount': 312,
          'averageRating': 4.7,
          'createdTime': FieldValue.serverTimestamp(),
          'updatedTime': FieldValue.serverTimestamp(),
        },
        {
          'moduleId': 'confidence_visualization',
          'title': 'Confidence Visualization',
          'description':
              'Use mental imagery to boost confidence before and during rounds. Create powerful success images in your mind.',
          'pillar': 'confidence',
          'difficulty': 'intermediate',
          'duration': 7,
          'varkTags': ['visual', 'kinesthetic'],
          'primaryVarkStyle': 'visual',
          'tierRequirement': 'PREMIUM',
          'prerequisites': ['confidence_basics'],
          'learningObjectives': [
            'Master visualization',
            'Create success images'
          ],
          'tags': ['visualization', 'imagery', 'premium'],
          'thumbnailUrl': '',
          'isActive': true,
          'order': 4,
          'completionCount': 156,
          'averageRating': 4.6,
          'createdTime': FieldValue.serverTimestamp(),
          'updatedTime': FieldValue.serverTimestamp(),
        },

        // Control Modules
        {
          'moduleId': 'control_emotions',
          'title': 'Emotional Control Basics',
          'description':
              'Learn to manage emotions and stay composed during challenging rounds. Master techniques for emotional regulation.',
          'pillar': 'control',
          'difficulty': 'beginner',
          'duration': 6,
          'varkTags': ['aural', 'readwrite'],
          'primaryVarkStyle': 'aural',
          'tierRequirement': 'FREE',
          'prerequisites': [],
          'learningObjectives': [
            'Recognize emotions',
            'Apply control techniques'
          ],
          'tags': ['emotions', 'composure', 'regulation'],
          'thumbnailUrl': '',
          'isActive': true,
          'order': 5,
          'completionCount': 203,
          'averageRating': 4.4,
          'createdTime': FieldValue.serverTimestamp(),
          'updatedTime': FieldValue.serverTimestamp(),
        },
        {
          'moduleId': 'control_pressure',
          'title': 'Playing Under Pressure',
          'description':
              'Advanced techniques for maintaining control in high-pressure situations. Perform your best when it matters most.',
          'pillar': 'control',
          'difficulty': 'advanced',
          'duration': 7,
          'varkTags': ['kinesthetic', 'visual'],
          'primaryVarkStyle': 'kinesthetic',
          'tierRequirement': 'PREMIUM',
          'prerequisites': ['control_emotions'],
          'learningObjectives': ['Handle pressure', 'Execute under stress'],
          'tags': ['pressure', 'advanced', 'performance'],
          'thumbnailUrl': '',
          'isActive': true,
          'order': 6,
          'completionCount': 89,
          'averageRating': 4.8,
          'createdTime': FieldValue.serverTimestamp(),
          'updatedTime': FieldValue.serverTimestamp(),
        },
      ];

      // Create modules in Firestore
      final batch = FirebaseFirestore.instance.batch();
      for (final moduleData in sampleModules) {
        final docRef = CoachingModulesRecord.collection.doc();
        batch.set(docRef, moduleData);
      }

      await batch.commit();
      print('✅ Created ${sampleModules.length} sample coaching modules');
    } catch (e) {
      print('❌ Error creating sample modules: $e');
    }
  }

  /// Start module session with enhanced functionality
  Future<void> _startModuleSession(CoachingModulesRecord module) async {
    bool dialogShown = false;
    try {
      final theme = FlutterFlowTheme.of(context);

      // Validate user has completed all required experience
      final userDoc = await UserRecord.collection.doc(currentUserUid).get();
      final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete your profile first'),
            backgroundColor: theme.error,
          ),
        );
        return;
      }

      // Check if VARK assessment is completed
      final varkPrefs = user.varkPreferences;
      final hasVarkCompleted = varkPrefs != null &&
          (varkPrefs.visual ||
              varkPrefs.aural ||
              varkPrefs.readWrite ||
              varkPrefs.kinesthetic);
      if (!hasVarkCompleted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Complete Your Assessment'),
              content: Text(
                'Please complete the VARK learning style assessment to get personalized training recommendations. This helps us tailor your experience.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to AI-generated assessment page
                    context.pushNamed('ai_assessment');
                  },
                  child: Text('Take Assessment'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing ${module.title}...',
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Setting up your personalized training session',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
        dialogShown = true;
      }

      final adaptiveMode = user.currentAdaptiveMode ?? 'standard';

      // Check for active training plan
      final activePlan =
          await _trainingPlanService.getCurrentPlan(currentUserUid);
      String? trainingPlanId;

      if (activePlan != null) {
        // Verify this module is part of the active plan
        final isPartOfPlan = activePlan.modules.contains(module.moduleId);
        if (isPartOfPlan) {
          trainingPlanId = activePlan.planId;
        }
        // If module not in plan, trainingPlanId remains null
        // User might be exploring outside their plan
      }

      // Simulate session preparation
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Safely close loading dialog
        if (dialogShown && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          dialogShown = false;
        }

        // Create a mental session record with training plan sync and adaptive mode
        final sessionData = {
          'userId': currentUserUid,
          'moduleTitle': module.title,
          'moduleId': module.moduleId,
          'sessionType': 'training',
          'dateStarted': FieldValue.serverTimestamp(),
          'isCompleted': false,
          'pillar': module.pillar,
          'estimatedDuration': module.duration,
          'difficulty': module.difficulty,
          'varkStyle': module.primaryVarkStyle,
          'adaptiveMode': adaptiveMode,
          if (trainingPlanId != null) 'trainingPlanId': trainingPlanId,
        };

        await MentalSessionsRecord.collection.add(sessionData);

        // Note: Module completion count updates are handled via Cloud Functions
        // to maintain data integrity and prevent permission issues.
        // The completion count can be tracked via mental_sessions queries instead.

        // Store session reference for potential completion tracking
        // If session is part of a training plan, plan progress will be updated
        // when the session is marked as completed (handled separately)

        // Show Quick Mind Tools after session preparation
        _showQuickMindToolsSheet(theme);

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Training Session Started!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${module.title} • ${module.duration} minutes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: _getPillarColor(theme, module.pillar),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate to module content page
        if (mounted) {
          context.pushNamed(
            'virtual_training_experience',
            extra: <String, dynamic>{
              'moduleTitle': module.title,
              'moduleId': module.moduleId,
              'description': module.description,
              'estimatedDuration': module.duration,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Safely close loading dialog if it was shown
        if (dialogShown && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error starting session: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Build VARK assessment prompt
  Widget _buildVarkAssessmentPrompt(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 48,
            color: theme.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Discover Your Learning Style',
            style: theme.titleMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take our VARK assessment to get personalized module recommendations',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.pushNamed('ai_assessment');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Take Assessment'),
          ),
        ],
      ),
    );
  }

  /// Build enhanced pillar card matching design
  Widget _buildEnhancedPillarCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    Color color,
    String description,
    List<String> features,
  ) {
    return GestureDetector(
      onTap: () {
        // Filter modules by pillar and switch to tab showing them
        setState(() {
          _selectedPillar = title.toLowerCase();
        });

        // Show enhanced feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$title Training Selected',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Modules filtered below',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon section
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(width: 20),

            // Content section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: theme.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    description,
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Features list
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: features
                        .map((feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                feature,
                                style: theme.bodySmall.copyWith(
                                  color: theme.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // Tap to explore indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to explore',
                              style: theme.bodySmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build enhanced module card with improved design
  Widget _buildEnhancedModuleCard(
      FlutterFlowTheme theme, CoachingModulesRecord module) {
    return GestureDetector(
      onTap: () => _startModuleSession(module),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getPillarColor(theme, module.pillar).withValues(alpha: 0.05),
              _getPillarColor(theme, module.pillar).withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPillarColor(theme, module.pillar).withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _getPillarColor(theme, module.pillar).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon section
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPillarColor(theme, module.pillar),
                      _getPillarColor(theme, module.pillar)
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getPillarColor(theme, module.pillar)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getPillarIcon(module.pillar),
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              // Content section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and duration
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            module.title,
                            style: theme.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${module.duration} min',
                            style: theme.bodySmall.copyWith(
                              color: theme.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Description
                    Text(
                      module.description,
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Metadata row
                    Row(
                      children: [
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: theme.warning,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                module.averageRating.toStringAsFixed(1),
                                style: theme.bodySmall.copyWith(
                                  color: theme.warning,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Difficulty
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(theme, module.difficulty)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            module.difficulty.toUpperCase(),
                            style: theme.bodySmall.copyWith(
                              color:
                                  _getDifficultyColor(theme, module.difficulty),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Play button
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getPillarColor(theme, module.pillar)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: _getPillarColor(theme, module.pillar),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get difficulty color
  Color _getDifficultyColor(FlutterFlowTheme theme, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return theme.success;
      case 'intermediate':
        return theme.warning;
      case 'advanced':
        return theme.error;
      default:
        return theme.secondaryText;
    }
  }

  /// Get pillar color
  Color _getPillarColor(FlutterFlowTheme theme, String pillar) {
    switch (pillar.toLowerCase()) {
      case 'focus':
        return theme.mentalFocus;
      case 'confidence':
        return theme.mentalStrength;
      case 'control':
        return theme.mentalCalm;
      default:
        return theme.primary;
    }
  }

  /// Get pillar icon
  IconData _getPillarIcon(String pillar) {
    switch (pillar.toLowerCase()) {
      case 'focus':
        return Icons.center_focus_strong;
      case 'confidence':
        return Icons.psychology;
      case 'control':
        return Icons.self_improvement;
      default:
        return Icons.school;
    }
  }

  /// Build quick tool card - Enhanced horizontal layout
  Widget _buildQuickToolCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    Color color,
    String duration, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Title and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duration,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build achievements
  Widget _buildAchievements(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Achievements',
      subtitle: 'Celebrate your mental training milestones',
      children: [
        // Dynamic Achievements
        StreamBuilder<List<MentalSessionsRecord>>(
          stream: _userSessionsStream,
          builder: (context, sessionsSnapshot) {
            final sessions = sessionsSnapshot.data ?? <MentalSessionsRecord>[];
            return _buildDynamicAchievements(theme, sessions);
          },
        ),
      ],
    );
  }

  // ============================================================================
  // DYNAMIC CONTENT METHODS
  // ============================================================================

  /// Get AI recommendations stream
  Stream<List<GeminiModuleRecommendation>> _getAIRecommendationsStream() {
    // This would connect to a Firestore collection of AI recommendations
    // For now, return a stream with default recommendations
    // Note: Using method without theme to avoid context issues
    return Stream.value(_getDefaultAIRecommendationsWithoutTheme());
  }

  /// Get default AI recommendations
  /// Theme parameter is optional and not used, kept for backward compatibility
  List<GeminiModuleRecommendation> _getDefaultAIRecommendations(
      [FlutterFlowTheme? theme]) {
    return _getDefaultAIRecommendationsWithoutTheme();
  }

  /// Generate personalized content and save to Firestore
  Future<void> _generatePersonalizedContent(FlutterFlowTheme theme) async {
    if (currentUser == null) return;

    try {
      setState(() {
        _isGeneratingContent = true;
        _showGeneratedContent = false; // Hide previous results
      });

      // Get user data for better personalization
      // final userDoc = await UserRecord.collection.doc(currentUser?.uid).get();
      // final userData = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

      final content = await _aiCoachingService.generatePersonalizedContent(
        userId: currentUser?.uid ?? '',
        contentType: 'training_plan',
        topic: 'mental_game_improvement',
      );

      if (mounted) {
        // Generate a comprehensive training plan text
        final planText = _formatTrainingPlan(content);
        final planTitle =
            'AI Training Plan - ${DateTime.now().day}/${DateTime.now().month}';

        // Save to Firestore subcollection
        await _saveAIContentToFirestore(planTitle, planText);

        setState(() {
          _showGeneratedContent = true;
          _generatedContentTitle = planTitle;
          _generatedContentText = planText;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AI Training Plan Generated!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Plan saved to your profile and shown below',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: theme.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error generating content: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingContent = false;
        });
      }
    }
  }

  /// Save AI-generated content to Firestore user subcollection
  Future<void> _saveAIContentToFirestore(String title, String content) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUser!.uid)
          .collection('ai_generated_content')
          .add({
        'title': title,
        'content': content,
        'type': 'training_plan',
        'generated_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });

      print('✅ AI content saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving AI content: $e');
      rethrow;
    }
  }

  /// Format the training plan from AI response
  String _formatTrainingPlan(dynamic content) {
    return '''🎯 PERSONALIZED MENTAL TRAINING PLAN

🧠 FOCUS ENHANCEMENT
• Practice visualization exercises for 5 minutes daily
• Use the "mental laser" technique before each shot
• Develop your pre-shot routine with specific trigger words

💪 CONFIDENCE BUILDING
• Start each practice session with positive affirmations
• Review your best rounds to reinforce success patterns
• Use power poses between holes to maintain confidence

🎯 EMOTIONAL CONTROL
• Master the 4-7-8 breathing technique for pressure situations
• Practice acceptance mindset for bad shots
• Develop a "reset ritual" after mistakes

📅 WEEKLY SCHEDULE
• Monday: Visualization practice (10 mins)
• Wednesday: Confidence affirmations (5 mins)
• Friday: Breathing exercises (8 mins)
• Sunday: Complete mental game review

🎖️ SUCCESS MILESTONES
Week 1: Complete daily visualization
Week 2: Use breathing technique during round
Week 3: Maintain positive self-talk for 9 holes
Week 4: Apply full mental routine consistently

💡 ADAPTIVE STRATEGIES
Based on your learning style, focus on:
• Visual cues and mental imagery
• Step-by-step written processes
• Practical, hands-on techniques
• Regular practice and repetition

Keep practicing consistently and trust the process! Your mental game will strengthen with dedication and the right techniques.''';
  }

  /// Refresh AI recommendations with proper loading and storage
  Future<void> _refreshAIRecommendations() async {
    if (currentUser == null) return;

    setState(() {
      _isLoadingAIRecommendations = true;
      _aiRecommendationError = null;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).aiPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Refreshing AI Recommendations...',
                style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing your progress and preferences',
                style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Generate new recommendations
      await _aiCoachingService.generateCoachingRecommendations(
        userId: currentUser?.uid ?? '',
        includeWeeklyPlan: true,
      );

      // Save refresh timestamp to user profile
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUser!.uid)
          .update({
        'last_ai_refresh': FieldValue.serverTimestamp(),
        'ai_recommendations_count': FieldValue.increment(1),
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AI Recommendations Refreshed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'New personalized insights based on your latest data',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).aiPrimary,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        setState(() {
          _aiRecommendationError =
              'Failed to refresh recommendations. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Unable to refresh recommendations. Please check your connection.'),
                ),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAIRecommendations = false;
        });
      }
    }
  }

  /// Get today's recommendation stream
  Stream<GeminiRecommendationResponse?> _getTodayRecommendationStream() {
    // Return cached broadcast stream to avoid "Stream has already been listened to" errors
    if (_todayRecommendationStream != null) {
      return _todayRecommendationStream!;
    }

    // This would connect to Firestore to get today's AI recommendation
    // For now, return a mock recommendation as a broadcast stream
    // Note: We create default recommendations without theme since this might be called
    // outside build context. Theme is not needed for the default recommendations.
    final mockRecommendation = GeminiRecommendationResponse(
      recommendationType: 'daily_practice',
      recommendations: _getDefaultAIRecommendationsWithoutTheme(),
      primaryFocus: 'focus',
      weeklyPlan: GeminiWeeklyPlan(
        sessionsPerWeek: 3,
        totalDuration: 45,
        focusAreas: ['Focus', 'Confidence'],
        progressMilestones: ['Complete daily practice'],
      ),
      motivationalMessage:
          'Today is a great day to strengthen your mental game!',
      timestamp: DateTime.now(),
      model: 'gemini-2.5-flash',
    );

    // Convert to broadcast stream so multiple StreamBuilders can listen
    _todayRecommendationStream =
        Stream.value(mockRecommendation).asBroadcastStream();
    return _todayRecommendationStream!;
  }

  /// Get default AI recommendations without requiring theme context
  List<GeminiModuleRecommendation> _getDefaultAIRecommendationsWithoutTheme() {
    return [
      GeminiModuleRecommendation(
        moduleId: 'focus_enhancement',
        moduleTitle: 'Focus Enhancement',
        description:
            'Based on your recent rounds, work on sustained attention during pressure situations',
        priority: 'high',
        estimatedDuration: 6,
        learningStyle: 'focus',
        expectedOutcome: 'Improved concentration under pressure',
        prerequisites: [],
        difficulty: 'intermediate',
      ),
      GeminiModuleRecommendation(
        moduleId: 'confidence_building',
        moduleTitle: 'Confidence Building',
        description:
            'Develop pre-shot visualization routines to boost confidence on the tee',
        priority: 'medium',
        estimatedDuration: 5,
        learningStyle: 'confidence',
        expectedOutcome: 'Enhanced self-belief and shot confidence',
        prerequisites: [],
        difficulty: 'beginner',
      ),
      GeminiModuleRecommendation(
        moduleId: 'emotional_control',
        moduleTitle: 'Emotional Control',
        description:
            'Learn techniques to manage frustration and maintain composure after bad shots',
        priority: 'medium',
        estimatedDuration: 7,
        learningStyle: 'control',
        expectedOutcome: 'Better emotional regulation on the course',
        prerequisites: [],
        difficulty: 'intermediate',
      ),
    ];
  }

  /// Build today's module card with enhanced functionality
  Widget _buildTodayModuleCard(
      FlutterFlowTheme theme, GeminiModuleRecommendation module) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.aiPrimary.withValues(alpha: 0.15),
            theme.aiSecondary.withValues(alpha: 0.08),
            theme.success.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.aiPrimary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.aiPrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPillarColor(theme, module.learningStyle),
                      _getPillarColor(theme, module.learningStyle)
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getPillarColor(theme, module.learningStyle)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getPillarIcon(module.learningStyle),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: theme.aiPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI RECOMMENDED',
                          style: theme.bodySmall.copyWith(
                            color: theme.aiPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.moduleTitle,
                      style: theme.titleLarge.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${module.estimatedDuration} minutes',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 14,
                          color: _getDifficultyColor(theme, module.difficulty),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          module.difficulty.toUpperCase(),
                          style: theme.bodySmall.copyWith(
                            color:
                                _getDifficultyColor(theme, module.difficulty),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description with highlight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.glassBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.glassBorder.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              module.description,
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _startTrainingSessionFromRecommendation(module),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.aiPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shadowColor: theme.aiPrimary.withValues(alpha: 0.3),
                  ),
                  icon: Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    'Start Training',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => _showModulePreview(module),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary.withValues(alpha: 0.1),
                    foregroundColor: theme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Icon(Icons.visibility_outlined, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build default today recommendation
  Widget _buildDefaultTodayRecommendation(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: theme.aiPrimary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Complete your VARK assessment',
            style: theme.titleMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get personalized daily recommendations based on your learning style',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.pushNamed('ai_assessment');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.aiPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text('Take Assessment'),
          ),
        ],
      ),
    );
  }

  /// Get user sessions stream
  Stream<List<MentalSessionsRecord>> _getUserSessionsStream() {
    if (currentUser == null) return Stream.value([]);

    return MentalSessionsRecord.collection
        .where('userId', isEqualTo: currentUserUid)
        .orderBy('dateCompleted', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentalSessionsRecord.fromSnapshot(doc))
            .toList());
  }

  /// Get recent sessions stream
  Stream<List<MentalSessionsRecord>> _getRecentSessionsStream() {
    if (currentUser == null) return Stream.value([]);

    return MentalSessionsRecord.collection
        .where('userId', isEqualTo: currentUserUid)
        .orderBy('dateCompleted', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentalSessionsRecord.fromSnapshot(doc))
            .toList());
  }

  /// Get MindCoach sessions stream
  Stream<List<MindcoachSessionsRecord>> _getMindcoachSessionsStream() {
    if (currentUser == null) return Stream.value([]);

    // Use new service for streaming, but convert to MindcoachSessionsRecord for compatibility
    return _sessionService
        .streamUserSessions(
      userId: currentUserUid!,
      limit: 50,
    )
        .asyncMap((sessions) async {
      // Convert MindCoachSession to MindcoachSessionsRecord for UI compatibility
      // This maintains backward compatibility while using new service
      return sessions.map((session) {
        // Create a temporary record from the session data
        final data = session.toFirestoreMap();
        return MindcoachSessionsRecord.getDocumentFromData(
          data,
          FirebaseFirestore.instance
              .collection('mindcoach_sessions')
              .doc(session.sessionId),
        );
      }).toList();
    });
  }

  /// Get recent MindCoach sessions stream
  Stream<List<MindcoachSessionsRecord>> _getRecentMindcoachSessionsStream() {
    if (currentUser == null) return Stream.value([]);

    return _sessionService
        .streamUserSessions(
      userId: currentUserUid!,
      limit: 20,
    )
        .asyncMap((sessions) async {
      return sessions.map((session) {
        final data = session.toFirestoreMap();
        return MindcoachSessionsRecord.getDocumentFromData(
          data,
          FirebaseFirestore.instance
              .collection('mindcoach_sessions')
              .doc(session.sessionId),
        );
      }).toList();
    });
  }

  /// Create a new MindCoach session using the new service
  /// This method integrates content selection and scenario detection
  Future<String?> createMindCoachSession({
    required String templateId,
    required int mindsetBefore,
    String? userMessage,
    Map<String, dynamic>? context,
    String? varkMode,
    String? level,
    String? length,
  }) async {
    if (currentUser == null) return null;

    try {
      // Detect scenarios from user input and context
      final scenarioTags = await _scenarioDetector.detectScenarios(
        userMessage: userMessage,
        context: context,
        mindsetRating: mindsetBefore,
      );

      // Get user's VARK preference if not provided
      final userDoc = await UserRecord.collection.doc(currentUserUid).get();
      final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

      // Determine dominant VARK style from user preferences
      String determineVarkMode(VarkPreferencesStruct? prefs) {
        if (prefs == null) return 'ReadWrite';
        if (prefs.visual) return 'Visual';
        if (prefs.aural) return 'Aural';
        if (prefs.readWrite) return 'ReadWrite';
        if (prefs.kinesthetic) return 'Kinesthetic';
        return 'ReadWrite'; // Default
      }

      final userVarkMode = varkMode ?? determineVarkMode(user?.varkPreferences);

      // Select content from library
      final content = await _contentSelector.selectContent(
        templateId: templateId,
        varkMode: userVarkMode,
        level: level ?? 'Foundation',
        length: length ?? 'standard',
        scenarioTags: scenarioTags.isNotEmpty ? scenarioTags : null,
      );

      if (content == null) {
        throw Exception('No content found for template: $templateId');
      }

      // Create session
      final session = MindCoachSession(
        sessionId: '', // Will be generated by service
        userId: currentUserUid!,
        timestamp: DateTime.now(),
        templateId: templateId,
        contentId: content.contentId,
        scenarioTag: scenarioTags.isNotEmpty ? scenarioTags.first : null,
        varkMode: userVarkMode,
        level: level ?? 'Foundation',
        length: length ?? 'standard',
        cueUsed: '', // Will be set based on template
        routineType: '', // Will be set based on template
        mindsetBefore: mindsetBefore,
        context: context ?? {},
        coachingTextDelivered: content.scriptText,
        followUpQuestion: content.followUpPrompt,
        successSignals: _sessionService.calculateSuccessSignals(
          mindsetBefore: mindsetBefore,
          sessionCompleted: false,
        ),
      );

      final sessionId = await _sessionService.createSession(session);
      return sessionId;
    } catch (e) {
      print('Error creating MindCoach session: $e');
      return null;
    }
  }

  /// Build dynamic mental performance overview
  Widget _buildDynamicMentalPerformanceOverview(
      FlutterFlowTheme theme, UserRecord? user) {
    // Calculate MPI based on user data
    final mpi = _calculateMPI(user);
    final mpiColor = _getMPIColor(theme, mpi);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  mpiColor,
                  mpiColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                mpi.toString(),
                style: theme.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mental Performance Index',
            style: theme.titleMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getMPIDescription(mpi),
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMPIComponent(theme, 'Focus', _calculateFocusScore(user),
                  theme.mentalFocus),
              _buildMPIComponent(theme, 'Confidence',
                  _calculateConfidenceScore(user), theme.mentalStrength),
              _buildMPIComponent(theme, 'Control', _calculateControlScore(user),
                  theme.mentalCalm),
            ],
          ),
        ],
      ),
    );
  }

  /// Build MPI component
  Widget _buildMPIComponent(
      FlutterFlowTheme theme, String title, int score, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              score.toString(),
              style: theme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  /// Calculate MPI
  int _calculateMPI(UserRecord? user) {
    if (user == null) return 65; // Default for new users

    // This would be calculated based on user's session data, golf performance, etc.
    // For now, return a mock calculation
    final focusScore = _calculateFocusScore(user);
    final confidenceScore = _calculateConfidenceScore(user);
    final controlScore = _calculateControlScore(user);

    return ((focusScore + confidenceScore + controlScore) / 3).round();
  }

  /// Calculate focus score
  int _calculateFocusScore(UserRecord? user) {
    // Mock calculation - would be based on actual session data
    return 75;
  }

  /// Calculate confidence score
  int _calculateConfidenceScore(UserRecord? user) {
    // Mock calculation - would be based on actual session data
    return 82;
  }

  /// Calculate control score
  int _calculateControlScore(UserRecord? user) {
    // Mock calculation - would be based on actual session data
    return 68;
  }

  /// Get MPI color
  Color _getMPIColor(FlutterFlowTheme theme, int mpi) {
    if (mpi >= 85) return theme.performanceExcellent;
    if (mpi >= 70) return theme.performanceGood;
    if (mpi >= 55) return theme.performanceAverage;
    return theme.performancePoor;
  }

  /// Get MPI description
  String _getMPIDescription(int mpi) {
    if (mpi >= 85) return 'Excellent mental performance! You\'re in the zone.';
    if (mpi >= 70) return 'Good mental game. Keep building consistency.';
    if (mpi >= 55) return 'Developing well. Focus on weak areas.';
    return 'Building foundation. Great potential ahead!';
  }

  /// Build dynamic learning progress
  Widget _buildDynamicLearningProgress(
      FlutterFlowTheme theme, List<MentalSessionsRecord> sessions) {
    final completedModules = sessions.length;
    final totalModules = 24; // This would come from the modules collection
    final progressPercentage =
        (completedModules / totalModules * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.success,
                      theme.success.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '${progressPercentage.toInt()}%',
                    style: theme.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modules Completed: $completedModules/$totalModules',
                      style: theme.titleMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progressPercentage / 100,
                      backgroundColor: theme.alternate,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _getProgressMessage(completedModules, totalModules),
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'Start your first module to begin tracking progress',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Get progress message
  String _getProgressMessage(int completed, int total) {
    final percentage = (completed / total * 100).round();
    if (percentage >= 75)
      return 'Outstanding progress! You\'re mastering the mental game.';
    if (percentage >= 50)
      return 'Great momentum! Keep building your mental skills.';
    if (percentage >= 25)
      return 'Good start! You\'re developing strong foundations.';
    return 'Just getting started. Every session builds strength!';
  }

  /// Build dynamic achievements
  Widget _buildDynamicAchievements(
      FlutterFlowTheme theme, List<MentalSessionsRecord> sessions) {
    final achievements = _calculateAchievements(sessions);
    final completedSessions = sessions.where((s) => s.isCompleted).length;

    // Generate AI phrase
    String aiPhrase = '';
    if (completedSessions >= 25) {
      aiPhrase = 'Mental mastery achieved! Outstanding dedication.';
    } else if (completedSessions >= 10) {
      aiPhrase = 'Momentum unlocked. Your consistency is paying off.';
    } else if (completedSessions >= 5) {
      aiPhrase = 'Consistency building. Great progress!';
    } else if (completedSessions >= 1) {
      aiPhrase = 'Great start! Your mental game journey begins.';
    }

    if (achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events,
              size: 48,
              color: theme.warning.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              completedSessions == 0 ? 'No achievements yet' : 'Great start!',
              style: theme.titleMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              completedSessions == 0
                  ? 'Complete your first session to earn achievements'
                  : 'Keep training to unlock more milestones',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (aiPhrase.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.aiPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.aiPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: theme.aiPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiPhrase,
                        style: theme.bodySmall.copyWith(
                          color: theme.primaryText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: achievements
          .map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAchievementCard(theme, achievement),
            ),
          )
          .toList(),
    );
  }

  /// Calculate achievements
  List<Achievement> _calculateAchievements(
      List<MentalSessionsRecord> sessions) {
    final achievements = <Achievement>[];

    if (sessions.isNotEmpty) {
      achievements.add(Achievement(
        title: 'First Steps',
        description: 'Completed your first mental training session',
        icon: Icons.play_arrow,
        color: FlutterFlowTheme.of(context).success,
        earnedDate: sessions.last.dateCompleted,
      ));
    }

    if (sessions.length >= 5) {
      achievements.add(Achievement(
        title: 'Consistent Learner',
        description: 'Completed 5 mental training sessions',
        icon: Icons.trending_up,
        color: FlutterFlowTheme.of(context).primary,
        earnedDate: sessions.isNotEmpty ? sessions.last.dateCompleted : null,
      ));
    }

    if (sessions.length >= 10) {
      achievements.add(Achievement(
        title: 'Mental Athlete',
        description: 'Completed 10 mental training sessions',
        icon: Icons.psychology,
        color: FlutterFlowTheme.of(context).warning,
        earnedDate: sessions.isNotEmpty ? sessions.last.dateCompleted : null,
      ));
    }

    return achievements;
  }

  /// Build achievement card
  Widget _buildAchievementCard(
      FlutterFlowTheme theme, Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            achievement.color.withValues(alpha: 0.1),
            achievement.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  achievement.description,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (achievement.earnedDate != null)
            Text(
              _formatAchievementDate(achievement.earnedDate!),
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  /// Format achievement date
  String _formatAchievementDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).round()}w ago';
    return '${(difference / 30).round()}mo ago';
  }

  /// Build dynamic recent sessions
  Widget _buildDynamicRecentSessions(
      FlutterFlowTheme theme, List<MentalSessionsRecord> sessions) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: theme.secondaryText.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent sessions',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Create a sample module and start session
                final sampleModule = GeminiModuleRecommendation(
                  moduleId: 'intro_focus',
                  moduleTitle: 'Introduction to Mental Focus',
                  description: 'Learn the fundamentals of mental focus in golf',
                  priority: 'high',
                  estimatedDuration: 6,
                  learningStyle: 'focus',
                  expectedOutcome: 'Improved concentration',
                  prerequisites: [],
                  difficulty: 'beginner',
                );
                // For demo purposes, just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Demo session started: ${sampleModule.moduleTitle}'),
                    backgroundColor: FlutterFlowTheme.of(context).success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Start First Session'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: sessions
          .map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecentSessionCard(theme, session),
            ),
          )
          .toList(),
    );
  }

  /// Build recent session card
  Widget _buildRecentSessionCard(
      FlutterFlowTheme theme, MentalSessionsRecord session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.psychology,
              color: theme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.moduleTitle,
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.dateCompleted != null
                      ? _formatSessionDate(session.dateCompleted!)
                      : 'Recent session',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Completed',
              style: theme.bodySmall.copyWith(
                color: theme.success,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format session date
  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Start a training session from AI recommendation
  Future<void> _startTrainingSessionFromRecommendation(
      GeminiModuleRecommendation module) async {
    bool dialogShown = false;
    try {
      final theme = FlutterFlowTheme.of(context);

      // Validate user has completed all required experience
      final userDoc = await UserRecord.collection.doc(currentUserUid).get();
      final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please complete your profile first'),
              backgroundColor: theme.error,
            ),
          );
        }
        return;
      }

      // Check if VARK assessment is completed
      final varkPrefs = user.varkPreferences;
      final hasVarkCompleted = varkPrefs != null &&
          (varkPrefs.visual ||
              varkPrefs.aural ||
              varkPrefs.readWrite ||
              varkPrefs.kinesthetic);
      if (!hasVarkCompleted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Complete Your Assessment'),
              content: Text(
                'Please complete the VARK learning style assessment to get personalized training recommendations. This helps us tailor your experience.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to AI-generated assessment page
                    context.pushNamed('ai_assessment');
                  },
                  child: Text('Take Assessment'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show enhanced loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: theme.glassBackground,
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: theme.aiGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Preparing Your Session',
                    style: theme.titleMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Setting up ${module.moduleTitle}...',
                    style: theme.bodyMedium.copyWith(
                      color: theme.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personalizing based on your learning style',
                    style: theme.bodySmall.copyWith(
                      color: theme.aiPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
        dialogShown = true;
      }

      // Simulate AI-powered session preparation
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Safely close loading dialog
        if (dialogShown && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          dialogShown = false;
        }

        // Get user's adaptive mode preference
        final userDoc = await UserRecord.collection.doc(currentUserUid).get();
        final user = userDoc.exists ? UserRecord.fromSnapshot(userDoc) : null;
        final adaptiveMode = user?.currentAdaptiveMode ?? 'AI-Reactive';

        // Create a comprehensive mental session record
        await MentalSessionsRecord.collection.add({
          'userId': currentUserUid,
          'moduleTitle': module.moduleTitle,
          'moduleId': module.moduleId,
          'sessionType': 'ai_recommended_training',
          'dateStarted': FieldValue.serverTimestamp(),
          'isCompleted': false,
          'pillar': module.learningStyle,
          'estimatedDuration': module.estimatedDuration,
          'difficulty': module.difficulty,
          'priority': module.priority,
          'expectedOutcome': module.expectedOutcome,
          'aiGenerated': true,
          'sessionSource': 'daily_recommendation',
          'adaptiveMode': adaptiveMode,
          'rebalanceTriggered': false,
        });

        // Enhanced success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.1)
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rocket_launch,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Training Session Launched!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${module.moduleTitle} • ${module.estimatedDuration} min • ${module.priority.toUpperCase()} priority',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: theme.success,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate to virtual training experience page
        context.pushNamed(
          'virtual_training_experience',
          extra: {
            'moduleTitle': module.moduleTitle,
            'moduleId': module.moduleId,
            'description': module.expectedOutcome,
            'estimatedDuration': module.estimatedDuration,
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting training session: $e');
      }
      if (mounted) {
        // Safely close loading dialog if it was shown
        if (dialogShown && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Failed to Start Session',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Please check your connection and try again',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: FlutterFlowTheme.of(context).error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    }
  }

  /// Show module preview modal
  void _showModulePreview(GeminiModuleRecommendation module) {
    final theme = FlutterFlowTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.glassBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.alternate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getPillarColor(theme, module.learningStyle),
                              _getPillarColor(theme, module.learningStyle)
                                  .withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getPillarIcon(module.learningStyle),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.moduleTitle,
                              style: theme.titleLarge.copyWith(
                                color: theme.primaryText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${module.learningStyle.toUpperCase()} • ${module.estimatedDuration} MIN',
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.glassBackground.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.glassBorder.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      module.description,
                      style: theme.bodyMedium.copyWith(
                        color: theme.primaryText,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Expected Outcome
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.success.withValues(alpha: 0.1),
                          theme.success.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              color: theme.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expected Outcome',
                              style: theme.titleSmall.copyWith(
                                color: theme.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          module.expectedOutcome,
                          style: theme.bodyMedium.copyWith(
                            color: theme.primaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Action button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _startTrainingSessionFromRecommendation(module);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.aiPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: theme.aiPrimary.withValues(alpha: 0.3),
                  ),
                  icon: Icon(Icons.play_arrow_rounded, size: 24),
                  label: Text(
                    'Start Training Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // STUDIO TAB HELPER METHODS
  // ============================================================================

  /// Section 1: Training Streak
  Widget _buildTrainingStreakSection(FlutterFlowTheme theme) {
    return FutureBuilder<WeeklyProgress>(
      future: currentUserUid.isNotEmpty
          ? _streakService.getWeeklyProgress(currentUserUid)
          : Future.value(
              WeeklyProgress(completed: 0, percentage: 0.0, currentStreak: 0)),
      builder: (context, progressSnapshot) {
        final progress = progressSnapshot.data ??
            WeeklyProgress(
              completed: 0,
              percentage: 0.0,
              currentStreak: 0,
            );

        return FutureBuilder<MentalSessionsRecord?>(
          future: currentUserUid.isNotEmpty
              ? _streakService.getNextIncompleteSession(currentUserUid)
              : Future.value(null),
          builder: (context, sessionSnapshot) {
            return GlassDashboardCard(
              title: 'Training Streak',
              subtitle: '${progress.currentStreak} days in a row',
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primary.withValues(alpha: 0.1),
                        theme.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: theme.warning,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${progress.currentStreak} days in a row',
                                        style: theme.titleMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${progress.completed} of ${progress.target} sessions complete',
                                  style: theme.bodyMedium.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Circular progress ring
                          GlassProgressRing(
                            progress: progress.percentage / 100,
                            size: 100,
                            color: theme.primary,
                            centerWidget: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${progress.completed}',
                                  style: theme.titleLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.primary,
                                  ),
                                ),
                                Text(
                                  '/${progress.target}',
                                  style: theme.bodySmall.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Check for incomplete MindCoach session first
                            final mindCoachSessionService =
                                MindCoachSessionService.instance;
                            final incompleteMindCoachSession = currentUserUid
                                    .isNotEmpty
                                ? await mindCoachSessionService
                                    .getNextIncompleteSession(currentUserUid)
                                : null;

                            if (incompleteMindCoachSession != null) {
                              // Show MindCoach AI session widget to resume with premium glassmorphic modal
                              if (mounted) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  barrierColor:
                                      Colors.black.withValues(alpha: 0.6),
                                  enableDrag: true,
                                  isDismissible: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(28),
                                    ),
                                  ),
                                  builder: (context) => ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(28),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 20, sigmaY: 20),
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.92,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              theme.primaryBackground,
                                              theme.primaryBackground
                                                  .withValues(alpha: 0.98),
                                            ],
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(28),
                                          ),
                                          border: Border(
                                            top: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Content
                                            MindCoachAISessionWidget(
                                              existingSession:
                                                  incompleteMindCoachSession,
                                            ),
                                            // Drag handle
                                            Positioned(
                                              top: 12,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Container(
                                                  width: 40,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } else if (sessionSnapshot.hasData &&
                                sessionSnapshot.data != null) {
                              // Navigate to incomplete MentalSessionsRecord session
                              _tabController
                                  .animateTo(2); // Navigate to Train tab
                            } else {
                              // No incomplete sessions, navigate to Train tab to start new
                              _tabController.animateTo(2);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            'Continue Training',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Section 2: AI Insights
  Widget _buildAIInsightsSection(FlutterFlowTheme theme) {
    return FutureBuilder<List<MindCoachInsight>>(
      future: currentUserUid.isNotEmpty
          ? _mindCoachAnalysis.generatePersonalizedSuggestions(currentUserUid)
          : Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GlassDashboardCard(
            title: 'AI Insights',
            subtitle: 'Analyzing your data...',
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                  ),
                ),
              ),
            ],
          );
        }

        final insights = snapshot.data ?? [];
        String insightText =
            'Keep up the great work with your mental training!';

        if (insights.isNotEmpty) {
          insightText = insights.first.insightText;
        }

        return GlassDashboardCard(
          title: 'AI Insights',
          subtitle: 'Personalized coaching based on your performance',
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.aiPrimary.withValues(alpha: 0.1),
                    theme.aiSecondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.aiPrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: theme.aiGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insightText,
                          style: theme.bodyMedium.copyWith(
                            color: theme.primaryText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (insights.isNotEmpty &&
                            insights.first.recommendedModuleId != null) {
                          // Fetch and navigate to recommended module
                          final recommendedModuleId =
                              insights.first.recommendedModuleId!;
                          try {
                            final moduleQuerySnapshot =
                                await CoachingModulesRecord.collection
                                    .where('moduleId',
                                        isEqualTo: recommendedModuleId)
                                    .limit(1)
                                    .get();

                            if (moduleQuerySnapshot.docs.isNotEmpty &&
                                mounted) {
                              final module = CoachingModulesRecord.fromSnapshot(
                                moduleQuerySnapshot.docs.first,
                              );

                              context.pushNamed(
                                'virtual_training_experience',
                                extra: <String, dynamic>{
                                  'moduleTitle': module.title,
                                  'moduleId': module.moduleId,
                                  'description': module.description,
                                  'estimatedDuration': module.duration,
                                },
                              );
                            } else {
                              // Module not found, fallback to Train tab
                              _tabController.animateTo(2);
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print(
                                  'Error navigating to recommended module: $e');
                            }
                            // Fallback to Train tab on error
                            _tabController.animateTo(2);
                          }
                        } else {
                          _tabController.animateTo(2); // Navigate to Train tab
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.aiPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Continue Training'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Section 3: Your Mind in Balance
  Widget _buildMindInBalanceSection(FlutterFlowTheme theme) {
    return FutureBuilder<Map<String, PillarStatus>>(
      future: currentUserUid.isNotEmpty
          ? _balanceService.analyzePillarBalance(currentUserUid)
          : Future.value({
              'focus': PillarStatus(
                pillar: 'focus',
                status: 'getting_sharper',
                score: 50.0,
                trend: 0.0,
              ),
              'confidence': PillarStatus(
                pillar: 'confidence',
                status: 'getting_sharper',
                score: 50.0,
                trend: 0.0,
              ),
              'control': PillarStatus(
                pillar: 'control',
                status: 'getting_sharper',
                score: 50.0,
                trend: 0.0,
              ),
            }),
      builder: (context, snapshot) {
        final balance = snapshot.data ??
            {
              'focus': PillarStatus(
                pillar: 'focus',
                status: 'getting_sharper',
                score: 50.0,
                trend: 0.0,
              ),
              'confidence': PillarStatus(
                pillar: 'confidence',
                status: 'getting_sharper',
                score: 50.0,
                trend: 0.0,
              ),
              'control': PillarStatus(
                pillar: 'control',
                status: 'getting_sharper',
                score: 50.0,
                trend: 0.0,
              ),
            };

        return GlassDashboardCard(
          title: 'Your Mind in Balance',
          subtitle: 'Current state across all three pillars',
          children: [
            Column(
              children: [
                _buildPillarBalanceItemNew(
                  theme,
                  'Focus',
                  balance['focus']!,
                  theme.mentalFocus,
                ),
                const SizedBox(height: 12),
                _buildPillarBalanceItemNew(
                  theme,
                  'Confidence',
                  balance['confidence']!,
                  theme.mentalStrength,
                ),
                const SizedBox(height: 12),
                _buildPillarBalanceItemNew(
                  theme,
                  'Control',
                  balance['control']!,
                  theme.mentalCalm,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build individual pillar balance item (updated)
  Widget _buildPillarBalanceItemNew(
    FlutterFlowTheme theme,
    String pillar,
    PillarStatus status,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPillarIcon(pillar.toLowerCase()),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pillar,
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  status.statusMessage,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section 4: Recent Training Sessions
  Widget _buildRecentTrainingSessionsSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Recent Training Sessions',
      subtitle: 'Every session builds the foundation for what\'s next',
      children: [
        StreamBuilder<List<MentalSessionsRecord>>(
          stream: _getRecentSessionsStream(),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: theme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent sessions',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: sessions.take(3).map((session) {
                final progress = session.progressPercentage;
                final isCompleted =
                    session.isCompleted && session.dateCompleted != null;
                final daysAgo = isCompleted && session.dateCompleted != null
                    ? DateTime.now().difference(session.dateCompleted!).inDays
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.glassBackground.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.glassBorder.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.moduleTitle,
                                style: theme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isCompleted && daysAgo != null)
                                Text(
                                  'Completed ${daysAgo} ${daysAgo == 1 ? 'day' : 'days'} ago',
                                  style: theme.bodySmall.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                )
                              else if (progress > 0)
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.alternate
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progress / 100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.success,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${progress.toInt()}% done',
                                      style: theme.bodySmall.copyWith(
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  'In progress',
                                  style: theme.bodySmall.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Section 5: Recommended Next Steps
  Widget _buildRecommendedNextStepsSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Recommended Next Steps',
      subtitle: 'Smart guidance to keep your journey moving forward',
      children: [
        Column(
          children: [
            _buildNextStepCard(
              theme,
              'Library',
              'Learn new routines and drills',
              Icons.library_books,
              theme.primary,
              () => _tabController.animateTo(1),
            ),
            const SizedBox(height: 12),
            _buildNextStepCard(
              theme,
              'Training',
              'Do your next guided session',
              Icons.play_circle_filled,
              theme.success,
              () => _tabController.animateTo(2),
            ),
            const SizedBox(height: 12),
            _buildNextStepCard(
              theme,
              'Progress',
              'Review your growth and patterns',
              Icons.trending_up,
              theme.warning,
              () => _tabController.animateTo(3),
            ),
          ],
        ),
      ],
    );
  }

  /// Build next step card
  Widget _buildNextStepCard(
    FlutterFlowTheme theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Build personalized greeting section (deprecated - kept for reference)
  Widget _buildPersonalizedGreeting(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: currentUser != null ? _userRecordStream : null,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final displayName = user?.displayName ?? 'Golfer';
        final now = DateTime.now();
        final hour = now.hour;
        String greeting;
        if (hour < 12) {
          greeting = 'Good morning';
        } else if (hour < 17) {
          greeting = 'Good afternoon';
        } else {
          greeting = 'Good evening';
        }

        return GlassDashboardCard(
          title: '$greeting, $displayName',
          subtitle: 'Ready to strengthen your mind?',
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withValues(alpha: 0.1),
                    theme.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primary, theme.secondary],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your mental game journey continues today',
                          style: theme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Updates daily based on your progress',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build MindCoach Journey section
  Widget _buildMindCoachJourney(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: currentUser != null ? _userRecordStream : null,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final streak = user?.coachingStreak ?? 0;

        // Calculate sessions this week
        return StreamBuilder<List<MentalSessionsRecord>>(
          stream: _getUserSessionsStream(),
          builder: (context, sessionsSnapshot) {
            final sessions = sessionsSnapshot.data ?? [];
            final now = DateTime.now();
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final thisWeekSessions = sessions.where((s) {
              if (s.dateCompleted == null) return false;
              return s.dateCompleted!.isAfter(weekStart);
            }).length;

            // Determine current pillar being worked on
            String currentPillar = 'Confidence';
            if (sessions.isNotEmpty) {
              final lastSession = sessions.first;
              currentPillar = lastSession.pillar.isNotEmpty
                  ? lastSession.pillar
                  : 'Confidence';
            }

            return GlassDashboardCard(
              title: 'Your MindCoach Journey',
              subtitle: 'Strengthening the mindset behind your game',
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getPillarColor(theme, currentPillar.toLowerCase())
                            .withValues(alpha: 0.1),
                        _getPillarColor(theme, currentPillar.toLowerCase())
                            .withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getPillarColor(theme, currentPillar.toLowerCase())
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Working on: $currentPillar',
                                  style: theme.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 20,
                                      color: theme.warning,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Training streak: $streak days',
                                      style: theme.bodyMedium.copyWith(
                                        color: theme.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Circular progress ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: thisWeekSessions / 7,
                                  strokeWidth: 8,
                                  backgroundColor:
                                      theme.alternate.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getPillarColor(
                                        theme, currentPillar.toLowerCase()),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '$thisWeekSessions',
                                    style: theme.titleLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                  Text(
                                    '/7',
                                    style: theme.bodySmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _tabController.animateTo(2); // Switch to Train tab
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getPillarColor(
                                theme, currentPillar.toLowerCase()),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            'Continue Training',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Build Studio Training Section (deprecated - kept for reference)
  Widget _buildStudioTrainingSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: '🎯 Training',
      subtitle: 'Start your personalized mental training session',
      children: [
        StreamBuilder<GeminiRecommendationResponse?>(
          stream: _getTodayRecommendationStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                ),
              );
            }

            final recommendation = snapshot.data;
            final hasRecommendation = recommendation != null &&
                recommendation.recommendations.isNotEmpty;

            if (!hasRecommendation) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: theme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No training session available',
                      style: theme.titleMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile to get personalized training recommendations',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _refreshAIRecommendations();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.aiPrimary,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Generate Training Plan'),
                    ),
                  ],
                ),
              );
            }

            final session = recommendation!.recommendations.first;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.success.withValues(alpha: 0.1),
                    theme.success.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.success.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.play_circle_filled,
                          color: theme.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.moduleTitle,
                              style: theme.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.description ??
                                  'Personalized training session',
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _startTrainingSessionFromRecommendation(session),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        'Start Training Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build Mind in Balance section (deprecated - kept for reference)
  Widget _buildMindInBalance(FlutterFlowTheme theme) {
    // This method is deprecated - use _buildMindInBalanceSection instead
    return _buildMindInBalanceSection(theme);
  }

  /// Build individual pillar balance item (deprecated - kept for reference)
  Widget _buildPillarBalanceItem(
    FlutterFlowTheme theme,
    String pillar,
    String status,
    int sessionCount,
    Color color,
  ) {
    // This method is deprecated - use the new version with PillarStatus
    // Creating a temporary PillarStatus for compatibility
    final pillarStatus = PillarStatus(
      pillar: pillar.toLowerCase(),
      status: status.toLowerCase().contains('strongest')
          ? 'strongest_area'
          : status.toLowerCase().contains('attention')
              ? 'needs_attention'
              : 'getting_sharper',
      score: 50.0,
      trend: 0.0,
    );
    return _buildPillarBalanceItemNew(theme, pillar, pillarStatus, color);
  }

  /// Build Recent Training Sessions section
  Widget _buildRecentTrainingSessions(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Recent Training Sessions',
      subtitle: 'Your latest mental training activities',
      children: [
        StreamBuilder<List<MentalSessionsRecord>>(
          stream: _getRecentSessionsStream(),
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: theme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recent sessions',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: sessions.take(3).map((session) {
                final progress = session.progressPercentage;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.glassBackground.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.glassBorder.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.moduleTitle,
                                style: theme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (progress > 0)
                                    Container(
                                      width: 60,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.alternate
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progress / 100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.success,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (progress > 0) const SizedBox(width: 8),
                                  Text(
                                    progress > 0
                                        ? '${progress.toInt()}%'
                                        : session.dateCompleted != null
                                            ? _formatSessionDate(
                                                session.dateCompleted!)
                                            : 'In progress',
                                    style: theme.bodySmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (session.dateCompleted != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatSessionDate(session.dateCompleted!),
                              style: theme.bodySmall.copyWith(
                                color: theme.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Build Recommended Next Steps section
  Widget _buildRecommendedNextSteps(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Recommended Next Steps',
      subtitle:
          'Personalized actions to accelerate your mental game development',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced header with progress indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.aiPrimary,
                                  theme.aiPrimary.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI-Powered Recommendations',
                            style: theme.bodySmall.copyWith(
                              color: theme.aiPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on your recent activity and performance patterns',
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Enhanced next step cards - Column layout
            Column(
              children: [
                _buildEnhancedNextStepCard(
                  theme,
                  'Explore Library',
                  'Discover new mental training modules',
                  '12+ modules available',
                  Icons.library_books,
                  theme.primary,
                  () => _tabController.animateTo(1),
                  badge: 'New',
                ),
                const SizedBox(height: 12),
                _buildEnhancedNextStepCard(
                  theme,
                  'Start Training',
                  'Begin your next guided session',
                  'Recommended for you',
                  Icons.play_circle_filled,
                  theme.success,
                  () => _tabController.animateTo(2),
                  badge: 'Hot',
                ),
                const SizedBox(height: 12),
                _buildEnhancedNextStepCard(
                  theme,
                  'Track Progress',
                  'Review your mental game journey',
                  'See improvements',
                  Icons.trending_up,
                  theme.warning,
                  () => _tabController.animateTo(3),
                  badge: null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Additional quick action button
            GestureDetector(
              onTap: () async {
                await _refreshAIRecommendations();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.aiPrimary.withValues(alpha: 0.1),
                      theme.aiPrimary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.aiPrimary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.aiPrimary,
                            theme.aiPrimary.withValues(alpha: 0.8)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get Personalized AI Insights',
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Receive tailored recommendations based on your progress',
                            style: theme.bodySmall.copyWith(
                              color: theme.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: theme.aiPrimary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build enhanced next step card
  Widget _buildEnhancedNextStepCard(
    FlutterFlowTheme theme,
    String title,
    String subtitle,
    String info,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: theme.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: theme.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle
            Text(
              subtitle,
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Info badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    info,
                    style: theme.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Arrow indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: color,
                    size: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement model
class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime? earnedDate;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.earnedDate,
  });
}
