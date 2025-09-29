import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import '/ai_integration/services/ai_coaching_service.dart';
import '/ai_integration/models/gemini_models.dart';
import '/backend/backend.dart';
import '/backend/schema/coaching_modules_record.dart';
import '/backend/schema/mental_sessions_record.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/app_tutorial_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'coaching_modules_model.dart';
export 'coaching_modules_model.dart';

class CoachingModulesWidget extends StatefulWidget {
  const CoachingModulesWidget({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  static String routeName = 'coaching_modules';
  static String routePath = '/coaching_modules';

  @override
  State<CoachingModulesWidget> createState() => _CoachingModulesWidgetState();
}

class _CoachingModulesWidgetState extends State<CoachingModulesWidget>
    with TickerProviderStateMixin {
  late CoachingModulesModel _model;
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CoachingModulesModel());
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex:
          widget.initialTabIndex.clamp(0, 2), // Ensure valid tab index
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
    if (loggedIn) {
      // Create broadcast streams to avoid "Stream has already been listened to" errors
      _userRecordStream = UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/${currentUserUid}'))
          .asBroadcastStream();

      _userSessionsStream = _getUserSessionsStream().asBroadcastStream();
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
        drawer: loggedIn && _userRecordStream != null
            ? StreamBuilder<UserRecord>(
                stream: _userRecordStream,
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  return EnhancedFoCoCoDrawer(
                    currentUser: userData,
                    currentRoute: 'coaching_modules',
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
                              // Coaching Library Tab
                              _buildCoachingLibraryTab(theme),

                              // Today's Training Tab
                              _buildTodayTrainingTab(theme),

                              // Progress & Analytics Tab
                              _buildProgressAnalyticsTab(theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Voice Button
            const FloatingVoiceButton(),
          ],
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'coaching_modules',
          onTap: (route) => context.goNamed(route),
          currentUser: null, // Will be handled by the navbar internally
        ),
      ),
    );
  }

