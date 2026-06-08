import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '/ai_integration/services/cartesia_api_service.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/haptic_service.dart';

import '/widgets/fococo_confirm_dialog.dart';

import 'caddyplay_models.dart';
import 'caddyplay_session_service.dart';

class CaddyPlayWidget extends StatefulWidget {
  const CaddyPlayWidget({super.key});

  static const String routeName = 'caddy_play';
  static const String routePath = '/caddy_play';

  @override
  State<CaddyPlayWidget> createState() => _CaddyPlayWidgetState();
}

enum _CaddyPlayScreen { home, newRound, active, snapshot }

enum _CaddyPlayOverlay {
  none,
  tapLog,
  justTalkRecording,
  justTalkPreview,
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _courseController = TextEditingController();
  final ScrollController _momentScrollController = ScrollController();

  _CaddyPlayScreen _screen = _CaddyPlayScreen.home;
  _CaddyPlayOverlay _overlay = _CaddyPlayOverlay.none;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showAdvancedSettings = false;
  bool _advancedSettingsTouched = false;
  bool _snapshotLoading = false;
  int _selectedHoles = 18;

  CaddyPlayAdvancedDefaults _advancedDefaults =
      const CaddyPlayAdvancedDefaults();
  CaddyPlayRoundType? _selectedRoundType;
  CaddyPlayPlayingPartners? _selectedPlayingPartners;
  CaddyPlayPreRoundMindset? _selectedPreRoundMindset;
  CaddyPlayWeather? _selectedWeather;

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
  double _justTalkAmplitude = 0;
  StreamSubscription<Amplitude>? _justTalkAmplitudeSub;
  AudioPlayer? _justTalkPreviewPlayer;
  bool _justTalkPreviewPlaying = false;
  late final AnimationController _micPulseController;

  int _mindSnapStep = 0;
  Timer? _mindSnapTimer;
  String _mindSnapOpeningLine = 'Quick reset. Back in 10 seconds.';
  int? _lastMindSnapOpeningIndex;
  CaddyPlayMindSnapSequence _mindSnapSequence =
      CaddyPlayMindSnapSequence.general;

  static const List<String> _mindSnapOpenings = <String>[
    'Quick reset. Back in 10 seconds.',
    'One breath. Then back to the shot.',
    'Slow down. Reset your focus.',
    'Ten seconds. Clear the noise.',
  ];

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
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer the nav-bar override mutation to after the current frame.
    // setFoCoCoNavBarBackgroundOverride writes to a ValueNotifier, which
    // synchronously notifies its ValueListenableBuilder ancestor — calling
    // it from inside didChangeDependencies (which runs during build) trips
    // "setState() called during build" because the listener tries to
    // markNeedsBuild on an ancestor that is still being built.
    if (_isRouteVisible(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setFoCoCoNavBarBackgroundOverride(_kBackgroundStart);
      });
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      await _sessionService.cleanupExpiredLocalArtifacts();
      _advancedDefaults = await _sessionService.loadAdvancedDefaults();
      _applyAdvancedDefaults(_advancedDefaults);

      _activeRound = await _sessionService.loadLocalActiveRound() ??
          await _sessionService.restoreRemoteActiveRound();

