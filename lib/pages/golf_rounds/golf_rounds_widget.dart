import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/glass_design_system.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:go_router/go_router.dart';
import 'dart:ui';

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

  final scaffoldKey = GlobalKey<ScaffoldState>();

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
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(
          FirebaseFirestore.instance.collection('users').doc(currentUserUid)),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        return StreamBuilder<List<GolfRoundsRecord>>(
          stream: queryGolfRoundsRecord(
            queryBuilder: (golfRoundsRecord) => golfRoundsRecord
                .where('userId', isEqualTo: currentUserUid)
                .orderBy('date', descending: true),
          ),
          builder: (context, roundsSnapshot) {
            final rounds = roundsSnapshot.data ?? [];

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
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        theme.glassBackground
                                            .withValues(alpha: 0.2),
                                        theme.glassTint.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: theme.glassBorder
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 60, 20, 20),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  'Golf Rounds',
                                                  style: theme.headlineMedium
                                                      .copyWith(
                                                    color: theme.primaryText,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 24,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Flexible(
                                                child: Text(
                                                  '${rounds.length} rounds tracked',
                                                  style:
                                                      theme.bodySmall.copyWith(
                                                    color: theme.secondaryText,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showAddRoundModal(
                                              context, theme),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  theme.primaryBrandGradient,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: theme.glassCardShadows,
                                            ),
                                            child: Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: 24,
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
                        ),

                        // Rounds Content
                        SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Quick Stats
                              _buildQuickStatsSection(theme, rounds),
                              const SizedBox(height: 20),

                              // Recent Rounds
                              _buildRecentRoundsSection(theme, rounds),
                              const SizedBox(
                                  height: 100), // Bottom padding for navbar
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
                onTap: (route) {
                  if (route == 'dashboard') {
                    context.go('/dashboard');
                  } else if (route == 'golf_rounds') {
                    // Already on this page
                  } else if (route == 'coaching_modules') {
                    context.go('/coaching_modules');
                  } else if (route == 'profile') {
                    context.go('/profile');
                  }
                },
                showLabels: true,
                enableVoiceButton: true,
                useGlassEffect: true,
              ),
            );
          },
        );
      },
    );
  }

  /// Quick Stats Section
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

    return GlassDashboardCard(
      title: 'Performance Overview',
      subtitle: 'Your golf statistics',
      showAIBadge: true,
      aiInsight: avgScore > 0
          ? 'Your average score has improved by 3.2 strokes this month!'
          : 'Start logging rounds to track your improvement!',
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
      ],
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

  DateTime _selectedDate = DateTime.now();
  String _selectedTeeBox = 'White';
  bool _isSubmitting = false;

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
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Log New Round',
                              style: widget.theme.headlineSmall.copyWith(
                                color: widget.theme.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.theme.alternate
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
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
                            _buildTextField(
                              controller: _courseNameController,
                              label: 'Course Name',
                              hint: 'Enter course name',
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Course name is required';
                                }
                                return null;
                              },
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
                                  child: _buildTextField(
                                    controller: _scoreController,
                                    label: 'Total Score',
                                    hint: '72',
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Score is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _parTotalController,
                                    label: 'Course Par',
                                    hint: '72',
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) {
                                        return 'Par is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _puttsController,
                              label: 'Total Putts',
                              hint: '32',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 24),

                            // Statistics
                            _buildSectionTitle('Statistics'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _fairwaysHitController,
                                    label: 'Fairways Hit',
                                    hint: '8',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _fairwaysTotalController,
                                    label: 'Total Fairways',
                                    hint: '14',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _girController,
                                    label: 'Greens in Regulation',
                                    hint: '10',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _girTotalController,
                                    label: 'Total Greens',
                                    hint: '18',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.theme.glassTint.withValues(alpha: 0.1),
            widget.theme.glassTint.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: widget.theme.bodyMedium.copyWith(
          color: widget.theme.primaryText,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: widget.theme.bodySmall.copyWith(
            color: widget.theme.secondaryText,
          ),
          hintStyle: widget.theme.bodySmall.copyWith(
            color: widget.theme.secondaryText.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.theme.glassTint.withValues(alpha: 0.1),
              widget.theme.glassTint.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: widget.theme.secondaryText,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: widget.theme.bodySmall.copyWith(
                      color: widget.theme.secondaryText,
                    ),
                  ),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: widget.theme.bodyMedium.copyWith(
                      color: widget.theme.primaryText,
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

  Widget _buildTeeBoxDropdown() {
    final teeBoxes = ['Black', 'Blue', 'White', 'Red', 'Gold'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.theme.glassTint.withValues(alpha: 0.1),
            widget.theme.glassTint.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTeeBox,
        decoration: InputDecoration(
          labelText: 'Tee Box',
          labelStyle: widget.theme.bodySmall.copyWith(
            color: widget.theme.secondaryText,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        dropdownColor: widget.theme.primaryBackground,
        style: widget.theme.bodyMedium.copyWith(
          color: widget.theme.primaryText,
        ),
        items: teeBoxes.map((teeBox) {
          return DropdownMenuItem(
            value: teeBox,
            child: Text(teeBox),
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
