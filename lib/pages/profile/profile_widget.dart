import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Stream subscription for proper disposal
  StreamSubscription<UserRecord>? _userStreamSubscription;

  // User data state management
  UserRecord? _currentUser;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();

    // Initialize user data stream
    _initializeUserStream();
  }

  void _initializeUserStream() {
    if (currentUserUid.isEmpty) {
      // Handle case where user is not authenticated
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'User not authenticated';
        });
      }
      return;
    }

    final userStream = UserRecord.getDocument(
        FirebaseFirestore.instance.collection('user').doc(currentUserUid));

    _userStreamSubscription = userStream.listen((userData) {
      if (mounted) {
        setState(() {
          _currentUser = userData;
          _isLoading = false;
          _hasError = false;
          _errorMessage = null;
        });
      }
    }, onError: (error) {
      print('❌ Profile Stream Error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = error.toString();
          // Create default user when there's an error
          _currentUser = _createDefaultUserRecord();
        });

        // Try to create/fix profile in background
        _createOrFixProfileInBackground();
      }
    });
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Debug logging
    print('🔍 Profile Build: currentUserUid = "$currentUserUid"');
    print(
        '🔍 Profile Build: User authenticated = ${currentUserUid.isNotEmpty}');
    print('🔍 Profile Build: Loading = $_isLoading, HasError = $_hasError');

    // Handle loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: theme.bodyMedium.copyWith(
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine user data and if it's default
    UserRecord user;
    bool isDefaultData = false;

    if (_hasError || _currentUser == null) {
      print('⚠️ Using default profile data - Error: $_errorMessage');
      isDefaultData = true;
      user = _currentUser ?? _createDefaultUserRecord();
    } else {
      user = _currentUser!;
    }

    final List<Map<String, dynamic>> achievements = []; // Placeholder for now

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      body: Container(
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
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // Glass App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.glassBackground.withValues(alpha: 0.2),
                              theme.glassTint.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: theme.glassBorder.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Profile',
                                      style: theme.headlineLarge.copyWith(
                                        color: theme.primaryText,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Montserrat',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Manage your FoCoCo experience',
                                      style: theme.bodyMedium.copyWith(
                                        color: theme.secondaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHeaderButton(
                                    theme,
                                    Icons.edit_outlined,
                                    () => context.goNamed('edit_profile'),
                                    isSecondary: true,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildHeaderButton(
                                    theme,
                                    Icons.settings_rounded,
                                    () => _showSettingsModal(
                                        context, theme, user),
                                    isSecondary: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Profile Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Header Card
                    _buildProfileHeaderCard(theme, user, isDefaultData),
                    const SizedBox(height: 20),

                    // Mental Performance Index
                    _buildMentalPerformanceSection(theme, user),
                    const SizedBox(height: 20),

                    // VARK Learning Preferences
                    _buildVarkPreferencesSection(theme, user),
                    const SizedBox(height: 20),

                    // Recent Achievements
                    _buildAchievementsSection(theme, achievements),
                    const SizedBox(height: 20),

                    // AI Insights Summary
                    _buildAIInsightsSection(theme, user),
                    const SizedBox(height: 20),

                    // Account & Subscription
                    _buildAccountSection(theme, user),
                    const SizedBox(height: 100), // Bottom padding for navbar
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: EnhancedFoCoCoNavBar(
        currentRoute: 'profile',
        onTap: (route) {
          print('🔄 Profile page: Navigation requested to route: $route');
          context.goNamed(route);
        },
        currentUser: null, // Will be handled by the navbar internally
      ),
    );
  }

  /// Profile Header Card with Avatar and Basic Info
  Widget _buildProfileHeaderCard(FlutterFlowTheme theme, UserRecord user,
      [bool isDefaultData = false]) {
    return GlassDashboardCard(
      title: user.displayName.isNotEmpty ? user.displayName : 'Golf Enthusiast',
      subtitle:
          isDefaultData ? '${user.email} (Profile syncing...)' : user.email,
      showAIBadge: user.currentMembershipTier == 'premium',
      aiInsight: isDefaultData
          ? 'Profile data is loading. Some information may be temporary.'
          : (user.currentMembershipTier == 'premium'
              ? 'Premium member with full AI coaching access'
              : null),
      children: [
        Row(
          children: [
            // Profile Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: theme.primaryBrandGradient,
                boxShadow: theme.glassCardShadows,
              ),
              child: user.profileImageUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.profileImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultAvatar(theme),
                      ),
                    )
                  : _buildDefaultAvatar(theme),
            ),
            const SizedBox(width: 20),

            // Profile Stats
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          theme,
                          'Handicap',
                          user.handicap.toStringAsFixed(1),
                          FontAwesomeIcons.golfBallTee,
                          theme.golfPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          theme,
                          'Streak',
                          '${user.coachingStreak}',
                          FontAwesomeIcons.fire,
                          theme.performanceExcellent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          theme,
                          'Modules',
                          '${user.totalModulesCompleted}',
                          FontAwesomeIcons.graduationCap,
                          theme.coachingPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          theme,
                          'AI Insights',
                          '${user.totalAIInsightsGenerated}',
                          FontAwesomeIcons.brain,
                          theme.aiPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(FlutterFlowTheme theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: theme.primaryBrandGradient,
      ),
      child: Icon(
        FontAwesomeIcons.user,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildStatItem(
    FlutterFlowTheme theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: theme.secondaryText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Mental Performance Index Section
  Widget _buildMentalPerformanceSection(
      FlutterFlowTheme theme, UserRecord user) {
    return GlassDashboardCard(
      title: 'Mental Performance Index',
      subtitle: 'Your FoCoCo pillars strength',
      showAIBadge: true,
      aiInsight:
          'Your focus has improved 12% this month. Keep practicing visualization techniques.',
      children: [
        Row(
          children: [
            Expanded(
              child: GlassProgressRing(
                progress: 0.85,
                size: 100,
                color: theme.aiPrimary,
                centerText: '85%',
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildPerformanceMetric(
                    theme,
                    'Focus',
                    85,
                    5.2,
                    FontAwesomeIcons.bullseye,
                    theme.aiPrimary,
                  ),
                  const SizedBox(height: 8),
                  _buildPerformanceMetric(
                    theme,
                    'Confidence',
                    78,
                    -2.1,
                    FontAwesomeIcons.trophy,
                    theme.coachingPrimary,
                  ),
                  const SizedBox(height: 8),
                  _buildPerformanceMetric(
                    theme,
                    'Control',
                    92,
                    8.5,
                    FontAwesomeIcons.crosshairs,
                    theme.performanceExcellent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceMetric(
    FlutterFlowTheme theme,
    String title,
    int value,
    double trend,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodySmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '$value%',
                      style: theme.titleSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      trend > 0 ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: trend > 0 ? theme.success : theme.error,
                    ),
                    Text(
                      '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                      style: theme.labelSmall.copyWith(
                        color: trend > 0 ? theme.success : theme.error,
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

  /// VARK Learning Preferences Section
  Widget _buildVarkPreferencesSection(FlutterFlowTheme theme, UserRecord user) {
    final vark = user.varkPreferences;
    final dominantStyle = _getDominantVarkStyle(vark);

    return GlassDashboardCard(
      title: 'Learning Style: $dominantStyle',
      subtitle: 'Your personalized coaching approach',
      icon: Icon(
        _getVarkIcon(dominantStyle),
        color: theme.mindfulnessPrimary,
        size: 24,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildVarkIndicator(
                theme,
                'Visual',
                vark.visual,
                FontAwesomeIcons.eye,
                theme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildVarkIndicator(
                theme,
                'Auditory',
                vark.aural,
                FontAwesomeIcons.volumeHigh,
                theme.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildVarkIndicator(
                theme,
                'Reading',
                vark.readWrite,
                FontAwesomeIcons.bookOpen,
                theme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildVarkIndicator(
                theme,
                'Kinesthetic',
                vark.kinesthetic,
                FontAwesomeIcons.handFist,
                theme.accent1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassDesignSystem.glassButton(
          text: 'Retake VARK Assessment',
          onPressed: () => _navigateToVarkAssessment(),
          icon: FontAwesomeIcons.arrowRotateRight,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildVarkIndicator(
    FlutterFlowTheme theme,
    String label,
    bool isActive,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isActive ? color : theme.secondaryText).withValues(alpha: 0.1),
            (isActive ? color : theme.secondaryText).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              (isActive ? color : theme.secondaryText).withValues(alpha: 0.2),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? color : theme.secondaryText,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.labelSmall.copyWith(
              color: isActive ? color : theme.secondaryText,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Recent Achievements Section
  Widget _buildAchievementsSection(
      FlutterFlowTheme theme, List<Map<String, dynamic>> achievements) {
    return GlassDashboardCard(
      title: 'Recent Achievements',
      subtitle: '${achievements.length} earned this month',
      icon: Icon(
        FontAwesomeIcons.trophy,
        color: theme.warning,
        size: 24,
      ),
      children: [
        if (achievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.medal,
                  color: theme.secondaryText,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'No achievements yet',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
                Text(
                  'Complete coaching modules to earn your first achievement!',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: achievements.take(3).map((achievement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildAchievementItem(theme, achievement),
              );
            }).toList(),
          ),
        if (achievements.length > 3)
          GlassDesignSystem.glassButton(
            text: 'View All Achievements',
            onPressed: () => context.pushNamed('achievements'),
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildAchievementItem(
      FlutterFlowTheme theme, Map<String, dynamic> achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.warning.withValues(alpha: 0.1),
            theme.warning.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.star,
              color: theme.warning,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'] ?? 'Achievement',
                  style: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  achievement['description'] ?? 'Earned recently',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if ((achievement['progress'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${((achievement['progress'] ?? 0) * 100).toInt()}%',
                style: theme.labelSmall.copyWith(
                  color: theme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// AI Insights Summary Section
  Widget _buildAIInsightsSection(FlutterFlowTheme theme, UserRecord user) {
    return GlassDashboardCard(
      title: 'AI Coaching Insights',
      subtitle: '${user.totalAIInsightsGenerated} insights generated',
      showAIBadge: true,
      aiInsight:
          'Your mental game has improved significantly. Focus on pre-shot routines for better consistency.',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightMetric(
                theme,
                'Mental Score',
                '${user.mentalPerformanceScore.toInt()}',
                FontAwesomeIcons.brain,
                theme.aiPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightMetric(
                theme,
                'Tokens Left',
                '${user.tokensRemaining}',
                FontAwesomeIcons.coins,
                theme.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassDesignSystem.glassButton(
          text: 'Get New AI Insight',
          onPressed: () => context.pushNamed('ai_insights'),
          icon: FontAwesomeIcons.star,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildInsightMetric(
    FlutterFlowTheme theme,
    String label,
    String value,
    IconData icon,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
            ),
          ),
          Text(
            label,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// Account & Subscription Section
  Widget _buildAccountSection(FlutterFlowTheme theme, UserRecord user) {
    return GlassDashboardCard(
      title: 'Account & Subscription',
      subtitle: '${user.currentMembershipTier.toUpperCase()} Member',
      icon: Icon(
        user.currentMembershipTier == 'premium'
            ? FontAwesomeIcons.crown
            : FontAwesomeIcons.user,
        color: user.currentMembershipTier == 'premium'
            ? theme.warning
            : theme.primary,
        size: 24,
      ),
      children: [
        _buildAccountOption(
          theme,
          'Subscription Settings',
          'Manage your FoCoCo membership',
          FontAwesomeIcons.creditCard,
          () => context.pushNamed('subscription_management'),
        ),
        const SizedBox(height: 8),
        _buildAccountOption(
          theme,
          'Privacy & Security',
          'Face ID, data preferences',
          FontAwesomeIcons.shield,
          () => context.pushNamed('face_id_settings'),
        ),
        const SizedBox(height: 8),
        _buildAccountOption(
          theme,
          'Coaching Modules',
          'Access your learning content',
          FontAwesomeIcons.graduationCap,
          () => context.pushNamed('coaching_modules'),
        ),
        const SizedBox(height: 8),
        _buildAccountOption(
          theme,
          'Progress Tracking',
          'View your improvement journey',
          FontAwesomeIcons.chartLine,
          () => context.pushNamed('coaching_modules', extra: {'initialTab': 2}),
        ),
      ],
    );
  }

  Widget _buildAccountOption(
    FlutterFlowTheme theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.glassTint.withValues(alpha: 0.1),
              theme.glassTint.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.titleSmall.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              Icons.chevron_right_rounded,
              color: theme.secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  String _getDominantVarkStyle(VarkPreferencesStruct vark) {
    if (vark.visual) return 'Visual';
    if (vark.aural) return 'Auditory';
    if (vark.readWrite) return 'Reading/Writing';
    if (vark.kinesthetic) return 'Kinesthetic';
    return 'Not Set';
  }

  IconData _getVarkIcon(String style) {
    switch (style) {
      case 'Visual':
        return FontAwesomeIcons.eye;
      case 'Auditory':
        return FontAwesomeIcons.volumeHigh;
      case 'Reading/Writing':
        return FontAwesomeIcons.bookOpen;
      case 'Kinesthetic':
        return FontAwesomeIcons.handFist;
      default:
        return FontAwesomeIcons.question;
    }
  }

  void _navigateToVarkAssessment() {
    context.pushNamed('vark_onboarding');
  }

  void _showSettingsModal(
      BuildContext context, FlutterFlowTheme theme, UserRecord user) {
    GlassDesignSystem.showGlassModal(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile Settings',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsOption(
              theme,
              'Edit Profile',
              'Update your personal information',
              FontAwesomeIcons.userPen,
              () {
                Navigator.pop(context);
                // Navigate to edit profile
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsOption(
              theme,
              'Notifications',
              'Manage push notifications',
              FontAwesomeIcons.bell,
              () {
                Navigator.pop(context);
                // Navigate to notifications settings
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsOption(
              theme,
              'Sign Out',
              'Log out of your account',
              FontAwesomeIcons.rightFromBracket,
              () => _showLogoutConfirmation(context, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption(
    FlutterFlowTheme theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.glassTint.withValues(alpha: 0.1),
              theme.glassTint.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.primary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.titleSmall.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
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
  }

  void _showLogoutConfirmation(BuildContext context, FlutterFlowTheme theme) {
    Navigator.pop(context); // Close settings modal first

    GlassDesignSystem.showGlassModal(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.error.withValues(alpha: 0.1),
                    theme.error.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                FontAwesomeIcons.rightFromBracket,
                color: theme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign Out',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to sign out of your FoCoCo account?',
              style: theme.bodyMedium.copyWith(
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll need to sign back in to access your mental performance data and coaching modules.',
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassDesignSystem.glassButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    color: theme.secondaryText,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassDesignSystem.glassButton(
                    text: 'Sign Out',
                    onPressed: () => _performLogout(context),
                    color: theme.error,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
    FlutterFlowTheme theme,
    IconData icon,
    VoidCallback onTap, {
    bool isSecondary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isSecondary
                  ? LinearGradient(
                      colors: [
                        theme.glassBackground.withValues(alpha: 0.3),
                        theme.glassTint.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : theme.primaryBrandGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSecondary
                    ? theme.glassBorder.withValues(alpha: 0.4)
                    : theme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSecondary ? theme.glassShadow : theme.primary)
                      .withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSecondary ? theme.primaryText : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  UserRecord _createDefaultUserRecord() {
    // Create a mock document reference for the default user
    final mockRef = FirebaseFirestore.instance
        .collection('user')
        .doc(currentUserUid.isNotEmpty ? currentUserUid : 'default');

    // Create default user data
    final defaultData = {
      'email':
          currentUserEmail.isNotEmpty ? currentUserEmail : 'user@example.com',
      'displayName': currentUserDisplayName.isNotEmpty
          ? currentUserDisplayName
          : 'Golf Enthusiast',
      'profileImageUrl': '',
      'handicap': 18.0,
      'golfExperience': 'beginner',
      'homeClub': '',
      'varkPreferences': {
        'visual': false,
        'aural': false,
        'readWrite': false,
        'kinesthetic': false,
      },
      'currentMembershipTier': 'base',
      'tokensRemaining': 10,
      'totalAIInsightsGenerated': 0,
      'mentalPerformanceScore': 50.0,
      'coachingStreak': 0,
      'totalModulesCompleted': 0,
      'notificationSettings': {
        'pushEnabled': true,
        'emailEnabled': true,
        'dailyReminders': true,
        'weeklyReports': true,
      },
      'audioPreferences': {
        'voiceType': 'neutral',
        'speechRate': 1.0,
        'backgroundMusic': false,
      },
      'timezone': 'UTC',
      'createdTime': DateTime.now(),
      'lastActive': DateTime.now(),
      'notificationTokens': <String>[],
      'dataProcessingConsent': true,
      'marketingConsent': false,
      'appVersion': '1.0.0',
      'platform': 'flutter',
      'referralSource': 'direct',
    };

    return UserRecord.getDocumentFromData(defaultData, mockRef);
  }

  void _createOrFixProfileInBackground() {
    // Run in background without blocking UI
    Future.delayed(Duration.zero, () async {
      if (!mounted) return; // Check if widget is still mounted

      try {
        print(
            '🔧 Creating/fixing profile in background for UID: $currentUserUid');

        final userRef =
            FirebaseFirestore.instance.collection('user').doc(currentUserUid);

        // Check if document exists
        final doc = await userRef.get();

        if (!mounted)
          return; // Check if widget is still mounted after async operation

        if (!doc.exists) {
          // Create new document
          await userRef.set({
            'email': currentUserEmail,
            'displayName': currentUserDisplayName.isNotEmpty
                ? currentUserDisplayName
                : 'Golf Enthusiast',
            'profileImageUrl': '',
            'handicap': 18.0,
            'golfExperience': 'beginner',
            'homeClub': '',
            'varkPreferences': {
              'visual': false,
              'aural': false,
              'readWrite': false,
              'kinesthetic': false,
            },
            'currentMembershipTier': 'base',
            'tokensRemaining': 10,
            'totalAIInsightsGenerated': 0,
            'mentalPerformanceScore': 50.0,
            'coachingStreak': 0,
            'totalModulesCompleted': 0,
            'notificationSettings': {
              'pushEnabled': true,
              'emailEnabled': true,
              'dailyReminders': true,
              'weeklyReports': true,
            },
            'audioPreferences': {
              'voiceType': 'neutral',
              'speechRate': 1.0,
              'backgroundMusic': false,
            },
            'timezone': 'UTC',
            'createdTime': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
            'notificationTokens': [],
            'dataProcessingConsent': true,
            'marketingConsent': false,
            'appVersion': '1.0.0',
            'platform': 'flutter',
            'referralSource': 'direct',
          });

          if (!mounted)
            return; // Check if widget is still mounted after async operation
          print('✅ Profile created in background');
        } else {
          // Fix existing document structure
          await userRef.update({
            'varkPreferences': {
              'visual': false,
              'aural': false,
              'readWrite': false,
              'kinesthetic': false,
            },
            'notificationSettings': {
              'pushEnabled': true,
              'emailEnabled': true,
              'dailyReminders': true,
              'weeklyReports': true,
            },
            'audioPreferences': {
              'voiceType': 'neutral',
              'speechRate': 1.0,
              'backgroundMusic': false,
            },
            'lastActive': FieldValue.serverTimestamp(),
          });

          if (!mounted)
            return; // Check if widget is still mounted after async operation
          print('✅ Profile structure fixed in background');
        }
      } catch (e) {
        print('❌ Background profile creation/fix failed: $e');
        // Silently fail - user still sees the default data
      }
    });
  }

  Future<void> _fixProfileData(BuildContext context) async {
    if (!mounted) return;

    try {
      print('🔧 Fixing profile data for UID: $currentUserUid');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context)
                  .primaryBackground
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fixing profile data...',
                  style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
      );

      // Get the document reference
      final userRef =
          FirebaseFirestore.instance.collection('user').doc(currentUserUid);

      // Update with proper structure, merging with existing data
      await userRef.update({
        'varkPreferences': {
          'visual': false,
          'aural': false,
          'readWrite': false,
          'kinesthetic': false,
        },
        'notificationSettings': {
          'pushEnabled': true,
          'emailEnabled': true,
          'dailyReminders': true,
          'weeklyReports': true,
        },
        'audioPreferences': {
          'voiceType': 'neutral',
          'speechRate': 1.0,
          'backgroundMusic': false,
        },
        'lastActive': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      print('✅ Profile data fixed successfully');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        // Trigger a rebuild to show the profile
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Error fixing profile data: $e');

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing profile: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _createUserProfile(BuildContext context) async {
    if (!mounted) return;

    try {
      print('🔧 Creating user profile for UID: $currentUserUid');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context)
                  .primaryBackground
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Creating your profile...',
                  style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
      );

      // Create user document with default values
      final userRef =
          FirebaseFirestore.instance.collection('user').doc(currentUserUid);

      await userRef.set({
        'email': currentUserEmail,
        'displayName': currentUserDisplayName.isNotEmpty
            ? currentUserDisplayName
            : 'Golf Enthusiast',
        'profileImageUrl': '',
        'handicap': 18.0,
        'golfExperience': 'beginner',
        'homeClub': '',
        'varkPreferences': {
          'visual': false,
          'aural': false,
          'readWrite': false,
          'kinesthetic': false,
        },
        'currentMembershipTier': 'base',
        'tokensRemaining': 10,
        'totalAIInsightsGenerated': 0,
        'mentalPerformanceScore': 50.0,
        'coachingStreak': 0,
        'totalModulesCompleted': 0,
        'notificationSettings': {
          'pushEnabled': true,
          'emailEnabled': true,
          'dailyReminders': true,
          'weeklyReports': true,
        },
        'audioPreferences': {
          'voiceType': 'neutral',
          'speechRate': 1.0,
          'backgroundMusic': false,
        },
        'timezone': 'UTC',
        'createdTime': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'notificationTokens': [],
        'dataProcessingConsent': true,
        'marketingConsent': false,
        'appVersion': '1.0.0',
        'platform': 'flutter',
        'referralSource': 'direct',
      });

      if (!mounted) return;
      print('✅ User profile created successfully');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        // Trigger a rebuild to show the profile
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Error creating user profile: $e');

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    if (!mounted) return;

    try {
      // Close the confirmation modal
      Navigator.pop(context);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context)
                  .primaryBackground
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Signing out...',
                  style: FlutterFlowTheme.of(context).bodyMedium.copyWith(
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
      );

      // Perform logout
      await Future.delayed(
          const Duration(milliseconds: 500)); // Brief delay for UX

      if (!mounted) return;

      GoRouter.of(context).prepareAuthEvent();
      await authManager.signOut();
      GoRouter.of(context).clearRedirectLocation();

      // Navigate to login
      if (context.mounted && mounted) {
        Navigator.pop(context); // Close loading dialog
        context.goNamedAuth('login', context.mounted);
      }
    } catch (e) {
      // Handle logout error
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }
}
