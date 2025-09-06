import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import '/ai_integration/services/ai_coaching_service.dart';
import '/backend/backend.dart';
import '/backend/schema/coaching_modules_record.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:flutter/material.dart';

import 'coaching_modules_model.dart';
export 'coaching_modules_model.dart';

class CoachingModulesWidget extends StatefulWidget {
  const CoachingModulesWidget({super.key});

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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // AI Coaching Services
  final AICoachingService _aiCoachingService = AICoachingService.instance;
  bool _isLoadingAIRecommendations = false;
  String? _aiRecommendationError;

  // Current user's VARK preferences
  String _selectedVarkFilter = 'all';
  String _selectedPillar = 'all';
  String _selectedDifficulty = 'all';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CoachingModulesModel());
    _tabController = TabController(length: 3, vsync: this);

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
        drawer: loggedIn
            ? StreamBuilder<UserRecord>(
                stream: UserRecord.getDocument(
                    FirebaseFirestore.instance.doc('user/${currentUserUid}')),
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
      stream: loggedIn
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/${currentUserUid}'))
          : null,
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
              // AI recommendation cards
              _buildAIRecommendationCard(
                theme,
                'Focus Enhancement',
                'Based on your recent rounds, work on sustained attention during pressure situations',
                'High Priority',
                Icons.center_focus_strong,
                theme.mentalFocus,
              ),

              const SizedBox(height: 12),

              _buildAIRecommendationCard(
                theme,
                'Confidence Building',
                'Develop pre-shot visualization routines to boost confidence on the tee',
                'Medium Priority',
                Icons.self_improvement,
                theme.mentalStrength,
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () async {
                  // Generate personalized content
                  if (currentUser != null) {
                    try {
                      await _aiCoachingService.generatePersonalizedContent(
                        userId: currentUser?.uid ?? '',
                        contentType: 'lesson',
                        topic: 'mental_game_improvement',
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('AI coaching content generated!'),
                            backgroundColor: theme.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Error generating content: ${e.toString()}'),
                            backgroundColor: theme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.aiPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.auto_awesome, size: 18),
                label: Text('Generate Personalized Plan'),
              ),
            ],
          ],
        ),
      ],
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
      stream: loggedIn
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/${currentUserUid}'))
          : null,
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

  /// Coaching Pillars Section
  Widget _buildCoachingPillars(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Mental Game Pillars',
      subtitle: 'Master the three foundations of mental performance',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPillarCard(
                theme,
                'Focus',
                Icons.center_focus_strong,
                theme.mentalFocus,
                'Enhance concentration and clarity',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPillarCard(
                theme,
                'Confidence',
                Icons.psychology,
                theme.mentalStrength,
                'Build unshakeable self-belief',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPillarCard(
                theme,
                'Control',
                Icons.self_improvement,
                theme.mentalCalm,
                'Master emotional regulation',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// All Modules Section with Dynamic Data
  Widget _buildAllModules(FlutterFlowTheme theme) {
    return StreamBuilder<List<CoachingModulesRecord>>(
      stream: _getFilteredModulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GlassDashboardCard(
            title: 'Coaching Modules',
            subtitle: 'Loading modules...',
            children: [
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              ),
            ],
          );
        }

        final modules = snapshot.data ?? [];

        return GlassDashboardCard(
          title: 'All Coaching Modules',
          subtitle: '${modules.length} modules available',
          children: [
            Column(
              children: modules
                  .map((module) => _buildModuleCard(theme, module))
                  .toList(),
            ),
          ],
        );
      },
    );
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

  /// Get filtered modules stream based on current filters
  Stream<List<CoachingModulesRecord>> _getFilteredModulesStream() {
    Query query = CoachingModulesRecord.collection
        .where('isActive', isEqualTo: true)
        .orderBy('order');

    // Apply VARK filter
    if (_selectedVarkFilter != 'all') {
      query = query.where('varkTags', arrayContains: _selectedVarkFilter);
    }

    // Apply pillar filter
    if (_selectedPillar != 'all') {
      query = query.where('pillar', isEqualTo: _selectedPillar);
    }

    // Apply difficulty filter
    if (_selectedDifficulty != 'all') {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => CoachingModulesRecord.fromSnapshot(doc))
        .toList());
  }

  /// Get primary VARK style from preferences
  String _getPrimaryVarkStyle(dynamic varkPrefs) {
    if (varkPrefs.visual) return 'Visual';
    if (varkPrefs.aural) return 'Auditory';
    if (varkPrefs.readWrite) return 'Reading/Writing';
    if (varkPrefs.kinesthetic) return 'Kinesthetic';
    return 'Mixed';
  }

  /// Show VARK filter dialog
  void _showVarkFilterDialog(FlutterFlowTheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Modules'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterDropdown(
                'Learning Style',
                _selectedVarkFilter,
                ['all', 'visual', 'aural', 'readwrite', 'kinesthetic'],
                (value) => setState(() => _selectedVarkFilter = value)),
            _buildFilterDropdown(
                'Pillar',
                _selectedPillar,
                ['all', 'focus', 'confidence', 'control'],
                (value) => setState(() => _selectedPillar = value)),
            _buildFilterDropdown(
                'Difficulty',
                _selectedDifficulty,
                ['all', 'beginner', 'intermediate', 'advanced'],
                (value) => setState(() => _selectedDifficulty = value)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  /// Build filter dropdown
  Widget _buildFilterDropdown(String label, String value, List<String> options,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: value,
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option.toUpperCase()),
                ))
            .toList(),
        onChanged: (newValue) => onChanged(newValue ?? 'all'),
      ),
    );
  }

  /// Build VARK modules list
  Widget _buildVarkModulesList(FlutterFlowTheme theme, dynamic varkPrefs) {
    return StreamBuilder<List<CoachingModulesRecord>>(
      stream: _getVarkFilteredModulesStream(varkPrefs),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final modules = snapshot.data ?? [];

        return Column(
          children: modules
              .take(3)
              .map((module) => _buildModuleCard(theme, module))
              .toList(),
        );
      },
    );
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
              // TODO: Navigate to VARK assessment
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

  /// Build pillar card
  Widget _buildPillarCard(
    FlutterFlowTheme theme,
    String title,
    IconData icon,
    Color color,
    String description,
  ) {
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
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build module card
  Widget _buildModuleCard(
      FlutterFlowTheme theme, CoachingModulesRecord module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color:
                  _getPillarColor(theme, module.pillar).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPillarIcon(module.pillar),
              color: _getPillarColor(theme, module.pillar),
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
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${module.duration} min',
                        style: theme.bodySmall.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  module.description,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 12,
                      color: theme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      module.averageRating.toStringAsFixed(1),
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      module.difficulty.toUpperCase(),
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get VARK filtered modules stream
  Stream<List<CoachingModulesRecord>> _getVarkFilteredModulesStream(
      dynamic varkPrefs) {
    String primaryStyle = 'visual';
    if (varkPrefs.aural) primaryStyle = 'aural';
    if (varkPrefs.readWrite) primaryStyle = 'readwrite';
    if (varkPrefs.kinesthetic) primaryStyle = 'kinesthetic';

    return CoachingModulesRecord.collection
        .where('isActive', isEqualTo: true)
        .where('varkTags', arrayContains: primaryStyle)
        .orderBy('averageRating', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoachingModulesRecord.fromSnapshot(doc))
            .toList());
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
        // This would be populated with AI recommendations
        Container(
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
                'Generating personalized recommendation...',
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
        Container(
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
        // This would integrate with the dashboard MPI data
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.psychology,
                size: 48,
                color: theme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Mental Performance Index: 78',
                style: theme.titleMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete more sessions to see detailed analytics',
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

  /// Build learning progress
  Widget _buildLearningProgress(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Learning Progress',
      subtitle: 'Your journey through the mental training modules',
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.school,
                size: 48,
                color: theme.success.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Modules Completed: 0/24',
                style: theme.titleMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your first module to begin tracking progress',
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

  /// Build achievements
  Widget _buildAchievements(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Achievements',
      subtitle: 'Celebrate your mental training milestones',
      children: [
        Container(
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
        ),
      ],
    );
  }
}