      if (_activeRound != null && _activeRound!.snapshot != null) {
        _snapshot = _activeRound!.snapshot;
      }
    } catch (error) {
      debugPrint('CaddyPlay setup failed: $error');
      _showBanner(_userSafeError('setup'), color: _kPendingAmber);
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
    setFoCoCoNavBarBackgroundOverride(null);
    _courseController.dispose();
    _momentScrollController.dispose();
    _bannerTimer?.cancel();
    _microInsightTimer?.cancel();
    _justTalkTimer?.cancel();
    _justTalkAmplitudeSub?.cancel();
    _mindSnapTimer?.cancel();
    _micPulseController.dispose();
    unawaited(_disposeJustTalkPreviewPlayer());
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

    return FoCoCoAdaptiveScaffold(
      backgroundColor: _kBackgroundStart,
      hideAppBar: true,
      currentRoute: CaddyPlayWidget.routeName,
      onTap: _handleNavigation,
      showBottomNav: false,
      enableVoiceButton: false,
      body: _buildBody(theme),
    );
  }

  bool _isRouteVisible(BuildContext context) {
    try {
      return GoRouterState.of(context)
          .uri
          .toString()
          .contains(CaddyPlayWidget.routePath);
    } catch (_) {
      return true;
    }
  }

  String _userSafeError(String context) {
    return switch (context) {
      'setup' => 'CaddyPlay could not load. Pull to refresh or try again.',
      'save' => 'Unable to save your round. Try again in a moment.',
      'justtalk' => 'JustTalk could not start. Check microphone access.',
      'complete' => 'Unable to finish the round. Try again in a moment.',
      _ => 'Something went wrong. Please try again.',
    };
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
      case _CaddyPlayOverlay.justTalkPreview:
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
    };
  }

  Widget _buildInlineHeader(FlutterFlowTheme theme) {
    return FoCoCoInlineScreenHeader(
      title: _appBarTitle,
      titleColor: _appBarTitleColor,
      leading: _buildLeading(theme),
      topInset: MediaQuery.viewPaddingOf(context).top,
    );
  }

  Color get _appBarTitleColor {
    if (_overlay == _CaddyPlayOverlay.justTalkRecording ||
        _overlay == _CaddyPlayOverlay.justTalkPreview ||
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
        _overlay == _CaddyPlayOverlay.justTalkPreview ||
        _overlay == _CaddyPlayOverlay.justTalkProcessing ||
        _overlay == _CaddyPlayOverlay.justTalkConfirmation) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryText),
        onPressed: _dismissTalkOrTapOverlay,
      );
    }

    if (_screen == _CaddyPlayScreen.snapshot) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryText),
        onPressed: () {
          if (_activeRound != null) {
            setState(() => _screen = _CaddyPlayScreen.active);
          } else {
            _backToHome();
          }
        },
      );
    }

    if (_overlay == _CaddyPlayOverlay.scorecard) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryText),
        onPressed: () => _setOverlay(_CaddyPlayOverlay.none),
      );
    }

    if (_screen == _CaddyPlayScreen.newRound) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryText),
        onPressed: _backToHome,
      );
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
            _buildInlineHeader(theme),
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
    final canStart = !_isSaving;
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
            onSelected: (value) => setState(() {
              _advancedSettingsTouched = true;
              _selectedRoundType = value;
            }),
          ),
          const SizedBox(height: 18),
          _buildChoiceGroup<CaddyPlayPlayingPartners>(
            theme: theme,
            label: 'Playing Group',
            values: CaddyPlayPlayingPartners.values,
            selected: _selectedPlayingPartners,
            labelFor: (value) => enumLabel(value),
            onSelected: (value) => setState(() {
              _advancedSettingsTouched = true;
              _selectedPlayingPartners = value;
            }),
          ),
          const SizedBox(height: 18),
          _buildChoiceGroup<CaddyPlayPreRoundMindset>(
            theme: theme,
            label: 'Pre-Round Mindset',
            values: CaddyPlayPreRoundMindset.values,
            selected: _selectedPreRoundMindset,
            labelFor: (value) => enumLabel(value),
            onSelected: (value) => setState(() {
              _advancedSettingsTouched = true;
              _selectedPreRoundMindset = value;
            }),
          ),
          const SizedBox(height: 18),
          _buildChoiceGroup<CaddyPlayWeather>(
            theme: theme,
            label: 'Weather',
            values: CaddyPlayWeather.values,
            selected: _selectedWeather,
            labelFor: (value) =>
                value == CaddyPlayWeather.ok ? 'OK' : enumLabel(value),
            onSelected: (value) => setState(() {
              _advancedSettingsTouched = true;
              _selectedWeather = value;
            }),
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
    final onLastHole = round.currentHole >= round.holesTotal;
    final canGoBack = round.currentHole > 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomReserve),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hole ${round.currentHole}',
            textAlign: TextAlign.center,
            style: theme.displaySmall.copyWith(
              color: _kCaddyGreen,
              fontWeight: FontWeight.w700,
              fontSize: 32,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Shots & Moments Captured',
            textAlign: TextAlign.center,
            style: theme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: _MomentRow(
              controller: _momentScrollController,
              moments: currentHoleMoments,
            ),
          ),
          if (round.allMoments.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _latestMomentPreview(round),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const _SectionLabel(label: 'Log Shot'),
          const SizedBox(height: 8),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.touch_app_outlined,
                    label: 'TAP',
                    onTap: tapDisabled ? _showTapCapMessage : _openTapLog,
                    disabled: tapDisabled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.mic_none_rounded,
                    label: 'TALK',
                    onTap: _openJustTalk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CaddyGhostButton(
                  label: 'BACK HOLE',
                  compact: true,
                  onTap: canGoBack ? _retreatHole : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CaddyGlowButton(
                  label: onLastHole ? 'END ROUND' : 'NEXT',
                  compact: true,
                  onTap: onLastHole ? _enterSnapshot : _advanceHole,
                ),
              ),
            ],
          ),
          if (!onLastHole) ...[
            const SizedBox(height: 8),
            _CaddyGhostButton(
              label: 'END ROUND',
              compact: true,
              onTap: _enterSnapshot,
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: _SecondaryActionTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Scorecard',
                    onTap: _openScorecard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryActionTile(
                    icon: Icons.autorenew_rounded,
                    label: 'MindSnap',
                    onTap: _openMindSnap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshot(FlutterFlowTheme theme, double bottomReserve) {
    final snapshot = _snapshot;
    if (_snapshotLoading || snapshot == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, bottomReserve),
        child: Column(
          children: const [
            _SkeletonBlock(height: 18, widthFactor: 0.72),
            SizedBox(height: 16),
            Expanded(child: _SkeletonBlock(height: 42)),
          ],
        ),
      );
    }

    final canContinueRound = _activeRound != null;
    final locked = snapshot.insightsLocked;
    final scoreLabel = snapshot.holesPlayed > 0 ||
            snapshot.scoreToPar != 0 ||
            !snapshot.scoreToParIsApproximate
        ? formatCaddyPlayScoreToParLabel(
            snapshot.scoreToPar,
            approximate: snapshot.scoreToParIsApproximate,
          )
        : '—';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 6, 20, bottomReserve),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${snapshot.courseName} • ${DateFormat('d MMM yyyy').format(snapshot.date)}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.bodyMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Center(
            child: _BadgePill(
              label: enumLabel(snapshot.roundType),
              borderColor: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 6),
          const _GlowSeparator(),
          const SizedBox(height: 6),
          if (locked) ...[
            Expanded(
              flex: 3,
              child: _SummaryCard(
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.mindsetSummary,
                      style: theme.bodyLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.momentumShift,
                      style: theme.bodyMedium.copyWith(
                        color: _kPendingAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ] else ...[
          Expanded(
            flex: 2,
            child: _SummaryCard(
              compact: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SnapshotMetric(
                      label: 'FOCUS',
                      value: snapshot.focusLabel,
                      color: snapshot.focusLabel == 'Weak'
                          ? _kWeakRed
                          : Colors.white,
                    ),
                  ),
                  const _VerticalDividerGlow(flexible: true),
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
                  const _VerticalDividerGlow(flexible: true),
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
          ),
          const SizedBox(height: 6),
          ],
          Expanded(
            flex: 2,
            child: _SummaryCard(
              compact: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SnapshotNumberBlock(
                      label: 'SCORE',
                      value: scoreLabel,
                      sublabel: snapshot.holesPlayed > 0
                          ? '${snapshot.holesPlayed} holes'
                          : 'Add scorecard',
                      color: _kCaddyGreen,
                    ),
                  ),
                  const _VerticalDividerGlow(flexible: true),
                  Expanded(
                    child: _SnapshotNumberBlock(
                      label: 'MOMENTS',
                      value: '${snapshot.totalMoments}',
                      sublabel:
                          '${snapshot.tapCount} TAP • ${snapshot.talkCount} TALK • ${snapshot.mindSnapCount} RESET',
                      color: _kPendingAmber,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: _BadgePill(
              label: '${snapshot.mindSnapCount} MindSnap',
              borderColor: const Color(0xFF89A8FF),
              textColor: const Color(0xFF89A8FF),
            ),
          ),
          if (!locked) ...[
            const SizedBox(height: 6),
            Expanded(
              flex: 3,
              child: _SummaryCard(
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOMENTUM SHIFT',
                      style: theme.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: Text(
                            snapshot.momentumShift,
                            style: theme.bodyLarge.copyWith(
                              color: _kPendingAmber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              flex: 2,
              child: _SummaryCard(
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MINDSET SUMMARY',
                      style: theme.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: Text(
                            snapshot.evaluationPhrase,
                            style: theme.bodyLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (canContinueRound) ...[
            _CaddyGhostButton(
              label: 'Back to Round',
              compact: true,
              onTap: () => setState(() => _screen = _CaddyPlayScreen.active),
            ),
            const SizedBox(height: 6),
          ],
          _CaddyGlowButton(
            label: 'Done',
            compact: true,
            textColor: Colors.white,
            onTap: _confirmCompleteRound,
            fillColor: Colors.black.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 6),
          _CaddyGhostButton(
            label: 'Reflect in GolfChat',
            compact: true,
            onTap: _openGolfChatWithRoundContext,
          ),
        ],
      ),
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
      _CaddyPlayOverlay.justTalkPreview => Stack(
          children: [
            blurred,
            _buildJustTalkPreview(theme, bottomReserve),
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
        Center(
          child: _buildChoiceGroup<CaddyPlayFocusLevel>(
            theme: theme,
            label: 'Focus Level',
            values: CaddyPlayFocusLevel.values,
            selected: _tapFocus,
            labelFor: (value) => enumLabel(value),
            onSelected: (value) => setState(() => _tapFocus = value),
          ),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        Center(
          child: _buildChoiceGroup<CaddyPlayRoutineStatus>(
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
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        Center(
          child: _buildChoiceGroup<CaddyPlayCommitmentLevel>(
            theme: theme,
            label: 'Commitment',
            values: CaddyPlayCommitmentLevel.values,
            selected: _tapCommitment,
            labelFor: (value) => enumLabel(value),
            onSelected: (value) => setState(() => _tapCommitment = value),
          ),
        ),
        const SizedBox(height: 18),
        const _GlowSeparator(),
        const SizedBox(height: 18),
        Center(
          child: _buildChoiceGroup<CaddyPlayShotResult>(
            theme: theme,
            label: 'Shot Result',
            values: CaddyPlayShotResult.values,
            selected: _tapResult,
            labelFor: (value) =>
                value == CaddyPlayShotResult.ok ? 'OK' : enumLabel(value),
            onSelected: (value) => setState(() => _tapResult = value),
          ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomReserve),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Tap the mic when you\'re done (30s max)',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 18),
          const _GlowSeparator(color: _kTalkPurple),
          const Spacer(flex: 2),
          Center(
            child: _MicOrb(
              warning: _justTalkWarning,
              elapsedLabel: _formatDuration(_justTalkDuration),
              amplitude: _justTalkAmplitude,
              pulseAnimation: _micPulseController,
              onTap: _stopJustTalkRecording,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildJustTalkPreview(FlutterFlowTheme theme, double bottomReserve) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomReserve),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Close preview',
              onPressed: _discardJustTalk,
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
          Text(
            'Preview your moment',
            textAlign: TextAlign.center,
            style: theme.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_justTalkDuration),
            style: theme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const Spacer(flex: 2),
          _JustTalkWaveformPreview(
            amplitude: _justTalkAmplitude,
            playing: _justTalkPreviewPlaying,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _JustTalkPreviewControl(
                icon: Icons.replay_rounded,
                label: 'Re-record',
                onTap: _reRecordJustTalk,
              ),
              const SizedBox(width: 18),
              _JustTalkPreviewControl(
                icon: _justTalkPreviewPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                label: _justTalkPreviewPlaying ? 'Pause' : 'Play',
                highlighted: true,
                onTap: _toggleJustTalkPreviewPlayback,
              ),
              const SizedBox(width: 18),
              _JustTalkPreviewControl(
                icon: Icons.stop_rounded,
                label: 'Stop',
                onTap: _stopJustTalkPreviewPlayback,
              ),
            ],
          ),
          const Spacer(flex: 3),
          _CaddyGlowButton(
            label: 'Confirm',
            onTap: _confirmJustTalkRecording,
          ),
          const SizedBox(height: 12),
          _CaddyGhostButton(
            label: 'Discard',
            onTap: _discardJustTalk,
          ),
        ],
      ),
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
      child: Padding(
          padding: EdgeInsets.fromLTRB(20, 40, 20, bottomReserve),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                _mindSnapOpeningLine,
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
            ],
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
            label: 'SAVE SCORE',
            onTap: _saveScorecard,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScorecardRows(
      FlutterFlowTheme theme, CaddyPlayActiveRound round) {
    final hole = _scorecardDraft.firstWhere(
      (entry) => entry.holeNumber == round.currentHole,
      orElse: () => CaddyPlayHole(holeNumber: round.currentHole),
    );
    return <Widget>[
      _buildScorecardRow(theme, round, hole),
    ];
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
            child: _ScoreScrollPicker(
              label: 'Par',
              values: List<int>.generate(9, (i) => i + 1),
              selected: hole.par ?? 4,
              onSelected: (value) => _updateDraftPar(hole.holeNumber, value),
            ),
          ),
          Expanded(
            flex: 2,
            child: _ScoreScrollPicker(
              label: 'Score',
              values: List<int>.generate(15, (i) => i + 1),
              selected: hole.score ?? 4,
              onSelected: (value) => _updateDraftScore(hole.holeNumber, value),
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
    final totals = caddyPlayScoringTotals(holes);
    final hasScored = holes.any((hole) => hole.score != null);
    final totalPar = totals.totalEffectivePar;
    final totalScore = totals.totalStrokes;
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
              hasScored ? '$totalPar' : '-',
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
              hasScored ? '$totalScore' : '-',
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.titleMedium.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
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
    setState(() {
      _selectedHoles = 18;
      _showAdvancedSettings = false;
      _advancedSettingsTouched = false;
      _selectedRoundType = null;
      _selectedPlayingPartners = null;
      _selectedPreRoundMindset = null;
      _selectedWeather = null;
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
    final entered = _courseController.text.trim();
    final courseName =
        entered.isEmpty ? kCaddyPlayCoursePlaceholder : entered;

    if (_advancedSettingsTouched) {
      final defaults = CaddyPlayAdvancedDefaults(
        roundType: _selectedRoundType,
        playingPartners: _selectedPlayingPartners,
        preRoundMindset: _selectedPreRoundMindset,
        weather: _selectedWeather,
      );
      await _sessionService.saveAdvancedDefaults(defaults);
      _advancedDefaults = defaults;
    }

    final round = CaddyPlayActiveRound.newRound(
      roundId: 'caddyplay_${DateTime.now().microsecondsSinceEpoch}',
      userId: currentUserUid,
      courseName: courseName,
      holesTotal: _selectedHoles,
      roundType: _advancedSettingsTouched ? _selectedRoundType : null,
      playingPartners:
          _advancedSettingsTouched ? _selectedPlayingPartners : null,
      preRoundMindset:
          _advancedSettingsTouched ? _selectedPreRoundMindset : null,
      weather: _advancedSettingsTouched ? _selectedWeather : null,
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
      debugPrint('Unable to save round: $error');
      _showBanner(_userSafeError('save'), color: _kPendingAmber);
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

    await HapticService.light();
    final updatedRound = round.addMoment(moment);
    await _saveRound(updatedRound);
    if (!mounted) {
      return;
    }

    _setOverlay(_CaddyPlayOverlay.none);
    _showBanner('Shot Saved.');
    _scrollMomentRowToEnd();
  }

  String _latestMomentPreview(CaddyPlayActiveRound round) {
    final latest = round.allMoments.last;
    final typeLabel = switch (latest.type) {
      CaddyPlayMomentType.tap => 'TAP',
      CaddyPlayMomentType.talk => 'TALK',
      CaddyPlayMomentType.mindsnap => 'RESET',
    };
    final detail = switch (latest.type) {
      CaddyPlayMomentType.tap =>
        latest.shotResult != null ? enumLabel(latest.shotResult!) : 'Logged',
      CaddyPlayMomentType.talk =>
        (latest.transcript ?? '').trim().isNotEmpty
            ? latest.transcript!.trim()
            : 'Voice moment',
      CaddyPlayMomentType.mindsnap => 'MindSnap reset',
    };
    return 'Latest: $typeLabel • Hole ${latest.holeNumber} • $detail';
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
      await _disposeJustTalkPreviewPlayer();
      _justTalkTimer?.cancel();
      _justTalkAmplitudeSub?.cancel();
      _justTalkDuration = Duration.zero;
      _justTalkWarning = false;
      _justTalkTranscript = '';
      _justTalkAnalysis = null;
      _justTalkAmplitude = 0;
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

      _justTalkAmplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((Amplitude amplitude) {
        if (!mounted ||
            _overlay != _CaddyPlayOverlay.justTalkRecording) {
          return;
        }
        final normalized =
            ((amplitude.current + 45) / 45).clamp(0.0, 1.0);
        setState(() => _justTalkAmplitude = normalized);
        if (normalized > 0.62) {
          unawaited(HapticService.light());
        }
      });

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

      await HapticService.medium();
      setState(() => _overlay = _CaddyPlayOverlay.justTalkRecording);
    } catch (error) {
      debugPrint('JustTalk start failed: $error');
      _showBanner(_userSafeError('justtalk'), color: _kPendingAmber);
      await _discardPendingAudioFile();
    }
  }

  Future<void> _stopJustTalkRecording() async {
    if (_overlay != _CaddyPlayOverlay.justTalkRecording) {
      return;
    }

    _justTalkTimer?.cancel();
    _justTalkAmplitudeSub?.cancel();
    _justTalkAmplitudeSub = null;
    final stoppedPath = await _audioRecorder.stop();
    if (stoppedPath != null && stoppedPath.isNotEmpty) {
      _justTalkAudioPath = stoppedPath;
    }

    if (_justTalkAudioPath == null || _justTalkAudioPath!.isEmpty) {
      _showBanner('Recording failed. Try again.', color: _kPendingAmber);
      _setOverlay(_CaddyPlayOverlay.none);
      return;
    }

    await HapticService.light();
    if (!mounted) return;
    setState(() => _overlay = _CaddyPlayOverlay.justTalkProcessing);
    await _processAndSaveJustTalk();
  }

  Future<void> _processAndSaveJustTalk() async {
    final round = _activeRound;
    if (round == null) return;

    final transcript = await _transcribeJustTalkAudio(_justTalkAudioPath);
    if (!mounted) return;

    final analysis = await _runTalkAnalysis(
      transcript: transcript,
      audioPath: _justTalkAudioPath,
      recordingDuration: _justTalkDuration,
    );
    if (!mounted) return;

    final trimmed = analysis.transcript.trim();
    if (trimmed.isEmpty) {
      await _discardPendingAudioFile();
      if (!mounted) return;
      setState(() {
        _pendingTalkMoment = null;
        _justTalkAnalysis = null;
        _overlay = _CaddyPlayOverlay.none;
      });
      _showBanner(
        'We couldn\'t capture that moment. Try speaking a little louder.',
        color: _kPendingAmber,
      );
      return;
    }

    final moment = CaddyPlayMoment(
      id: 'talk_${DateTime.now().microsecondsSinceEpoch}',
      holeNumber: round.currentHole,
      type: CaddyPlayMomentType.talk,
      timestamp: DateTime.now(),
      transcript: analysis.transcript,
      aiInterpretation: analysis.aiInterpretation,
      pillarTags: analysis.pillarTags,
      recordingDurationSeconds: analysis.recordingDuration.inSeconds,
      audioPath: analysis.audioPath,
    );

    await HapticService.light();
    final updated = round.addMoment(moment);
    await _saveRound(updated);
    if (!mounted) return;

    _pendingTalkMoment = null;
    _justTalkAnalysis = null;
    _justTalkAudioPath = null;
    _setOverlay(_CaddyPlayOverlay.none);
    _scrollMomentRowToEnd();
  }

  Future<void> _initJustTalkPreviewPlayer() async {
    await _disposeJustTalkPreviewPlayer();
    final path = _justTalkAudioPath;
    if (path == null || path.isEmpty) {
      return;
    }
    final player = AudioPlayer();
    _justTalkPreviewPlayer = player;
    await player.setFilePath(path);
    player.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _justTalkPreviewPlaying = state.playing);
    });
    player.positionStream.listen((position) {
      if (!mounted || _overlay != _CaddyPlayOverlay.justTalkPreview) {
        return;
      }
      final totalMs = _justTalkDuration.inMilliseconds;
      if (totalMs <= 0) {
        return;
      }
      setState(() {
        _justTalkAmplitude =
            (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
      });
    });
  }

  Future<void> _disposeJustTalkPreviewPlayer() async {
    final player = _justTalkPreviewPlayer;
    _justTalkPreviewPlayer = null;
    _justTalkPreviewPlaying = false;
    if (player == null) {
      return;
    }
    try {
      await player.stop();
      await player.dispose();
    } catch (_) {
      // Best effort cleanup.
    }
  }

  Future<void> _toggleJustTalkPreviewPlayback() async {
    final player = _justTalkPreviewPlayer;
    if (player == null) {
      return;
    }
    if (player.playing) {
      await player.pause();
      await HapticService.light();
      return;
    }
    await player.play();
    await HapticService.light();
  }

  Future<void> _stopJustTalkPreviewPlayback() async {
    final player = _justTalkPreviewPlayer;
    if (player == null) {
      return;
    }
    await player.stop();
    await player.seek(Duration.zero);
    if (mounted) {
      setState(() => _justTalkAmplitude = 0);
    }
    await HapticService.light();
  }

  Future<void> _reRecordJustTalk() async {
    await _disposeJustTalkPreviewPlayer();
    await _discardPendingAudioFile();
    if (!mounted) {
      return;
    }
    setState(() {
      _justTalkAnalysis = null;
      _justTalkTranscript = '';
      _justTalkAmplitude = 0;
    });
    await _openJustTalk();
  }

  Future<void> _confirmJustTalkRecording() async {
    if (_overlay != _CaddyPlayOverlay.justTalkPreview) {
      return;
    }

    await _stopJustTalkPreviewPlayback();
    final round = _activeRound;
    if (round == null) {
      return;
    }

    setState(() => _overlay = _CaddyPlayOverlay.justTalkProcessing);
    final transcript = await _transcribeJustTalkAudio(_justTalkAudioPath);
    if (!mounted) {
      return;
    }
    _justTalkTranscript = transcript;

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

    final trimmed = analysis.transcript.trim();
    if (trimmed.isEmpty) {
      await _discardPendingAudioFile();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingTalkMoment = null;
        _justTalkAnalysis = null;
        _overlay = _CaddyPlayOverlay.none;
      });
      _showBanner(
        'We couldn\'t capture that moment. Try speaking a little louder.',
        color: _kPendingAmber,
      );
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

  /// Transcribe a JustTalk recording with the Cartesia speech-to-text API.
  /// Returns an empty string when nothing usable could be captured.
  Future<String> _transcribeJustTalkAudio(String? path) async {
    if (path == null || path.isEmpty) {
      return '';
    }
    try {
      final file = File(path);
      if (!file.existsSync()) {
        return '';
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return '';
      }
      final result = await CartesiaAPIService.instance
          .transcribeAudio(
            audioBytes: bytes,
            fileName: 'justtalk.m4a',
            contentType: MediaType('audio', 'mp4'),
            language: 'en',
          )
          .timeout(const Duration(seconds: 20));
      return result.text.trim();
    } catch (error) {
      if (kDebugMode) {
        print('⚠️ JustTalk Cartesia STT failed: $error');
      }
      return '';
    }
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

    await HapticService.light();
    await _disposeJustTalkPreviewPlayer();
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
    await _disposeJustTalkPreviewPlayer();
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
      _justTalkAmplitudeSub?.cancel();
      _justTalkAmplitudeSub = null;
      await _audioRecorder.stop();
      await _discardPendingAudioFile();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingTalkMoment = null;
        _justTalkAnalysis = null;
        _justTalkAmplitude = 0;
      });
      _setOverlay(_CaddyPlayOverlay.none);
      return;
    }

    if (_overlay == _CaddyPlayOverlay.justTalkPreview) {
      await _disposeJustTalkPreviewPlayer();
      await _discardPendingAudioFile();
      if (!mounted) {
        return;
      }
      setState(() {
        _justTalkAnalysis = null;
        _justTalkAmplitude = 0;
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

    _mindSnapTimer?.cancel();
    final random = math.Random();
    var index = random.nextInt(_mindSnapOpenings.length);
    if (_mindSnapOpenings.length > 1 &&
        _lastMindSnapOpeningIndex != null &&
        index == _lastMindSnapOpeningIndex) {
      index = (index + 1) % _mindSnapOpenings.length;
    }
    _lastMindSnapOpeningIndex = index;

    setState(() {
      _mindSnapSequence = _sessionService.nextMindSnapSequence(round);
      _mindSnapStep = 0;
      _mindSnapOpeningLine = _mindSnapOpenings[index];
      _overlay = _CaddyPlayOverlay.mindSnap;
    });

    _mindSnapTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted || _overlay != _CaddyPlayOverlay.mindSnap) {
        timer.cancel();
        return;
      }
      final elapsedMs = timer.tick * 400;
      final nextStep = elapsedMs < 4000
          ? 0
          : elapsedMs < 6000
              ? 1
              : 2;
      if (elapsedMs >= 10000) {
        timer.cancel();
        unawaited(_finishMindSnap());
        return;
      }
      if (nextStep != _mindSnapStep) {
        setState(() => _mindSnapStep = nextStep);
      }
    });
  }

  Future<void> _finishMindSnap() async {
    if (_overlay != _CaddyPlayOverlay.mindSnap) {
      return;
    }

    _mindSnapTimer?.cancel();
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

    await HapticService.light();
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

    await HapticService.light();
    var updated = round.copyWith(
      holes: _scorecardDraft,
      lastUpdatedAt: DateTime.now(),
      syncState: CaddyPlaySyncState.localOnly,
      lastSyncError: null,
    );
    if (updated.currentHole < updated.holesTotal) {
      updated = updated.advanceHole();
    }
    await _saveRound(updated);
    if (!mounted) {
      return;
    }

    _setOverlay(_CaddyPlayOverlay.none);
    _showBanner('Score saved.');
  }

  Future<void> _retreatHole() async {
    final round = _activeRound;
    if (round == null || round.currentHole <= 1) {
      return;
    }
    await _saveRound(round.retreatHole());
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

  Future<void> _confirmCompleteRound() async {
    if (_activeRound == null) {
      if (_completedRound != null) {
        setState(() => _screen = _CaddyPlayScreen.home);
      }
      return;
    }

    final confirmed = await showFoCoCoConfirmDialog(
      context: context,
      title: 'Finish this round?',
      message:
          'Your round snapshot will be saved and you can start a new round from home.',
      confirmLabel: 'Done',
      cancelLabel: 'Keep reviewing',
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _completeRound();
  }

  Future<void> _completeRound() async {
    if (_activeRound == null) {
      if (_completedRound != null) {
        setState(() => _screen = _CaddyPlayScreen.home);
      }
      return;
    }

    final round = _activeRound!;
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
      });
      context.goNamed('fococo_tab');
    } catch (error) {
      debugPrint('Unable to complete round: $error');
      _showBanner(_userSafeError('complete'), color: _kPendingAmber);
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
        'autoStartReflection': true,
      },
    );
  }

  String _scorecardScoreToPar() {
    if (!_scorecardDraft.any((hole) => hole.score != null)) {
      return '-';
    }
    final totals = caddyPlayScoringTotals(_scorecardDraft);
    return formatCaddyPlayScoreToParLabel(
      totals.scoreToPar,
      approximate: totals.usesDefaultedPar,
    );
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
    if (mounted) {
      setState(() => _overlay = overlay);
    } else {
      _overlay = overlay;
    }
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
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final Color textColor;
  final Color fillColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 56.0 : 72.0;
    final fontSize = compact ? 18.0 : 20.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: height,
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
                fontSize: fontSize,
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
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 52.0 : 64.0;
    final fontSize = compact ? 18.0 : 20.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _CaddyPlayWidgetState._kCaddyGreen.withValues(alpha: 0.9),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
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
                size: 64,
              ),
              const SizedBox(height: 12),
              const _GlowSeparator(),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: _CaddyPlayWidgetState._kCaddyGreen,
                  fontSize: 28,
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
              size: 34,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
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
  const _SummaryCard({
    required this.child,
    this.compact = false,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 0.6,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 0.6,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.headlineMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VerticalDividerGlow extends StatelessWidget {
  const _VerticalDividerGlow({this.flexible = false});

  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final divider = Container(
      width: 1,
      color: Colors.white.withValues(alpha: 0.14),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
    if (flexible) {
      return divider;
    }
    return SizedBox(
      height: 82,
      child: divider,
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
    required this.elapsedLabel,
    required this.amplitude,
    required this.pulseAnimation,
    this.onTap,
  });

  final bool warning;
  final String elapsedLabel;
  final double amplitude;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glowColor = warning
        ? _CaddyPlayWidgetState._kPendingAmber
        : _CaddyPlayWidgetState._kTalkPurple;
    final pulseScale = 1 + (pulseAnimation.value * 0.08);
    final ampScale = 1 + (amplitude * 0.22);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: pulseScale * ampScale,
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                _VoiceWaveRing(
                  color: glowColor,
                  amplitude: amplitude,
                  ringScale: 1.34,
                ),
                _VoiceWaveRing(
                  color: glowColor,
                  amplitude: amplitude,
                  ringScale: 1.16,
                ),
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: 0.28 + (amplitude * 0.35),
                        ),
                        blurRadius: 34 + (amplitude * 24),
                        spreadRadius: 8 + (amplitude * 10),
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [
                        glowColor.withValues(alpha: 0.28 + (amplitude * 0.2)),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: glowColor,
                    size: 96,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          elapsedLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VoiceWaveRing extends StatelessWidget {
  const _VoiceWaveRing({
    required this.color,
    required this.amplitude,
    required this.ringScale,
  });

  final Color color;
  final double amplitude;
  final double ringScale;

  @override
  Widget build(BuildContext context) {
    final size = 220 * ringScale * (1 + amplitude * 0.12);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.18 + (amplitude * 0.45)),
          width: 2 + (amplitude * 2.5),
        ),
      ),
    );
  }
}

class _JustTalkWaveformPreview extends StatelessWidget {
  const _JustTalkWaveformPreview({
    required this.amplitude,
    required this.playing,
  });

  final double amplitude;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(18, (index) {
          final wave =
              (math.sin((index * 0.72) + (amplitude * 8)) + 1) / 2;
          final level = playing
              ? (0.25 + (wave * 0.75) * (0.35 + amplitude * 0.65))
              : 0.18 + (amplitude * 0.12);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: 6,
            height: 18 + (level * 72),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: _CaddyPlayWidgetState._kTalkPurple
                  .withValues(alpha: 0.35 + (level * 0.55)),
              borderRadius: BorderRadius.circular(999),
              boxShadow: playing
                  ? [
                      BoxShadow(
                        color: _CaddyPlayWidgetState._kTalkPurple
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

class _JustTalkPreviewControl extends StatelessWidget {
  const _JustTalkPreviewControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted
        ? _CaddyPlayWidgetState._kTalkPurple
        : Colors.white.withValues(alpha: 0.82);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlighted
                    ? color.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.75)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreScrollPicker extends StatelessWidget {
  const _ScoreScrollPicker({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<int> values;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected).clamp(0, values.length - 1);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        SizedBox(
          height: 88,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: index),
            itemExtent: 28,
            magnification: 1.08,
            squeeze: 1.1,
            onSelectedItemChanged: (i) => onSelected(values[i]),
            children: values
                .map(
                  (v) => Center(
                    child: Text(
                      '$v',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale the stepper buttons so two of them plus the score label fit
          // the cell width even on small screens / narrow score grids
          // (the per-hole grid hands us cells around 67pt wide).
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 80.0;
          final buttonWidth = available < 80
              ? (available * 0.32).clamp(22.0, 30.0)
              : 32.0;
          final iconSize = buttonWidth >= 28 ? 20.0 : 18.0;
          return Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: onMinus,
                width: buttonWidth,
                iconSize: iconSize,
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: onPlus,
                width: buttonWidth,
                iconSize: iconSize,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.width = 32,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double width;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Icon(icon, color: Colors.white, size: iconSize),
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
