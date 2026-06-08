import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluid_background/fluid_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/ai_integration/services/cartesia_api_service.dart';
import '/ai_integration/services/cartesia_speech_prompt.dart';
import '/ai_integration/widgets/navbar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/widgets/fococo_drawer_widget.dart';

import 'fococo_insight_service.dart';

// IMPORTANT — crash-mitigation notes (keep in mind before re-adding features).
//
// Symptom: app crashes on iOS launch when the FoCoCo tab is the default route.
// Native trace ends in `std::__libcpp_condvar_wait` — this is the Firestore /
// gRPC native thread abort that happens when Firestore is touched while the
// platform is still warming up (Flutter engine + Firebase plugins + gRPC
// channel all initializing at the same time).
//
// To keep the app from crashing, this screen intentionally touches NO Firebase
// APIs on mount:
//   • No FirebaseFirestore.instance.* calls
//   • No Firebase Functions calls
//   • No StreamBuilder / FutureBuilder on remote docs
//   • No user-record drawer (drawer is disabled for now)
//
// What we DO do:
//   • Read the cached insight from SharedPreferences (pure on-disk, safe).
//   • After a 3s delay — i.e. well past the native init window — kick off the
//     backend insight refresh in the background ([FoCoCoInsightService] hits
//     `getOrCreateFoCoCoDailyInsight` with a refreshed ID token; on failure uses
//     Firebase AI Logic on-device so copy still generates when Functions/Gemini
//     backend is degraded). Result is persisted to prefs.
//   • Cartesia TTS runs only after the user taps the speaker (no audio init on
//     first paint).
//
// Daily insight copy is generated server-side (see firebase/functions/
// fococo_daily_insights.js — model gemini-3.1-pro-preview). Live / richer audio
// experiments can follow gemini_voice_config live model ids separately.
//
// When layering features back in, do so one at a time and confirm on a real
// TestFlight build before adding the next:
//   1. Drawer (UserRecord fetch) — only after first successful insight load
//   2. `markOpened` Firestore write
//   3. Heavy animations beyond [FluidBackground] + nav logo rotation
//   4. Screen-time tracking + WidgetsBindingObserver
class FoCoCoTabWidget extends StatefulWidget {
  const FoCoCoTabWidget({super.key});

  static const String routeName = 'fococo';
  static const String routePath = '/fococo';

  @override
  State<FoCoCoTabWidget> createState() => _FoCoCoTabWidgetState();
}

class _FoCoCoTabWidgetState extends State<FoCoCoTabWidget> {
  static const _prefKeyCurrentJson = 'fococo_insight_json';
  static const _prefKeyLastJson = 'fococo_insight_last_json';
  static const _fallbackText =
      'The MindGame System is ready. Every round, every session, every '
      'conversation builds the picture of your mental game.';

