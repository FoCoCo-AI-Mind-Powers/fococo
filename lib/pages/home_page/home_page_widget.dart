import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/fococo_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
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
        body: StreamBuilder<List<HomeDataRecord>>(
          stream: queryHomeDataRecord(
            queryBuilder: (homeDataRecord) => homeDataRecord
                .where('userId', isEqualTo: currentUserUid)
                .limit(1),
          ),
          builder: (context, snapshot) {
            // Default values
            HomeDataRecord? homeData = snapshot.data?.firstOrNull;
            
            return SafeArea(
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
                          _buildMentalScoreSection(
                            homeData, 
                            primaryAccent, 
                            cardBackground, 
                            lightText, 
                            mutedText
                          ),
                          
                          // Stats Row
                          _buildStatsRow(
                            homeData,
                            cardBackground,
                            lightText,
                            mutedText,
                            primaryAccent,
                            secondaryAccent
                          ),
                          
                          // Performance Chart
                          _buildPerformanceChart(
                            homeData,
                            cardBackground,
                            lightText,
                            mutedText,
                            secondaryAccent
                          ),
                          
                          // Coach Section
                          _buildCoachSection(
                            homeData,
                            cardBackground,
                            lightText,
                            mutedText,
                            primaryAccent
                          ),
                          
                          // Log Round Section
                          _buildLogRoundSection(
                            homeData,
                            cardBackground,
                            lightText,
                            mutedText,
                            primaryAccent,
                            secondaryAccent
                          ),
                          
                          // AI Insights Section
                          _buildAIInsightsSection(
                            homeData,
                            cardBackground,
                            lightText,
                            mutedText,
                            primaryAccent
                          ),
                          
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Bottom Navigation
        bottomNavigationBar: _buildBottomNavigation(
          cardBackground,
          lightText,
          mutedText,
          primaryAccent
        ),
      ),
    );
  }

  Widget _buildHeader(
    HomeDataRecord? data,
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
              const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 16),
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
    HomeDataRecord? data,
    Color primaryAccent,
    Color cardBackground,
    Color lightText,
    Color mutedText,
  ) {
    final mentalScore = data?.mentalScore ?? 76;
    final mentalLabel = data?.mentalScoreLabel ?? 'Mental';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            CircularPercentIndicator(
              radius: 110.0,
              lineWidth: 15.0,
              animation: true,
              percent: mentalScore / 100,
              backgroundColor: cardBackground,
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
    );
  }

  Widget _buildStatsRow(
    HomeDataRecord? data,
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
              label: data?.teeDistanceUnit ?? 'TEE',
              value: data?.teeDistance ?? '252.2',
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
              label: data?.ebedLabel ?? 'EBED',
              value: data?.ebedScore ?? '16',
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
              label: data?.stiksaLabel ?? 'STIKSA',
              value: data?.stiksaScore ?? '46m',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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
    );
  }

  Widget _buildPerformanceChart(
    HomeDataRecord? data,
    Color cardBackground,
    Color lightText,
    Color mutedText,
    Color secondaryAccent,
  ) {
    final performanceData = data?.performanceData ?? [65, 70, 68, 75, 72, 78, 76];
    
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
              data?.performanceTrend ?? 'Your 60 is trending upward',
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
                        return FlSpot(entry.key.toDouble(), entry.value);
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
    HomeDataRecord? data,
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
              data?.welcomeMessage ?? 'Welcome to FoCoCo',
              style: TextStyle(
                color: lightText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data?.coachMessage ?? 'Personates your mental game with expert guides travingic',
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
    HomeDataRecord? data,
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
                            data?.lastRoundScore ?? '83',
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
                              data?.lastRoundDiff ?? '+11',
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
                          data?.lastRoundType ?? 'GOLD',
                          style: TextStyle(
                            color: primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data?.lastRoundStatus ?? 'Bonus',
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
                    'AQ insights',
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
    HomeDataRecord? data,
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
                      'Get personalized recommendations',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
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
}