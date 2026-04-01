import '/backend/backend.dart';
import '/backend/schema/ai_insights_record.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/mental_sessions_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_design_system.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/ai_integration/index.dart';
import '/auth/firebase_auth/auth_util.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import 'ai_insights_model.dart';
import 'widgets/ai_insights_loading_skeletons.dart';
export 'ai_insights_model.dart';

class AiInsightsWidget extends StatefulWidget {
  const AiInsightsWidget({super.key});

  static String routeName = 'ai_insights';
  static String routePath = '/ai_insights';

  @override
  State<AiInsightsWidget> createState() => _AiInsightsWidgetState();
}

class _AiInsightsWidgetState extends State<AiInsightsWidget>
    with TickerProviderStateMixin {
  late AiInsightsModel _model;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Filter state
  String _selectedDateRange = '30 Days';
  String? _selectedCourse;
  String _selectedHoles = '18';
  String? _selectedRoundType;
  String? _selectedWeather;
  String _selectedSortBy = 'Most Recent';
  bool _includeFoCoMap = true;

  // Chat state for Round Review Assistant
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _chatMessages = [];
  bool _isChatExpanded = false;
  bool _isTyping = false;

  // Data loading state
  bool _isLoading = true;
  bool _isGeneratingInsights = false;

  // Dynamic data
  List<AiInsightsRecord> _insights = [];
  List<GolfRoundsRecord> _recentRounds = [];
  List<RoundLogsRecord> _roundLogs = [];
  List<MentalSessionsRecord> _mentalSessions = [];
  UserRecord? _currentUser;

  // Computed insights data
  List<Map<String, dynamic>> _smartHighlights = [];
  List<Map<String, dynamic>> _mindGameLinks = [];
  Map<String, dynamic> _pillarPulse = {};
  List<Map<String, dynamic>> _cuesRoutines = [];
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AiInsightsModel());

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();

    // Add welcome message to chat
    _chatMessages.add(ChatMessage(
      text:
          "Hi! I'm Carter, your AI round review assistant. Ask me anything about your rounds, routines, or mental game performance.",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Load data
    _loadData();
  }

  /// Load all data from Firestore
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = currentUserUid;
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load user data
      final userQuery = queryUserRecord(
        queryBuilder: (q) => q.where('uid', isEqualTo: userId).limit(1),
        singleRecord: true,
      );
      final users = await userQuery.first;
      if (users.isNotEmpty) {
        _currentUser = users.first;
      }

      // Load insights
      await _loadInsights(userId);

      // Load rounds
      await _loadRounds(userId);

      // Load round logs
      await _loadRoundLogs(userId);

      // Load mental sessions
      await _loadMentalSessions(userId);

      // Generate insights if needed
      await _generateInsightsIfNeeded(userId);

      // Process and compute insights
      _processInsightsData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading insights: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load AI insights from Firestore
  Future<void> _loadInsights(String userId) async {
    final dateRange = _getDateRange();
    _insights = await queryCollectionOnce<AiInsightsRecord>(
      AiInsightsRecord.collection,
      AiInsightsRecord.fromSnapshot,
      queryBuilder: (q) => q
          .where('userId', isEqualTo: userId)
          .where('createdTime', isGreaterThanOrEqualTo: dateRange.start)
          .orderBy('createdTime', descending: true)
          .limit(50),
    );
    _insights = _insights.where((insight) => !insight.isFoCoCoDaily).toList();
  }

  /// Load golf rounds from Firestore
  Future<void> _loadRounds(String userId) async {
    final dateRange = _getDateRange();
    _recentRounds = await queryGolfRoundsRecordOnce(
      queryBuilder: (q) {
        var filtered = q
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThanOrEqualTo: dateRange.start)
            .orderBy('date', descending: true);

        if (_selectedCourse != null) {
          filtered = filtered.where('courseName', isEqualTo: _selectedCourse);
        }

        return filtered;
      },
      limit: 30,
    );
  }

  /// Load round logs from Firestore
  Future<void> _loadRoundLogs(String userId) async {
    final dateRange = _getDateRange();
    _roundLogs = await queryCollectionOnce<RoundLogsRecord>(
      RoundLogsRecord.collection,
      RoundLogsRecord.fromSnapshot,
      queryBuilder: (q) => q
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: dateRange.start)
          .orderBy('date', descending: true)
          .limit(30),
    );
  }

  /// Load mental sessions from Firestore
  Future<void> _loadMentalSessions(String userId) async {
    final dateRange = _getDateRange();
    _mentalSessions = await queryCollectionOnce<MentalSessionsRecord>(
      MentalSessionsRecord.collection,
      MentalSessionsRecord.fromSnapshot,
      queryBuilder: (q) => q
          .where('userId', isEqualTo: userId)
          .where('dateCompleted', isGreaterThanOrEqualTo: dateRange.start)
          .orderBy('dateCompleted', descending: true)
          .limit(20),
    );
  }

  /// Generate insights using Gemini if needed
  Future<void> _generateInsightsIfNeeded(String userId) async {
    if (_recentRounds.isEmpty || _isGeneratingInsights) return;

    // Check if we need to generate insights for recent rounds
    final roundsNeedingInsights = _recentRounds
        .where((round) => !round.aiInsightsGenerated)
        .take(3)
        .toList();

    if (roundsNeedingInsights.isEmpty) return;

    setState(() {
      _isGeneratingInsights = true;
    });

    try {
      for (final round in roundsNeedingInsights) {
        try {
          final insight = await FoCoCoAI.generateRoundInsight(
            userId: userId,
            golfRound: round,
            userProfile: _currentUser,
            historicalRounds: _recentRounds.take(10).toList(),
            mentalSessions: _mentalSessions.take(5).toList(),
          );

          // Save insight to Firestore
          await AiInsightsRecord.collection.add({
            'userId': userId,
            'sourceId': round.reference.id,
            'sourceType': 'golf_round',
            'insightType': 'performance_analysis',
            'insightTitle': insight.insightTitle,
            'insightContent': insight.summaryText,
            'keyPoints': insight.keyPoints,
            'recommendations': insight.recommendations
                .map((r) => r.toRecommendationStruct().toMap())
                .toList(),
            'createdTime': FieldValue.serverTimestamp(),
            'generatedTime': FieldValue.serverTimestamp(),
            'aiModel': 'gemini',
            'status': 'active',
          });

          // Update round to mark insights as generated
          await round.reference.update({
            'aiInsightsGenerated': true,
            'aiProcessingStatus': 'completed',
          });
        } catch (e) {
          print('Error generating insight for round ${round.reference.id}: $e');
        }
      }

      // Reload insights after generation
      await _loadInsights(userId);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingInsights = false;
        });
      }
    }
  }

  /// Process insights data to create computed insights
  void _processInsightsData() {
    // Process Smart Highlights from insights
    _smartHighlights = _insights
        .take(3)
        .map((insight) => {
              'title': _categorizeInsight(insight),
              'insight': insight.insightTitle,
              'whyMatters': insight.insightContent,
              'sparklineData': _generateSparklineData(insight),
              'actions': ['Learn', 'Train', 'Review'],
            })
        .toList();

    // Process Mind & Game Links from round logs and insights
    _mindGameLinks = _processMindGameLinks();

    // Process Pillar Pulse from round logs
    _pillarPulse = _processPillarPulse();

    // Process Cues & Routines from round logs
    _cuesRoutines = _processCuesRoutines();

    // Process Recommendations from insights
    _recommendations = _processRecommendations();
  }

  /// Get date range based on selected filter
  ({DateTime start, DateTime end}) _getDateRange() {
    final now = DateTime.now();
    DateTime start;

    switch (_selectedDateRange) {
      case '7 Days':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30 Days':
        start = now.subtract(const Duration(days: 30));
        break;
      case '90 Days':
        start = now.subtract(const Duration(days: 90));
        break;
      default:
        start = now.subtract(const Duration(days: 30));
    }

    return (start: start, end: now);
  }

  /// Categorize insight for Smart Highlights
  String _categorizeInsight(AiInsightsRecord insight) {
    final content = insight.insightContent.toLowerCase();
    if (content.contains('improve') || content.contains('better')) {
      return 'Biggest Positive Influence';
    } else if (content.contains('dip') ||
        content.contains('decrease') ||
        content.contains('worse')) {
      return 'Improvement Area';
    } else {
      return 'Quick Win';
    }
  }

  /// Generate sparkline data from insight
  List<double> _generateSparklineData(AiInsightsRecord insight) {
    // Generate mock data based on insight - in production, use actual performance data
    return [65, 68, 72, 75, 78, 81, 79];
  }

  /// Process Mind & Game Links from data
  List<Map<String, dynamic>> _processMindGameLinks() {
    final links = <Map<String, dynamic>>[];

    // Analyze round logs for patterns
    if (_roundLogs.length >= 3) {
      // Example: Focus vs Approach Accuracy
      final focusRounds =
          _roundLogs.where((log) => log.mindsetFocus >= 80).toList();
      if (focusRounds.isNotEmpty) {
        links.add({
          'headline': 'When Focus above 80, Approach Accuracy improves',
          'keyStat': 'Focus consistency correlates with better approach shots',
          'body':
              'Based on your recent rounds, maintaining high focus leads to more accurate approach shots.',
          'tags': ['Focus', 'Approach', 'Accuracy'],
        });
      }

      // Example: Confidence vs Fairways Hit
      final confidenceRounds =
          _roundLogs.where((log) => log.mindsetConfidence >= 75).toList();
      if (confidenceRounds.isNotEmpty) {
        links.add({
          'headline': 'When Confidence MPI is 75+, Fairways Hit improves',
          'keyStat': 'High confidence correlates with better tee shots',
          'body':
              'Your confidence routines have shown positive correlation with fairway accuracy.',
          'tags': ['Confidence', 'Tee Shots', 'Fairways'],
        });
      }
    }

    // Add insights-based links
    for (final insight in _insights.take(3)) {
      links.add({
        'headline': insight.insightTitle,
        'keyStat': insight.keyPoints.isNotEmpty ? insight.keyPoints.first : '',
        'body': insight.insightContent.length > 100
            ? insight.insightContent.substring(0, 100) + '...'
            : insight.insightContent,
        'tags': insight.category.isNotEmpty ? [insight.category] : ['General'],
      });
    }

    return links.take(5).toList();
  }

  /// Process Pillar Pulse data
  Map<String, dynamic> _processPillarPulse() {
    if (_roundLogs.isEmpty) {
      return {
        'focus': {'change': 'N/A', 'note': 'No data available'},
        'confidence': {'change': 'N/A', 'note': 'No data available'},
        'control': {'change': 'N/A', 'note': 'No data available'},
      };
    }

    // Calculate averages for recent rounds
    final recentLogs = _roundLogs.take(5).toList();
    final olderLogs = _roundLogs.skip(5).take(5).toList();

    final recentFocus =
        recentLogs.map((l) => l.mindsetFocus).reduce((a, b) => a + b) /
            recentLogs.length;
    final olderFocus = olderLogs.isNotEmpty
        ? olderLogs.map((l) => l.mindsetFocus).reduce((a, b) => a + b) /
            olderLogs.length
        : recentFocus;

    final recentConfidence =
        recentLogs.map((l) => l.mindsetConfidence).reduce((a, b) => a + b) /
            recentLogs.length;
    final olderConfidence = olderLogs.isNotEmpty
        ? olderLogs.map((l) => l.mindsetConfidence).reduce((a, b) => a + b) /
            olderLogs.length
        : recentConfidence;

    final recentControl =
        recentLogs.map((l) => l.mindsetControl).reduce((a, b) => a + b) /
            recentLogs.length;
    final olderControl = olderLogs.isNotEmpty
        ? olderLogs.map((l) => l.mindsetControl).reduce((a, b) => a + b) /
            olderLogs.length
        : recentControl;

    return {
      'focus': {
        'change': recentFocus > olderFocus
            ? '+${((recentFocus - olderFocus) / olderFocus * 100).toStringAsFixed(0)}%'
            : '${((recentFocus - olderFocus) / olderFocus * 100).toStringAsFixed(0)}%',
        'note':
            recentFocus > olderFocus ? 'Improving trend' : 'Needs attention',
      },
      'confidence': {
        'change': (recentConfidence - olderConfidence).abs() < 2
            ? 'Steady'
            : recentConfidence > olderConfidence
                ? '+${((recentConfidence - olderConfidence) / olderConfidence * 100).toStringAsFixed(0)}%'
                : '${((recentConfidence - olderConfidence) / olderConfidence * 100).toStringAsFixed(0)}%',
        'note': 'Maintained through routines',
      },
      'control': {
        'change': recentControl > olderControl
            ? '+${((recentControl - olderControl) / olderControl * 100).toStringAsFixed(0)}%'
            : '${((recentControl - olderControl) / olderControl * 100).toStringAsFixed(0)}%',
        'note': recentControl < olderControl
            ? 'Slight dip under pressure'
            : 'Stable',
      },
    };
  }

  /// Process Cues & Routines data
  List<Map<String, dynamic>> _processCuesRoutines() {
    final cues = <Map<String, dynamic>>[];

    // Analyze best cues from round logs
    final bestCues = <String, int>{};
    for (final log in _roundLogs) {
      if (log.bestCue.isNotEmpty) {
        bestCues[log.bestCue] = (bestCues[log.bestCue] ?? 0) + 1;
      }
    }

    if (bestCues.isNotEmpty) {
      final topCue =
          bestCues.entries.reduce((a, b) => a.value > b.value ? a : b);
      cues.add({
        'title': 'Top MindCue',
        'content':
            '${topCue.key} used ${topCue.value} times. Shows positive correlation with performance.',
        'icon': FontAwesomeIcons.comment,
      });
    }

    // Add more cues/routines analysis
    cues.add({
      'title': 'Timing Impact',
      'content':
          'Pre-shot routines show consistent positive impact on performance.',
      'icon': FontAwesomeIcons.clock,
    });

    return cues;
  }

  /// Process Recommendations from insights
  List<Map<String, dynamic>> _processRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    for (final insight in _insights.take(3)) {
      if (insight.recommendations.isNotEmpty) {
        final rec = insight.recommendations.first;
        recommendations.add({
          'title': rec.action.isNotEmpty ? rec.action : 'Recommended Action',
          'content': rec.category.isNotEmpty
              ? '${rec.category} - ${rec.priority} priority'
              : 'Follow this recommendation',
          'example': rec.relatedModuleId.isNotEmpty
              ? 'Module: ${rec.relatedModuleId}'
              : 'Apply in next round',
          'icon': FontAwesomeIcons.dumbbell,
          'color': Theme.of(context).colorScheme.primary,
        });
      }
    }

    // Add default recommendations if none available
    if (recommendations.isEmpty) {
      recommendations.addAll([
        {
          'title': 'Train Now',
          'content': '5–8 min adaptive session built from recent patterns',
          'example': 'Focus Reset – two-breath routine + focus anchor.',
          'icon': FontAwesomeIcons.dumbbell,
          'color': Theme.of(context).colorScheme.primary,
        },
        {
          'title': 'Learn Next',
          'content':
              '1–2 MindCoach modules tailored to current pillar & VARK style',
          'example': 'Visualization Booster (VARK Visual)',
          'icon': FontAwesomeIcons.book,
          'color': Theme.of(context).colorScheme.secondary,
        },
      ]);
    }

    return recommendations;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header Section
                    _buildHeader(theme),

                    // Content
                    Expanded(
                      child: _isLoading
                          ? AIInsightsLoadingSkeletons.buildFullPageSkeleton(
                              theme)
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),

                                  // Filter Search Section
                                  _buildFilterSection(theme),

                                  const SizedBox(height: 32),

                                  // Section 1: Top 3 Smart Highlights
                                  _buildSmartHighlightsSection(theme),

                                  const SizedBox(height: 32),

                                  // Section 2: Mind & Game Links
                                  _buildMindGameLinksSection(theme),

                                  const SizedBox(height: 32),

                                  // Section 3: Pillar Pulse
                                  _buildPillarPulseSection(theme),

                                  const SizedBox(height: 32),

                                  // Section 4: Cues & Routines Effectiveness
                                  _buildCuesRoutinesSection(theme),

                                  const SizedBox(height: 32),

                                  // Section 5: Round Review Assistant
                                  _buildRoundReviewAssistant(theme),

                                  const SizedBox(height: 32),

                                  // Section 6: Recommendations & Next Actions
                                  _buildRecommendationsSection(theme),

                                  const SizedBox(
                                      height: 100), // Space for navbar
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'ai_insights',
          barBackgroundColor: theme.primaryBackground,
          onTap: (route) => context.goNamed(route),
          currentUser: null, // Will be handled by the navbar internally
        ),
      ),
    );
  }

  /// Header with Title and Info Icon
  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insights',
                  style: theme.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Understand what\'s working, and why.',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message:
                'Generated from your rounds, routines, cues, and conversations.',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.glassBackground.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.info_outline,
                color: theme.primaryText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filter Search Section
  Widget _buildFilterSection(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: GlassDesignSystem.glassBlur,
            sigmaY: GlassDesignSystem.glassBlur),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.glassBackground
                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                theme.glassTint
                    .withValues(alpha: GlassDesignSystem.glassOpacity),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder
                  .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filters',
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 16),

              // Date Range Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ['7 Days', '30 Days', '90 Days', 'Custom'].map((range) {
                  return _buildFilterChip(
                    theme,
                    range,
                    _selectedDateRange == range,
                    () => setState(() => _selectedDateRange = range),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Course Dropdown
              _buildDropdown(
                theme,
                'Course: ...',
                _selectedCourse,
                ['Monte Rei', 'Quinta do Lago', 'Vale do Lobo'],
                (value) => setState(() => _selectedCourse = value),
              ),

              const SizedBox(height: 12),

              // Holes Radio
              Row(
                children: [
                  Text(
                    'Holes: ',
                    style: theme.bodyMedium.copyWith(color: theme.primaryText),
                  ),
                  const SizedBox(width: 8),
                  _buildRadioOption(theme, '9', _selectedHoles == '9',
                      () => setState(() => _selectedHoles = '9')),
                  const SizedBox(width: 16),
                  _buildRadioOption(theme, '18', _selectedHoles == '18',
                      () => setState(() => _selectedHoles = '18')),
                ],
              ),

              const SizedBox(height: 12),

              // Round Type Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Tournament', 'Social', 'Practice'].map((type) {
                  return _buildFilterChip(
                    theme,
                    type,
                    _selectedRoundType == type,
                    () => setState(() => _selectedRoundType = type),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Weather Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Sunny',
                  'Cloudy',
                  'Calm',
                  'Wind',
                  'Storm',
                  'Rain',
                  'Cold',
                  'Humid'
                ].map((weather) {
                  return _buildFilterChip(
                    theme,
                    weather,
                    _selectedWeather == weather,
                    () => setState(() => _selectedWeather = weather),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Sort By Dropdown
              _buildDropdown(
                theme,
                'Sort By: Most Recent',
                _selectedSortBy,
                ['Most Recent', 'Best MPI', 'Lowest Score'],
                (value) =>
                    setState(() => _selectedSortBy = value ?? 'Most Recent'),
              ),

              const SizedBox(height: 12),

              // Include FoCoMap Toggle
              Row(
                children: [
                  Text(
                    'Include FoCoMap: ',
                    style: theme.bodyMedium.copyWith(color: theme.primaryText),
                  ),
                  Switch(
                    value: _includeFoCoMap,
                    onChanged: (value) =>
                        setState(() => _includeFoCoMap = value),
                    activeColor: theme.primary,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Reset Filters Button
              FFButtonWidget(
                onPressed: () {
                  setState(() {
                    _selectedDateRange = '30 Days';
                    _selectedCourse = null;
                    _selectedHoles = '18';
                    _selectedRoundType = null;
                    _selectedWeather = null;
                    _selectedSortBy = 'Most Recent';
                    _includeFoCoMap = true;
                  });
                  _loadData(); // Reload data with new filters
                },
                text: 'Reset Filters',
                options: FFButtonOptions(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: theme.secondaryBackground,
                  textStyle: theme.bodyMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(FlutterFlowTheme theme, String label, bool isSelected,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withValues(alpha: 0.2)
              : theme.secondaryBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.primary
                : theme.glassBorder.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: theme.bodySmall.copyWith(
            color: isSelected ? theme.primary : theme.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(FlutterFlowTheme theme, String hint, String? value,
      List<String> options, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint,
            style: theme.bodyMedium.copyWith(color: theme.secondaryText)),
        isExpanded: true,
        underline: Container(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option,
                style: theme.bodyMedium.copyWith(color: theme.primaryText)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRadioOption(FlutterFlowTheme theme, String label,
      bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.primary : theme.secondaryText,
                width: 2,
              ),
              color: isSelected ? theme.primary : Colors.transparent,
            ),
            child: isSelected
                ? Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: theme.bodyMedium.copyWith(color: theme.primaryText)),
        ],
      ),
    );
  }

  /// Section 1: Top 3 Smart Highlights
  Widget _buildSmartHighlightsSection(FlutterFlowTheme theme) {
    if (_smartHighlights.isEmpty && _recentRounds.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3 Smart Highlights',
            style: theme.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The foundation of how you play the game.',
            style: theme.bodyMedium.copyWith(color: theme.secondaryText),
          ),
          const SizedBox(height: 20),
          Text(
            'Log at least 2 rounds or run 1 training session to unlock Smart Highlights.',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 3 Smart Highlights',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'The foundation of how you play the game.',
          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 20),
        ..._smartHighlights.asMap().entries.map((entry) {
          final index = entry.key;
          final highlight = entry.value;
          return Column(
            children: [
              _buildSmartHighlightCard(
                theme,
                title: highlight['title'] as String,
                insight: highlight['insight'] as String,
                whyMatters: highlight['whyMatters'] as String,
                sparklineData: highlight['sparklineData'] as List<double>,
                actions: highlight['actions'] as List<String>,
              ),
              if (index < _smartHighlights.length - 1)
                const SizedBox(height: 16),
            ],
          );
        }),
        if (_smartHighlights.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Generating insights from your rounds...',
            style: theme.bodySmall.copyWith(
              color: theme.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmartHighlightCard(
    FlutterFlowTheme theme, {
    required String title,
    required String insight,
    required String whyMatters,
    required List<double> sparklineData,
    required List<String> actions,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: GlassDesignSystem.glassBlur,
            sigmaY: GlassDesignSystem.glassBlur),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.glassBackground
                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                theme.glassTint
                    .withValues(alpha: GlassDesignSystem.glassOpacity),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder
                  .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini sparkline
              SizedBox(
                height: 40,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sparklineData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),
                        isCurved: true,
                        color: theme.primary,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                insight,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Why this matters: $whyMatters',
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((action) {
                  return FFButtonWidget(
                    onPressed: () {
                      // Handle action
                      if (action == 'Learn') {
                        context.goNamed('mind_coach');
                      } else if (action == 'Train') {
                        context.goNamed('mind_coach');
                      } else if (action == 'Review') {
                        context.goNamed('caddy_play');
                      }
                    },
                    text: action,
                    options: FFButtonOptions(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: theme.primary.withValues(alpha: 0.2),
                      textStyle: theme.bodySmall.copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section 2: Mind & Game Links
  Widget _buildMindGameLinksSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mind & Game Links',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'See what truly drives performance.',
          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 280,
          child: _mindGameLinks.isEmpty
              ? Center(
                  child: Text(
                    'No mind-game links available yet. Log more rounds to see patterns.',
                    style:
                        theme.bodyMedium.copyWith(color: theme.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: _mindGameLinks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final link = entry.value;
                    return Row(
                      children: [
                        _buildMindGameLinkTile(
                          theme,
                          headline: link['headline'] as String,
                          keyStat: link['keyStat'] as String,
                          body: link['body'] as String,
                          tags: link['tags'] as List<String>,
                        ),
                        if (index < _mindGameLinks.length - 1)
                          const SizedBox(width: 16),
                      ],
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'Each tile reveals how your mind and game interact. The more you log, the clearer these patterns become.',
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMindGameLinkTile(
    FlutterFlowTheme theme, {
    required String headline,
    required String keyStat,
    required String body,
    required List<String> tags,
  }) {
    return SizedBox(
      width: 320,
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: GlassDesignSystem.glassBlur,
              sigmaY: GlassDesignSystem.glassBlur),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.glassBackground
                      .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                  theme.glassTint
                      .withValues(alpha: GlassDesignSystem.glassOpacity),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.glassBorder
                    .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    headline,
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    keyStat,
                    style: theme.bodyMedium.copyWith(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: theme.labelSmall.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () => context.goNamed('foco_map'),
                          text: 'View on FoCoMap',
                          options: FFButtonOptions(
                            height: 36,
                            color: theme.primary,
                            textStyle: theme.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FFButtonWidget(
                          onPressed: () => context.goNamed('caddy_play'),
                          text: 'Open LogBook',
                          options: FFButtonOptions(
                            height: 36,
                            color: theme.secondaryBackground,
                            textStyle: theme.bodySmall.copyWith(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                            borderRadius: BorderRadius.circular(12),
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
    );
  }

  /// Section 3: Pillar Pulse
  Widget _buildPillarPulseSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pillar Pulse',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track how your mental foundations evolve.',
          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: GlassDesignSystem.glassBlur,
                sigmaY: GlassDesignSystem.glassBlur),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.glassBackground.withValues(
                        alpha: GlassDesignSystem.glassOpacity + 0.1),
                    theme.glassTint
                        .withValues(alpha: GlassDesignSystem.glassOpacity),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.glassBorder
                      .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  if (_pillarPulse.isNotEmpty) ...[
                    _buildPillarRow(
                      theme,
                      'Focus',
                      _pillarPulse['focus']?['change'] ?? 'N/A',
                      _pillarPulse['focus']?['note'] ?? 'No data',
                      theme.aiPrimary,
                    ),
                    const SizedBox(height: 16),
                    _buildPillarRow(
                      theme,
                      'Confidence',
                      _pillarPulse['confidence']?['change'] ?? 'N/A',
                      _pillarPulse['confidence']?['note'] ?? 'No data',
                      theme.coachingPrimary,
                    ),
                    const SizedBox(height: 16),
                    _buildPillarRow(
                      theme,
                      'Control',
                      _pillarPulse['control']?['change'] ?? 'N/A',
                      _pillarPulse['control']?['note'] ?? 'No data',
                      theme.performanceExcellent,
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No pillar data available. Log rounds to see trends.',
                          style: theme.bodyMedium
                              .copyWith(color: theme.secondaryText),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillarRow(FlutterFlowTheme theme, String pillar, String change,
      String note, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    pillar,
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: change.startsWith('+')
                          ? theme.success.withValues(alpha: 0.2)
                          : change.startsWith('-')
                              ? theme.error.withValues(alpha: 0.2)
                              : theme.secondaryBackground
                                  .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      change,
                      style: theme.bodySmall.copyWith(
                        color: change.startsWith('+')
                            ? theme.success
                            : change.startsWith('-')
                                ? theme.error
                                : theme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Note: $note',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section 4: Cues & Routines Effectiveness
  Widget _buildCuesRoutinesSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cues & Routines Effectiveness',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find what truly works for you, and when.',
          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 20),
        if (_cuesRoutines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No cues and routines data available. Log rounds with routines to see effectiveness.',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._cuesRoutines.asMap().entries.map((entry) {
            final index = entry.key;
            final cue = entry.value;
            return Column(
              children: [
                _buildCuesRoutinesCard(
                  theme,
                  title: cue['title'] as String,
                  content: cue['content'] as String,
                  icon: cue['icon'] as IconData,
                ),
                if (index < _cuesRoutines.length - 1)
                  const SizedBox(height: 16),
              ],
            );
          }),
        const SizedBox(height: 12),
        Text(
          'The more you log your Routines and MindCues, the smarter your personal analytics become.',
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildCuesRoutinesCard(FlutterFlowTheme theme,
      {required String title,
      required String content,
      required IconData icon}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: GlassDesignSystem.glassBlur,
            sigmaY: GlassDesignSystem.glassBlur),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.glassBackground
                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                theme.glassTint
                    .withValues(alpha: GlassDesignSystem.glassOpacity),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder
                  .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: theme.primary, size: 24),
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
                          content,
                          style: theme.bodyMedium.copyWith(
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: () => context.goNamed('mind_coach'),
                      text: 'Add to Training Plan',
                      options: FFButtonOptions(
                        height: 40,
                        color: theme.primary,
                        textStyle: theme.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: () => context.goNamed('foco_map'),
                      text: 'See on FoCoMap',
                      options: FFButtonOptions(
                        height: 40,
                        color: theme.secondaryBackground,
                        textStyle: theme.bodySmall.copyWith(
                          color: theme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  /// Section 5: Round Review Assistant
  Widget _buildRoundReviewAssistant(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round Review Assistant',
                  style: theme.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask Carter. Get answers from your data.',
                  style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
            IconButton(
              onPressed: () =>
                  setState(() => _isChatExpanded = !_isChatExpanded),
              icon: Icon(
                _isChatExpanded ? Icons.expand_less : Icons.expand_more,
                color: theme.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isChatExpanded ? 400 : 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: GlassDesignSystem.glassBlur,
                  sigmaY: GlassDesignSystem.glassBlur),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.glassBackground.withValues(
                          alpha: GlassDesignSystem.glassOpacity + 0.1),
                      theme.glassTint
                          .withValues(alpha: GlassDesignSystem.glassOpacity),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.glassBorder.withValues(
                        alpha: GlassDesignSystem.glassBorderOpacity),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Prompt Suggestions - Made more compact
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        'Why did my focus drop on hole 7?',
                        'Which MindCue helped my tee shots most this week?',
                        'What changed on windy days?',
                      ].map((suggestion) {
                        return GestureDetector(
                          onTap: () {
                            _chatController.text = suggestion;
                            _sendChatMessage();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              suggestion,
                              style: theme.bodySmall.copyWith(
                                color: theme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 6),

                    // Chat Messages - Made flexible to prevent overflow
                    Expanded(
                      child: ListView.builder(
                        controller: _chatScrollController,
                        shrinkWrap: false,
                        padding: EdgeInsets.zero,
                        itemCount: _chatMessages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _chatMessages.length && _isTyping) {
                            return _buildTypingIndicator(theme);
                          }
                          return _buildChatMessage(theme, _chatMessages[index]);
                        },
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Input Area
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.glassBorder.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _chatController,
                              style: theme.bodyMedium
                                  .copyWith(color: theme.primaryText),
                              decoration: InputDecoration(
                                hintText: 'Ask about your rounds...',
                                hintStyle: theme.bodyMedium
                                    .copyWith(color: theme.secondaryText),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _sendChatMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primary,
                                theme.primary.withValues(alpha: 0.8)
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _sendChatMessage,
                            icon:
                                Icon(Icons.send, color: Colors.white, size: 20),
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
        const SizedBox(height: 12),
        Text(
          'All responses are educational and performance-focused, not medical advice.',
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessage(FlutterFlowTheme theme, ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [theme.aiPrimary, theme.aiSecondary]),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(FontAwesomeIcons.brain, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.primary.withValues(alpha: 0.2)
                    : theme.secondaryBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: theme.bodySmall.copyWith(
                  color: theme.primaryText,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [theme.aiPrimary, theme.aiSecondary]),
              shape: BoxShape.circle,
            ),
            child: Icon(FontAwesomeIcons.brain, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.secondaryBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(theme, 0),
                const SizedBox(width: 4),
                _buildTypingDot(theme, 200),
                const SizedBox(width: 4),
                _buildTypingDot(theme, 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(FlutterFlowTheme theme, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * (value * 2 - 1).abs()),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.secondaryText,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  void _sendChatMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _chatMessages.add(ChatMessage(
          text: userMessage, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });

    _scrollChatToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _chatMessages.add(ChatMessage(
            text: _generateAIResponse(userMessage),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollChatToBottom();
      }
    });
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    if (message.contains('focus') || message.contains('hole 7')) {
      return 'Based on your data, focus dropped on hole 7 likely due to fatigue. Your average focus score decreases by 12% after the 6th hole. Try implementing a reset routine between holes 6 and 7.';
    } else if (message.contains('mindcue') || message.contains('tee')) {
      return 'Self-Talk has been your most effective MindCue for tee shots this week, improving fairway accuracy by 11%. Visualization comes second with 8% improvement.';
    } else if (message.contains('windy')) {
      return 'On windy days, your confidence routines become more critical. When you maintain your breathing routine, your score improves by an average of 3 strokes compared to rounds where you skip it.';
    }
    return 'I\'m analyzing your question based on your recent rounds and performance data. Let me provide you with personalized insights...';
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Section 6: Recommendations & Next Actions
  Widget _buildRecommendationsSection(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations & Next Actions',
          style: theme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Turn insight into improvement.',
          style: theme.bodyMedium.copyWith(color: theme.secondaryText),
        ),
        const SizedBox(height: 20),
        if (_recommendations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No recommendations available. Complete more rounds to get personalized recommendations.',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final rec = entry.value;
            return Column(
              children: [
                _buildRecommendationCard(
                  theme,
                  title: rec['title'] as String,
                  content: rec['content'] as String,
                  example: rec['example'] as String,
                  icon: rec['icon'] as IconData,
                  color: rec['color'] as Color,
                  onTap: () {
                    if (rec['title'] == 'Train Now' ||
                        rec['title'] == 'Learn Next') {
                      context.goNamed('mind_coach');
                    } else {
                      context.goNamed('caddy_play');
                    }
                  },
                ),
                if (index < _recommendations.length - 1)
                  const SizedBox(height: 16),
              ],
            );
          }),
        const SizedBox(height: 12),
        Text(
          'Smart Recommendations refresh automatically after each logged round or training session.',
          style: theme.bodySmall.copyWith(
            color: theme.secondaryText,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    FlutterFlowTheme theme, {
    required String title,
    required String content,
    required String example,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: GlassDesignSystem.glassBlur,
              sigmaY: GlassDesignSystem.glassBlur),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.glassBackground
                      .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                  theme.glassTint
                      .withValues(alpha: GlassDesignSystem.glassOpacity),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.glassBorder
                    .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Example: $example',
                          style: theme.bodySmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: theme.secondaryText, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
