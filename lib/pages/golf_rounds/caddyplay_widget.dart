import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/services/profile_service.dart';

import 'caddyplay_models.dart';
import 'caddyplay_session_service.dart';

class CaddyPlayWidget extends StatefulWidget {
  const CaddyPlayWidget({super.key});

  static const String routeName = 'caddy_play';
  static const String routePath = '/caddy_play';

  @override
  State<CaddyPlayWidget> createState() => _CaddyPlayWidgetState();
}

enum _CaddyPlayScreen { home, setup, active }

class _CaddyPlayWidgetState extends State<CaddyPlayWidget>
    with WidgetsBindingObserver {
  final CaddyPlaySessionService _sessionService = CaddyPlaySessionService();
  ProfileService? _profileService;
  final SpeechToText _speechToText = SpeechToText();

  _CaddyPlayScreen _screen = _CaddyPlayScreen.home;
  CaddyPlayMode _mode = CaddyPlayMode.play;
  CaddyPlaySession? _activeSession;

  bool _isBusy = false;
  bool _isListeningVoiceLog = false;
  bool _isSpeechAvailable = false;
  bool _showCapturePulse = false;

  Timer? _capturePulseTimer;
  Timer? _backgroundPracticeTimer;

  List<CaddyPlayHole> _holes = <CaddyPlayHole>[];
  List<CaddyPlayLog> _recentLogs = <CaddyPlayLog>[];

  List<GolfClub> _courseOptions = <GolfClub>[];
  final TextEditingController _courseSearchController = TextEditingController();

  String? _selectedCourseName;
  String? _selectedCourseId;
  String? _selectedTeeName;
  int? _selectedTeeDistance;
  int _selectedHoles = 9;

  double? _courseRating;
  double? _slopeRating;
  bool _showAdvancedSetup = false;

  final List<Map<String, dynamic>> _teeOptions = const <Map<String, dynamic>>[
    {'name': 'Red', 'distance': 5400},
    {'name': 'White', 'distance': 6200},
    {'name': 'Blue', 'distance': 6800},
    {'name': 'Black', 'distance': 7300},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    setState(() => _isBusy = true);
    try {
      _profileService ??= ProfileService();
    } catch (_) {
      _profileService = null;
    }

    try {
      _isSpeechAvailable = await _speechToText.initialize();
      await _loadCourseOptions();
      await _loadActiveSession();
    } catch (_) {
      // Best effort init only.
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _loadCourseOptions() async {
    final profileService = _profileService;
    if (profileService == null) {
      if (!mounted) return;
      setState(() => _courseOptions = <GolfClub>[]);
      return;
    }

    try {
      final location = await profileService.getCurrentLocation();
      if (!mounted) return;
      final courses = location != null
          ? await profileService.searchNearbyGolfClubs(location)
          : <GolfClub>[];
      setState(() {
        _courseOptions = courses;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _courseOptions = <GolfClub>[];
      });
    }
  }

  Future<void> _loadActiveSession() async {
    if (currentUserUid.isEmpty) return;

    final resumed = await _sessionService.resumeActiveSession(currentUserUid);
    if (!mounted) return;

    if (resumed != null) {
      _activeSession = resumed;
      _mode = resumed.mode;
      _selectedCourseName = resumed.courseName;
      _selectedCourseId = resumed.courseId;
      _selectedTeeName = resumed.teeName;
      _selectedTeeDistance = resumed.teeDistance;
      _selectedHoles = resumed.holesTotal;
      await _loadHoles(resumed.id);
    }
    setState(() {});
  }

  Future<void> _loadHoles(String sessionId) async {
    final holesSnapshot = await FirebaseFirestore.instance
        .collection('caddyplay_sessions')
        .doc(sessionId)
        .collection('holes')
        .orderBy('holeNumber', descending: false)
        .get();

    _holes = holesSnapshot.docs
        .map((doc) => CaddyPlayHole.fromMap(doc.data()))
        .toList(growable: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _activeSession;
    if (session == null || session.mode != CaddyPlayMode.practice) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _startBackgroundPracticeTimeout();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _cancelBackgroundPracticeTimeout();
    }
  }

  void _startBackgroundPracticeTimeout() {
    _backgroundPracticeTimer?.cancel();
    _backgroundPracticeTimer = Timer(const Duration(minutes: 10), () async {
      final session = _activeSession;
      if (session == null || session.mode != CaddyPlayMode.practice) return;
      await _completePracticeSession(autoTriggered: true);
    });
  }

  void _cancelBackgroundPracticeTimeout() {
    _backgroundPracticeTimer?.cancel();
    _backgroundPracticeTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _courseSearchController.dispose();
    _capturePulseTimer?.cancel();
    _backgroundPracticeTimer?.cancel();
    _speechToText.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (currentUserUid.isEmpty) {
      return Scaffold(
        backgroundColor: theme.primaryBackground,
        body: Center(
          child: Text(
            'Please sign in to use CaddyPlay.',
            style: theme.bodyLarge,
          ),
        ),
      );
    }

    return StreamBuilder<UserRecord>(
      stream: UserRecord.getDocument(
        FirebaseFirestore.instance.doc('user/$currentUserUid'),
      ),
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: _screen == _CaddyPlayScreen.active
              ? const Color(0xFF0E1116)
              : theme.primaryBackground,
          drawer: user != null
              ? EnhancedFoCoCoDrawer(
                  currentUser: user,
                  currentRoute: 'caddy_play',
                  onNavigate: (route) => context.goNamed(route),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(theme),
                if (_isBusy) const LinearProgressIndicator(minHeight: 2),
                Expanded(child: _buildBody(theme)),
              ],
            ),
          ),
          bottomNavigationBar: EnhancedFoCoCoNavBar(
            currentRoute: 'caddy_play',
            currentUser: user,
            onTap: _handleNavigation,
            showLabels: true,
            enableVoiceButton: true,
            useGlassEffect: true,
          ),
        );
      },
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    final title = switch (_screen) {
      _CaddyPlayScreen.home => 'CaddyPlay',
      _CaddyPlayScreen.setup =>
        _mode == CaddyPlayMode.play ? 'Play Setup' : 'Practice Setup',
      _CaddyPlayScreen.active =>
        _mode == CaddyPlayMode.play ? 'Play' : 'Practice',
    };

    final subtitle = switch (_screen) {
      _CaddyPlayScreen.home => 'Capture what happened',
      _CaddyPlayScreen.setup =>
        'Set context once. Capture stays fast and calm.',
      _CaddyPlayScreen.active => _activeSession == null
          ? 'Session inactive'
          : 'Hole ${_activeSession!.currentHole} • ${_activeSession!.holesPlayed}/${_activeSession!.holesTotal}',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: theme.alternate.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_screen != _CaddyPlayScreen.home)
            IconButton(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            )
          else
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
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
          if (_screen == _CaddyPlayScreen.active && _mode == CaddyPlayMode.play)
            TextButton.icon(
              onPressed: _openScorecardSheet,
              icon: const Icon(Icons.table_chart_rounded),
              label: const Text('Scorecard'),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(FlutterFlowTheme theme) {
    return switch (_screen) {
      _CaddyPlayScreen.home => _buildHome(theme),
      _CaddyPlayScreen.setup => _buildSetup(theme),
      _CaddyPlayScreen.active => _buildActive(theme),
    };
  }

  Widget _buildHome(FlutterFlowTheme theme) {
    final hasActive = _activeSession != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _buildActionCard(
          theme: theme,
          icon: FontAwesomeIcons.flag,
          title: 'Play',
          subtitle: 'Capture your round with context and control',
          color: const Color(0xFF0A3669),
          onTap: () {
            setState(() {
              _mode = CaddyPlayMode.play;
              _screen = _CaddyPlayScreen.setup;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          theme: theme,
          icon: FontAwesomeIcons.dumbbell,
          title: 'Practice',
          subtitle: 'Capture learning moments without scoring',
          color: const Color(0xFF017B3D),
          onTap: () {
            setState(() {
              _mode = CaddyPlayMode.practice;
              _screen = _CaddyPlayScreen.setup;
            });
          },
        ),
        const SizedBox(height: 12),
        if (hasActive)
          _buildActionCard(
            theme: theme,
            icon: Icons.play_circle_fill_rounded,
            title: _activeSession!.mode == CaddyPlayMode.play
                ? 'Resume Session'
                : 'Resume Practice',
            subtitle: _activeSession!.mode == CaddyPlayMode.play
                ? 'Continue round • Hole ${_activeSession!.currentHole}'
                : 'Continue active practice capture',
            color: const Color(0xFFFEA400),
            onTap: () async {
              await _loadHoles(_activeSession!.id);
              if (!mounted) return;
              setState(() {
                _mode = _activeSession!.mode;
                _screen = _CaddyPlayScreen.active;
              });
            },
          ),
        const SizedBox(height: 18),
        _buildGolfChatCta(theme),
      ],
    );
  }

  Widget _buildGolfChatCta(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.secondary.withValues(alpha: 0.14),
            theme.primary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: theme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: theme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GolfChat',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Reflect • Understand • Reset',
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.pushNamed('golf_chat'),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetup(FlutterFlowTheme theme) {
    final filteredCourses = _courseOptions.where((club) {
      final q = _courseSearchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return club.name.toLowerCase().contains(q) ||
          club.address.toLowerCase().contains(q);
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        if (_mode == CaddyPlayMode.play)
          Text(
            'Play requires context before logging starts.',
            style: theme.bodyMedium.copyWith(color: theme.warning),
          ),
        if (_mode == CaddyPlayMode.practice)
          Text(
            'Course is optional in Practice mode.',
            style: theme.bodyMedium.copyWith(color: theme.secondaryText),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _courseSearchController,
          decoration: InputDecoration(
            labelText: 'Course',
            hintText: 'Search course list',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _selectedCourseName != null
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedCourseName = null;
                        _selectedCourseId = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        if (filteredCourses.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.alternate.withValues(alpha: 0.3)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                final selected = _selectedCourseName == course.name;
                return ListTile(
                  dense: true,
                  title: Text(course.name),
                  subtitle: Text(course.address),
                  trailing: selected
                      ? Icon(Icons.check_circle_rounded, color: theme.success)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCourseName = course.name;
                      _selectedCourseId = course.placeId;
                      _courseSearchController.text = course.name;
                    });
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _selectedTeeName,
          decoration: const InputDecoration(labelText: 'Tee'),
          items: _teeOptions
              .map((tee) => DropdownMenuItem<String>(
                    value: tee['name'] as String,
                    child: Text('${tee['name']} • ${tee['distance']}y'),
                  ))
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) return;
            final selected =
                _teeOptions.firstWhere((tee) => tee['name'] == value);
            setState(() {
              _selectedTeeName = value;
              _selectedTeeDistance = selected['distance'] as int;
            });
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('9 Holes'),
                selected: _selectedHoles == 9,
                onSelected: (_) => setState(() => _selectedHoles = 9),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('18 Holes'),
                selected: _selectedHoles == 18,
                onSelected: (_) => setState(() => _selectedHoles = 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          title: Text(
            'Advanced fields',
            style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Optional Course Rating / Slope'),
          value: _showAdvancedSetup,
          onChanged: (v) => setState(() => _showAdvancedSetup = v),
        ),
        if (_showAdvancedSetup) ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _courseRating?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Course Rating'),
            onChanged: (v) => _courseRating = double.tryParse(v),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _slopeRating?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Slope'),
            onChanged: (v) => _slopeRating = double.tryParse(v),
          ),
        ],
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: _isBusy ? null : _startSession,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
              _mode == CaddyPlayMode.play ? 'Start Round' : 'Start Practice'),
        ),
      ],
    );
  }

  Widget _buildActive(FlutterFlowTheme theme) {
    final session = _activeSession;
    if (session == null) {
      return Center(
        child: Text(
          'No active session found.',
          style: theme.bodyLarge.copyWith(color: Colors.white),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              _statusPill(
                icon: Icons.flag_circle_rounded,
                text: session.mode == CaddyPlayMode.play ? 'Play' : 'Practice',
                color: session.mode == CaddyPlayMode.play
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF22C55E),
              ),
              const SizedBox(width: 8),
              if (session.mode == CaddyPlayMode.play)
                _statusPill(
                  icon: Icons.pin_drop_outlined,
                  text: 'Hole ${session.currentHole}',
                  color: const Color(0xFFFEA400),
                ),
              const Spacer(),
              Text(
                '${session.holesPlayed}/${session.holesTotal}',
                style: theme.labelLarge.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _showCapturePulse
                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: _showCapturePulse
                  ? const Color(0xFF10B981)
                  : Colors.white.withValues(alpha: 0.12),
              width: _showCapturePulse ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: session.mode == CaddyPlayMode.play
                    ? ElevatedButton.icon(
                        onPressed: _isBusy || _isListeningVoiceLog
                            ? null
                            : _startVoiceLogCapture,
                        icon: Icon(_isListeningVoiceLog
                            ? Icons.hearing_rounded
                            : FontAwesomeIcons.microphone),
                        label: Text(
                          _isListeningVoiceLog ? 'Listening...' : 'JustTalk',
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : () => _showTapLogSheet(),
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('Tap to Log'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_recentLogs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent capture',
                  style: theme.labelLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _recentLogs.last.transcription.isNotEmpty
                      ? _recentLogs.last.transcription
                      : '${chipLabel(_recentLogs.last.result)} • ${chipLabel(_recentLogs.last.focus)}',
                  style: theme.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (session.mode == CaddyPlayMode.play)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _goPreviousHole,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back Hole'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _advanceHole,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next Hole'),
                ),
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: _isBusy ? null : _completePracticeSession,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('End Practice'),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _openScorecardSheet,
          icon: const Icon(Icons.swipe_up_alt_rounded),
          label: const Text('Open Sliding Scorecard'),
        ),
        if (session.mode == CaddyPlayMode.play)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Hard limits: no typing forms, no analytics, no coaching interruptions.',
              style: theme.bodySmall.copyWith(color: Colors.white54),
            ),
          ),
      ],
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _startSession() async {
    if (_isBusy) return;

    final isPlay = _mode == CaddyPlayMode.play;
    final hasCourse = (_selectedCourseName ?? '').trim().isNotEmpty;
    final hasTee = (_selectedTeeName ?? '').trim().isNotEmpty;

    if (isPlay && (!hasCourse || !hasTee)) {
      _showSnack('Set course and tee before starting Play.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      final session = await _sessionService.startSession(
        mode: _mode,
        courseName: hasCourse ? _selectedCourseName : null,
        courseId: hasCourse ? _selectedCourseId : null,
        teeName: hasTee ? _selectedTeeName : null,
        teeDistance: _selectedTeeDistance,
        holesTotal: _selectedHoles,
        courseRating: _courseRating,
        slopeRating: _slopeRating,
      );

      await _loadHoles(session.id);

      if (!mounted) return;
      setState(() {
        _activeSession = session;
        _screen = _CaddyPlayScreen.active;
        _recentLogs = <CaddyPlayLog>[];
      });
    } catch (e) {
      _showSnack('Failed to start session: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _startVoiceLogCapture() async {
    if (!_isSpeechAvailable) {
      _showSnack('Voice logging is not available on this device right now.');
      return;
    }

    if (_isListeningVoiceLog) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListeningVoiceLog = false);
      return;
    }

    setState(() => _isListeningVoiceLog = true);
    String finalWords = '';

    await _speechToText.listen(
      onResult: (result) async {
        finalWords = result.recognizedWords;
        if (!result.finalResult) return;

        await _speechToText.stop();
        if (!mounted) return;
        setState(() => _isListeningVoiceLog = false);
        await _handleVoiceTranscript(finalWords);
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en_US',
    );
  }

  Future<void> _handleVoiceTranscript(String transcript) async {
    final text = transcript.trim();
    if (text.isEmpty) {
      _showSnack('No speech captured. Try again.');
      return;
    }

    final inferred = inferChipSelectionFromTranscript(text);
    if (inferred.hasRequired) {
      await _saveCapture(
        selection: inferred,
        transcription: text,
        inputMethod: 'voice',
      );
      return;
    }

    await _showTapLogSheet(
      initialSelection: inferred,
      transcript: text,
      inputMethod: 'voice',
      title: 'Complete Required Chips',
    );
  }

  Future<void> _showTapLogSheet({
    CaddyPlayChipSelection? initialSelection,
    String transcript = '',
    String inputMethod = 'tap',
    String title = 'Tap to Log',
  }) async {
    var selection = initialSelection ?? const CaddyPlayChipSelection();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildSection<T extends Enum>({
              required String label,
              required List<T> values,
              required T? selected,
              required void Function(T value) onPick,
              bool requiredField = false,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requiredField ? '$label *' : label,
                    style:
                        theme.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: values.map((value) {
                      return ChoiceChip(
                        label: Text(chipLabel(value)),
                        selected: selected == value,
                        onSelected: (_) => setModalState(() => onPick(value)),
                      );
                    }).toList(growable: false),
                  ),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.headlineSmall),
                      if (transcript.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          transcript,
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      buildSection<CaddyPlayResultChip>(
                        label: 'Result',
                        requiredField: true,
                        values: CaddyPlayResultChip.values,
                        selected: selection.result,
                        onPick: (value) =>
                            selection = selection.copyWith(result: value),
                      ),
                      const SizedBox(height: 12),
                      buildSection<CaddyPlayFocusChip>(
                        label: 'Focus',
                        requiredField: true,
                        values: CaddyPlayFocusChip.values,
                        selected: selection.focus,
                        onPick: (value) =>
                            selection = selection.copyWith(focus: value),
                      ),
                      const SizedBox(height: 12),
                      buildSection<CaddyPlayRoutineChip>(
                        label: 'Routine',
                        values: CaddyPlayRoutineChip.values,
                        selected: selection.routine,
                        onPick: (value) =>
                            selection = selection.copyWith(routine: value),
                      ),
                      const SizedBox(height: 12),
                      buildSection<CaddyPlayEmotionChip>(
                        label: 'Emotion',
                        values: CaddyPlayEmotionChip.values,
                        selected: selection.emotion,
                        onPick: (value) =>
                            selection = selection.copyWith(emotion: value),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!selection.hasRequired) {
                                  _showSnack('Result and Focus are required.');
                                  return;
                                }
                                await _saveCapture(
                                  selection: selection,
                                  transcription: transcript,
                                  inputMethod: inputMethod,
                                );
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Save Capture'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveCapture({
    required CaddyPlayChipSelection selection,
    required String transcription,
    required String inputMethod,
  }) async {
    final session = _activeSession;
    if (session == null) return;

    final log = CaddyPlayLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: session.id,
      userId: currentUserUid,
      mode: session.mode,
      holeNumber:
          session.mode == CaddyPlayMode.play ? session.currentHole : null,
      inputMethod: inputMethod,
      transcription: transcription,
      result: selection.result,
      focus: selection.focus,
      routine: selection.routine,
      emotion: selection.emotion,
      capturedAt: DateTime.now(),
      editedAt: null,
    );

    setState(() => _isBusy = true);
    try {
      await _sessionService.saveLog(log);
      if (!mounted) return;
      setState(() {
        _recentLogs = [..._recentLogs, log];
      });
      _triggerCaptureFeedback();
    } catch (e) {
      _showSnack('Failed to save capture: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _triggerCaptureFeedback() {
    HapticFeedback.lightImpact();
    setState(() => _showCapturePulse = true);
    _capturePulseTimer?.cancel();
    _capturePulseTimer = Timer(const Duration(milliseconds: 620), () {
      if (mounted) setState(() => _showCapturePulse = false);
    });
  }

  Future<void> _advanceHole() async {
    final session = _activeSession;
    if (session == null) return;

    setState(() => _isBusy = true);
    try {
      final reachedFinal = await _sessionService.advanceHole(session.id);
      await _loadActiveSession();
      await _loadHoles(session.id);

      if (reachedFinal) {
        await _showRoundCompletionPrompt();
      }
    } catch (e) {
      _showSnack('Unable to advance hole: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _goPreviousHole() async {
    final session = _activeSession;
    if (session == null || session.currentHole <= 1) return;

    await FirebaseFirestore.instance
        .collection('caddyplay_sessions')
        .doc(session.id)
        .update({
      'currentHole': session.currentHole - 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _loadActiveSession();
    if (mounted) setState(() {});
  }

  Future<void> _showRoundCompletionPrompt() async {
    final theme = FlutterFlowTheme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Round?',
                  style: theme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'You reached the final hole. Review scorecard edits if needed, then finalize this round.',
                  style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Keep Editing'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _completePlaySession();
                        },
                        child: const Text('Finalize Round'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completePlaySession() async {
    final session = _activeSession;
    if (session == null) return;

    setState(() => _isBusy = true);
    try {
      await _sessionService.completePlaySession(session.id);
      if (!mounted) return;
      setState(() {
        _activeSession = null;
        _screen = _CaddyPlayScreen.home;
        _holes = <CaddyPlayHole>[];
        _recentLogs = <CaddyPlayLog>[];
      });
      _showSnack('Round completed and synced.');
    } catch (e) {
      _showSnack('Failed to complete round: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _completePracticeSession({bool autoTriggered = false}) async {
    final session = _activeSession;
    if (session == null) return;

    setState(() => _isBusy = true);
    try {
      await _sessionService.completePracticeSession(session.id);
      if (!mounted) return;
      setState(() {
        _activeSession = null;
        _screen = _CaddyPlayScreen.home;
        _holes = <CaddyPlayHole>[];
        _recentLogs = <CaddyPlayLog>[];
      });
      _showSnack(autoTriggered
          ? 'Practice auto-ended after background inactivity.'
          : 'Practice session completed.');
    } catch (e) {
      _showSnack('Failed to complete practice: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _openScorecardSheet() async {
    final session = _activeSession;
    if (session == null || session.mode != CaddyPlayMode.play) {
      _showSnack('Scorecard is available in Play mode only.');
      return;
    }

    if (_holes.isEmpty) {
      await _loadHoles(session.id);
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.34,
          minChildSize: 0.33,
          maxChildSize: 0.66,
          expand: false,
          builder: (context, controller) {
            final totalScore =
                _holes.fold<int>(0, (sum, hole) => sum + (hole.score ?? 0));
            final totalPar =
                _holes.fold<int>(0, (sum, hole) => sum + (hole.par ?? 4));

            return Container(
              decoration: BoxDecoration(
                color: theme.primaryBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: theme.alternate.withValues(alpha: 0.2),
                ),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  Text(
                    '${session.courseName ?? 'Course'} • ${session.mode.name.toUpperCase()}',
                    style:
                        theme.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${session.teeName ?? 'Tee'} • ${session.teeDistance ?? 0}y • Hole ${session.currentHole}/${session.holesTotal}',
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _holes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final hole = _holes[index];
                        final isCurrent =
                            hole.holeNumber == session.currentHole;
                        final delta = (hole.score ?? 0) - (hole.par ?? 4);
                        final deltaText = hole.score == null
                            ? '-'
                            : (delta == 0
                                ? '0'
                                : (delta > 0 ? '+$delta' : '$delta'));

                        return InkWell(
                          onTap: () => _editHole(hole),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 68,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isCurrent
                                  ? theme.primary.withValues(alpha: 0.14)
                                  : theme.secondaryBackground,
                              border: Border.all(
                                color: isCurrent
                                    ? theme.primary
                                    : theme.alternate.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('H${hole.holeNumber}',
                                    style: theme.labelMedium),
                                const SizedBox(height: 4),
                                Text(deltaText,
                                    style: theme.bodySmall.copyWith(
                                      color: delta <= 0
                                          ? theme.success
                                          : theme.error,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Score Summary', style: theme.titleSmall),
                          const SizedBox(height: 8),
                          Text('Total Score: $totalScore'),
                          Text(
                              'Score to Par: ${totalScore - totalPar >= 0 ? '+' : ''}${totalScore - totalPar}'),
                          if (session.holesTotal == 18)
                            Text(
                                'Front/Back split available after round completion.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editHole(CaddyPlayHole hole) async {
    final parController = TextEditingController(
      text: hole.par?.toString() ?? '4',
    );
    final distanceController = TextEditingController(
      text: hole.distance?.toString() ?? '',
    );
    final scoreController = TextEditingController(
      text: hole.score?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return AlertDialog(
          title: Text('Edit Hole ${hole.holeNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: parController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Par'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Distance (yards)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Score'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final session = _activeSession;
                if (session == null) return;

                await _sessionService.updateHole(
                  sessionId: session.id,
                  holeNumber: hole.holeNumber,
                  par: int.tryParse(parController.text.trim()),
                  distance: int.tryParse(distanceController.text.trim()),
                  score: int.tryParse(scoreController.text.trim()),
                  isComplete: int.tryParse(scoreController.text.trim()) != null,
                );

                await _loadHoles(session.id);
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Save',
                style: theme.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _goBack() {
    if (_screen == _CaddyPlayScreen.active) {
      setState(() => _screen = _CaddyPlayScreen.home);
      return;
    }

    if (_screen == _CaddyPlayScreen.setup) {
      setState(() => _screen = _CaddyPlayScreen.home);
    }
  }

  void _handleNavigation(String route) {
    if (!mounted) return;

    switch (route) {
      case 'dashboard':
        context.go('/mind_coach');
        break;
      case 'caddy_play':
      case 'golf_sync': // legacy alias
        context.go('/caddy_play');
        break;
      case 'mind_coach':
      case 'coaching_modules':
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
