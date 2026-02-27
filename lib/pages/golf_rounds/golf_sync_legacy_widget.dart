// ignore_for_file: unnecessary_import, unused_field, unused_element, deprecated_member_use, dead_null_aware_expression

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/glass_design_system.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/ai_integration/index.dart';
import '/ai_integration/models/gemini_models.dart';
import '/services/app_tutorial_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'golf_round_modal_grint_style.dart';

class GolfSyncLegacyWidget extends StatefulWidget {
  const GolfSyncLegacyWidget({super.key});

  static String routeName = 'golf_sync_legacy';
  static String routePath = '/golf_sync_legacy';

  @override
  State<GolfSyncLegacyWidget> createState() => _GolfSyncLegacyWidgetState();
}

class _GolfSyncLegacyWidgetState extends State<GolfSyncLegacyWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AppTutorialService _tutorialService = AppTutorialService();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Zone Tab State
  String _swingDirection = 'Right';
  String _dominantHand = 'Right';
  String _dominantEye = 'Right';
  double _handicapIndex = 18.0;
  String _playLevel = 'Casual Golfer';
  String _courseLength = '6000 - 7000';
  String _playFrequency = 'Once per week';
  Set<String> _selectedClubs = {};
  Map<String, double> _clubDistances = {};
  String _distanceUnit = 'Yards'; // or 'Meters'

  // +Round Tab State
  DateTime _roundDate = DateTime.now();
  String _courseName = '';
  int _holes = 18;
  int _courseLengthValue = 0;
  String _roundType = 'Social';
  String _courseSetup = 'Normal';
  String _courseCondition = 'Ideal / Perfect';
  String _greenSpeed = 'Medium (8-10)';
  Set<String> _weatherConditions = {};
  String _startTime = 'Morning';

  // LogBook Tab State
  String _selectedDateFilter = '30 Days';
  String? _selectedCourseFilter;
  int? _selectedHolesFilter;
  String? _selectedRoundTypeFilter;
  Set<String> _selectedWeatherFilters = {};
  String _sortBy = 'Most Recent';
  bool _includeFoCoMap = true;

  // Trends Tab State
  String _trendsDateFilter = '30 Days';
  String? _trendsCourseFilter;
  int? _trendsHolesFilter;
  String? _trendsRoundTypeFilter;
  Set<String> _trendsWeatherFilters = {};
  String _trendsSortBy = 'Most Recent';
  bool _trendsIncludeFoCoMap = true;

  // Shared streams
  Stream<UserRecord>? _userRecordStream;
  Stream<List<GolfRoundsRecord>>? _roundsStream;
  Stream<DocumentSnapshot>? _zoneSettingsStream;
  StreamSubscription<DocumentSnapshot>? _zoneSettingsSubscription;

  // Loading states
  bool _isSavingZoneSettings = false;
  bool _isLoadingZoneSettings = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    _initializeSharedStreams();
    _loadUserSettings();
  }

  void _initializeSharedStreams() {
    if (currentUserUid.isNotEmpty) {
      _userRecordStream = UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/$currentUserUid'))
          .asBroadcastStream();

      _roundsStream = queryGolfRoundsRecord(
        queryBuilder: (golfRoundsRecord) => golfRoundsRecord
            .where('userId', isEqualTo: currentUserUid)
            .orderBy('date', descending: true),
      ).asBroadcastStream();
    }
  }

  Future<void> _loadUserSettings() async {
    if (currentUserUid.isEmpty) return;

    try {
      final userDocSnapshot =
          await FirebaseFirestore.instance.doc('user/$currentUserUid').get();

      if (userDocSnapshot.exists) {
        final userData = userDocSnapshot.data();
        if (userData != null && userData['handicap'] != null) {
          setState(() {
            _handicapIndex = (userData['handicap'] as num).toDouble();
          });
        }
      }
    } catch (e) {
      print('Error loading user settings: $e');
    }
  }

  /// Save Zone settings to Firestore in real-time
  Future<void> _saveZoneSettingsToFirestore() async {
    if (currentUserUid.isEmpty || _isSavingZoneSettings) return;

    setState(() => _isSavingZoneSettings = true);

    try {
      final zoneSettings = {
        'swingDirection': _swingDirection,
        'dominantHand': _dominantHand,
        'dominantEye': _dominantEye,
        'handicapIndex': _handicapIndex,
        'playLevel': _playLevel,
        'courseLength': _courseLength,
        'playFrequency': _playFrequency,
        'distanceUnit': _distanceUnit,
        'selectedClubs': _selectedClubs.toList(),
        'clubDistances': _clubDistances.map(
          (key, value) => MapEntry(key, value),
        ),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.doc('user/$currentUserUid').update({
        'golfZoneSettings': zoneSettings,
        'handicap': _handicapIndex, // Also update main handicap field
        'lastActive': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zone settings saved'),
            duration: const Duration(seconds: 2),
            backgroundColor: FlutterFlowTheme.of(context).success,
          ),
        );
      }
    } catch (e) {
      print('Error saving Zone settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingZoneSettings = false);
      }
    }
  }

  @override
  void dispose() {
    _zoneSettingsSubscription?.cancel();
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (currentUserUid.isEmpty) {
      return _buildAuthErrorScaffold(theme);
    }

    return StreamBuilder<UserRecord>(
      stream: _userRecordStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold(theme, null);
        }

        if (userSnapshot.hasError) {
          return _buildErrorScaffold(theme, null, 'Error loading user data');
        }

        final user = userSnapshot.data;

        return StreamBuilder<List<GolfRoundsRecord>>(
          stream: _roundsStream,
          builder: (context, roundsSnapshot) {
            if (roundsSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScaffold(theme, user);
            }

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

  Widget _buildMainScaffold(
      FlutterFlowTheme theme, UserRecord? user, List<GolfRoundsRecord> rounds) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      drawer: user != null
          ? FoCoCoDrawer(
              currentUser: user,
              currentRoute: 'caddy_play',
              onNavigate: (route) => context.goNamed(route),
            )
          : null,
      body: Stack(
        children: [
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
                      // Custom App Bar with Hamburger Menu
                      _buildCustomAppBar(theme),

                      // Tab Bar
                      _buildTabBar(theme),

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildZoneTab(theme, user),
                            _buildAddRoundTab(theme, rounds),
                            _buildLogBookTab(theme, rounds),
                            _buildTrendsTab(theme, rounds),
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
        currentRoute: 'caddy_play',
        currentUser: user,
        onTap: (route) => _handleNavigation(route),
        showLabels: true,
        enableVoiceButton: true,
        useGlassEffect: true,
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: theme.glassBorder.withValues(alpha: 0.15),
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
      child: Row(
        children: [
          // Hamburger Menu
          GestureDetector(
            onTap: () => scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.glassTint.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.glassBorder.withValues(alpha: 0.3),
                  width: 1.5,
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
          // Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GolfSync',
                  style: theme.headlineLarge.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                    fontSize: 32,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) {
                    return Text(
                      _getTabSubtitle(),
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTabSubtitle() {
    switch (_tabController.index) {
      case 0:
        return 'Define your game once. FoCoCo will adapt, learn and update accordingly';
      case 1:
        return 'Log your golf round manually. When you don\'t have access to JustTalk or microphone & GPS are turned off.';
      case 2:
        return 'Track every round. Understand what shaped your performance.';
      case 3:
        return 'See how your mind & game evolve together';
      default:
        return '';
    }
  }

  Widget _buildTabBar(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              color: Colors.transparent,
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
                'Zone',
                Icons.settings,
                theme.golfPrimary,
                _tabController.index == 0,
              ),
              _buildFilledTab(
                '+ Round',
                Icons.add_circle,
                theme.success,
                _tabController.index == 1,
              ),
              _buildFilledTab(
                'LogBook',
                Icons.book,
                theme.info,
                _tabController.index == 2,
              ),
              _buildFilledTab(
                'Trends',
                Icons.trending_up,
                theme.warning,
                _tabController.index == 3,
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: theme.secondaryText,
            onTap: (index) {
              setState(() {
                // Update subtitle when tab changes
              });
            },
          );
        },
      ),
    );
  }

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
        currentRoute: 'caddy_play',
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
        currentRoute: 'caddy_play',
        currentUser: user,
        onTap: (route) => _handleNavigation(route),
        showLabels: true,
        enableVoiceButton: true,
        useGlassEffect: true,
      ),
    );
  }

  // Zone Tab Implementation
  Widget _buildZoneTab(FlutterFlowTheme theme, UserRecord? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Your Swing
          _buildZoneSection(
            theme,
            title: 'Your Swing',
            subtitle: 'The foundation of how you play the game.',
            children: [
              _buildToggleSelector(
                theme,
                label: 'Swing Direction',
                options: ['Left', 'Right'],
                selected: _swingDirection,
                onChanged: (value) {
                  setState(() => _swingDirection = value);
                  _saveZoneSettingsToFirestore();
                },
              ),
              const SizedBox(height: 16),
              _buildToggleSelector(
                theme,
                label: 'Dominant Hand',
                options: ['Left', 'Right'],
                selected: _dominantHand,
                onChanged: (value) {
                  setState(() => _dominantHand = value);
                  _saveZoneSettingsToFirestore();
                },
              ),
              const SizedBox(height: 16),
              _buildToggleSelector(
                theme,
                label: 'Dominant Eye',
                options: ['Left', 'Right'],
                selected: _dominantEye,
                onChanged: (value) {
                  setState(() => _dominantEye = value);
                  _saveZoneSettingsToFirestore();
                },
              ),
              const SizedBox(height: 12),
              Text(
                'These basics help FoCoCo interpret your shots correctly … Left or right makes a big difference!',
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 2: Playing Environment
          _buildZoneSection(
            theme,
            title: 'Playing Environment',
            subtitle: 'Details that help shape your personal baseline.',
            children: [
              _buildHandicapWheel(theme),
              const SizedBox(height: 20),
              _buildDropdown(
                theme,
                label: 'Play Level',
                value: _playLevel,
                items: [
                  'Casual Golfer',
                  'Competitive Amateur',
                  'University / National Team',
                  'Elite Amateur',
                  'Professional',
                ],
                onChanged: (value) {
                  setState(() => _playLevel = value);
                  _saveZoneSettingsToFirestore();
                },
              ),
              const SizedBox(height: 16),
              _buildRangePicker(
                theme,
                label: 'Typical Course Length',
                value: _courseLength,
                options: [
                  'Under 3000',
                  '3000 - 4000',
                  '4000 - 5000',
                  '5000 - 6000',
                  '6000 - 7000',
                  'Over 7000',
                ],
                onChanged: (value) {
                  setState(() => _courseLength = value);
                  _saveZoneSettingsToFirestore();
                },
              ),
              const SizedBox(height: 16),
              _buildChipRow(
                theme,
                label: 'Play Frequency',
                value: _playFrequency,
                options: [
                  'Few times per year',
                  '1-2 times per month',
                  'Once per week',
                  '2-3 times per week',
                  '4+ times per week',
                ],
                onChanged: (value) {
                  setState(() => _playFrequency = value);
                  _saveZoneSettingsToFirestore();
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Set the basics that define your game.',
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 3: What's in the bag?
          _buildZoneSection(
            theme,
            title: 'What\'s in the bag?',
            subtitle: 'Choose your clubs',
            children: [
              _buildClubSelector(theme),
              const SizedBox(height: 12),
              Text(
                'Tap to toggle. Add lofts if you know them.',
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 4: How far does it go?
          if (_selectedClubs.isNotEmpty)
            _buildZoneSection(
              theme,
              title: 'How far does it go?',
              subtitle: 'Add your current carry distances',
              children: [
                _buildDistanceUnitToggle(theme),
                const SizedBox(height: 20),
                _buildDistanceInputs(theme),
                const SizedBox(height: 12),
                Text(
                  'Leave it blank if you\'re unsure. It\'s optional and easy to change anytime.',
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildZoneSection(
    FlutterFlowTheme theme, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return GlassDashboardCard(
      title: title,
      subtitle: subtitle,
      children: children,
    );
  }

  Widget _buildToggleSelector(
    FlutterFlowTheme theme, {
    required String label,
    required List<String> options,
    required String selected,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            final isSelected = selected == option;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(option);
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: option == options.first ? 8 : 0,
                    left: option == options.last ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.golfPrimary.withValues(alpha: 0.2)
                        : theme.glassTint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.golfPrimary
                          : theme.glassBorder.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: theme.bodyMedium.copyWith(
                      color:
                          isSelected ? theme.golfPrimary : theme.secondaryText,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHandicapWheel(FlutterFlowTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Handicap Index',
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem:
                  ((_handicapIndex - (-8.0)) * 10).round().clamp(0, 620),
            ),
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              HapticFeedback.selectionClick();
              setState(() {
                _handicapIndex = -8.0 + (index * 0.1);
                if (_handicapIndex > 54.0) _handicapIndex = 54.0;
              });
              _saveZoneSettingsToFirestore();
            },
            children: List.generate(621, (index) {
              final value = -8.0 + (index * 0.1);
              final displayValue =
                  value > 54.0 ? 'N/A' : value.toStringAsFixed(1);
              return Center(
                child: Text(
                  displayValue,
                  style: theme.titleMedium.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.glassTint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.glassBorder.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: Container(),
            style: theme.bodyMedium.copyWith(color: theme.primaryText),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                HapticFeedback.selectionClick();
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRangePicker(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = value == option;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(option);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.golfPrimary.withValues(alpha: 0.2)
                      : theme.glassTint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.golfPrimary
                        : theme.glassBorder.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: theme.bodyMedium.copyWith(
                    color: isSelected ? theme.golfPrimary : theme.secondaryText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChipRow(
    FlutterFlowTheme theme, {
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = value == option;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(option);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.golfPrimary.withValues(alpha: 0.2)
                          : theme.glassTint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? theme.golfPrimary
                            : theme.glassBorder.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option,
                      style: theme.bodyMedium.copyWith(
                        color: isSelected
                            ? theme.golfPrimary
                            : theme.secondaryText,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildClubSelector(FlutterFlowTheme theme) {
    final clubCategories = {
      'Woods & Hybrids': ['Driver', '3w', '5w', '7w', '3h', '4h', '5h'],
      'Irons': ['2i', '3i', '4i', '5i', '6i', '7i', '8i', '9i'],
      'Wedges': ['PW', 'GW', 'AW', 'SW', 'LW'],
      'Putter': ['Putter'],
    };

    return Column(
      children: clubCategories.entries.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.key,
              style: theme.titleSmall.copyWith(
                color: theme.secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.value.map((club) {
                final isSelected = _selectedClubs.contains(club);
                final canSelect = _selectedClubs.length < 14 || isSelected;
                return GestureDetector(
                  onTap: canSelect
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isSelected) {
                              _selectedClubs.remove(club);
                              _clubDistances.remove(club);
                            } else {
                              _selectedClubs.add(club);
                            }
                          });
                          _saveZoneSettingsToFirestore();
                        }
                      : null,
                  onLongPress: isSelected
                      ? () {
                          _showClubLoftDialog(theme, club);
                        }
                      : null,
                  child: Opacity(
                    opacity: canSelect ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.golfPrimary.withValues(alpha: 0.2)
                            : theme.glassTint.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? theme.golfPrimary
                              : theme.glassBorder.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            club,
                            style: theme.bodyMedium.copyWith(
                              color: isSelected
                                  ? theme.golfPrimary
                                  : theme.secondaryText,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: theme.golfPrimary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  void _showClubLoftDialog(FlutterFlowTheme theme, String club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Loft for $club'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Loft (degrees)',
            hintText: 'e.g., 10.5',
          ),
          onSubmitted: (value) {
            final loft = double.tryParse(value);
            if (loft != null) {
              setState(() {
                // Store loft info - you might want to add this to a separate map
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceUnitToggle(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleSelector(
            theme,
            label: 'Distance Unit',
            options: ['Meters', 'Yards'],
            selected: _distanceUnit,
            onChanged: (value) {
              setState(() => _distanceUnit = value);
              _saveZoneSettingsToFirestore();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceInputs(FlutterFlowTheme theme) {
    return Column(
      children: _selectedClubs.map((club) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '$club Distance',
              hintText: 'Enter ${_distanceUnit.toLowerCase()}',
              prefixIcon: Icon(Icons.golf_course),
            ),
            onChanged: (value) {
              final distance = double.tryParse(value);
              if (distance != null) {
                setState(() {
                  _clubDistances[club] = distance;
                });
                _saveZoneSettingsToFirestore();
              }
            },
          ),
        );
      }).toList(),
    );
  }

  // +Round Tab Implementation
  Widget _buildAddRoundTab(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Before you start
          _buildZoneSection(
            theme,
            title: 'Before you start.',
            subtitle: 'Provide the basics for this round.',
            children: [
              _buildDatePicker(theme),
              const SizedBox(height: 16),
              _buildCourseNameInput(theme),
              const SizedBox(height: 16),
              _buildHolesSelector(theme),
              const SizedBox(height: 16),
              _buildTextField(
                theme,
                label: 'Course Length',
                hint: 'Enter course length',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _courseLengthValue = int.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),
              _buildChipRow(
                theme,
                label: 'Round Type',
                value: _roundType,
                options: ['Tournament', 'Social', 'Practice'],
                onChanged: (value) {
                  setState(() => _roundType = value);
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                theme,
                label: 'Course Setup',
                value: _courseSetup,
                items: ['Easy', 'Normal', 'Difficult'],
                onChanged: (value) {
                  setState(() => _courseSetup = value);
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                theme,
                label: 'Course Condition',
                value: _courseCondition,
                items: [
                  'Ideal / Perfect',
                  'Firm / Fast',
                  'Soft / Wet',
                  'Dry / Burned',
                  'Poor / Damaged',
                  'Recently Maintained',
                ],
                onChanged: (value) {
                  setState(() => _courseCondition = value);
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                theme,
                label: 'Green Speed',
                value: _greenSpeed,
                items: [
                  'Slow (6-8)',
                  'Medium (8-10)',
                  'Fast (10-12)',
                  'Lightning (12-14>)',
                ],
                onChanged: (value) {
                  setState(() => _greenSpeed = value);
                },
              ),
              const SizedBox(height: 16),
              _buildMultiSelectChips(
                theme,
                label: 'Weather',
                selected: _weatherConditions,
                options: [
                  'Sunny',
                  'Cloudy',
                  'Calm',
                  'Wind',
                  'Storm',
                  'Rain',
                  'Cold',
                  'Humid',
                ],
                onChanged: (selected) {
                  setState(() => _weatherConditions = selected);
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                theme,
                label: 'Start Time',
                value: _startTime,
                items: ['Morning', 'Midday', 'Afternoon', 'Twilight'],
                onChanged: (value) {
                  setState(() => _startTime = value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'These details help FoCoCo understand how conditions affect both your performance and mindset.',
                style: theme.bodySmall.copyWith(
                  color: theme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 2: Hole-by-Hole Data
          _buildZoneSection(
            theme,
            title: 'Hole-by-Hole Data',
            subtitle:
                'Log as much or as little as you want … The more details you provide, the smarter FoCoCo becomes.',
            children: [
              GlassDesignSystem.glassButton(
                text: 'Start Logging Holes',
                onPressed: () {
                  _showAddRoundModal(context, theme);
                },
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDatePicker(FlutterFlowTheme theme) {
    return GestureDetector(
      onTap: () => _showPlatformDatePicker(theme),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.glassTint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: theme.bodySmall.copyWith(
                      color: theme.secondaryText,
                    ),
                  ),
                  Text(
                    '${_roundDate.day}/${_roundDate.month}/${_roundDate.year}',
                    style: theme.bodyMedium.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
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

  Future<void> _showPlatformDatePicker(FlutterFlowTheme theme) async {
    if (Platform.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 300,
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _roundDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    setState(() => _roundDate = date);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final date = await showDatePicker(
        context: context,
        initialDate: _roundDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (date != null) {
        setState(() => _roundDate = date);
      }
    }
  }

  Widget _buildCourseNameInput(FlutterFlowTheme theme) {
    return _buildTextField(
      theme,
      label: 'Course Name',
      hint: 'Enter course name',
      value: _courseName,
      onChanged: (value) {
        setState(() => _courseName = value);
      },
    );
  }

  Widget _buildHolesSelector(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _holes = 9);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _holes == 9
                    ? theme.golfPrimary.withValues(alpha: 0.2)
                    : theme.glassTint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _holes == 9
                      ? theme.golfPrimary
                      : theme.glassBorder.withValues(alpha: 0.3),
                  width: _holes == 9 ? 2 : 1,
                ),
              ),
              child: Text(
                '9',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.copyWith(
                  color: _holes == 9 ? theme.golfPrimary : theme.secondaryText,
                  fontWeight: _holes == 9 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _holes = 18);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _holes == 18
                    ? theme.golfPrimary.withValues(alpha: 0.2)
                    : theme.glassTint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _holes == 18
                      ? theme.golfPrimary
                      : theme.glassBorder.withValues(alpha: 0.3),
                  width: _holes == 18 ? 2 : 1,
                ),
              ),
              child: Text(
                '18',
                textAlign: TextAlign.center,
                style: theme.bodyMedium.copyWith(
                  color: _holes == 18 ? theme.golfPrimary : theme.secondaryText,
                  fontWeight: _holes == 18 ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    FlutterFlowTheme theme, {
    required String label,
    required String hint,
    String? value,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
      controller: value != null ? TextEditingController(text: value) : null,
    );
  }

  Widget _buildMultiSelectChips(
    FlutterFlowTheme theme, {
    required String label,
    required Set<String> selected,
    required List<String> options,
    required Function(Set<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.titleSmall.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                final newSelected = Set<String>.from(selected);
                if (isSelected) {
                  newSelected.remove(option);
                } else {
                  newSelected.add(option);
                }
                onChanged(newSelected);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.golfPrimary.withValues(alpha: 0.2)
                      : theme.glassTint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.golfPrimary
                        : theme.glassBorder.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: theme.bodyMedium.copyWith(
                    color: isSelected ? theme.golfPrimary : theme.secondaryText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // LogBook Tab Implementation
  Widget _buildLogBookTab(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Section
          _buildZoneSection(
            theme,
            title: 'Overview',
            subtitle: 'LogBook Stats',
            children: [
              _buildLogBookStats(theme, rounds),
              const SizedBox(height: 16),
              GlassDesignSystem.glassButton(
                text: 'View All Stats',
                onPressed: () {
                  _tabController.animateTo(3); // Switch to Trends tab
                },
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filter & Find Section
          _buildZoneSection(
            theme,
            title: 'Filter & Find',
            subtitle: 'Search by date, course, round type and weather.',
            children: [
              _buildLogBookFilters(theme, rounds),
            ],
          ),
          const SizedBox(height: 24),

          // My Rounds Section
          _buildZoneSection(
            theme,
            title: 'My Rounds',
            subtitle: 'Tap any scorecard for more details',
            children: [
              if (rounds.isEmpty)
                _buildEmptyRoundsState(theme)
              else
                ...rounds.map((round) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRoundScorecard(theme, round),
                    )),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLogBookStats(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    final totalRounds = rounds.length;
    final avgScore = rounds.isNotEmpty
        ? rounds.map((r) => r.score).reduce((a, b) => a + b) / rounds.length
        : 0.0;
    final avgMPI = 83.0; // TODO: Calculate from actual MPI data
    final mostUsedMindCue = 'Self-Talk'; // TODO: Calculate from actual data
    final strongestPillar = 'Confidence'; // TODO: Calculate from actual data
    final mostPlayedCourse = rounds.isNotEmpty
        ? rounds.map((r) => r.courseName).toSet().toList().first
        : 'N/A';

    return Column(
      children: [
        _buildStatRow(theme, 'Total Rounds', totalRounds.toString()),
        _buildStatRow(theme, 'Avg Score',
            avgScore > 0 ? avgScore.toStringAsFixed(1) : '--'),
        _buildStatRow(theme, 'Avg MPI', avgMPI.toStringAsFixed(0)),
        _buildStatRow(theme, 'Most Used MindCue', mostUsedMindCue),
        _buildStatRow(theme, 'Strongest Pillar', strongestPillar),
        _buildStatRow(theme, 'Most Played Course', mostPlayedCourse),
      ],
    );
  }

  Widget _buildStatRow(FlutterFlowTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.bodyMedium.copyWith(color: theme.secondaryText),
          ),
          Text(
            value,
            style: theme.bodyMedium.copyWith(
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogBookFilters(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    return Column(
      children: [
        _buildChipRow(
          theme,
          label: 'Date',
          value: _selectedDateFilter,
          options: ['7 Days', '30 Days', '90 Days', 'Custom'],
          onChanged: (value) {
            setState(() => _selectedDateFilter = value);
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          theme,
          label: 'Course',
          value: _selectedCourseFilter ?? 'All Courses',
          items: [
            'All Courses',
            ...rounds.map((r) => r.courseName).toSet().toList()
          ],
          onChanged: (value) {
            setState(() =>
                _selectedCourseFilter = value == 'All Courses' ? null : value);
          },
        ),
        // Add more filters as needed
      ],
    );
  }

  Widget _buildRoundScorecard(FlutterFlowTheme theme, GolfRoundsRecord round) {
    return GestureDetector(
      onTap: () {
        _showRoundDetails(theme, round);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.glassTint.withValues(alpha: 0.12),
              theme.glassTint.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    round.date != null
                        ? '${round.date!.day}/${round.date!.month}/${round.date!.year}'
                        : 'Recent',
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    round.courseName.isNotEmpty
                        ? round.courseName
                        : 'Golf Round',
                    style: theme.titleSmall.copyWith(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Score: ${round.score}',
                    style: theme.bodyMedium.copyWith(color: theme.primaryText),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: theme.primaryBrandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MPI',
                    style: theme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRoundsState(FlutterFlowTheme theme) {
    return Container(
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
            'Start tracking your golf rounds to see your progress!',
            style: theme.bodyMedium.copyWith(color: theme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRoundDetails(FlutterFlowTheme theme, GolfRoundsRecord round) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Round Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Course: ${round.courseName}'),
              Text('Score: ${round.score}'),
              Text('Date: ${round.date?.toString() ?? 'N/A'}'),
              // Add more details
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Trends Tab Implementation
  Widget _buildTrendsTab(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Filter Section
          _buildZoneSection(
            theme,
            title: 'Filters',
            subtitle: 'Filters update all charts and averages instantly.',
            children: [
              _buildChipRow(
                theme,
                label: 'Date',
                value: _trendsDateFilter,
                options: ['7 Days', '30 Days', '90 Days', 'Custom'],
                onChanged: (value) {
                  setState(() => _trendsDateFilter = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pillar Trends Section
          _buildZoneSection(
            theme,
            title: 'Pillar Trends',
            subtitle: 'Track your mental performance',
            children: [
              _buildPillarTrendCard(theme, 'Focus', '+8% ⬆',
                  'Consistency improving, distractions reduced.'),
              const SizedBox(height: 12),
              _buildPillarTrendCard(theme, 'Confidence', '+5% ⬆',
                  'Visualization routines increase success rate.'),
              const SizedBox(height: 12),
              _buildPillarTrendCard(theme, 'Control', '+2% ⬆',
                  'Reset cues used less frequently. Recovery faster.'),
              const SizedBox(height: 16),
              GlassDesignSystem.glassButton(
                text: 'See Full Pillar Analytics',
                onPressed: () {
                  _showFullPillarAnalyticsPanel(theme, rounds);
                },
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Performance Overview Section
          _buildZoneSection(
            theme,
            title: 'Golf Performance Overview',
            subtitle:
                'Your technical stats, analyzed through your mindset data.',
            children: [
              Text(
                'Tap on a specific Metric to see detailed analysis.',
                style: theme.bodySmall.copyWith(color: theme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mind & Game Insights Section
          _buildZoneSection(
            theme,
            title: 'Mind & Game Insights',
            subtitle:
                'A dynamic overview of what FoCoCo has analyzed about your game',
            children: [
              _buildInsightCard(theme,
                  'Visualization + Calm mindset improved approach accuracy by 14%.'),
              const SizedBox(height: 8),
              _buildInsightCard(theme,
                  'Confidence rebounds faster after rounds with pre-shot routines.'),
              const SizedBox(height: 8),
              _buildInsightCard(theme,
                  'Focus dip detected mid-round. Recommend earlier reset MindCue.'),
              const SizedBox(height: 16),
              GlassDesignSystem.glassButton(
                text: 'View in AI Insights',
                onPressed: () {
                  _showAIInsightsPanel(theme, rounds);
                },
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Your Best Moments Section
          _buildZoneSection(
            theme,
            title: 'Your Best Moments',
            subtitle: 'Key achievements within your selected date range.',
            children: [
              _buildBestMomentCard(theme, 'Best Score', '74'),
              _buildBestMomentCard(theme, 'Highest MPI', '86'),
              _buildBestMomentCard(theme, 'Strongest MindCue', 'Deep Breath'),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPillarTrendCard(
      FlutterFlowTheme theme, String pillar, String trend, String insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.glassTint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pillar,
                style: theme.titleSmall.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                trend,
                style: theme.bodyMedium.copyWith(
                  color: theme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight,
            style: theme.bodySmall.copyWith(color: theme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(FlutterFlowTheme theme, String insight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.aiPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.aiPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: theme.aiPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: theme.bodySmall.copyWith(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestMomentCard(
      FlutterFlowTheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.glassTint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.bodyMedium.copyWith(color: theme.secondaryText),
            ),
            Text(
              value,
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show AI Insights Panel
  void _showAIInsightsPanel(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    // Navigate to AI Insights tab or show modal
    context.go('/ai_insights');
  }

  /// Show Full Pillar Analytics Panel with AI-generated content
  void _showFullPillarAnalyticsPanel(
      FlutterFlowTheme theme, List<GolfRoundsRecord> rounds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _FullPillarAnalyticsPanel(
        theme: theme,
        rounds: rounds,
        userId: currentUserUid,
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
        context.go('/mind_coach');
        break;
      case 'caddy_play':
      case 'golf_sync':
        // Already on this page
        break;
      case 'coaching_modules':
      case 'mind_coach':
        context.go('/mind_coach');
        break;
      case 'golf_chat':
        context.go('/golf_chat');
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
      builder: (context) => GolfRoundModalGrintStyle(theme: theme),
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

/// Add Round Modal Widget - Grint Style Design
class _AddRoundModal extends StatefulWidget {
  final FlutterFlowTheme theme;

  const _AddRoundModal({required this.theme});

  @override
  State<_AddRoundModal> createState() => _AddRoundModalState();
}

class _AddRoundModalState extends State<_AddRoundModal> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();

  // Score and Putts controllers
  final _scoreController = TextEditingController();
  final _parTotalController = TextEditingController();
  final _puttsController = TextEditingController();

  // Statistics controllers
  final _fairwaysHitController = TextEditingController();
  final _fairwaysTotalController = TextEditingController();
  final _girController = TextEditingController();
  final _girTotalController = TextEditingController();

  // AI notes controller
  final _aiNotesController = TextEditingController();

  // Focus nodes
  final _courseNameFocus = FocusNode();
  final _scoreFocus = FocusNode();
  final _parTotalFocus = FocusNode();
  final _puttsFocus = FocusNode();
  final _fairwaysHitFocus = FocusNode();
  final _fairwaysTotalFocus = FocusNode();
  final _girFocus = FocusNode();
  final _girTotalFocus = FocusNode();
  final _aiNotesFocus = FocusNode();

  // AI processing state
  bool _isAiProcessing = false;
  String _aiSuggestion = '';

  // Score and Putts
  int _score = 5;
  int _putts = 2;

  // Tee Shot
  String _teeShotDirection = 'center';
  String _teeShotClub = 'Driver';
  bool _teeShotMisHit = false;

  // Putt Distance
  int? _firstPuttDistance;

  // Bunkers
  bool _fairwayBunker = false;
  bool _greenSideBunker = false;

  // Penalties
  bool _hazardWater = false;
  bool _dropShot = false;
  bool _outOfBounds = false;

  // Drinks
  bool _drinksOnHole = false;

  // Mode
  bool _isAdvancedMode = true;

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

/// Full Pillar Analytics Panel with AI-Generated Content
class _FullPillarAnalyticsPanel extends StatefulWidget {
  final FlutterFlowTheme theme;
  final List<GolfRoundsRecord> rounds;
  final String userId;

  const _FullPillarAnalyticsPanel({
    required this.theme,
    required this.rounds,
    required this.userId,
  });

  @override
  State<_FullPillarAnalyticsPanel> createState() =>
      _FullPillarAnalyticsPanelState();
}

class _FullPillarAnalyticsPanelState extends State<_FullPillarAnalyticsPanel>
    with TickerProviderStateMixin {
  bool _isGenerating = false;
  String? _aiGeneratedContent;
  Map<String, dynamic>? _pillarData;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    _generatePillarAnalytics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generatePillarAnalytics() async {
    if (widget.rounds.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      // Calculate pillar trends from rounds
      final pillarTrends = _calculatePillarTrends(widget.rounds);

      // Generate AI insights for pillar analytics
      final aiInsight = await _generatePillarAnalyticsAIForPanel(
        userId: widget.userId,
        rounds: widget.rounds,
        pillarTrends: pillarTrends,
      );

      if (mounted) {
        setState(() {
          _pillarData = {
            'focus': pillarTrends['focus'],
            'confidence': pillarTrends['confidence'],
            'control': pillarTrends['control'],
            'aiInsight': aiInsight,
          };
          _aiGeneratedContent = aiInsight.summaryText;
          _isGenerating = false;
        });
      }
    } catch (e) {
      print('Error generating pillar analytics: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _aiGeneratedContent = 'Unable to generate analytics at this time.';
        });
      }
    }
  }

  /// Generate AI-powered pillar analytics (for panel)
  Future<GeminiInsightResponse> _generatePillarAnalyticsAIForPanel({
    required String userId,
    required List<GolfRoundsRecord> rounds,
    required Map<String, dynamic> pillarTrends,
  }) async {
    try {
      if (rounds.isEmpty) {
        return GeminiInsightResponse(
          insightTitle: 'Pillar Analytics',
          category: 'pillar_analysis',
          priority: 'medium',
          summaryText: 'Log more rounds to generate detailed pillar analytics.',
          keyPoints: [],
          recommendations: [],
          personalizedElements: [],
          sentimentAnalysis: GeminiSentimentAnalysis(
            overallSentiment: 'neutral',
            confidenceLevel: 0.5,
            emotionalIndicators: [],
            moodProgression: 'stable',
          ),
          contextualFactors: [],
          followUpQuestions: [],
          sourceId: 'pillar_analytics_empty',
          sourceType: 'trend_analysis',
          timestamp: DateTime.now(),
          model: 'gemini',
          userId: userId,
          tokensUsed: 0,
        );
      }

      // Use the most recent round to generate insights
      final recentRound = rounds.first;

      // Generate insight using existing AI service
      final insight = await FoCoCoAI.generateRoundInsight(
        userId: userId,
        golfRound: recentRound,
        userProfile: null, // Will be fetched internally
        historicalRounds: rounds.take(10).toList(),
        mentalSessions: [],
      );

      // Enhance with pillar-specific analysis
      final pillarSummary = '''
Based on your recent performance data:

**Focus Pillar**: ${pillarTrends['focus']?['percentage'] ?? 'N/A'} trend
**Confidence Pillar**: ${pillarTrends['confidence']?['percentage'] ?? 'N/A'} trend  
**Control Pillar**: ${pillarTrends['control']?['percentage'] ?? 'N/A'} trend

${insight.summaryText ?? ''}

Your mental game shows consistent patterns across all three pillars. Focus on maintaining balance and addressing areas with declining trends.
''';

      return GeminiInsightResponse(
        insightTitle: insight.insightTitle,
        category: insight.category,
        priority: insight.priority,
        summaryText: pillarSummary,
        keyPoints: insight.keyPoints,
        recommendations: insight.recommendations,
        personalizedElements: insight.personalizedElements,
        sentimentAnalysis: insight.sentimentAnalysis,
        contextualFactors: insight.contextualFactors,
        followUpQuestions: insight.followUpQuestions,
        sourceId: 'pillar_analytics_${DateTime.now().millisecondsSinceEpoch}',
        sourceType: 'pillar_trend_analysis',
        timestamp: DateTime.now(),
        model: insight.model,
        userId: userId,
        tokensUsed: insight.tokensUsed,
      );
    } catch (e) {
      print('Error generating pillar analytics: $e');
      return GeminiInsightResponse(
        insightTitle: 'Pillar Analytics',
        category: 'pillar_analysis',
        priority: 'medium',
        summaryText:
            'Analyzing your mental performance patterns. Your data shows interesting trends across Focus, Confidence, and Control pillars.',
        keyPoints: [],
        recommendations: [],
        personalizedElements: [],
        sentimentAnalysis: GeminiSentimentAnalysis(
          overallSentiment: 'neutral',
          confidenceLevel: 0.5,
          emotionalIndicators: [],
          moodProgression: 'stable',
        ),
        contextualFactors: [],
        followUpQuestions: [],
        sourceId: 'pillar_analytics_error',
        sourceType: 'trend_analysis',
        timestamp: DateTime.now(),
        model: 'gemini',
        userId: userId,
        tokensUsed: 0,
      );
    }
  }

  Map<String, dynamic> _calculatePillarTrends(List<GolfRoundsRecord> rounds) {
    // Calculate trends for each pillar
    // This is a simplified version - you can enhance with actual MPI data
    final recentRounds = rounds.take(5).toList();
    final olderRounds = rounds.skip(5).take(5).toList();

    double calculateTrend(List<GolfRoundsRecord> roundList) {
      if (roundList.isEmpty) return 0.0;
      // Simplified calculation - replace with actual MPI pillar scores
      return roundList.length * 10.0;
    }

    final recentFocus = calculateTrend(recentRounds);
    final olderFocus = calculateTrend(olderRounds);
    final focusTrend = recentFocus - olderFocus;

    return {
      'focus': {
        'current': recentFocus,
        'trend': focusTrend,
        'percentage': focusTrend > 0
            ? '+${(focusTrend / olderFocus * 100).toStringAsFixed(1)}%'
            : '${(focusTrend / olderFocus * 100).toStringAsFixed(1)}%',
      },
      'confidence': {
        'current': recentFocus * 0.95,
        'trend': focusTrend * 0.95,
        'percentage': focusTrend > 0
            ? '+${(focusTrend / olderFocus * 100 * 0.95).toStringAsFixed(1)}%'
            : '${(focusTrend / olderFocus * 100 * 0.95).toStringAsFixed(1)}%',
      },
      'control': {
        'current': recentFocus * 0.9,
        'trend': focusTrend * 0.9,
        'percentage': focusTrend > 0
            ? '+${(focusTrend / olderFocus * 100 * 0.9).toStringAsFixed(1)}%'
            : '${(focusTrend / olderFocus * 100 * 0.9).toStringAsFixed(1)}%',
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.theme.glassBackground.withValues(alpha: 0.98),
            widget.theme.glassTint.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: widget.theme.glassBorder.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Content
                  Expanded(
                    child: _isGenerating
                        ? _buildLoadingState()
                        : _buildAnalyticsContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: widget.theme.aiGradient,
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
                  'Full Pillar Analytics',
                  style: widget.theme.headlineSmall.copyWith(
                    color: widget.theme.primaryText,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  'AI-powered mental performance analysis',
                  style: widget.theme.bodySmall.copyWith(
                    color: widget.theme.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.theme.glassTint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: widget.theme.aiGradient,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Generating AI Analytics...',
            style: widget.theme.titleMedium.copyWith(
              color: widget.theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing your mental performance patterns',
            style: widget.theme.bodySmall.copyWith(
              color: widget.theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    if (_pillarData == null) {
      return Center(
        child: Text(
          'No analytics data available',
          style: widget.theme.bodyMedium.copyWith(
            color: widget.theme.secondaryText,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pillar Comparison Chart
          _buildPillarComparisonChart(),
          const SizedBox(height: 24),

          // AI-Generated Insights
          if (_aiGeneratedContent != null && _aiGeneratedContent!.isNotEmpty)
            _buildAIGeneratedInsights(),
          const SizedBox(height: 24),

          // Individual Pillar Details
          _buildPillarDetails(),
          const SizedBox(height: 24),

          // Recommendations
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildPillarComparisonChart() {
    final focus = _pillarData!['focus'] as Map<String, dynamic>;
    final confidence = _pillarData!['confidence'] as Map<String, dynamic>;
    final control = _pillarData!['control'] as Map<String, dynamic>;

    return GlassDashboardCard(
      title: 'Pillar Performance Comparison',
      subtitle: 'Focus, Confidence & Control trends',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPillarMiniCard('Focus', focus, widget.theme.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPillarMiniCard(
                  'Confidence', confidence, widget.theme.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  _buildPillarMiniCard('Control', control, widget.theme.info),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Simple bar chart representation
        _buildSimpleBarChart(focus, confidence, control),
      ],
    );
  }

  Widget _buildPillarMiniCard(
      String name, Map<String, dynamic> data, Color color) {
    final trend = data['trend'] as double;
    final percentage = data['percentage'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: widget.theme.bodySmall.copyWith(
              color: widget.theme.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            percentage,
            style: widget.theme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontFamily: 'Montserrat',
            ),
          ),
          Icon(
            trend > 0 ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(Map<String, dynamic> focus,
      Map<String, dynamic> confidence, Map<String, dynamic> control) {
    final maxValue = [
      (focus['current'] as double).abs(),
      (confidence['current'] as double).abs(),
      (control['current'] as double).abs(),
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        _buildBar('Focus', focus['current'] as double, maxValue,
            widget.theme.success),
        const SizedBox(height: 12),
        _buildBar('Confidence', confidence['current'] as double, maxValue,
            widget.theme.warning),
        const SizedBox(height: 12),
        _buildBar('Control', control['current'] as double, maxValue,
            widget.theme.info),
      ],
    );
  }

  Widget _buildBar(String label, double value, double maxValue, Color color) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: widget.theme.bodySmall.copyWith(
              color: widget.theme.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: widget.theme.glassTint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            value.toStringAsFixed(0),
            textAlign: TextAlign.right,
            style: widget.theme.bodySmall.copyWith(
              color: widget.theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIGeneratedInsights() {
    return GlassDashboardCard(
      title: 'AI-Generated Analysis',
      subtitle: 'Personalized insights from your performance data',
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.theme.aiPrimary.withValues(alpha: 0.1),
                widget.theme.aiSecondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: widget.theme.aiGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Analysis',
                    style: widget.theme.titleSmall.copyWith(
                      color: widget.theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _aiGeneratedContent ?? 'Generating insights...',
                style: widget.theme.bodyMedium.copyWith(
                  color: widget.theme.primaryText,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillarDetails() {
    return GlassDashboardCard(
      title: 'Detailed Pillar Breakdown',
      subtitle: 'Deep dive into each mental performance pillar',
      children: [
        _buildPillarDetailCard(
            'Focus', _pillarData!['focus'], widget.theme.success),
        const SizedBox(height: 12),
        _buildPillarDetailCard(
            'Confidence', _pillarData!['confidence'], widget.theme.warning),
        const SizedBox(height: 12),
        _buildPillarDetailCard(
            'Control', _pillarData!['control'], widget.theme.info),
      ],
    );
  }

  Widget _buildPillarDetailCard(
      String name, Map<String, dynamic> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: widget.theme.titleSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                data['percentage'] as String,
                style: widget.theme.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current Score: ${(data['current'] as double).toStringAsFixed(1)}',
            style: widget.theme.bodySmall.copyWith(
              color: widget.theme.secondaryText,
            ),
          ),
          Text(
            'Trend: ${(data['trend'] as double) > 0 ? "Improving" : "Declining"}',
            style: widget.theme.bodySmall.copyWith(
              color: widget.theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return GlassDashboardCard(
      title: 'AI Recommendations',
      subtitle: 'Personalized actions to improve your mental game',
      children: [
        _buildRecommendationItem(
          'Focus',
          'Practice pre-shot routines consistently to improve focus stability.',
          Icons.center_focus_strong,
          widget.theme.success,
        ),
        const SizedBox(height: 12),
        _buildRecommendationItem(
          'Confidence',
          'Use visualization techniques before challenging shots.',
          Icons.visibility,
          widget.theme.warning,
        ),
        const SizedBox(height: 12),
        _buildRecommendationItem(
          'Control',
          'Develop reset strategies for recovery after difficult holes.',
          Icons.refresh,
          widget.theme.info,
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(
      String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.theme.glassTint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: widget.theme.titleSmall.copyWith(
                    color: widget.theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: widget.theme.bodySmall.copyWith(
                    color: widget.theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
