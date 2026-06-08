import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

/// Drives the FoCoCo iOS Live Activity used during a Gemini Live voice
/// coaching session. Surfaces in the lock screen + Dynamic Island.
///
/// Maps to `ios/FoCoCoWidgets/FoCoCoWidgetsLiveActivity.swift`
/// (`LiveActivitiesAppAttributes`). The keys written here are read in Swift
/// via `context.attributes.prefixedKey("<key>")` from the App Group
/// `UserDefaults`, so they must match exactly.
class VoiceLiveActivityService {
  VoiceLiveActivityService._();
  static final instance = VoiceLiveActivityService._();

  /// Must match the App Group capability set on both `Runner` and
  /// `FoCoCoWidgetsExtension` targets.
  static const _appGroupId = 'group.com.fococo.fococo';

  /// Stable identifier passed to the plugin. iOS only allows one
  /// `LiveActivitiesAppAttributes` activity per attributes.id, so reusing
  /// this lets `createOrUpdateActivity` resume an existing activity if the
  /// app was backgrounded mid-session.
  static const _activityName = 'fococo.voiceCoaching';

  final _plugin = LiveActivities();
  bool _initialized = false;
  String? _activityId;
  Timer? _ticker;
  DateTime? _startedAt;
  Map<String, dynamic> _state = const <String, dynamic>{};

  bool get _supported => !kIsWeb && Platform.isIOS;

  Future<void> _ensureInit() async {
    if (_initialized || !_supported) return;
    try {
      await _plugin.init(appGroupId: _appGroupId);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LiveActivity.init failed: $e');
    }
  }

  /// Start a new coaching-session activity. Quietly no-ops on Android, web,
  /// pre-iOS-16.1 devices, or when the user disabled Live Activities.
  Future<void> start({String topic = 'Mental coaching'}) async {
    if (!_supported) return;
    try {
      await _ensureInit();
      if (!_initialized) return;
      if (!await _plugin.areActivitiesSupported()) return;
      if (!await _plugin.areActivitiesEnabled()) return;

      await stop();
      _startedAt = DateTime.now();
      _state = <String, dynamic>{
        'status': 'connecting',
        'topic': topic,
        'transcript': '',
        'elapsed': '00:00',
      };
      _activityId = await _plugin.createActivity(_activityName, _state);
      _startTicker();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LiveActivity.start failed: $e');
    }
  }

  /// Update the activity status and/or transcript line.
  Future<void> update({String? status, String? transcript}) async {
    if (!_supported || _activityId == null) return;
    try {
      _state = <String, dynamic>{
        ..._state,
        if (status != null) 'status': status,
        if (transcript != null) 'transcript': transcript,
      };
      await _plugin.updateActivity(_activityId!, _state);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LiveActivity.update failed: $e');
    }
  }

  /// End and dismiss the activity.
  Future<void> stop() async {
    if (!_supported) return;
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    final id = _activityId;
    _activityId = null;
    if (id == null) return;
    try {
      await _plugin.endActivity(id);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ LiveActivity.stop failed: $e');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final id = _activityId;
      final startedAt = _startedAt;
      if (id == null || startedAt == null) return;
      final secs = DateTime.now().difference(startedAt).inSeconds;
      final mm = (secs ~/ 60).toString().padLeft(2, '0');
      final ss = (secs % 60).toString().padLeft(2, '0');
      _state = <String, dynamic>{..._state, 'elapsed': '$mm:$ss'};
      _plugin.updateActivity(id, _state).catchError((_) {});
    });
  }
}
