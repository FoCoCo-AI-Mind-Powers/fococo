import '/services/home_data_service.dart';
import '/services/focomap_tutorial_service.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/fococo_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'home_page';
  static String routePath = '/home_page';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;
  final HomeDataService _homeDataService = HomeDataService();
  final FoCoMapTutorialService _tutorialService = FoCoMapTutorialService();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Tutorial keys
  final GlobalKey _mentalScoreKey = GlobalKey();
  final GlobalKey _coachSectionKey = GlobalKey();
  final GlobalKey _logRoundKey = GlobalKey();
  final GlobalKey _aiInsightsKey = GlobalKey();
  final GlobalKey _performanceChartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    _checkAndShowTutorial();
  }

  /// Check if user needs onboarding tutorial
  Future<void> _checkAndShowTutorial() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final hasCompletedTutorial =
        await _tutorialService.hasCompletedMainTutorial();
    if (!hasCompletedTutorial && mounted) {
      _showHomeTutorial();
    }
  }

  /// Show home page tutorial
  void _showHomeTutorial() {
    _tutorialService.showQuickTip(
      context,
      targetKey: _mentalScoreKey,
      title: 'Mental Performance Score',
      description:
          'Track your mental game progress. This score is calculated from your recent rounds and coaching activities.',
      icon: Icons.psychology,
      color: const Color(0xFFFFB800),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme colors based on dashboard
    final deepOceanBlue = const Color(0xFF0A1628);
    final primaryAccent = const Color(0xFFFFB800);
    final secondaryAccent = const Color(0xFF00C9A7);
    final cardBackground = const Color(0xFF162238);
    final lightText = Colors.white;
    final mutedText = Colors.white.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: deepOceanBlue,
        extendBody: true,
        body: StreamBuilder<HomeData>(
          stream: _homeDataService.getHomeDataStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final homeData = snapshot.data;
            if (homeData == null) {
              return _buildLoadingState();
            }

            // Show empty state for new users
            if (!homeData.hasData) {
              return _buildEmptyState(homeData);
            }

            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              // Header Section
                              _buildHeader(homeData, lightText, mutedText),

                              // Mental Score Circle
                              Container(
                                key: _mentalScoreKey,
                                child: _buildMentalScoreSection(
                                    homeData,
                                    primaryAccent,
                                    cardBackground,
                                    lightText,
                                    mutedText),
                              ),

                              // Stats Row
                              _buildStatsRow(
                                  homeData,
                                  cardBackground,
                                  lightText,
                                  mutedText,
                                  primaryAccent,
                                  secondaryAccent),

                              // Performance Chart
                              Container(
                                key: _performanceChartKey,
                                child: _buildPerformanceChart(
                                    homeData,
                                    cardBackground,
                                    lightText,
                                    mutedText,
                                    secondaryAccent),
                              ),

                              // Coach Section
                              Container(
                                key: _coachSectionKey,
                                child: _buildCoachSection(
                                    homeData,
                                    cardBackground,
                                    lightText,
                                    mutedText,
                                    primaryAccent),
                              ),

                              // Log Round Section
                              Container(
                                key: _logRoundKey,
                                child: _buildLogRoundSection(
                                    homeData,
                                    cardBackground,
                                    lightText,
                                    mutedText,
                                    primaryAccent,
                                    secondaryAccent),
                              ),

                              // AI Insights Section
                              Container(
                                key: _aiInsightsKey,
                                child: _buildAIInsightsSection(
                                    homeData,
                                    cardBackground,
                                    lightText,
                                    mutedText,
                                    primaryAccent),
                              ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Voice Button
                const FloatingVoiceButton(),
              ],
            );
          },
        ),
        // Bottom Navigation
        bottomNavigationBar: _buildBottomNavigation(
            cardBackground, lightText, mutedText, primaryAccent),
      ),
    );
  }

  Widget _buildHeader(
    HomeData data,
    Color lightText,
    Color mutedText,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FoCoCoLogo(
            size: LogoSize.medium,
            showText: true,
            color: lightText,
            animated: true,
          ),
          Row(
            children: [
              const Icon(Icons.signal_cellular_alt,
                  color: Colors.white, size: 16),
              const SizedBox(width: 4),
              const Icon(Icons.wifi, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              const Icon(Icons.battery_full, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                '9:41',
                style: TextStyle(
                  color: lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentalScoreSection(
    HomeData data,
    Color primaryAccent,
    Color cardBackground,
    Color lightText,
    Color mutedText,
  ) {
    final mentalScore = data.mentalScore;
    final mentalLabel = data.mentalScoreLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(110),
          boxShadow: [
            BoxShadow(
              color: primaryAccent.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(110),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardBackground.withValues(alpha: 0.8),
                    cardBackground.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(110),
                border: Border.all(
                  color: lightText.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  CircularPercentIndicator(
                    radius: 100.0,
                    lineWidth: 12.0,
                    animation: true,
                    percent: mentalScore / 100,
                    backgroundColor: cardBackground.withValues(alpha: 0.3),
                    progressColor: primaryAccent,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  // Inner content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$mentalScore',
                        style: TextStyle(
                          color: lightText,
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Montserrat',
                          shadows: [
                            Shadow(
                              color: primaryAccent.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        mentalLabel,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildStatsRow(
    HomeData data,
    Color cardBackground,
    Color lightText,
    Color mutedText,
    Color primaryAccent,
    Color secondaryAccent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              label: data.teeDistanceUnit,
              value: data.teeDistance,
              unit: 'm',
              color: primaryAccent,
              cardBackground: cardBackground,
              lightText: lightText,
              mutedText: mutedText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: data.ebedLabel,
              value: data.ebedScore,
              unit: '',
              color: secondaryAccent,
              cardBackground: cardBackground,
              lightText: lightText,
              mutedText: mutedText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              label: data.stiksaLabel,
              value: data.stiksaScore,
              unit: '',
              color: Colors.purpleAccent,
              cardBackground: cardBackground,
              lightText: lightText,
              mutedText: mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required Color cardBackground,
    required Color lightText,
    required Color mutedText,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardBackground.withValues(alpha: 0.8),
                cardBackground.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        color: lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: unit,
                        style: TextStyle(
                          color: mutedText,
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
      ),
    );
  }

  Widget _buildPerformanceChart(
    HomeData data,
    Color cardBackground,
    Color lightText,
    Color mutedText,
    Color secondaryAccent,
  ) {
    final performanceData = data.performanceData.isNotEmpty
        ? data.performanceData
        : [65, 70, 68, 75, 72, 78, 76];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance',
                  style: TextStyle(
                    color: lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Icon(
                  Icons.trending_up,
                  color: secondaryAccent,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.performanceTrend,
              style: TextStyle(
                color: mutedText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: performanceData.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: secondaryAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: secondaryAccent.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachSection(
    HomeData data,
    Color cardBackground,
    Color lightText,
    Color mutedText,
    Color primaryAccent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Coach Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: primaryAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.welcomeMessage,
              style: TextStyle(
                color: lightText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.coachMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FFButtonWidget(
              onPressed: () => context.goNamed('coaching_modules'),
              text: 'Start',
              options: FFButtonOptions(
                width: double.infinity,
                height: 48,
                color: primaryAccent,
                textStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                elevation: 0,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogRoundSection(
    HomeData data,
    Color cardBackground,
    Color lightText,
    Color mutedText,
    Color primaryAccent,
    Color secondaryAccent,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: () => context.goNamed('golf_rounds'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Round',
                style: TextStyle(
                  color: lightText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backline',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            data.lastRoundScore,
                            style: TextStyle(
                              color: lightText,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: secondaryAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data.lastRoundDiff,
                              style: TextStyle(
                                color: secondaryAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.lastRoundType,
                          style: TextStyle(
                            color: primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.lastRoundStatus,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data.aiInsightTitle,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: mutedText,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsightsSection(
    HomeData data,
    Color cardBackground,
    Color lightText,
    Color mutedText,
    Color primaryAccent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => context.goNamed('ai_insights'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAccent.withValues(alpha: 0.8),
                primaryAccent.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                FontAwesomeIcons.brain,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.aiInsightContent.isNotEmpty
                          ? data.aiInsightContent
                          : 'Get personalized recommendations',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    Color cardBackground,
    Color lightText,
    Color mutedText,
    Color primaryAccent,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isActive: true,
            lightText: lightText,
            mutedText: mutedText,
            primaryAccent: primaryAccent,
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.psychology_outlined,
            label: 'Coach',
            isActive: false,
            lightText: lightText,
            mutedText: mutedText,
            primaryAccent: primaryAccent,
            onTap: () => context.goNamed('coaching_modules'),
          ),
          _buildNavItem(
            icon: FontAwesomeIcons.golfBallTee,
            label: 'Rounds',
            isActive: false,
            lightText: lightText,
            mutedText: mutedText,
            primaryAccent: primaryAccent,
            onTap: () => context.goNamed('golf_rounds'),
          ),
          _buildNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: false,
            lightText: lightText,
            mutedText: mutedText,
            primaryAccent: primaryAccent,
            onTap: () => context.goNamed('profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color lightText,
    required Color mutedText,
    required Color primaryAccent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? primaryAccent : mutedText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryAccent : mutedText,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading state with shimmer effects
  Widget _buildLoadingState() {
    final cardBackground = const Color(0xFF162238);
    final lightText = Colors.white;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FoCoCoLogo(
                    size: LogoSize.medium,
                    showText: true,
                    color: lightText,
                    animated: true,
                  ),
                  Shimmer.fromColors(
                    baseColor: cardBackground,
                    highlightColor: lightText.withValues(alpha: 0.1),
                    child: Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mental Score Loading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Shimmer.fromColors(
                baseColor: cardBackground,
                highlightColor: lightText.withValues(alpha: 0.1),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBackground,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Stats Row Loading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                    3,
                    (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                            child: Shimmer.fromColors(
                              baseColor: cardBackground,
                              highlightColor: lightText.withValues(alpha: 0.1),
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        )),
              ),
            ),

            // Performance Chart Loading
            Padding(
              padding: const EdgeInsets.all(20),
              child: Shimmer.fromColors(
                baseColor: cardBackground,
                highlightColor: lightText.withValues(alpha: 0.1),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            // Coach Section Loading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Shimmer.fromColors(
                baseColor: cardBackground,
                highlightColor: lightText.withValues(alpha: 0.1),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    final cardBackground = const Color(0xFF162238);
    final lightText = Colors.white;
    final mutedText = Colors.white.withValues(alpha: 0.7);
    final primaryAccent = const Color(0xFFFFB800);

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        color: lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'re having trouble loading your data. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FFButtonWidget(
                      onPressed: () => setState(() {}),
                      text: 'Retry',
                      options: FFButtonOptions(
                        width: 120,
                        height: 48,
                        color: primaryAccent,
                        textStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 0,
                        borderRadius: BorderRadius.circular(24),
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

  /// Build empty state for new users
  Widget _buildEmptyState(HomeData homeData) {
    final primaryAccent = const Color(0xFFFFB800);
    final secondaryAccent = const Color(0xFF00C9A7);
    final cardBackground = const Color(0xFF162238);
    final lightText = Colors.white;
    final mutedText = Colors.white.withValues(alpha: 0.7);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header
            _buildHeader(homeData, lightText, mutedText),

            // Welcome Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryAccent.withValues(alpha: 0.8),
                      secondaryAccent.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      homeData.welcomeMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      homeData.coachMessage,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Getting Started Guide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get Started with FoCoCo',
                      style: TextStyle(
                        color: lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGettingStartedStep(
                      icon: Icons.school,
                      title: 'Take Coaching Modules',
                      description: 'Learn mental performance techniques',
                      color: primaryAccent,
                      onTap: () => context.goNamed('coaching_modules'),
                    ),
                    const SizedBox(height: 12),
                    _buildGettingStartedStep(
                      icon: FontAwesomeIcons.golfBallTee,
                      title: 'Log Your First Round',
                      description: 'Track your mental game on the course',
                      color: secondaryAccent,
                      onTap: () => context.goNamed('golf_rounds'),
                    ),
                    const SizedBox(height: 12),
                    _buildGettingStartedStep(
                      icon: Icons.map,
                      title: 'Explore FoCoMap',
                      description: 'Visualize your performance data',
                      color: Colors.purpleAccent,
                      onTap: () => context.goNamed('focomap'),
                    ),
                    const SizedBox(height: 12),
                    _buildGettingStartedStep(
                      icon: Icons.psychology,
                      title: 'Get AI Insights',
                      description: 'Receive personalized recommendations',
                      color: Colors.blueAccent,
                      onTap: () => context.goNamed('ai_insights'),
                    ),
                  ],
                ),
              ),
            ),

            // Tutorial Prompt
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: primaryAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              color: lightText,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take a quick tour to learn the basics',
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FFButtonWidget(
                      onPressed: _showHomeTutorial,
                      text: 'Tour',
                      options: FFButtonOptions(
                        width: 80,
                        height: 36,
                        color: primaryAccent,
                        textStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 0,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Build getting started step item
  Widget _buildGettingStartedStep({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final lightText = Colors.white;
    final mutedText = Colors.white.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: TextStyle(
                      color: lightText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 14,
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
}
