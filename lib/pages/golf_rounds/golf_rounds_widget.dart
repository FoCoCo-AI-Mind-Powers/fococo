import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/glass_design_system.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import '/services/app_tutorial_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'dart:io';

class GolfRoundsWidget extends StatefulWidget {
  const GolfRoundsWidget({super.key});

  static String routeName = 'golf_rounds';
  static String routePath = '/golf_rounds';

  @override
  State<GolfRoundsWidget> createState() => _GolfRoundsWidgetState();
}

class _GolfRoundsWidgetState extends State<GolfRoundsWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final AppTutorialService _tutorialService = AppTutorialService();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Tutorial service keys
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _roundsListKey = GlobalKey();

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

    // Show tutorial after animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    _tutorialService.startGolfRoundsTutorial(
      context,
      roundsListKey: _roundsListKey,
      addRoundKey: _addButtonKey,
      filterKey: _filterKey,
      statsKey: _statsKey,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    // Safety check for user authentication
    if (currentUserUid.isEmpty) {
      return _buildAuthErrorScaffold(theme);
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(
          FirebaseFirestore.instance.doc('user/$currentUserUid')),
      builder: (context, userSnapshot) {
        // Handle loading state
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold(theme, null);
        }

        // Handle error state
        if (userSnapshot.hasError) {
          return _buildErrorScaffold(theme, null, 'Error loading user data');
        }

        final user = userSnapshot.data;

        return StreamBuilder<List<GolfRoundsRecord>>(
          stream: queryGolfRoundsRecord(
            queryBuilder: (golfRoundsRecord) => golfRoundsRecord
                .where('userId', isEqualTo: currentUserUid)
                .orderBy('date', descending: true),
          ),
          builder: (context, roundsSnapshot) {
            // Handle loading state for rounds
            if (roundsSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScaffold(theme, user);
            }

            // Handle error state for rounds
            if (roundsSnapshot.hasError) {
              return _buildErrorScaffold(
                  theme, user, 'Error loading golf rounds');
            }

            final rounds = roundsSnapshot.data ?? [];

            return _buildMainScaffold(theme, user, rounds);
          },
        );
      },
    );
  }

  Widget _buildLoadingScaffold(FlutterFlowTheme theme, UserRecord? user) {
    return Scaffold(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your golf rounds...',
                style: theme.bodyLarge.copyWith(
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: EnhancedFoCoCoNavBar(
        currentRoute: 'golf_rounds',
        currentUser: user,
        onTap: (route) => _handleNavigation(route),
        showLabels: true,
        enableVoiceButton: true,
        useGlassEffect: true,
      ),
    );
  }

  Widget _buildErrorScaffold(
      FlutterFlowTheme theme, UserRecord? user, String errorMessage) {
    return Scaffold(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: theme.titleMedium.copyWith(color: theme.error),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GlassDesignSystem.glassButton(
                text: 'Retry',
                onPressed: () {
                  setState(() {
                    // Trigger rebuild
                  });
                },
                theme: theme,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: EnhancedFoCoCoNavBar(
        currentRoute: 'golf_rounds',
        currentUser: user,
        onTap: (route) => _handleNavigation(route),
        showLabels: true,
        enableVoiceButton: true,
        useGlassEffect: true,
      ),
    );
  }

  Widget _buildMainScaffold(
      FlutterFlowTheme theme, UserRecord? user, List<GolfRoundsRecord> rounds) {
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
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Enhanced Glass App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                theme.glassBackground.withValues(alpha: 0.85),
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    theme.glassBorder.withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      // Title section (expanded to take more space)
                                      Expanded(
                                        child: Column(
                                          key: _titleKey,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Golf Rounds',
                                              style:
                                                  theme.headlineLarge.copyWith(
                                                color: theme.primaryText,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Montserrat',
                                                fontSize: 32,
                                                letterSpacing: -0.8,
                                                height: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${rounds.length} rounds tracked',
                                              style: theme.bodyMedium.copyWith(
                                                color: theme.secondaryText,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Glass Add button
                                      GestureDetector(
                                        key: _addButtonKey,
                                        onTap: () =>
                                            _showAddRoundModal(context, theme),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 15, sigmaY: 15),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: theme.glassTint
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: theme.glassBorder
                                                      .withValues(alpha: 0.3),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 10,
                                                    offset:
                                                        const Offset(-2, -2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.add_rounded,
                                                color: theme.primary,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
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
                ),

                // Rounds Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Quick Stats with tutorial key
                      _buildQuickStatsSection(theme, rounds),
                      const SizedBox(height: 20),

                      // Recent Rounds with tutorial key
                      _buildRecentRoundsSection(theme, rounds),
                      const SizedBox(height: 100), // Bottom padding for navbar
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: EnhancedFoCoCoNavBar(
        currentRoute: 'golf_rounds',
        currentUser: user,
        onTap: (route) => _handleNavigation(route),
        showLabels: true,
        enableVoiceButton: true,
        useGlassEffect: true,
      ),
    );
  }

  Widget _buildAuthErrorScaffold(FlutterFlowTheme theme) {
    return Scaffold(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                color: theme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: theme.titleMedium.copyWith(color: theme.error),
              ),
              const SizedBox(height: 8),
              Text(
                'Please log in to view your golf rounds',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GlassDesignSystem.glassButton(
                text: 'Go to Login',
                onPressed: () {
                  context.go('/auth');
                },
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(String route) {
    if (!mounted) return;

    switch (route) {
      case 'dashboard':
        context.go('/dashboard');
        break;
      case 'golf_rounds':
        // Already on this page
        break;
      case 'coaching_modules':
        context.go('/coaching_modules');
        break;
      case 'profile':
        context.go('/profile');
        break;
      default:
        break;
    }
  }

  /// Quick Stats Section with AI Popup
  Widget _buildQuickStatsSection(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    final avgScore = rounds.isNotEmpty
        ? rounds.map((r) => r.score).reduce((a, b) => a + b) / rounds.length
        : 0.0;
    final bestScore = rounds.isNotEmpty
        ? rounds.map((r) => r.score).reduce((a, b) => a < b ? a : b)
        : 0;

    // Calculate rounds this month
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final roundsThisMonth = rounds
        .where((r) =>
            r.date != null &&
            r.date!.isAfter(thisMonth) &&
            r.date!.isBefore(DateTime(now.year, now.month + 1)))
        .length;

    return GestureDetector(
      onTap: () => _showPerformanceAIPopup(context, theme, rounds),
      child: GlassDashboardCard(
        key: _statsKey,
        title: 'Performance Overview',
        subtitle: 'Your golf statistics • Tap for AI insights',
        showAIBadge: true,
        aiInsight:
            _generatePerformanceInsight(avgScore, bestScore, roundsThisMonth),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Average Score',
                  avgScore > 0 ? avgScore.toStringAsFixed(1) : '--',
                  FontAwesomeIcons.golfBallTee,
                  theme.golfPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Best Score',
                  bestScore > 0 ? bestScore.toString() : '--',
                  FontAwesomeIcons.trophy,
                  theme.performanceExcellent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'This Month',
                  roundsThisMonth.toString(),
                  FontAwesomeIcons.calendar,
                  theme.secondary,
                ),
              ),
            ],
          ),
          // AI Assistance Hint
          if (rounds.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.aiPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.aiPrimary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.aiPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap for personalized AI insights and improvement tips',
                      style: theme.bodySmall.copyWith(
                        color: theme.aiPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.touch_app_rounded,
                    color: theme.aiPrimary.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    FlutterFlowTheme theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontFamily: 'Montserrat',
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Recent Rounds Section
  Widget _buildRecentRoundsSection(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    return GlassDashboardCard(
      key: _roundsListKey,
      title: 'Recent Rounds',
      subtitle: rounds.isNotEmpty ? 'Tap to view details' : 'No rounds yet',
      children: [
        if (rounds.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  FontAwesomeIcons.golfBallTee,
                  color: theme.secondaryText,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No rounds logged yet',
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your golf rounds to see your progress and get AI insights!',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GlassDesignSystem.glassButton(
                  text: 'Log Your First Round',
                  onPressed: () => _showAddRoundModal(context, theme),
                  icon: FontAwesomeIcons.plus,
                  theme: theme,
                ),
              ],
            ),
          )
        else
          Column(
            children: rounds.take(5).map((round) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRoundCard(theme, round),
              );
            }).toList(),
          ),
        if (rounds.length > 5)
          GlassDesignSystem.glassButton(
            text: 'View All Rounds',
            onPressed: () {
              // TODO: Navigate to full rounds history
            },
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildRoundCard(FlutterFlowTheme theme, GolfRoundsRecord round) {
    final scoreColor = round.scoreToPar > 0
        ? theme.error
        : round.scoreToPar < 0
            ? theme.success
            : theme.golfPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.glassTint.withValues(alpha: 0.12),
            theme.glassTint.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scoreColor.withValues(alpha: 0.2),
                  scoreColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              FontAwesomeIcons.golfBallTee,
              color: scoreColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  round.courseName.isNotEmpty ? round.courseName : 'Golf Round',
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  round.date != null
                      ? '${round.date!.day}/${round.date!.month}/${round.date!.year}'
                      : 'Recent round',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  round.score.toString(),
                  style: theme.headlineSmall.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                round.scoreToPar > 0
                    ? '+${round.scoreToPar}'
                    : round.scoreToPar < 0
                        ? '${round.scoreToPar}'
                        : 'E',
                style: theme.labelSmall.copyWith(
                  color: scoreColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRoundModal(BuildContext context, FlutterFlowTheme theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _AddRoundModal(theme: theme),
    );
  }

  String _generatePerformanceInsight(
      double avgScore, int bestScore, int roundsThisMonth) {
    if (avgScore == 0) {
      return 'Start logging rounds to get personalized AI insights about your game!';
    }

    if (roundsThisMonth == 0) {
      return 'Log a round this month to see your current form and get improvement tips!';
    }

    if (avgScore < 80) {
      return 'Excellent scoring! Your consistency is your strength - let\'s maintain this level.';
    } else if (avgScore < 90) {
      return 'Good progress! Focus on short game to break into the next scoring tier.';
    } else if (avgScore < 100) {
      return 'Solid foundation! Work on course management and mental game for improvement.';
    } else {
      return 'Great start! Focus on fundamentals and enjoy the journey of improvement.';
    }
  }

  void _showPerformanceAIPopup(BuildContext context, FlutterFlowTheme theme,
      List<GolfRoundsRecord> rounds) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: theme.glassBackground.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: _buildAIInsightContent(theme, rounds),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsightContent(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    final avgScore = rounds.isNotEmpty
        ? rounds.map((r) => r.score).reduce((a, b) => a + b) / rounds.length
        : 0.0;
    final bestScore = rounds.isNotEmpty
        ? rounds.map((r) => r.score).reduce((a, b) => a < b ? a : b)
        : 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: theme.aiGradient,
                  borderRadius: BorderRadius.circular(16),
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
                      'AI Performance Insights',
                      style: theme.titleLarge.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      'Personalized analysis of your game',
                      style: theme.bodySmall.copyWith(
                        color: theme.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.glassTint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: theme.primaryText,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // AI Insights
          if (rounds.isEmpty)
            _buildEmptyStateInsight(theme)
          else
            _buildPerformanceAnalysis(theme, rounds, avgScore, bestScore),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: GlassDesignSystem.glassButton(
              text: rounds.isEmpty ? 'Log Your First Round' : 'Log New Round',
              onPressed: () {
                Navigator.pop(context);
                _showAddRoundModal(context, theme);
              },
              icon: FontAwesomeIcons.plus,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateInsight(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.aiPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.aiPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.chartLine,
            color: theme.aiPrimary,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to unlock AI insights?',
            style: theme.titleMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your golf rounds to receive personalized AI analysis, performance trends, and improvement recommendations tailored to your game.',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis(FlutterFlowTheme theme,
      List<GolfRoundsRecord> rounds, double avgScore, int bestScore) {
    final improvement = _calculateImprovement(rounds);
    final strengths = _identifyStrengths(rounds);
    final recommendations = _generateRecommendations(avgScore, rounds);

    return Column(
      children: [
        // Performance Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.success.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.chartLine,
                    color: theme.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Performance Trend',
                    style: theme.titleSmall.copyWith(
                      color: theme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                improvement,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Strengths
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.aiPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.aiPrimary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.star,
                    color: theme.aiPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Key Strengths',
                    style: theme.titleSmall.copyWith(
                      color: theme.aiPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strengths,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Recommendations
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.warning.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.lightbulb,
                    color: theme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Recommendations',
                    style: theme.titleSmall.copyWith(
                      color: theme.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendations,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateImprovement(List<GolfRoundsRecord> rounds) {
    if (rounds.length < 3) {
      return 'Log more rounds to see your improvement trends and patterns.';
    }

    final recent = rounds.take(3).map((r) => r.score).toList();
    final older = rounds.skip(3).take(3).map((r) => r.score).toList();

    if (older.isEmpty) {
      return 'Your recent average is ${(recent.reduce((a, b) => a + b) / recent.length).toStringAsFixed(1)}. Keep logging rounds to track improvement!';
    }

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    final diff = olderAvg - recentAvg;

    if (diff > 2) {
      return 'Excellent progress! You\'ve improved by ${diff.toStringAsFixed(1)} strokes on average. Your consistency is paying off!';
    } else if (diff > 0) {
      return 'Good improvement! You\'re ${diff.toStringAsFixed(1)} strokes better on average. Keep up the momentum!';
    } else if (diff > -2) {
      return 'Your scores are stable around ${recentAvg.toStringAsFixed(1)}. Focus on consistency and mental game.';
    } else {
      return 'Recent rounds show some challenges. Consider working on fundamentals and course management.';
    }
  }

  String _identifyStrengths(List<GolfRoundsRecord> rounds) {
    if (rounds.isEmpty)
      return 'Start logging rounds to identify your strengths!';

    final avgPutts = rounds.where((r) => r.totalPutts > 0).isNotEmpty
        ? rounds
                .where((r) => r.totalPutts > 0)
                .map((r) => r.totalPutts)
                .reduce((a, b) => a + b) /
            rounds.where((r) => r.totalPutts > 0).length
        : 0.0;

    final fairwayAccuracy = rounds.where((r) => r.fairwaysTotal > 0).isNotEmpty
        ? rounds
                .where((r) => r.fairwaysTotal > 0)
                .map((r) => r.fairwaysHit / r.fairwaysTotal)
                .reduce((a, b) => a + b) /
            rounds.where((r) => r.fairwaysTotal > 0).length
        : 0.0;

    List<String> strengths = [];

    if (avgPutts > 0 && avgPutts < 32) {
      strengths.add(
          'Strong putting game (${avgPutts.toStringAsFixed(1)} avg putts)');
    }

    if (fairwayAccuracy > 0.6) {
      strengths.add(
          'Good driving accuracy (${(fairwayAccuracy * 100).toStringAsFixed(0)}% fairways)');
    }

    final consistency = _calculateConsistency(rounds);
    if (consistency < 5) {
      strengths.add('Consistent scoring patterns');
    }

    if (strengths.isEmpty) {
      return 'Your dedication to tracking rounds shows commitment to improvement. This data will help identify strengths as you log more rounds.';
    }

    return strengths.join(', ') +
        '. These are solid foundations to build upon!';
  }

  String _generateRecommendations(
      double avgScore, List<GolfRoundsRecord> rounds) {
    if (rounds.isEmpty)
      return 'Start logging rounds to get personalized recommendations!';

    List<String> recommendations = [];

    if (avgScore > 100) {
      recommendations.add('Focus on course management and club selection');
      recommendations.add('Practice short game fundamentals');
    } else if (avgScore > 90) {
      recommendations.add('Work on approach shots and green-side play');
      recommendations.add('Develop a consistent pre-shot routine');
    } else if (avgScore > 80) {
      recommendations.add('Fine-tune putting and short game');
      recommendations.add('Focus on mental game and pressure situations');
    } else {
      recommendations.add('Maintain current form and work on course strategy');
      recommendations.add('Consider competitive play to test your skills');
    }

    final avgPutts = rounds.where((r) => r.totalPutts > 0).isNotEmpty
        ? rounds
                .where((r) => r.totalPutts > 0)
                .map((r) => r.totalPutts)
                .reduce((a, b) => a + b) /
            rounds.where((r) => r.totalPutts > 0).length
        : 0.0;

    if (avgPutts > 34) {
      recommendations.add(
          'Prioritize putting practice - aim for under 32 putts per round');
    }

    return recommendations.take(2).join('. ') + '.';
  }

  double _calculateConsistency(List<GolfRoundsRecord> rounds) {
    if (rounds.length < 3) return 10.0;

    final scores = rounds.map((r) => r.score.toDouble()).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final variance =
        scores.map((s) => (s - avg) * (s - avg)).reduce((a, b) => a + b) /
            scores.length;

    return variance;
  }
}

/// Add Round Modal Widget
class _AddRoundModal extends StatefulWidget {
  final FlutterFlowTheme theme;

  const _AddRoundModal({required this.theme});

  @override
  State<_AddRoundModal> createState() => _AddRoundModalState();
}

class _AddRoundModalState extends State<_AddRoundModal> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _scoreController = TextEditingController();
  final _parTotalController = TextEditingController();
  final _puttsController = TextEditingController();
  final _fairwaysHitController = TextEditingController();
  final _fairwaysTotalController = TextEditingController();
  final _girController = TextEditingController();
  final _girTotalController = TextEditingController();
  final _aiNotesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedTeeBox = 'White';
  bool _isSubmitting = false;
  bool _isAiProcessing = false;
  String _aiSuggestion = '';

  // Focus nodes for better UX
  final _courseNameFocus = FocusNode();
  final _scoreFocus = FocusNode();
  final _parTotalFocus = FocusNode();
  final _puttsFocus = FocusNode();
  final _fairwaysHitFocus = FocusNode();
  final _fairwaysTotalFocus = FocusNode();
  final _girFocus = FocusNode();
  final _girTotalFocus = FocusNode();
  final _aiNotesFocus = FocusNode();

  @override
  void dispose() {
    _courseNameController.dispose();
    _scoreController.dispose();
    _parTotalController.dispose();
    _puttsController.dispose();
    _fairwaysHitController.dispose();
    _fairwaysTotalController.dispose();
    _girController.dispose();
    _girTotalController.dispose();
    _aiNotesController.dispose();

    _courseNameFocus.dispose();
    _scoreFocus.dispose();
    _parTotalFocus.dispose();
    _puttsFocus.dispose();
    _fairwaysHitFocus.dispose();
    _fairwaysTotalFocus.dispose();
    _girFocus.dispose();
    _girTotalFocus.dispose();
    _aiNotesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.theme.glassBackground.withValues(alpha: 0.95),
                  widget.theme.glassTint.withValues(alpha: 0.9),
                ],
              ),
              border: Border.all(
                color: widget.theme.glassBorder.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Enhanced Header with AI Badge
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                widget.theme.glassBorder.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: widget.theme.primaryBrandGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: widget.theme.glassCardShadows,
                            ),
                            child: Icon(
                              FontAwesomeIcons.golfBallTee,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log New Round',
                                  style: widget.theme.headlineSmall.copyWith(
                                    color: widget.theme.primaryText,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: widget.theme.aiGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'AI Assisted',
                                            style:
                                                widget.theme.bodySmall.copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
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
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: widget.theme.glassTint
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.theme.glassBorder
                                      .withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: widget.theme.primaryText,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course Information
                            _buildSectionTitle('Course Information'),
                            const SizedBox(height: 12),
                            _buildEnhancedTextField(
                              controller: _courseNameController,
                              focusNode: _courseNameFocus,
                              label: 'Course Name',
                              hint: 'e.g., Pebble Beach Golf Links',
                              icon: FontAwesomeIcons.mapLocationDot,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Course name is required';
                                }
                                return null;
                              },
                              onChanged: (value) => _processAiSuggestions(),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildDatePicker(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTeeBoxDropdown(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Scoring
                            _buildSectionTitle('Scoring'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildEnhancedTextField(
                                    controller: _scoreController,
                                    focusNode: _scoreFocus,
                                    label: 'Total Score',
                                    hint: '72',
                                    icon: FontAwesomeIcons.bullseye,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Score is required';
                                      }
                                      final score = int.tryParse(value!);
                                      if (score == null ||
                                          score < 50 ||
                                          score > 150) {
                                        return 'Enter a valid score (50-150)';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        _calculateScoreToPar(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEnhancedTextField(
                                    controller: _parTotalController,
                                    focusNode: _parTotalFocus,
                                    label: 'Course Par',
                                    hint: '72',
                                    icon: FontAwesomeIcons.flag,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Par is required';
                                      }
                                      final par = int.tryParse(value!);
                                      if (par == null || par < 60 || par > 80) {
                                        return 'Enter a valid par (60-80)';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) =>
                                        _calculateScoreToPar(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildEnhancedTextField(
                              controller: _puttsController,
                              focusNode: _puttsFocus,
                              label: 'Total Putts',
                              hint: '32',
                              icon: FontAwesomeIcons.golfBallTee,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final putts = int.tryParse(value);
                                  if (putts == null ||
                                      putts < 18 ||
                                      putts > 60) {
                                    return 'Enter valid putts (18-60)';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Statistics
                            _buildSectionTitle('Statistics'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildEnhancedTextField(
                                    controller: _fairwaysHitController,
                                    focusNode: _fairwaysHitFocus,
                                    label: 'Fairways Hit',
                                    hint: '8',
                                    icon: FontAwesomeIcons.road,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        final fairways = int.tryParse(value);
                                        if (fairways == null ||
                                            fairways < 0 ||
                                            fairways > 18) {
                                          return 'Enter valid fairways (0-18)';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEnhancedTextField(
                                    controller: _fairwaysTotalController,
                                    focusNode: _fairwaysTotalFocus,
                                    label: 'Total Fairways',
                                    hint: '14',
                                    icon: FontAwesomeIcons.route,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        final total = int.tryParse(value);
                                        if (total == null ||
                                            total < 0 ||
                                            total > 18) {
                                          return 'Enter valid total (0-18)';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildEnhancedTextField(
                                    controller: _girController,
                                    focusNode: _girFocus,
                                    label: 'Greens in Regulation',
                                    hint: '10',
                                    icon: FontAwesomeIcons.bullseye,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        final gir = int.tryParse(value);
                                        if (gir == null ||
                                            gir < 0 ||
                                            gir > 18) {
                                          return 'Enter valid GIR (0-18)';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildEnhancedTextField(
                                    controller: _girTotalController,
                                    focusNode: _girTotalFocus,
                                    label: 'Total Greens',
                                    hint: '18',
                                    icon: FontAwesomeIcons.circle,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        final total = int.tryParse(value);
                                        if (total == null ||
                                            total < 0 ||
                                            total > 18) {
                                          return 'Enter valid total (0-18)';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // AI Notes Section
                            _buildSectionTitle('AI Notes & Insights'),
                            const SizedBox(height: 12),
                            _buildAiNotesSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),

                    // Submit Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: _isSubmitting
                            ? Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: widget.theme.alternate
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            widget.theme.primaryText,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Saving Round...',
                                        style: widget.theme.bodyMedium.copyWith(
                                          color: widget.theme.primaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GlassDesignSystem.glassButton(
                                text: 'Save Round',
                                onPressed: () {
                                  _submitRound();
                                },
                                theme: widget.theme,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: widget.theme.titleMedium.copyWith(
        color: widget.theme.primaryText,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.theme.glassTint.withValues(alpha: 0.12),
            widget.theme.glassTint.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.theme.glassBorder.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        style: widget.theme.bodyMedium.copyWith(
          color: widget.theme.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: widget.theme.primary,
              size: 18,
            ),
          ),
          labelStyle: widget.theme.bodySmall.copyWith(
            color: widget.theme.secondaryText,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          hintStyle: widget.theme.bodySmall.copyWith(
            color: widget.theme.secondaryText.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          errorStyle: widget.theme.bodySmall.copyWith(
            color: widget.theme.error,
            fontSize: 11,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _showPlatformDatePicker(),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.theme.glassTint.withValues(alpha: 0.12),
              widget.theme.glassTint.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.theme.glassBorder.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: widget.theme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: widget.theme.bodySmall.copyWith(
                      color: widget.theme.secondaryText,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(_selectedDate),
                    style: widget.theme.bodyMedium.copyWith(
                      color: widget.theme.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: widget.theme.secondaryText,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPlatformDatePicker() async {
    if (Platform.isIOS) {
      await _showCupertinoDatePicker();
    } else {
      await _showMaterialDatePicker();
    }
  }

  Future<void> _showCupertinoDatePicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: widget.theme.primaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: widget.theme.bodyMedium.copyWith(
                        color: widget.theme.secondaryText,
                      ),
                    ),
                  ),
                  Text(
                    'Select Date',
                    style: widget.theme.titleMedium.copyWith(
                      color: widget.theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Done',
                      style: widget.theme.bodyMedium.copyWith(
                        color: widget.theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime(2020),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMaterialDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.theme.primary,
              onPrimary: Colors.white,
              surface: widget.theme.primaryBackground,
              onSurface: widget.theme.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildTeeBoxDropdown() {
    final teeBoxes = [
      {'name': 'Black', 'color': Colors.black, 'icon': FontAwesomeIcons.crown},
      {'name': 'Blue', 'color': Colors.blue, 'icon': FontAwesomeIcons.star},
      {
        'name': 'White',
        'color': Colors.grey[600]!,
        'icon': FontAwesomeIcons.circle
      },
      {'name': 'Red', 'color': Colors.red, 'icon': FontAwesomeIcons.heart},
      {'name': 'Gold', 'color': Colors.amber, 'icon': FontAwesomeIcons.medal},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.theme.glassTint.withValues(alpha: 0.12),
            widget.theme.glassTint.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.theme.glassBorder.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTeeBox,
        decoration: InputDecoration(
          labelText: 'Tee Box',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.theme.golfPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              FontAwesomeIcons.golfBallTee,
              color: widget.theme.golfPrimary,
              size: 18,
            ),
          ),
          labelStyle: widget.theme.bodySmall.copyWith(
            color: widget.theme.secondaryText,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        dropdownColor: widget.theme.primaryBackground,
        style: widget.theme.bodyMedium.copyWith(
          color: widget.theme.primaryText,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        items: teeBoxes.map((teeBox) {
          return DropdownMenuItem(
            value: teeBox['name'] as String,
            child: Row(
              children: [
                Icon(
                  teeBox['icon'] as IconData,
                  color: teeBox['color'] as Color,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Text(
                  teeBox['name'] as String,
                  style: widget.theme.bodyMedium.copyWith(
                    color: widget.theme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedTeeBox = value;
            });
          }
        },
      ),
    );
  }

  // AI Integration Methods
  Widget _buildAiNotesSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.theme.aiPrimary.withValues(alpha: 0.08),
                widget.theme.aiSecondary.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.theme.aiPrimary.withValues(alpha: 0.2),
              width: 1.5,
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
                      gradient: widget.theme.aiGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
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
                          'AI Round Assistant',
                          style: widget.theme.titleSmall.copyWith(
                            color: widget.theme.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Add notes about your mental game',
                          style: widget.theme.bodySmall.copyWith(
                            color: widget.theme.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isAiProcessing)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.theme.aiPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: widget.theme.primaryBackground.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.theme.glassBorder.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  controller: _aiNotesController,
                  focusNode: _aiNotesFocus,
                  maxLines: 3,
                  onChanged: (value) => _processAiSuggestions(),
                  style: widget.theme.bodyMedium.copyWith(
                    color: widget.theme.primaryText,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'e.g., "Felt confident on drives, struggled with putting under pressure..."',
                    hintStyle: widget.theme.bodySmall.copyWith(
                      color: widget.theme.secondaryText.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              if (_aiSuggestion.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.theme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.theme.success.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: widget.theme.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _aiSuggestion,
                          style: widget.theme.bodySmall.copyWith(
                            color: widget.theme.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _processAiSuggestions() {
    if (_isAiProcessing) return;

    // Simulate AI processing
    setState(() {
      _isAiProcessing = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isAiProcessing = false;
          _aiSuggestion = _generateAiSuggestion();
        });
      }
    });
  }

  String _generateAiSuggestion() {
    final score = int.tryParse(_scoreController.text) ?? 0;
    final par = int.tryParse(_parTotalController.text) ?? 72;
    final notes = _aiNotesController.text.toLowerCase();

    if (score > 0 && par > 0) {
      final scoreToPar = score - par;
      if (scoreToPar <= -5) {
        return 'Excellent round! Focus on maintaining this mental state in future rounds.';
      } else if (scoreToPar <= 0) {
        return 'Great performance! Consider logging specific mental cues that worked well.';
      } else if (scoreToPar <= 5) {
        return 'Solid round. Identify 2-3 mental strategies to improve consistency.';
      } else {
        return 'Focus on mental fundamentals: pre-shot routine, breathing, and positive self-talk.';
      }
    }

    if (notes.contains('confident')) {
      return 'Confidence is key! Note what specifically made you feel confident.';
    } else if (notes.contains('pressure') || notes.contains('nervous')) {
      return 'Try breathing exercises and visualization for pressure situations.';
    } else if (notes.contains('focus') || notes.contains('distracted')) {
      return 'Consider developing a stronger pre-shot routine to maintain focus.';
    }

    return 'Add more details about your mental game for personalized insights.';
  }

  void _calculateScoreToPar() {
    final score = int.tryParse(_scoreController.text);
    final par = int.tryParse(_parTotalController.text);

    if (score != null && par != null) {
      // You could show this in the UI or use it for AI suggestions
      _processAiSuggestions();
    }
  }

  Future<void> _submitRound() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final score = int.parse(_scoreController.text);
      final parTotal = int.parse(_parTotalController.text);
      final scoreToPar = score - parTotal;

      final roundData = {
        'userId': currentUserUid,
        'date': _selectedDate,
        'courseName': _courseNameController.text.trim(),
        'teeBox': _selectedTeeBox,
        'score': score,
        'parTotal': parTotal,
        'scoreToPar': scoreToPar,
        'totalPutts': _puttsController.text.isNotEmpty
            ? int.parse(_puttsController.text)
            : 0,
        'fairwaysHit': _fairwaysHitController.text.isNotEmpty
            ? int.parse(_fairwaysHitController.text)
            : 0,
        'fairwaysTotal': _fairwaysTotalController.text.isNotEmpty
            ? int.parse(_fairwaysTotalController.text)
            : 0,
        'greensInRegulation':
            _girController.text.isNotEmpty ? int.parse(_girController.text) : 0,
        'greensTotal': _girTotalController.text.isNotEmpty
            ? int.parse(_girTotalController.text)
            : 0,
        'aiNotes': _aiNotesController.text.trim(),
        'aiSuggestion': _aiSuggestion,
        'createdTime': DateTime.now(),
        'updatedTime': DateTime.now(),
        'isValid': true,
      };

      await GolfRoundsRecord.collection.add(roundData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Round saved successfully!'),
            backgroundColor: widget.theme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving round: $e'),
            backgroundColor: widget.theme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