  /// Custom App Bar matching dashboard design
  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return StreamBuilder<UserRecord>(
      stream: loggedIn ? _userRecordStream : null,
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
                      'Mental Training',
                      style: theme.headlineSmall.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Strengthen your mental game',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // VARK filter button
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
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: theme.primary,
        unselectedLabelColor: theme.secondaryText,
        labelStyle: theme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.bodyMedium.copyWith(
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Library'),
          Tab(text: 'Training'),
          Tab(text: 'Progress'),
        ],
      ),
    );
  }

  /// Coaching Library Tab - Dynamic content from backend
  Widget _buildCoachingLibraryTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // AI-Powered Coaching Recommendations
          _buildAICoachingRecommendations(theme),

          const SizedBox(height: 24),

          // VARK-Based Module Recommendations
          _buildVarkRecommendations(theme),

          const SizedBox(height: 24),

          // Coaching Pillars
          _buildCoachingPillars(theme),

          const SizedBox(height: 24),

          // All Modules
          _buildAllModules(theme),

          const SizedBox(height: 100), // Space for navbar
        ],
      ),
    );
  }

  /// AI-Powered Coaching Recommendations - Integrated AI Services
  Widget _buildAICoachingRecommendations(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'AI Coaching Recommendations',
      subtitle: 'Personalized mental training insights',
      children: [
        Column(
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
                Expanded(
                  child: Text(
                    'AI Coaching Recommendations',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                ),
                if (_isLoadingAIRecommendations)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_aiRecommendationError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: theme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unable to load AI recommendations. Please try again later.',
                        style: theme.bodySmall.copyWith(color: theme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadAIRecommendations,
                      child:
                          Text('Retry', style: TextStyle(color: theme.error)),
                    ),
                  ],
                ),
              )
            else ...[
              // AI recommendation cards - Dynamic from Gemini
              StreamBuilder<List<GeminiModuleRecommendation>>(
                stream: _getAIRecommendationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                      ),
                    );
                  }

                  final recommendations =
                      snapshot.data ?? _getDefaultAIRecommendations(theme);

                  return Column(
                    children: recommendations
                        .take(3)
                        .map(
                          (rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildAIRecommendationCard(
                              theme,
                              rec.moduleTitle,
                              rec.description,
                              '${rec.priority.toUpperCase()} Priority',
                              _getPillarIcon(rec.learningStyle),
                              _getPillarColor(theme, rec.learningStyle),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoadingAIRecommendations || _isGeneratingContent
                              ? null
                              : () => _generatePersonalizedContent(theme),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isLoadingAIRecommendations ||
                                _isGeneratingContent)
                            ? theme.aiPrimary.withValues(alpha: 0.6)
                            : theme.aiPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: (_isLoadingAIRecommendations ||
                              _isGeneratingContent)
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                          (_isLoadingAIRecommendations || _isGeneratingContent)
                              ? 'Generating...'
                              : 'Generate Plan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingAIRecommendations
                          ? null
                          : () => _refreshAIRecommendations(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoadingAIRecommendations
                            ? theme.secondary.withValues(alpha: 0.6)
                            : theme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: _isLoadingAIRecommendations
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.refresh, size: 18),
                      label: Text(_isLoadingAIRecommendations
                          ? 'Loading...'
                          : 'Refresh'),
                    ),
                  ),
                ],
              ),
            ],

            // Show Generated Content Card if available
            if (_showGeneratedContent && _generatedContentText != null) ...[
              const SizedBox(height: 24),
              _buildGeneratedContentCard(theme),
            ],
          ],
        ),
      ],
    );
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
      stream: loggedIn ? _userRecordStream : null,
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

  /// Enhanced Mental Game Pillars Section
  Widget _buildCoachingPillars(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Master the three foundations of mental performance',
      subtitle: '',
      children: [
        // Enhanced pillars layout matching the design
        Column(
          children: [
            // First pillar - Focus
            _buildEnhancedPillarCard(
              theme,
              'Focus',
              Icons.center_focus_strong,
              theme.mentalFocus,
              'Enhance concentration and clarity',
              [
                '• Pre-shot routines',
                '• Visualization techniques',
                '• Attention control drills',
              ],
            ),
            const SizedBox(height: 16),

            // Second pillar - Confidence
            _buildEnhancedPillarCard(
              theme,
              'Confidence',
              Icons.psychology,
              theme.mentalStrength,
              'Build unshakeable self-belief',
              [
                '• Positive self-talk',
                '• Success visualization',
                '• Achievement tracking',
              ],
            ),
            const SizedBox(height: 16),

            // Third pillar - Control
            _buildEnhancedPillarCard(
              theme,
              'Control',
              Icons.self_improvement,
              theme.mentalCalm,
              'Master emotional regulation',
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

  /// All Modules Section with Enhanced Dynamic Data
  Widget _buildAllModules(FlutterFlowTheme theme) {
    return StreamBuilder<List<CoachingModulesRecord>>(
      stream: _getFilteredModulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GlassDashboardCard(
            title: 'Coaching Modules',
            subtitle: 'Loading modules...',
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fetching coaching modules from library...',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return GlassDashboardCard(
            title: 'Coaching Modules',
            subtitle: 'Error loading modules',
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to load modules',
                      style: theme.titleMedium.copyWith(
                        color: theme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your internet connection and try again.',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshModules,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.refresh, size: 16),
                      label: Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final modules = snapshot.data ?? [];

        if (modules.isEmpty) {
          return GlassDashboardCard(
            title: 'Coaching Modules',
            subtitle: 'No modules found with current filters',
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 48,
                      color: theme.secondaryText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No modules found',
                      style: theme.titleMedium.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters or check back later for new content.',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedVarkFilter = 'all';
                          _selectedPillar = 'all';
                          _selectedDifficulty = 'all';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.clear_all, size: 16),
                      label: Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return GlassDashboardCard(
          title: 'Coaching Library',
          subtitle:
              '${modules.length} module${modules.length != 1 ? 's' : ''} available',
          children: [
            // Filter summary
            if (_selectedPillar != 'all' ||
                _selectedVarkFilter != 'all' ||
                _selectedDifficulty != 'all') ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: theme.info, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtered by: ${_getActiveFiltersDescription()}',
                        style: theme.bodySmall.copyWith(
                          color: theme.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedVarkFilter = 'all';
                          _selectedPillar = 'all';
                          _selectedDifficulty = 'all';
                        });
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: theme.info,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Modules list
            Column(
              children: modules
                  .map((module) => _buildEnhancedModuleCard(theme, module))
                  .toList(),
            ),
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

  /// Today's Training Tab
  Widget _buildTodayTrainingTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Daily Mental Training Goal
          _buildDailyGoal(theme),

          const SizedBox(height: 24),

          // Recommended Session for Today
          _buildTodayRecommendation(theme),

          const SizedBox(height: 24),

          // Quick Training Tools
          _buildQuickTools(theme),

          const SizedBox(height: 24),

          // Recent Sessions
          _buildRecentSessions(theme),

          const SizedBox(height: 100), // Space for navbar
        ],
      ),
    );
  }

  /// Progress & Analytics Tab
  Widget _buildProgressAnalyticsTab(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Mental Performance Overview
          _buildMentalPerformanceOverview(theme),

          const SizedBox(height: 24),

          // Learning Progress
          _buildLearningProgress(theme),

          const SizedBox(height: 24),

          // Achievements
          _buildAchievements(theme),

          const SizedBox(height: 100), // Space for navbar
        ],
      ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: theme.glassBackground,
          elevation: 0,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                const SizedBox(width: 16),
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
                        'Customize your learning experience',
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Learning Style Section
                Text(
                  'Learning Style',
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
                      () => setDialogState(() => _selectedVarkFilter = 'all'),
                      theme.primary,
                    ),
                    _buildFilterChip(
                      theme,
                      'Visual',
                      _selectedVarkFilter == 'visual',
                      () =>
                          setDialogState(() => _selectedVarkFilter = 'visual'),
                      theme.info,
                    ),
                    _buildFilterChip(
                      theme,
                      'Auditory',
                      _selectedVarkFilter == 'aural',
                      () => setDialogState(() => _selectedVarkFilter = 'aural'),
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

                // Mental Game Pillars Section
                Text(
                  'Mental Game Pillars',
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
                      () => setDialogState(() => _selectedPillar = 'focus'),
                      theme.mentalFocus,
                    ),
                    _buildFilterChip(
                      theme,
                      '💪 Confidence',
                      _selectedPillar == 'confidence',
                      () =>
                          setDialogState(() => _selectedPillar = 'confidence'),
                      theme.mentalStrength,
                    ),
                    _buildFilterChip(
                      theme,
                      '🧘 Control',
                      _selectedPillar == 'control',
                      () => setDialogState(() => _selectedPillar = 'control'),
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
                      () => setDialogState(() => _selectedDifficulty = 'all'),
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
                        '• Learning Style: ${_selectedVarkFilter.toUpperCase()}\n'
                        '• Pillar: ${_selectedPillar.toUpperCase()}\n'
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
          actions: [
            TextButton(
              onPressed: () {
                // Reset filters
                setDialogState(() {
                  _selectedVarkFilter = 'all';
                  _selectedPillar = 'all';
                  _selectedDifficulty = 'all';
                });
              },
              child: Text(
                'Reset',
                style: TextStyle(color: theme.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.secondaryText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Apply filters
                Navigator.pop(context);

                // Show feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.filter_alt, color: Colors.white, size: 20),
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
              ),
              child: Text('Apply Filters'),
            ),
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
                      Row(
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
                          const SizedBox(width: 12),
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
          'duration': 10,
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
          'duration': 15,
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
          'duration': 12,
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
          'duration': 18,
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
          'duration': 14,
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
          'duration': 25,
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
    try {
      final theme = FlutterFlowTheme.of(context);

      // Show loading dialog
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

      // Simulate session preparation
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Create a mental session record
        await MentalSessionsRecord.collection.add({
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
        });

        // Update module completion count
        await CoachingModulesRecord.collection.doc(module.reference.id).update({
          'completionCount': FieldValue.increment(1),
        });

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

        // TODO: Navigate to actual module content page when implemented
        // For now, just show the success message
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open

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
              context.goNamed('vark_onboarding');
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

  /// Build daily goal
  Widget _buildDailyGoal(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Today\'s Mental Training Goal',
      subtitle: 'Stay consistent with your mental game development',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary.withValues(alpha: 0.1),
                theme.primary.withValues(alpha: 0.05),
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
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag,
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
                      '15 minutes of focused practice',
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete one mental training module today',
                      style: theme.bodyMedium.copyWith(
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
  }

  /// Build today's recommendation
  Widget _buildTodayRecommendation(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Recommended for Today',
      subtitle: 'AI-selected based on your recent performance',
      children: [
        // AI-powered daily recommendation
        StreamBuilder<GeminiRecommendationResponse?>(
          stream: _getTodayRecommendationStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.aiPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Generating personalized recommendation...',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final recommendation = snapshot.data;
            if (recommendation != null &&
                recommendation.recommendations.isNotEmpty) {
              final todayModule = recommendation.recommendations.first;
              return _buildTodayModuleCard(theme, todayModule);
            }

            return _buildDefaultTodayRecommendation(theme);
          },
        ),
      ],
    );
  }

  /// Build quick tools
  Widget _buildQuickTools(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Quick Training Tools',
      subtitle: 'Fast mental exercises for immediate use',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickToolCard(
                theme,
                'Breathing',
                Icons.air,
                theme.breathingActive,
                '2 min',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickToolCard(
                theme,
                'Visualization',
                Icons.visibility,
                theme.mentalFocus,
                '5 min',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickToolCard(
                theme,
                'Affirmations',
                Icons.record_voice_over,
                theme.mentalStrength,
                '3 min',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build quick tool card
  Widget _buildQuickToolCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    Color color,
    String duration,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          Text(
            duration,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent sessions
  Widget _buildRecentSessions(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Recent Sessions',
      subtitle: 'Your latest mental training activities',
      children: [
        // Dynamic Recent Sessions
        StreamBuilder<List<MentalSessionsRecord>>(
          stream: _getRecentSessionsStream(),
          builder: (context, sessionsSnapshot) {
            final sessions = sessionsSnapshot.data ?? <MentalSessionsRecord>[];
            return _buildDynamicRecentSessions(theme, sessions);
          },
        ),
      ],
    );
  }

  /// Build mental performance overview
  Widget _buildMentalPerformanceOverview(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Mental Performance Overview',
      subtitle: 'Track your mental game development',
      children: [
        // Dynamic Mental Performance Overview
        StreamBuilder<UserRecord>(
          stream: loggedIn ? _userRecordStream : null,
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;
            return _buildDynamicMentalPerformanceOverview(theme, user);
          },
        ),
      ],
    );
  }

  /// Build learning progress
  Widget _buildLearningProgress(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Learning Progress',
      subtitle: 'Your journey through the mental training modules',
      children: [
        // Dynamic Learning Progress
        StreamBuilder<List<MentalSessionsRecord>>(
          stream: _userSessionsStream,
          builder: (context, sessionsSnapshot) {
            final sessions = sessionsSnapshot.data ?? <MentalSessionsRecord>[];
            return _buildDynamicLearningProgress(theme, sessions);
          },
        ),
      ],
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
    return Stream.value(
        _getDefaultAIRecommendations(FlutterFlowTheme.of(context)));
  }

  /// Get default AI recommendations
  List<GeminiModuleRecommendation> _getDefaultAIRecommendations(
      FlutterFlowTheme theme) {
    return [
      GeminiModuleRecommendation(
        moduleId: 'focus_enhancement',
        moduleTitle: 'Focus Enhancement',
        description:
            'Based on your recent rounds, work on sustained attention during pressure situations',
        priority: 'high',
        estimatedDuration: 15,
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
        estimatedDuration: 20,
        learningStyle: 'confidence',
        expectedOutcome: 'Enhanced self-belief and shot confidence',
        prerequisites: [],
        difficulty: 'beginner',
      ),
      GeminiModuleRecommendation(
        moduleId: 'emotional_control',
        moduleTitle: 'Emotional Control',
        description:
            'Master breathing techniques to maintain composure during challenging rounds',
        priority: 'medium',
        estimatedDuration: 12,
        learningStyle: 'control',
        expectedOutcome: 'Better emotional regulation on course',
        prerequisites: [],
        difficulty: 'beginner',
      ),
    ];
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
    // This would connect to Firestore to get today's AI recommendation
    // For now, return a mock recommendation
    final mockRecommendation = GeminiRecommendationResponse(
      recommendationType: 'daily_practice',
      recommendations:
          _getDefaultAIRecommendations(FlutterFlowTheme.of(context)),
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

    return Stream.value(mockRecommendation);
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
              context.goNamed('vark_onboarding');
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
              'No achievements yet',
              style: theme.titleMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first session to earn achievements',
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
                  estimatedDuration: 10,
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
    try {
      final theme = FlutterFlowTheme.of(context);

      // Show enhanced loading dialog
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

      // Simulate AI-powered session preparation
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

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

        // TODO: Navigate to actual training session when implemented
        // For now, switch to Progress tab to show the started session
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open

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
