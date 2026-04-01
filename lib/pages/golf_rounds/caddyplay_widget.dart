import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '/ai_integration/widgets/navbar_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import 'caddyplay_models.dart';
import 'caddyplay_session_service.dart';

class CaddyPlayWidget extends StatefulWidget {
  const CaddyPlayWidget({super.key});

  static const String routeName = 'caddy_play';
  static const String routePath = '/caddy_play';

  @override
  State<CaddyPlayWidget> createState() => _CaddyPlayWidgetState();
}

enum _CaddyPlayScreen { home, newRound, active, snapshot, completed }

enum _CaddyPlayOverlay {
  none,
  tapLog,
  justTalkRecording,
  justTalkProcessing,
  justTalkConfirmation,
  mindSnap,
  scorecard,
}

class _CaddyPlayWidgetState extends State<CaddyPlayWidget>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const Color _kBackgroundStart = Color(0xFF0D0D1A);
  static const Color _kBackgroundEnd = Color(0xFF1A0A2E);
  static const Color _kCardColor = Color(0x1AFFFFFF);
  static const Color _kCardSolid = Color(0xFF18141F);
  static const Color _kScorecardSurface = Color(0xFF1C1C1E);
  static const Color _kCaddyGreen = Color(0xFF66BB6A);
  static const Color _kTalkPurple = Color(0xFF9C27B0);
  static const Color _kTapGold = Color(0xFFFFB300);
  static const Color _kMindSnapBlue = Color(0xFF1565C0);
  static const Color _kPendingAmber = Color(0xFFFFA726);
  static const Color _kWeakRed = Color(0xFFEF5350);
  static const Duration _messageDuration = Duration(seconds: 2);

  final CaddyPlaySessionService _sessionService = CaddyPlaySessionService();
  final SpeechToText _speechToText = SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _courseController = TextEditingController();
  final ScrollController _momentScrollController = ScrollController();

  _CaddyPlayScreen _screen = _CaddyPlayScreen.home;
  _CaddyPlayOverlay _overlay = _CaddyPlayOverlay.none;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showAdvancedSettings = false;
  bool _speechReady = false;
  bool _snapshotLoading = false;
  int _selectedHoles = 18;

  CaddyPlayAdvancedDefaults _advancedDefaults =
      const CaddyPlayAdvancedDefaults();
  CaddyPlayRoundType _selectedRoundType = CaddyPlayRoundType.practice;
  CaddyPlayPlayingPartners _selectedPlayingPartners =
      CaddyPlayPlayingPartners.friends;
  CaddyPlayPreRoundMindset _selectedPreRoundMindset =
      CaddyPlayPreRoundMindset.positive;
  CaddyPlayWeather _selectedWeather = CaddyPlayWeather.good;

  CaddyPlayActiveRound? _activeRound;
  CaddyPlayActiveRound? _completedRound;
  CaddyPlayRoundSnapshot? _snapshot;

  CaddyPlayCommitmentLevel? _tapCommitment;
  CaddyPlayFocusLevel? _tapFocus;
  CaddyPlayShotResult? _tapResult;
  CaddyPlayRoutineStatus? _tapRoutine;

  Duration _justTalkDuration = Duration.zero;
  Timer? _justTalkTimer;
  bool _justTalkWarning = false;
  String _justTalkTranscript = '';
  CaddyPlayTalkAnalysis? _justTalkAnalysis;
  CaddyPlayMoment? _pendingTalkMoment;
  String? _justTalkAudioPath;

  int _mindSnapStep = 0;
  CaddyPlayMindSnapSequence _mindSnapSequence =
      CaddyPlayMindSnapSequence.general;

  List<CaddyPlayHole> _scorecardDraft = <CaddyPlayHole>[];

  String? _microInsight;
  Timer? _microInsightTimer;
  String? _bannerMessage;
  Color _bannerColor = _kCaddyGreen;
  Timer? _bannerTimer;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isRouteVisible(context)) {
      setFoCoCoNavBarBackgroundOverride(_kBackgroundStart);
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await _sessionService.cleanupExpiredLocalArtifacts();
      _speechReady = await _speechToText.initialize();
      _advancedDefaults = await _sessionService.loadAdvancedDefaults();
      _applyAdvancedDefaults(_advancedDefaults);

      _activeRound = await _sessionService.loadLocalActiveRound() ??
          await _sessionService.restoreRemoteActiveRound();

      if (_activeRound != null && _activeRound!.snapshot != null) {
        _snapshot = _activeRound!.snapshot;
      }
    } catch (error) {
      _showBanner('CaddyPlay setup failed: $error', color: _kPendingAmber);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyAdvancedDefaults(CaddyPlayAdvancedDefaults defaults) {
    _selectedRoundType = defaults.roundType;
    _selectedPlayingPartners = defaults.playingPartners;
    _selectedPreRoundMindset = defaults.preRoundMindset;
    _selectedWeather = defaults.weather;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setFoCoCoNavLabelOverride(CaddyPlayWidget.routeName, null);
    setFoCoCoNavBarBackgroundOverride(null);
    _courseController.dispose();
    _momentScrollController.dispose();
    _bannerTimer?.cancel();
    _microInsightTimer?.cancel();
    _justTalkTimer?.cancel();
    _speechToText.cancel();
    unawaited(_audioRecorder.stop());
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    _bootstrapIfVisible();
    final isVisible = _isRouteVisible(context);
    if (currentUserUid.isEmpty) {
      return Scaffold(
        backgroundColor: _kBackgroundStart,
        body: Center(
          child: Text(
            'Please sign in to use CaddyPlay.',
            style: theme.bodyLarge.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    return StreamBuilder<UserRecord>(
      stream: isVisible
          ? UserRecord.getDocument(
              FirebaseFirestore.instance.doc('user/$currentUserUid'),
            )
          : null,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return FoCoCoAdaptiveScaffold(
          backgroundColor: _kBackgroundStart,
          currentRoute: CaddyPlayWidget.routeName,
          onTap: _handleNavigation,
          titleWidget: Text(
            _appBarTitle,
            style: theme.titleLarge.copyWith(
              color: _appBarTitleColor,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
            ),
          ),
          leading: _buildLeading(theme),
          actions: _buildActions(theme),
          drawer: _canUseDrawer && user != null
              ? FoCoCoDrawer(
                  currentUser: user,
                  currentRoute: CaddyPlayWidget.routeName,
                  onNavigate: (route) => context.goNamed(route),
                )
              : null,
          showBottomNav: false,
          enableVoiceButton: false,
          body: _buildBody(theme),
        );
      },
    );
  }

  bool get _canUseDrawer =>
      _overlay == _CaddyPlayOverlay.none && _screen == _CaddyPlayScreen.home;

  bool _isRouteVisible(BuildContext context) {
    return GoRouterState.of(context).uri.toString().contains(
          CaddyPlayWidget.routePath,
        );
  }

  void _bootstrapIfVisible() {
    if (_hasInitialized || !_isRouteVisible(context)) {
      return;
    }

    _hasInitialized = true;
    unawaited(_initialize());
  }

  String get _appBarTitle {
    switch (_overlay) {
      case _CaddyPlayOverlay.tapLog:
        return 'Log Shot';
      case _CaddyPlayOverlay.justTalkRecording:
      case _CaddyPlayOverlay.justTalkProcessing:
      case _CaddyPlayOverlay.justTalkConfirmation:
        return 'JustTalk';
      case _CaddyPlayOverlay.mindSnap:
        return 'MindSnap Reset';
      case _CaddyPlayOverlay.scorecard:
        return 'Scorecard';
      case _CaddyPlayOverlay.none:
        break;
    }

    return switch (_screen) {
      _CaddyPlayScreen.home => 'CaddyPlay',
      _CaddyPlayScreen.newRound => 'New Round',
      _CaddyPlayScreen.active => 'Active Round',
      _CaddyPlayScreen.snapshot => 'Round Snapshot',
      _CaddyPlayScreen.completed => 'Round Completed',
    };
  }

  Color get _appBarTitleColor {
    if (_overlay == _CaddyPlayOverlay.justTalkRecording ||
        _overlay == _CaddyPlayOverlay.justTalkProcessing ||
        _overlay == _CaddyPlayOverlay.justTalkConfirmation) {
      return _kTalkPurple;
    }
    if (_overlay == _CaddyPlayOverlay.scorecard ||
        _screen == _CaddyPlayScreen.snapshot) {
      return _kCaddyGreen;
    }
    return Colors.white;
  }

  Widget? _buildLeading(FlutterFlowTheme theme) {
    if (_overlay == _CaddyPlayOverlay.mindSnap) {
      return null;
    }

    if (_overlay == _CaddyPlayOverlay.tapLog ||
        _overlay == _CaddyPlayOverlay.justTalkRecording ||
        _overlay == _CaddyPlayOverlay.justTalkProcessing ||
        _overlay == _CaddyPlayOverlay.justTalkConfirmation) {
      return IconButton(
        icon: Icon(Icons.menu_rounded, color: theme.primaryText),
        onPressed: _dismissTalkOrTapOverlay,
      );
    }

    if (_overlay == _CaddyPlayOverlay.scorecard) {
      return IconButton(
        icon: Icon(Icons.menu_rounded, color: theme.primaryText),
        onPressed: () => _setOverlay(_CaddyPlayOverlay.none),
      );
    }

    if (_screen == _CaddyPlayScreen.newRound) {
      return IconButton(
        icon: Icon(Icons.menu_rounded, color: theme.primaryText),
        onPressed: _backToHome,
      );
    }

    return null;
  }

  List<Widget>? _buildActions(FlutterFlowTheme theme) {
    if (_overlay == _CaddyPlayOverlay.scorecard) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _HeaderCircleButton(
            icon: Icons.close_rounded,
            onTap: () => _setOverlay(_CaddyPlayOverlay.none),
          ),
        ),
      ];
    }

    if (_overlay == _CaddyPlayOverlay.none &&
        _screen == _CaddyPlayScreen.active &&
        _activeRound != null) {
      return <Widget>[
        PopupMenuButton<String>(
          color: _kCardSolid,
          onSelected: (value) {
            if (value == 'end_round') {
              _enterSnapshot();
            }
          },
          itemBuilder: (context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'end_round',
              child: Text('End Round'),
            ),
          ],
          icon: Icon(Icons.menu_rounded, color: theme.primaryText),
        ),
      ];
    }

    return null;
  }

  Widget _buildBody(FlutterFlowTheme theme) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final bottomReserve = keyboardInset > 0
        ? keyboardInset + 20
        : viewPadding + kFoCoCoBottomNavStripAndTabsHeight + 24;

    return Stack(
      children: [
        Positioned.fill(child: _buildBackdrop()),
        Column(
          children: [
            if (_isLoading || _isSaving || _snapshotLoading)
              LinearProgressIndicator(
                minHeight: 2,
                color: _kCaddyGreen,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            Expanded(child: _buildScreen(theme, bottomReserve)),
          ],
        ),
        if (_microInsight != null && _overlay == _CaddyPlayOverlay.none)
          Positioned(
            top: 86,
            left: 28,
            right: 28,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _microInsight == null ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _kCaddyGreen.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      _microInsight!,
                      style: theme.bodyMedium.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_overlay != _CaddyPlayOverlay.none)
          Positioned.fill(child: _buildOverlay(theme, bottomReserve)),
        if (_bannerMessage != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomReserve - 6,
            child: _InlineBanner(
              message: _bannerMessage!,
              color: _bannerColor,
            ),
          ),
      ],
    );
  }

  Widget _buildBackdrop() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[_kBackgroundStart, _kBackgroundEnd],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.8),
                  radius: 1.2,
                  colors: <Color>[
                    _kCaddyGreen.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            right: -40,
            child: IgnorePointer(
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.08,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                  child: CustomPaint(
                    painter: _NoisePainter(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen(FlutterFlowTheme theme, double bottomReserve) {
    return switch (_screen) {
      _CaddyPlayScreen.home => _buildHome(theme, bottomReserve),
      _CaddyPlayScreen.newRound => _buildNewRound(theme, bottomReserve),
      _CaddyPlayScreen.active => _buildActiveRound(theme, bottomReserve),
      _CaddyPlayScreen.snapshot => _buildSnapshot(theme, bottomReserve),
      _CaddyPlayScreen.completed => _buildCompleted(theme, bottomReserve),
    };
  }

  Widget _buildHome(FlutterFlowTheme theme, double bottomReserve) {
    final round = _activeRound;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomReserve),
      children: [
        SizedBox(height: round == null ? 44 : 24),
        if (round == null) ...[
          Text(
            'Ready when you are',
            textAlign: TextAlign.center,
            style: theme.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 18),
          const _GlowSeparator(),
          const SizedBox(height: 30),
          _CaddyGlowButton(
            label: 'START ROUND',
            onTap: _openNewRound,
          ),
        ] else ...[
          Text(
            'Round in Progress',
            textAlign: TextAlign.center,
            style: theme.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '${round.courseName} • Hole ${round.currentHole}',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 18),
          const _GlowSeparator(),
          const SizedBox(height: 28),
          _CaddyGlowButton(
            label: 'RESUME ROUND',
            onTap: () => setState(() => _screen = _CaddyPlayScreen.active),
          ),
          const SizedBox(height: 14),
          _CaddyGhostButton(
            label: 'START NEW ROUND',
            onTap: _confirmStartNewRound,
          ),
        ],
      ],
    );
  }

  Widget _buildNewRound(FlutterFlowTheme theme, double bottomReserve) {
    final canStart = _courseController.text.trim().isNotEmpty && !_isSaving;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
      children: [
        Text(
          'Course Name',
          style: theme.titleMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        _GlassTextField(
          controller: _courseController,
          hintText: 'Enter course name',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 28),
        _SectionLabel(label: 'Holes'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SegmentChoice(
                label: '9',
                selected: _selectedHoles == 9,
                onTap: () => setState(() => _selectedHoles = 9),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SegmentChoice(
                label: '18',
                selected: _selectedHoles == 18,
                onTap: () => setState(() => _selectedHoles = 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        InkWell(
          onTap: () =>
              setState(() => _showAdvancedSettings = !_showAdvancedSettings),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Advanced Settings',
                    style: theme.titleMedium.copyWith(color: Colors.white),
                  ),
                ),
                AnimatedRotation(
                  turns: _showAdvancedSettings ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showAdvancedSettings) ...[
          const SizedBox(height: 10),
          _buildChoiceGroup<CaddyPlayRoundType>(
            theme: theme,
            label: 'Round Type',
            values: CaddyPlayRoundType.values,
            selected: _selectedRoundType,
            labelFor: (value) => enumLabel(value),
            onSelected: (value) => setState(() => _selectedRoundType = value),
          ),
          const SizedBox(height: 18),
          _buildChoiceGroup<CaddyPlayPlayingPartners>(
            theme: theme,
            label: 'Playing Group',
            values: CaddyPlayPlayingPartners.values,
            selected: _selectedPlayingPartners,
            labelFor: (value) => enumLabel(value),
            onSelected: (value) =>
                setState(() => _selectedPlayingPartners = value),
          ),
          const SizedBox(height: 18),
          _buildChoiceGroup<CaddyPlayPreRoundMindset>(
            theme: theme,
            label: 'Pre-Round Mindset',
            values: CaddyPlayPreRoundMindset.values,
            selected: _selectedPreRoundMindset,
            labelFor: (value) => enumLabel(value),
            onSelected: (value) =>
                setState(() => _selectedPreRoundMindset = value),
          ),
          const SizedBox(height: 18),
          _buildChoiceGroup<CaddyPlayWeather>(
            theme: theme,
            label: 'Weather',
            values: CaddyPlayWeather.values,
            selected: _selectedWeather,
            labelFor: (value) =>
                value == CaddyPlayWeather.ok ? 'OK' : enumLabel(value),
            onSelected: (value) => setState(() => _selectedWeather = value),
          ),
        ],
        const SizedBox(height: 24),
        const _GlowSeparator(),
        const SizedBox(height: 22),
        _CaddyGlowButton(
          label: 'START ROUND',
          enabled: canStart,
          onTap: canStart ? _startRound : null,
        ),
      ],
    );
  }

  Widget _buildActiveRound(FlutterFlowTheme theme, double bottomReserve) {
    final round = _activeRound;
    if (round == null) {
      return Center(
        child: Text(
          'No active round found.',
          style: theme.bodyLarge.copyWith(color: Colors.white),
        ),
      );
    }

    final currentHoleMoments = _displayMomentsForCurrentHole(round);
    final tapDisabled = round.tapCountForHole(round.currentHole) >= 10;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
      children: [
        Text(
          round.courseName,
          textAlign: TextAlign.center,
          style: theme.bodyLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Center(
          child: _BadgePill(
            label: enumLabel(round.roundType),
            borderColor: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Hole ${round.currentHole}',
          textAlign: TextAlign.center,
          style: theme.displaySmall.copyWith(
            color: _kCaddyGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Moments Captured',
          textAlign: TextAlign.center,
          style: theme.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        _MomentRow(
          controller: _momentScrollController,
          moments: currentHoleMoments,
        ),
        const SizedBox(height: 24),
        _SectionLabel(label: 'Log Shot'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.touch_app_outlined,
                label: 'TAP',
                onTap: tapDisabled ? _showTapCapMessage : _openTapLog,
                disabled: tapDisabled,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionTile(
                icon: Icons.mic_none_rounded,
                label: 'TALK',
                onTap: _openJustTalk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _CaddyGhostButton(
          label:
              round.currentHole >= round.holesTotal ? 'END ROUND' : 'NEXT HOLE',
          onTap: round.currentHole >= round.holesTotal
              ? _enterSnapshot
              : _advanceHole,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _SecondaryActionTile(
                icon: Icons.edit_note_rounded,
                label: 'Scorecard',
                onTap: _openScorecard,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SecondaryActionTile(
                icon: Icons.autorenew_rounded,
                label: 'MindSnap',
                onTap: _openMindSnap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSnapshot(FlutterFlowTheme theme, double bottomReserve) {
    final snapshot = _snapshot;
    if (_snapshotLoading || snapshot == null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
        children: const [
          SizedBox(height: 12),
          _SkeletonBlock(height: 18, widthFactor: 0.72),
          SizedBox(height: 16),
          _SkeletonBlock(height: 42),
          SizedBox(height: 18),
          _SkeletonBlock(height: 108),
          SizedBox(height: 16),
          _SkeletonBlock(height: 112),
          SizedBox(height: 16),
          _SkeletonBlock(height: 92),
          SizedBox(height: 16),
          _SkeletonBlock(height: 92),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
      children: [
        Text(
          '${snapshot.courseName} • ${DateFormat('d MMM yyyy').format(snapshot.date)}',
          textAlign: TextAlign.center,
          style: theme.bodyLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 16),
        Center(
          child: _BadgePill(
            label: enumLabel(snapshot.roundType),
            borderColor: Colors.white.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        _SummaryCard(
          child: Row(
            children: [
              Expanded(
                child: _SnapshotMetric(
                  label: 'FOCUS',
                  value: snapshot.focusLabel,
                  color:
                      snapshot.focusLabel == 'Weak' ? _kWeakRed : Colors.white,
                ),
              ),
              const _VerticalDividerGlow(),
              Expanded(
                child: _SnapshotMetric(
                  label: 'CONFIDENCE',
                  value: snapshot.confidenceLabel,
                  color: snapshot.confidenceLabel == 'Building'
                      ? _kPendingAmber
                      : snapshot.confidenceLabel == 'Weak'
                          ? _kWeakRed
                          : Colors.white,
                ),
              ),
              const _VerticalDividerGlow(),
              Expanded(
                child: _SnapshotMetric(
                  label: 'CONTROL',
                  value: snapshot.controlLabel,
                  color: snapshot.controlLabel == 'Weak'
                      ? _kWeakRed
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SummaryCard(
          child: Row(
            children: [
              Expanded(
                child: _SnapshotNumberBlock(
                  label: 'SCORE',
                  value: snapshot.scoreToPar >= 0
                      ? '+${snapshot.scoreToPar}'
                      : '${snapshot.scoreToPar}',
                  sublabel: '${snapshot.holesPlayed} holes',
                  color: _kCaddyGreen,
                ),
              ),
              const _VerticalDividerGlow(),
              Expanded(
                child: _SnapshotNumberBlock(
                  label: 'MOMENTS CAPTURED',
                  value: '${snapshot.totalMoments}',
                  sublabel:
                      '${snapshot.tapCount} TAP • ${snapshot.talkCount} TALK • ${snapshot.mindSnapCount} RESET',
                  color: _kPendingAmber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: _BadgePill(
            label: '${snapshot.mindSnapCount} MindSnap',
            borderColor: const Color(0xFF89A8FF),
            textColor: const Color(0xFF89A8FF),
          ),
        ),
        const SizedBox(height: 18),
        _SummaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MOMENTUM SHIFT',
                style: theme.labelLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                snapshot.momentumShift,
                style: theme.titleLarge.copyWith(
                  color: _kPendingAmber,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MINDSET SUMMARY',
                style: theme.labelLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                snapshot.evaluationPhrase,
                style: theme.headlineSmall.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _CaddyGlowButton(
          label: 'Done',
          textColor: Colors.white,
          onTap: _completeRound,
          fillColor: Colors.black.withValues(alpha: 0.18),
        ),
        const SizedBox(height: 14),
        _CaddyGhostButton(
          label: 'Reflect in GolfChat',
          onTap: _openGolfChatWithRoundContext,
        ),
      ],
    );
  }

  Widget _buildCompleted(FlutterFlowTheme theme, double bottomReserve) {
    final round = _completedRound;
    final snapshot = round?.snapshot ?? _snapshot;
    final synced = round?.syncState == CaddyPlaySyncState.synced;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomReserve),
      children: [
        if (snapshot != null) ...[
          Text(
            snapshot.completionInsight,
            textAlign: TextAlign.center,
            style: theme.headlineSmall.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          const _GlowSeparator(),
          const SizedBox(height: 24),
        ],
        _CompletionStatusRow(
          icon: Icons.check_rounded,
          label: 'Round Saved',
          active: true,
        ),
        const SizedBox(height: 16),
        _CompletionStatusRow(
          icon: synced ? Icons.check_rounded : Icons.sync_rounded,
          label: 'Round Synced',
          active: synced,
          trailing: synced ? null : 'Sync pending',
        ),
        const SizedBox(height: 16),
        _CompletionStatusRow(
          icon: synced ? Icons.check_rounded : Icons.cloud_upload_outlined,
          label: 'Available in WebApp',
          active: synced,
          trailing: synced ? null : 'Sync pending',
        ),
        const SizedBox(height: 32),
        _CaddyGhostButton(
          label: 'Reflect in GolfChat',
          onTap: _openGolfChatWithRoundContext,
        ),
        const SizedBox(height: 14),
        _CaddyGhostButton(
          label: 'View Snapshot',
          onTap: () => setState(() => _screen = _CaddyPlayScreen.snapshot),
        ),
      ],
    );
  }

  Widget _buildOverlay(FlutterFlowTheme theme, double bottomReserve) {
    final blurred = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(color: Colors.black.withValues(alpha: 0.42)),
    );

    return switch (_overlay) {
      _CaddyPlayOverlay.tapLog => Stack(
          children: [
            blurred,
            _buildTapOverlay(theme, bottomReserve),
          ],
        ),
      _CaddyPlayOverlay.justTalkRecording => Stack(
          children: [
            blurred,
            _buildJustTalkRecording(theme, bottomReserve),
          ],
        ),
      _CaddyPlayOverlay.justTalkProcessing => Stack(
          children: [
            blurred,
            _buildJustTalkProcessing(theme, bottomReserve),
          ],
        ),
      _CaddyPlayOverlay.justTalkConfirmation => Stack(
          children: [
            blurred,
            _buildJustTalkConfirmation(theme, bottomReserve),
          ],
        ),
      _CaddyPlayOverlay.mindSnap => _buildMindSnapOverlay(theme, bottomReserve),
      _CaddyPlayOverlay.scorecard => Stack(
          children: [
            blurred,
            _buildScorecardOverlay(theme, bottomReserve),
          ],
        ),
      _CaddyPlayOverlay.none => const SizedBox.shrink(),
    };
  }

  Widget _buildTapOverlay(FlutterFlowTheme theme, double bottomReserve) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
      children: [
        _buildChoiceGroup<CaddyPlayCommitmentLevel>(
          theme: theme,
          label: 'Commitment',
          values: CaddyPlayCommitmentLevel.values,
          selected: _tapCommitment,
          labelFor: (value) => enumLabel(value),
          onSelected: (value) => setState(() => _tapCommitment = value),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        _buildChoiceGroup<CaddyPlayFocusLevel>(
          theme: theme,
          label: 'Focus Level',
          values: CaddyPlayFocusLevel.values,
          selected: _tapFocus,
          labelFor: (value) => enumLabel(value),
          onSelected: (value) => setState(() => _tapFocus = value),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        _buildChoiceGroup<CaddyPlayShotResult>(
          theme: theme,
          label: 'Shot Result',
          values: CaddyPlayShotResult.values,
          selected: _tapResult,
          labelFor: (value) =>
              value == CaddyPlayShotResult.ok ? 'OK' : enumLabel(value),
          onSelected: (value) => setState(() => _tapResult = value),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        _buildChoiceGroup<CaddyPlayRoutineStatus>(
          theme: theme,
          label: 'Pre-Shot Routine',
          values: CaddyPlayRoutineStatus.values,
          selected: _tapRoutine,
          labelFor: (value) => switch (value) {
            CaddyPlayRoutineStatus.partly => 'Partly',
            _ => enumLabel(value),
          },
          onSelected: (value) => setState(() => _tapRoutine = value),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 26),
        _CaddyGlowButton(
          label: 'SAVE SHOT',
          onTap: _saveTapMoment,
        ),
      ],
    );
  }

  Widget _buildJustTalkRecording(FlutterFlowTheme theme, double bottomReserve) {
    final transcript = _justTalkTranscript.trim();
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
      children: [
        Text(
          'Example',
          textAlign: TextAlign.center,
          style: theme.headlineSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '7 iron, rushed routine, pushed it right',
          textAlign: TextAlign.center,
          style: theme.titleLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(color: _kCaddyGreen),
        const SizedBox(height: 36),
        Center(
          child: _MicOrb(
            warning: _justTalkWarning,
            transcript: transcript,
            elapsedLabel: _formatDuration(_justTalkDuration),
          ),
        ),
        const SizedBox(height: 36),
        _CaddyGhostButton(
          label: 'Stop',
          onTap: _stopJustTalkRecording,
        ),
      ],
    );
  }

  Widget _buildJustTalkProcessing(
      FlutterFlowTheme theme, double bottomReserve) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomReserve),
      child: Center(
        child: Text(
          'Interpreting your moment…',
          textAlign: TextAlign.center,
          style: theme.headlineSmall.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildJustTalkConfirmation(
    FlutterFlowTheme theme,
    double bottomReserve,
  ) {
    final analysis = _justTalkAnalysis;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
      children: [
        if ((analysis?.transcript ?? '').trim().isNotEmpty)
          _SummaryCard(
            child: Text(
              analysis!.transcript,
              style: theme.bodyLarge.copyWith(color: Colors.white),
            ),
          ),
        if ((analysis?.aiInterpretation ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _SummaryCard(
            child: Text(
              analysis!.aiInterpretation!,
              style: theme.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: analysis?.pillarTags.isNotEmpty == true
              ? analysis!.pillarTags
                  .map(
                    (tag) => _BadgePill(
                      label: enumLabel(tag),
                      borderColor: _kCaddyGreen.withValues(alpha: 0.75),
                      textColor: _kCaddyGreen,
                    ),
                  )
                  .toList(growable: false)
              : <Widget>[
                  _BadgePill(
                    label: 'No pillar tags yet',
                    borderColor: Colors.white.withValues(alpha: 0.2),
                    textColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
        ),
        const SizedBox(height: 14),
        Text(
          _formatDuration(analysis?.recordingDuration ?? Duration.zero),
          textAlign: TextAlign.center,
          style: theme.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 22),
        _CaddyGlowButton(
          label: 'Save Shot',
          onTap: _saveJustTalkMoment,
        ),
        const SizedBox(height: 14),
        _CaddyGhostButton(
          label: 'Discard',
          onTap: _discardJustTalk,
        ),
      ],
    );
  }

  Widget _buildMindSnapOverlay(FlutterFlowTheme theme, double bottomReserve) {
    final instruction = switch (_mindSnapStep) {
      0 => 'Slow breath in.',
      1 => 'Hold.',
      _ => 'Release.',
    };
    final scale = switch (_mindSnapStep) {
      0 => 1.08,
      1 => 1.14,
      _ => 0.92,
    };

    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      child: InkWell(
        onTap: _advanceMindSnap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 40, 20, bottomReserve),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                'Quick reset. Back in 10 seconds.',
                textAlign: TextAlign.center,
                style: theme.titleMedium.copyWith(color: _kCaddyGreen),
              ),
              const SizedBox(height: 34),
              AnimatedScale(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOut,
                scale: scale,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _kCaddyGreen.withValues(alpha: 0.85),
                        _kCaddyGreen.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.72, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kCaddyGreen.withValues(alpha: 0.45),
                        blurRadius: 34,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Text(
                instruction,
                textAlign: TextAlign.center,
                style: theme.headlineSmall.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(3, (index) {
                  final filled = index <= _mindSnapStep;
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? _kCaddyGreen
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  );
                }),
              ),
              const Spacer(),
              Text(
                'Tap anywhere to advance',
                style: theme.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScorecardOverlay(FlutterFlowTheme theme, double bottomReserve) {
    final round = _activeRound;
    if (round == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 18, 12, 0),
      decoration: BoxDecoration(
        color: _kScorecardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: _kCaddyGreen.withValues(alpha: 0.18)),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(18, 18, 18, bottomReserve),
        children: [
          const _GlowSeparator(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Hole',
                  style: theme.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Par',
                  textAlign: TextAlign.center,
                  style: theme.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Score',
                  textAlign: TextAlign.center,
                  style: theme.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Moments Captured',
                  textAlign: TextAlign.center,
                  style: theme.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildScorecardRows(theme, round),
          const SizedBox(height: 18),
          _SummaryCard(
            child: Row(
              children: [
                Expanded(
                  child: _SnapshotNumberBlock(
                    label: 'RUNNING SCORE',
                    value: _scorecardScoreToPar(),
                    sublabel:
                        '${_scorecardDraft.where((hole) => hole.score != null).length} scored holes',
                    color: _kCaddyGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CaddyGlowButton(
            label: 'SAVE HOLE',
            onTap: _saveScorecard,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScorecardRows(
      FlutterFlowTheme theme, CaddyPlayActiveRound round) {
    final children = <Widget>[];
    final outHoles =
        _scorecardDraft.where((hole) => hole.holeNumber <= 9).toList();
    final inHoles =
        _scorecardDraft.where((hole) => hole.holeNumber > 9).toList();

    for (final hole in outHoles) {
      children.add(_buildScorecardRow(theme, round, hole));
    }
    if (round.holesTotal >= 9) {
      children.add(_buildSubtotalRow('OUT', outHoles));
    }
    for (final hole in inHoles) {
      children.add(_buildScorecardRow(theme, round, hole));
    }
    if (round.holesTotal == 18) {
      children.add(_buildSubtotalRow('IN', inHoles));
    }
    return children;
  }

  Widget _buildScorecardRow(
    FlutterFlowTheme theme,
    CaddyPlayActiveRound round,
    CaddyPlayHole hole,
  ) {
    final isCurrent = hole.holeNumber == round.currentHole;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? _kCaddyGreen.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: _kCaddyGreen.withValues(alpha: 0.28),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Hole ${hole.holeNumber}',
              style: theme.titleMedium.copyWith(color: Colors.white),
            ),
          ),
          Expanded(
            flex: 2,
            child: _ScoreStepper(
              value: hole.par,
              allowBlank: false,
              onMinus: () => _updateDraftPar(hole.holeNumber, hole.par - 1),
              onPlus: () => _updateDraftPar(hole.holeNumber, hole.par + 1),
            ),
          ),
          Expanded(
            flex: 2,
            child: _ScoreStepper(
              value: hole.score,
              allowBlank: true,
              onMinus: () =>
                  _updateDraftScore(hole.holeNumber, (hole.score ?? 1) - 1),
              onPlus: () =>
                  _updateDraftScore(hole.holeNumber, (hole.score ?? 0) + 1),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: hole.moments
                    .map((moment) => _MomentDot(moment: moment))
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtotalRow(String label, List<CaddyPlayHole> holes) {
    final totalPar = holes.fold<int>(0, (sum, hole) => sum + hole.par);
    final totalScore =
        holes.fold<int>(0, (sum, hole) => sum + (hole.score ?? 0));
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$totalPar',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              holes.any((hole) => hole.score != null) ? '$totalScore' : '-',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Expanded(flex: 3, child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildChoiceGroup<T extends Enum>({
    required FlutterFlowTheme theme,
    required String label,
    required List<T> values,
    required T? selected,
    required String Function(T value) labelFor,
    required void Function(T value) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.titleMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values
              .map(
                (value) => _ChoicePill(
                  label: labelFor(value),
                  selected: value == selected,
                  onTap: () => onSelected(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  List<CaddyPlayMoment> _displayMomentsForCurrentHole(
      CaddyPlayActiveRound round) {
    final moments = <CaddyPlayMoment>[...round.currentHoleData.moments];
    if (_pendingTalkMoment != null &&
        _pendingTalkMoment!.holeNumber == round.currentHole) {
      moments.add(_pendingTalkMoment!);
    }
    return moments;
  }

  void _backToHome() {
    setState(() => _screen = _CaddyPlayScreen.home);
  }

  void _openNewRound() {
    _courseController.clear();
    _applyAdvancedDefaults(_advancedDefaults);
    setState(() {
      _selectedHoles = 18;
      _showAdvancedSettings = false;
      _screen = _CaddyPlayScreen.newRound;
    });
  }

  Future<void> _confirmStartNewRound() async {
    final round = _activeRound;
    if (round == null) {
      _openNewRound();
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Start New Round?'),
            content: const Text('This will end your current round.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await _sessionService.cancelRound(round);
    if (!mounted) {
      return;
    }

    setState(() {
      _activeRound = null;
      _snapshot = null;
      _completedRound = null;
    });
    _openNewRound();
  }

  Future<void> _startRound() async {
    final courseName = _courseController.text.trim();
    if (courseName.isEmpty) {
      return;
    }

    final defaults = CaddyPlayAdvancedDefaults(
      roundType: _selectedRoundType,
      playingPartners: _selectedPlayingPartners,
      preRoundMindset: _selectedPreRoundMindset,
      weather: _selectedWeather,
    );
    await _sessionService.saveAdvancedDefaults(defaults);
    _advancedDefaults = defaults;

    final round = CaddyPlayActiveRound.newRound(
      roundId: 'caddyplay_${DateTime.now().microsecondsSinceEpoch}',
      userId: currentUserUid,
      courseName: courseName,
      holesTotal: _selectedHoles,
      roundType: _selectedRoundType,
      playingPartners: _selectedPlayingPartners,
      preRoundMindset: _selectedPreRoundMindset,
      weather: _selectedWeather,
    );

    await _saveRound(round, nextScreen: _CaddyPlayScreen.active);
  }

  Future<void> _saveRound(
    CaddyPlayActiveRound round, {
    _CaddyPlayScreen? nextScreen,
    bool sync = true,
  }) async {
    setState(() => _isSaving = true);
    try {
      final saved = await _sessionService.saveRound(round, sync: sync);
      if (!mounted) {
        return;
      }

      setState(() {
        _activeRound = saved;
        if (saved.snapshot != null) {
          _snapshot = saved.snapshot;
        }
        if (nextScreen != null) {
          _screen = nextScreen;
        }
      });
    } catch (error) {
      _showBanner('Unable to save round: $error', color: _kPendingAmber);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showTapCapMessage() {
    _showBanner('Max 10 shot logs for this hole.', color: _kPendingAmber);
  }

  void _openTapLog() {
    setState(() {
      _tapCommitment = null;
      _tapFocus = null;
      _tapResult = null;
      _tapRoutine = null;
    });
    _setOverlay(_CaddyPlayOverlay.tapLog);
  }

  Future<void> _saveTapMoment() async {
    final round = _activeRound;
    if (round == null) {
      return;
    }

    final moment = CaddyPlayMoment(
      id: 'tap_${DateTime.now().microsecondsSinceEpoch}',
      holeNumber: round.currentHole,
      type: CaddyPlayMomentType.tap,
      timestamp: DateTime.now(),
      commitment: _tapCommitment,
      focusLevel: _tapFocus,
      shotResult: _tapResult,
      preShotRoutine: _tapRoutine,
    );

    HapticFeedback.lightImpact();
    final updatedRound = round.addMoment(moment);
    await _saveRound(updatedRound);
    if (!mounted) {
      return;
    }

    _setOverlay(_CaddyPlayOverlay.none);
    _showMicroInsight(buildTapMicroInsight(moment));
    _scrollMomentRowToEnd();
  }

  Future<void> _openJustTalk() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      _showBanner(
        'Enable microphone access in Settings to use JustTalk.',
        color: _kPendingAmber,
      );
      return;
    }

    try {
      _justTalkTimer?.cancel();
      _justTalkDuration = Duration.zero;
      _justTalkWarning = false;
      _justTalkTranscript = '';
      _justTalkAnalysis = null;
      _justTalkAudioPath = await _sessionService
          .createTalkAudioPath(_activeRound?.roundId ?? 'draft');
      _pendingTalkMoment = null;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _justTalkAudioPath!,
      );

      if (_speechReady) {
        await _speechToText.listen(
          onResult: (result) {
            if (!mounted) {
              return;
            }
            setState(() {
              _justTalkTranscript = result.recognizedWords.trim();
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
        );
      }

      _justTalkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          return;
        }
        final next = Duration(seconds: timer.tick);
        if (next >= const Duration(seconds: 25)) {
          _justTalkWarning = true;
        }
        if (next >= const Duration(seconds: 30)) {
          unawaited(_stopJustTalkRecording());
          timer.cancel();
          return;
        }
        setState(() {
          _justTalkDuration = next;
        });
      });

      setState(() => _overlay = _CaddyPlayOverlay.justTalkRecording);
      _setJustTalkNavLabel(true);
    } catch (error) {
      _showBanner('JustTalk could not start: $error', color: _kPendingAmber);
      await _discardPendingAudioFile();
    }
  }

  Future<void> _stopJustTalkRecording() async {
    if (_overlay != _CaddyPlayOverlay.justTalkRecording) {
      return;
    }

    _justTalkTimer?.cancel();
    await _speechToText.stop();
    final stoppedPath = await _audioRecorder.stop();
    if (stoppedPath != null && stoppedPath.isNotEmpty) {
      _justTalkAudioPath = stoppedPath;
    }

    final transcript = _justTalkTranscript.trim();
    final round = _activeRound;
    if (round == null) {
      return;
    }

    final pendingMoment = CaddyPlayMoment(
      id: 'talk_${DateTime.now().microsecondsSinceEpoch}',
      holeNumber: round.currentHole,
      type: CaddyPlayMomentType.talk,
      timestamp: DateTime.now(),
      transcript: transcript,
      recordingDurationSeconds: _justTalkDuration.inSeconds,
      audioPath: _justTalkAudioPath,
      pendingProcessing: true,
    );

    setState(() {
      _pendingTalkMoment = pendingMoment;
      _overlay = _CaddyPlayOverlay.justTalkProcessing;
    });
    _scrollMomentRowToEnd();

    final analysis = await _runTalkAnalysis(
      transcript: transcript,
      audioPath: _justTalkAudioPath,
      recordingDuration: _justTalkDuration,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _justTalkAnalysis = analysis;
      _pendingTalkMoment = pendingMoment.copyWith(
        transcript: analysis.transcript,
        aiInterpretation: analysis.aiInterpretation,
        pillarTags: analysis.pillarTags,
        recordingDurationSeconds: analysis.recordingDuration.inSeconds,
        audioPath: analysis.audioPath,
        pendingProcessing: false,
      );
      _overlay = _CaddyPlayOverlay.justTalkConfirmation;
    });
  }

  Future<CaddyPlayTalkAnalysis> _runTalkAnalysis({
    required String transcript,
    required String? audioPath,
    required Duration recordingDuration,
  }) async {
    try {
      return await _sessionService
          .analyzeTalkTranscript(
            transcript: transcript,
            recordingDuration: recordingDuration,
            audioPath: audioPath,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return CaddyPlayTalkAnalysis(
        transcript: transcript,
        recordingDuration: recordingDuration,
        audioPath: audioPath,
      );
    }
  }

  Future<void> _saveJustTalkMoment() async {
    final round = _activeRound;
    final pendingMoment = _pendingTalkMoment;
    if (round == null || pendingMoment == null) {
      return;
    }

    HapticFeedback.lightImpact();
    final updated = round.addMoment(
      pendingMoment.copyWith(
        pendingProcessing: false,
        syncState: CaddyPlaySyncState.localOnly,
      ),
    );

    await _saveRound(updated);
    if (!mounted) {
      return;
    }

    _pendingTalkMoment = null;
    _justTalkAnalysis = null;
    _justTalkAudioPath = null;
    _setOverlay(_CaddyPlayOverlay.none);
    _scrollMomentRowToEnd();
  }

  Future<void> _discardJustTalk() async {
    await _discardPendingAudioFile();
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingTalkMoment = null;
      _justTalkAnalysis = null;
      _justTalkTranscript = '';
    });
    _setOverlay(_CaddyPlayOverlay.none);
  }

  Future<void> _discardPendingAudioFile() async {
    final path = _justTalkAudioPath ?? _pendingTalkMoment?.audioPath;
    _justTalkAudioPath = null;
    if (path == null || path.trim().isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup.
    }
  }

  Future<void> _dismissTalkOrTapOverlay() async {
    if (_overlay == _CaddyPlayOverlay.tapLog) {
      _setOverlay(_CaddyPlayOverlay.none);
      return;
    }

    if (_overlay == _CaddyPlayOverlay.justTalkRecording) {
      _justTalkTimer?.cancel();
      await _speechToText.stop();
      await _audioRecorder.stop();
      await _discardPendingAudioFile();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingTalkMoment = null;
        _justTalkAnalysis = null;
      });
      _setOverlay(_CaddyPlayOverlay.none);
      return;
    }

    await _discardJustTalk();
  }

  void _openMindSnap() {
    final round = _activeRound;
    if (round == null) {
      return;
    }
    setState(() {
      _mindSnapSequence = _sessionService.nextMindSnapSequence(round);
      _mindSnapStep = 0;
      _overlay = _CaddyPlayOverlay.mindSnap;
    });
  }

  Future<void> _advanceMindSnap() async {
    if (_overlay != _CaddyPlayOverlay.mindSnap) {
      return;
    }

    if (_mindSnapStep < 2) {
      setState(() => _mindSnapStep += 1);
      return;
    }

    final round = _activeRound;
    if (round == null) {
      return;
    }

    final moment = CaddyPlayMoment(
      id: 'mindsnap_${DateTime.now().microsecondsSinceEpoch}',
      holeNumber: round.currentHole,
      type: CaddyPlayMomentType.mindsnap,
      timestamp: DateTime.now(),
      mindSnapSequence: _mindSnapSequence,
    );

    final updated = round.addMoment(moment);
    await _saveRound(updated);
    if (!mounted) {
      return;
    }

    HapticFeedback.lightImpact();
    _setOverlay(_CaddyPlayOverlay.none);
    _scrollMomentRowToEnd();
  }

  void _openScorecard() {
    final round = _activeRound;
    if (round == null) {
      return;
    }

    _scorecardDraft = round.holes
        .map(
          (hole) => hole.copyWith(
            moments: <CaddyPlayMoment>[...hole.moments],
          ),
        )
        .toList(growable: false);
    _setOverlay(_CaddyPlayOverlay.scorecard);
  }

  void _updateDraftPar(int holeNumber, int nextValue) {
    final safeValue = nextValue.clamp(1, 9);
    setState(() {
      _scorecardDraft = _scorecardDraft
          .map(
            (hole) => hole.holeNumber == holeNumber
                ? hole.copyWith(par: safeValue)
                : hole,
          )
          .toList(growable: false);
    });
  }

  void _updateDraftScore(int holeNumber, int nextValue) {
    final safeValue = nextValue < 1 ? null : nextValue;
    setState(() {
      _scorecardDraft = _scorecardDraft
          .map(
            (hole) => hole.holeNumber == holeNumber
                ? hole.copyWith(score: safeValue)
                : hole,
          )
          .toList(growable: false);
    });
  }

  Future<void> _saveScorecard() async {
    final round = _activeRound;
    if (round == null) {
      return;
    }

    final updated = round.copyWith(
      holes: _scorecardDraft,
      lastUpdatedAt: DateTime.now(),
      syncState: CaddyPlaySyncState.localOnly,
      lastSyncError: null,
    );
    await _saveRound(updated);
    if (!mounted) {
      return;
    }

    _showBanner('Hole saved.');
  }

  Future<void> _advanceHole() async {
    final round = _activeRound;
    if (round == null || round.currentHole >= round.holesTotal) {
      return;
    }
    await _saveRound(round.advanceHole());
  }

  Future<void> _enterSnapshot() async {
    final round = _activeRound;
    if (round == null) {
      return;
    }

    setState(() {
      _snapshotLoading = true;
      _screen = _CaddyPlayScreen.snapshot;
    });

    final snapshot = _sessionService.buildSnapshot(round);
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) {
      return;
    }

    final updatedRound = round.copyWith(snapshot: snapshot);
    await _saveRound(updatedRound,
        nextScreen: _CaddyPlayScreen.snapshot, sync: true);
    if (!mounted) {
      return;
    }

    setState(() {
      _snapshot = snapshot;
      _snapshotLoading = false;
    });
  }

  Future<void> _completeRound() async {
    final round = _activeRound;
    if (round == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final completed = await _sessionService.completeRound(
        round.copyWith(snapshot: _snapshot ?? round.snapshot),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _completedRound = completed;
        _snapshot = completed.snapshot;
        _activeRound = null;
        _screen = _CaddyPlayScreen.completed;
      });
    } catch (error) {
      _showBanner('Unable to complete round: $error', color: _kPendingAmber);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openGolfChatWithRoundContext() {
    final roundId = _completedRound?.roundId ?? _activeRound?.roundId;
    final snapshot = _completedRound?.snapshot ?? _snapshot;
    if (roundId == null || roundId.isEmpty) {
      context.goNamed('golf_chat');
      return;
    }

    context.goNamed(
      'golf_chat',
      extra: <String, dynamic>{
        'roundId': roundId,
        if (snapshot != null) 'caddyplaySnapshot': snapshot.toJson(),
      },
    );
  }

  String _scorecardScoreToPar() {
    final totalPar =
        _scorecardDraft.fold<int>(0, (sum, hole) => sum + hole.par);
    final totalScore =
        _scorecardDraft.fold<int>(0, (sum, hole) => sum + (hole.score ?? 0));
    final delta = totalScore - totalPar;
    return delta >= 0 ? '+$delta' : '$delta';
  }

  void _showBanner(String message, {Color color = _kCaddyGreen}) {
    _bannerTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _bannerMessage = message;
      _bannerColor = color;
    });
    _bannerTimer = Timer(_messageDuration, () {
      if (mounted) {
        setState(() => _bannerMessage = null);
      }
    });
  }

  void _showMicroInsight(String message) {
    _microInsightTimer?.cancel();
    setState(() => _microInsight = message);
    _microInsightTimer = Timer(_messageDuration, () {
      if (mounted) {
        setState(() => _microInsight = null);
      }
    });
  }

  void _scrollMomentRowToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_momentScrollController.hasClients) {
        return;
      }
      _momentScrollController.animateTo(
        _momentScrollController.position.maxScrollExtent + 64,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _setOverlay(_CaddyPlayOverlay overlay) {
    if (overlay != _CaddyPlayOverlay.justTalkRecording &&
        overlay != _CaddyPlayOverlay.justTalkProcessing &&
        overlay != _CaddyPlayOverlay.justTalkConfirmation) {
      _setJustTalkNavLabel(false);
    }

    if (mounted) {
      setState(() => _overlay = overlay);
    } else {
      _overlay = overlay;
    }
  }

  void _setJustTalkNavLabel(bool enabled) {
    setFoCoCoNavLabelOverride(
      CaddyPlayWidget.routeName,
      enabled ? 'Just Talk' : null,
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleNavigation(String route) {
    if (!mounted) {
      return;
    }
    context.goNamed(route);
  }
}

class _GlowSeparator extends StatelessWidget {
  const _GlowSeparator({this.color = _CaddyPlayWidgetState._kCaddyGreen});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: 1.5,
              color: color.withValues(alpha: 0.55),
            ),
          ),
          Container(
            width: 132,
            height: 14,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.88),
                  color.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0, 0.38, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: theme.titleLarge.copyWith(color: Colors.white),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

class _CaddyGlowButton extends StatelessWidget {
  const _CaddyGlowButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.textColor = _CaddyPlayWidgetState._kCaddyGreen,
    this.fillColor = Colors.black12,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final Color textColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: fillColor.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _CaddyPlayWidgetState._kCaddyGreen),
            boxShadow: [
              BoxShadow(
                color:
                    _CaddyPlayWidgetState._kCaddyGreen.withValues(alpha: 0.26),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaddyGhostButton extends StatelessWidget {
  const _CaddyGhostButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _CaddyPlayWidgetState._kCaddyGreen.withValues(alpha: 0.9),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentChoice extends StatelessWidget {
  const _SegmentChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: selected
              ? _CaddyPlayWidgetState._kCaddyGreen.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _CaddyPlayWidgetState._kCaddyGreen
                : Colors.white.withValues(alpha: 0.18),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _CaddyPlayWidgetState._kCaddyGreen
                        .withValues(alpha: 0.22),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? _CaddyPlayWidgetState._kCaddyGreen
                  : Colors.white.withValues(alpha: 0.78),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _CaddyPlayWidgetState._kCaddyGreen.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? _CaddyPlayWidgetState._kCaddyGreen
                : Colors.white.withValues(alpha: 0.22),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? _CaddyPlayWidgetState._kCaddyGreen
                : Colors.white.withValues(alpha: 0.72),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: disabled ? 0.45 : 1,
        child: Container(
          height: 236,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _CaddyPlayWidgetState._kCaddyGreen,
                size: 82,
              ),
              const SizedBox(height: 18),
              const _GlowSeparator(),
              const SizedBox(height: 18),
              Text(
                label,
                style: const TextStyle(
                  color: _CaddyPlayWidgetState._kCaddyGreen,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionTile extends StatelessWidget {
  const _SecondaryActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _CaddyPlayWidgetState._kCaddyGreen,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 20),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.48),
          fontSize: 20,
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _CaddyPlayWidgetState._kCaddyGreen),
        ),
      ),
    );
  }
}

class _MomentRow extends StatelessWidget {
  const _MomentRow({
    required this.controller,
    required this.moments,
  });

  final ScrollController controller;
  final List<CaddyPlayMoment> moments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: moments
              .map(
                (moment) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _MomentDot(moment: moment),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _MomentDot extends StatelessWidget {
  const _MomentDot({required this.moment});

  final CaddyPlayMoment moment;

  @override
  Widget build(BuildContext context) {
    final color = moment.pendingProcessing
        ? _CaddyPlayWidgetState._kPendingAmber
        : switch (moment.type) {
            CaddyPlayMomentType.tap => _CaddyPlayWidgetState._kTapGold,
            CaddyPlayMomentType.talk => _CaddyPlayWidgetState._kCaddyGreen,
            CaddyPlayMomentType.mindsnap =>
              _CaddyPlayWidgetState._kMindSnapBlue,
          };

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.72),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _CaddyPlayWidgetState._kCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.labelLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.headlineSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SnapshotNumberBlock extends StatelessWidget {
  const _SnapshotNumberBlock({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.labelLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.displaySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          sublabel,
          textAlign: TextAlign.center,
          style: theme.bodyMedium
              .copyWith(color: Colors.white.withValues(alpha: 0.78)),
        ),
      ],
    );
  }
}

class _VerticalDividerGlow extends StatelessWidget {
  const _VerticalDividerGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 82,
      color: Colors.white.withValues(alpha: 0.14),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.borderColor,
    this.textColor = Colors.white,
  });

  final String label;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MicOrb extends StatelessWidget {
  const _MicOrb({
    required this.warning,
    required this.transcript,
    required this.elapsedLabel,
  });

  final bool warning;
  final String transcript;
  final String elapsedLabel;

  @override
  Widget build(BuildContext context) {
    final glowColor = warning
        ? _CaddyPlayWidgetState._kPendingAmber
        : _CaddyPlayWidgetState._kCaddyGreen;

    return Column(
      children: [
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.45),
                blurRadius: 38,
                spreadRadius: 10,
              ),
            ],
            gradient: RadialGradient(
              colors: [
                glowColor.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
          child: Icon(
            Icons.mic_rounded,
            color: glowColor,
            size: 110,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          elapsedLabel,
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
        if (transcript.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            transcript,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ],
    );
  }
}

class _ScoreStepper extends StatelessWidget {
  const _ScoreStepper({
    required this.value,
    required this.allowBlank,
    required this.onMinus,
    required this.onPlus,
  });

  final int? value;
  final bool allowBlank;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.toString() ?? (allowBlank ? '-' : '4');
    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _StepperButton(icon: Icons.remove_rounded, onTap: onMinus),
          Expanded(
            child: Text(
              displayValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepperButton(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: double.infinity,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.85)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CompletionStatusRow extends StatelessWidget {
  const _CompletionStatusRow({
    required this.icon,
    required this.label,
    required this.active,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool active;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? _CaddyPlayWidgetState._kCaddyGreen
        : Colors.white.withValues(alpha: 0.45);
    return Row(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: active ? 1 : 0.65),
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: _CaddyPlayWidgetState._kPendingAmber,
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.height,
    this.widthFactor = 1,
  });

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.028);
    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final radius = ((x + y) % 3) + 0.6;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