  String? _insightText;
  FoCoCoDailyInsight? _insight;
  bool _insightLoading = true;
  bool _refreshBusy = false;
  bool _audioBusy = false;
  String? _refreshError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrapInsight());
  }

  Future<void> _bootstrapInsight() async {
    await _hydrateFromCache();
    if (!mounted) return;
    await _refreshInsightSafely();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _hydrateFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonCurrent = prefs.getString(_prefKeyCurrentJson);
      final jsonLast = prefs.getString(_prefKeyLastJson);
      final insight = _decodeInsight(jsonCurrent) ?? _decodeInsight(jsonLast);
      final text = insight?.insightText;
      if (!mounted) return;
      setState(() {
        _insight = insight;
        _insightText = (text != null && text.isNotEmpty) ? text : _fallbackText;
        _insightLoading = false;
        _refreshError = null;
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo cache hydrate failed: $error');
      }
      if (!mounted) return;
      setState(() {
        _insightText = _fallbackText;
        _insightLoading = false;
      });
    }
  }

  FoCoCoDailyInsight? _decodeInsight(String? jsonValue) {
    if (jsonValue == null || jsonValue.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonValue);
      if (decoded is! Map) return null;
      return FoCoCoDailyInsight.fromMap(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshInsightSafely({bool userInitiated = false}) async {
    if (_refreshBusy) return;
    setState(() {
      _refreshBusy = true;
      _refreshError = null;
      if (userInitiated) {
        _insightLoading = true;
      }
    });
    try {
      final insight = await FoCoCoInsightService.instance.getTodayInsight();
      if (!mounted) return;
      final text = insight.insightText.trim().isNotEmpty
          ? insight.insightText.trim()
          : _fallbackText;
      setState(() {
        _insight = insight;
        _insightText = text;
        _insightLoading = false;
        _refreshBusy = false;
      });
      if (insight.hasRemoteRecord && !insight.opened) {
        unawaited(FoCoCoInsightService.instance.markOpened(insight));
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ FoCoCo deferred refresh failed: $error');
      }
      if (!mounted) return;
      setState(() {
        _refreshBusy = false;
        _insightLoading = false;
        _refreshError = userInitiated
            ? 'Could not refresh. Check connection and try again.'
            : null;
      });
    }
  }

  Future<void> _playInsightAudio() async {
    final text = (_insightText ?? _fallbackText).trim();
    if (text.isEmpty || _audioBusy) return;

    setState(() => _audioBusy = true);
    try {
      final tts = CartesiaAPIService.instance;
      if (!tts.isInitialized) {
        await tts.initialize();
      }
      await tts.speakTextWithContinuations(
        text: text,
        voiceProfileKey: 'mentor_calm',
        contentType: 'daily_insight',
        speechProfile: CartesiaSpeechPrompt.dailyInsight,
      );
      final insight = _insight;
      if (insight != null && insight.hasRemoteRecord && !insight.playedAudio) {
        unawaited(FoCoCoInsightService.instance.markAudioPlayed(insight));
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Could not play audio: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _audioBusy = false);
      }
    }
  }

  String _headerDateLabel() {
    final raw = _insight?.insightDate.trim() ?? '';
    if (raw.isEmpty) {
      return DateFormat.yMMMMd().format(DateTime.now());
    }
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return DateFormat.yMMMMd().format(DateTime(y, m, d));
      }
    } catch (_) {}
    return raw;
  }

  List<Widget> _buildInsightParagraphWidgets(FlutterFlowTheme theme) {
    final raw = (_insightText ?? _fallbackText).trim();
    final chunks = raw
        .split(RegExp(r'\n\s*\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final paragraphs = chunks.isEmpty ? [raw] : chunks;
    final widgets = <Widget>[];
    for (var i = 0; i < paragraphs.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: 18));
      }
      widgets.add(
        Text(
          paragraphs[i],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.94),
            fontSize: 18,
            height: 1.65,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
            fontFamily: theme.bodyLarge.fontFamily,
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const shellTint = Color(0xFF0F0514);

    return FoCoCoAdaptiveScaffold(
      backgroundColor: shellTint,
      hideAppBar: true,
      currentRoute: 'fococo',
      onTap: (route) => context.goNamed(route),
      showBottomNav: false,
      enableVoiceButton: false,
      drawer: FoCoCoDrawer(
        currentRoute: 'fococo',
        onNavigate: (route) => context.goNamed(route),
      ),
      body: ColoredBox(
        color: shellTint,
        child: FluidBackground(
          initialColors: InitialColors.custom([
            theme.primary.withValues(alpha: 0.52),
            theme.secondary.withValues(alpha: 0.48),
            theme.tertiary.withValues(alpha: 0.42),
          ]),
          initialPositions: InitialOffsets.random(3),
          bubblesSize: 440,
          velocity: 82,
          // fluid_background 1.0.5 always cancels this timer in dispose; it
          // must be constructed whenever the widget is used.
          bubbleMutationDuration: const Duration(minutes: 45),
          allowColorChanging: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FoCoCoInlineScreenHeader(
                title: 'FoCoCo',
                showDrawerButton: true,
                compactTitle: true,
                topInset: MediaQuery.viewPaddingOf(context).top,
              ),
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewPaddingOf(context).bottom +
                          kFoCoCoBottomNavStripAndTabsHeight +
                          8,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Daily insight',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 13,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w600,
                                fontFamily: theme.bodyLarge.fontFamily,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _headerDateLabel(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                fontFamily: theme.bodyLarge.fontFamily,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_insightLoading)
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFCCCCCC),
                                  ),
                                ),
                              )
                            else ...[
                              ..._buildInsightParagraphWidgets(theme),
                              if (_refreshError != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _refreshError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.orangeAccent
                                        .withValues(alpha: 0.9),
                                    fontSize: 13,
                                    height: 1.4,
                                    fontFamily: theme.bodyLarge.fontFamily,
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 24),
                            IconButton(
                              tooltip: 'Listen to today’s insight',
                              onPressed: _insightLoading ||
                                      _audioBusy ||
                                      _refreshBusy
                                  ? null
                                  : _playInsightAudio,
                              iconSize: 40,
                              color: Colors.white.withValues(alpha: 0.92),
                              icon: _audioBusy
                                  ? const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white70,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.volume_up_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
