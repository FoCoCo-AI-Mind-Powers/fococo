import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/vark_preferences_struct.dart';
import '/backend/schema/user_subscriptions_record.dart';
import '/config/app_feature_flags.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/services/revenuecat_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
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

  // Preferences state (will be stored in user record later)
  bool _useMetricUnits = true; // Default to metric
  bool _aiVoiceEnabled = true; // Default to enabled

  // Subscription state
  final RevenueCatService _revenueCatService = RevenueCatService();
  Offerings? _offerings;

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

    // Load subscription offerings and check premium status
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      // Load RevenueCat offerings
      await _revenueCatService.initialize();
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading subscription data: $e');
    }
  }

  Future<void> _showPaywall() async {
    if (_offerings?.current == null) {
      // Fallback: navigate to subscription onboarding
      if (mounted) {
        context.pushNamed('subscription_onboarding');
      }
      return;
    }

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .secondaryText
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Paywall View
              Expanded(
                child: PaywallView(
                  offering: _offerings!.current!,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
      drawer: currentUserUid.isNotEmpty
          ? StreamBuilder<UserRecord>(
              stream: UserRecord.getDocument(
                  FirebaseFirestore.instance.doc('user/${currentUserUid}')),
              builder: (context, snapshot) {
                final userData = snapshot.data;
                return EnhancedFoCoCoDrawer(
                  currentUser: userData,
                  currentRoute: 'profile',
                  onNavigate: (route) => context.goNamed(route),
                );
              },
            )
          : null,
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
              // Enhanced App Bar
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: theme.primaryBackground,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Row with drawer icon and title
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Drawer icon
                                IconButton(
                                  icon: Icon(
                                    Icons.menu_rounded,
                                    color: theme.primaryText,
                                    size: 28,
                                  ),
                                  onPressed: () =>
                                      scaffoldKey.currentState?.openDrawer(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 12),
                                // Profile title
                                Expanded(
                                  child: Text(
                                    'Profile',
                                    style: theme.headlineLarge.copyWith(
                                      color: theme.primaryText,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Montserrat',
                                      fontSize: 32,
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Subtitle in 2 lines
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 40), // Align with title text
                              child: Text(
                                'Personalize your experience. Your profile settings shape how FoCoCo thinks, responds, and coaches you.',
                                style: theme.bodyMedium.copyWith(
                                  color: theme.secondaryText,
                                  fontSize: 15,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                    // Section 1: Overview
                    _buildOverviewSection(theme, user, isDefaultData),
                    const SizedBox(height: 20),

                    if (AppFeatureFlags.varkEnabled) ...[
                      // Section 2: Learning Style
                      _buildLearningStyleSection(theme, user),
                      const SizedBox(height: 20),
                    ],

                    // Section 3: Preferences
                    _buildPreferencesSection(theme),
                    const SizedBox(height: 20),

                    // Section 4: Goals
                    _buildGoalsSection(theme, user),
                    const SizedBox(height: 20),

                    // Section 5: Your Journey So Far
                    _buildJourneySection(theme, user, achievements),
                    const SizedBox(height: 20),

                    // Footer: Settings Link
                    _buildFooterSection(theme),
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

  /// Section 1: Overview
  Widget _buildOverviewSection(FlutterFlowTheme theme, UserRecord user,
      [bool isDefaultData = false]) {
    return GlassDashboardCard(
      title: 'Overview',
      subtitle: 'Your profile at a glance',
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
              child: _getProfileImageUrl(user).isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _getProfileImageUrl(user),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultAvatar(theme),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: theme.primary,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      ),
                    )
                  : _buildDefaultAvatar(theme),
            ),
            const SizedBox(width: 20),
            // Profile Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name (using displayName for now, can add fullName field later)
                  Text(
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : 'Golf Enthusiast',
                    style: theme.titleLarge.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Display Name (if different from full name)
                  if (user.displayName.isNotEmpty)
                    Text(
                      user.displayName,
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    isDefaultData
                        ? '${user.email} (Profile syncing...)'
                        : user.email,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Membership Level
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (user.currentMembershipTier == 'premium'
                                  ? theme.warning
                                  : theme.primary)
                              .withValues(alpha: 0.2),
                          (user.currentMembershipTier == 'premium'
                                  ? theme.warning
                                  : theme.primary)
                              .withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (user.currentMembershipTier == 'premium'
                                ? theme.warning
                                : theme.primary)
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.currentMembershipTier == 'premium'
                              ? FontAwesomeIcons.crown
                              : FontAwesomeIcons.user,
                          size: 12,
                          color: user.currentMembershipTier == 'premium'
                              ? theme.warning
                              : theme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.currentMembershipTier.toUpperCase(),
                          style: theme.labelSmall.copyWith(
                            color: user.currentMembershipTier == 'premium'
                                ? theme.warning
                                : theme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            StreamBuilder<List<UserSubscriptionsRecord>>(
              stream: UserSubscriptionsRecord.collection
                  .where('userId', isEqualTo: currentUserUid)
                  .where('status', whereIn: ['active', 'trialing'])
                  .orderBy('currentPeriodEnd', descending: true)
                  .limit(1)
                  .snapshots()
                  .map((snapshot) => snapshot.docs
                      .map((doc) => UserSubscriptionsRecord.fromSnapshot(doc))
                      .toList()),
              builder: (context, snapshot) {
                final hasActiveSubscription =
                    snapshot.hasData && snapshot.data!.isNotEmpty;

                if (hasActiveSubscription) {
                  final subscription = snapshot.data!.first;
                  final membershipTier =
                      subscription.membershipTier.toLowerCase();
                  final isPremium =
                      membershipTier == 'premium' || membershipTier == 'prime';

                  return GlassDesignSystem.glassButton(
                    text: isPremium
                        ? 'Manage Subscription'
                        : 'Upgrade to Premium',
                    onPressed: _showPaywall,
                    icon: isPremium
                        ? FontAwesomeIcons.creditCard
                        : FontAwesomeIcons.crown,
                    theme: theme,
                  );
                } else {
                  return GlassDesignSystem.glassButton(
                    text: 'Upgrade to Premium',
                    onPressed: _showPaywall,
                    icon: FontAwesomeIcons.crown,
                    theme: theme,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            GlassDesignSystem.glassButton(
              text: 'Edit Profile',
              onPressed: () => context.goNamed('edit_profile'),
              icon: Icons.edit_outlined,
              theme: theme,
              color: theme.secondaryText,
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

  /// Get profile image URL - checks user.profileImageUrl first, then falls back to Firebase Auth photoUrl
  String _getProfileImageUrl(UserRecord user) {
    // First check user record profileImageUrl
    if (user.profileImageUrl.isNotEmpty) {
      return user.profileImageUrl;
    }
    // Fallback to Firebase Auth photo URL
    final authPhotoUrl = currentUserPhoto;
    if (authPhotoUrl.isNotEmpty) {
      return authPhotoUrl;
    }
    return '';
  }

  /// Section 2: Learning Style
  Widget _buildLearningStyleSection(FlutterFlowTheme theme, UserRecord user) {
    final vark = user.varkPreferences;
    final dominantStyle = _getDominantVarkStyle(vark);

    return GlassDashboardCard(
      title: 'Learning Style',
      subtitle: 'How your mind absorbs, adapts, and learns best',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary.withValues(alpha: 0.1),
                theme.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getVarkIcon(dominantStyle),
                color: theme.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VARK Type',
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dominantStyle,
                      style: theme.titleLarge.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassDesignSystem.glassButton(
          text: 'Retake VARK',
          onPressed: () => _navigateToVarkAssessment(),
          icon: FontAwesomeIcons.arrowRotateRight,
          theme: theme,
        ),
      ],
    );
  }

  /// Section 3: Preferences
  Widget _buildPreferencesSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Preferences',
      subtitle: 'How FoCoCo interacts, responds, and measures your game',
      children: [
        // Units Preference
        _buildPreferenceRow(
          theme,
          'Units',
          _useMetricUnits ? 'Metric' : 'Imperial',
          FontAwesomeIcons.ruler,
          () {
            setState(() {
              _useMetricUnits = !_useMetricUnits;
            });
          },
        ),
        const SizedBox(height: 12),
        // AI Voice Preference
        _buildPreferenceRow(
          theme,
          'AI Voice',
          _aiVoiceEnabled ? 'On' : 'Off',
          FontAwesomeIcons.volumeHigh,
          () {
            setState(() {
              _aiVoiceEnabled = !_aiVoiceEnabled;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreferenceRow(
    FlutterFlowTheme theme,
    String label,
    String value,
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
                    label,
                    style: theme.titleSmall.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: theme.bodyMedium.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
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

  /// Section 4: Goals
  Widget _buildGoalsSection(FlutterFlowTheme theme, UserRecord user) {
    // Placeholder values - these should come from user record
    String currentGoal = 'Focus'; // Focus / Confidence / Control
    String goalTimeline = 'Monthly'; // Weekly / Monthly

    return GlassDashboardCard(
      title: 'Goals',
      subtitle: 'Define what you\'re working towards',
      children: [
        _buildGoalRow(
          theme,
          'Current Goal to Improve',
          currentGoal,
          FontAwesomeIcons.bullseye,
        ),
        const SizedBox(height: 12),
        _buildGoalRow(
          theme,
          'Goal Timeline',
          goalTimeline,
          FontAwesomeIcons.calendar,
        ),
        const SizedBox(height: 12),
        GlassDesignSystem.glassButton(
          text: 'Edit Goals',
          onPressed: () => _showEditGoalsDialog(theme, user),
          icon: FontAwesomeIcons.pencil,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildGoalRow(
    FlutterFlowTheme theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
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
                  label,
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.bodyMedium.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section 5: Your Journey So Far
  Widget _buildJourneySection(FlutterFlowTheme theme, UserRecord user,
      List<Map<String, dynamic>> achievements) {
    return GlassDashboardCard(
      title: 'Your Journey So Far',
      subtitle: 'A snapshot of your growth and milestones',
      showAIBadge: true,
      aiInsight:
          'Your focus has improved 12% this month. Keep practicing visualization techniques.',
      children: [
        // Member Since
        _buildJourneyRow(
          theme,
          'Member Since',
          user.createdTime != null
              ? _formatDate(user.createdTime!)
              : 'Recently',
          FontAwesomeIcons.calendarCheck,
        ),
        const SizedBox(height: 12),
        // Total Modules Completed
        _buildJourneyRow(
          theme,
          'Total Modules Completed',
          '${user.totalModulesCompleted}',
          FontAwesomeIcons.graduationCap,
        ),
        const SizedBox(height: 12),
        // Achievements Earned
        _buildJourneyRow(
          theme,
          'Achievements Earned',
          '${achievements.length}',
          FontAwesomeIcons.trophy,
        ),
        const SizedBox(height: 20),
        // Mind Power Index (MPI)
        Text(
          'Mind Power Index (MPI)',
          style: theme.titleMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 12),
        _buildMPIMetric(
            theme, 'Focus', 85, FontAwesomeIcons.bullseye, theme.aiPrimary),
        const SizedBox(height: 8),
        _buildMPIMetric(theme, 'Confidence', 78, FontAwesomeIcons.trophy,
            theme.coachingPrimary),
        const SizedBox(height: 8),
        _buildMPIMetric(theme, 'Control', 92, FontAwesomeIcons.crosshairs,
            theme.performanceExcellent),
      ],
    );
  }

  Widget _buildJourneyRow(
    FlutterFlowTheme theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
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
                  label,
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.bodyMedium.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMPIMetric(
    FlutterFlowTheme theme,
    String title,
    int value,
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
            child: Text(
              title,
              style: theme.bodySmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value%',
            style: theme.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  /// Footer Section
  Widget _buildFooterSection(FlutterFlowTheme theme) {
    return GestureDetector(
      onTap: () => context.pushNamed('settings'),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.shield,
              color: theme.primary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Manage your data and privacy in Settings',
              style: theme.bodyMedium.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
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

  void _showEditGoalsDialog(FlutterFlowTheme theme, UserRecord user) {
    String selectedGoal = 'Focus';
    String selectedTimeline = 'Monthly';

    GlassDesignSystem.showGlassModal(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Goals',
                style: theme.headlineSmall.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 20),
              // Goal Selection
              _buildGoalDropdown(
                theme,
                'Current Goal to Improve',
                selectedGoal,
                ['Focus', 'Confidence', 'Control'],
                (value) {
                  setDialogState(() {
                    selectedGoal = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Timeline Selection
              _buildGoalDropdown(
                theme,
                'Goal Timeline',
                selectedTimeline,
                ['Weekly', 'Monthly'],
                (value) {
                  setDialogState(() {
                    selectedTimeline = value;
                  });
                },
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
                      text: 'Save',
                      onPressed: () {
                        // TODO: Save goals to user record
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Goals updated successfully'),
                            backgroundColor: theme.success,
                          ),
                        );
                      },
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalDropdown(
    FlutterFlowTheme theme,
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.bodyMedium.copyWith(
            color: theme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.glassBackground.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.glassBorder.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            style: theme.bodyMedium.copyWith(
              color: theme.primaryText,
            ),
            dropdownColor: theme.secondaryBackground,
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
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
}
