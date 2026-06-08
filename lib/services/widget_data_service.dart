import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Pushes data into the iOS App Group so the FoCoCoWidgets extension can
/// render it on the home screen. Keys must match those declared in
/// [ios/FoCoCoWidgets/WidgetData.swift] (`FoWidgetKey`).
class WidgetDataService {
  WidgetDataService._();

  static const _appGroupId = 'group.com.fococo.fococo';

  static const _kCaddyPlayKind = 'CaddyPlayWidget';
  static const _kMindSessionKind = 'MindSessionWidget';
  static const _kGolfChatKind = 'GolfChatWidget';

  static const _kHasActiveRound = 'fococo.caddyplay.hasActiveRound';
  static const _kCourseName = 'fococo.caddyplay.courseName';
  static const _kCurrentHole = 'fococo.caddyplay.currentHole';
  static const _kHolesTotal = 'fococo.caddyplay.holesTotal';
  static const _kScoreToPar = 'fococo.caddyplay.scoreToPar';

  static bool get _supported => !kIsWeb && Platform.isIOS;

  static Future<void> initialize() async {
    if (!_supported) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      if (kDebugMode) print('⚠️ HomeWidget init failed: $e');
    }
  }

  static Future<void> pushActiveRound({
    required String courseName,
    required int currentHole,
    required int holesTotal,
    int scoreToPar = 0,
  }) async {
    if (!_supported) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<bool>(_kHasActiveRound, true),
        HomeWidget.saveWidgetData<String>(_kCourseName, courseName),
        HomeWidget.saveWidgetData<int>(_kCurrentHole, currentHole),
        HomeWidget.saveWidgetData<int>(_kHolesTotal, holesTotal),
        HomeWidget.saveWidgetData<int>(_kScoreToPar, scoreToPar),
      ]);
      await _reloadCaddyPlay();
    } catch (e) {
      if (kDebugMode) print('⚠️ Widget pushActiveRound failed: $e');
    }
  }

  static Future<void> clearActiveRound() async {
    if (!_supported) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<bool>(_kHasActiveRound, false),
        HomeWidget.saveWidgetData<String>(_kCourseName, ''),
        HomeWidget.saveWidgetData<int>(_kCurrentHole, 0),
      ]);
      await _reloadCaddyPlay();
    } catch (e) {
      if (kDebugMode) print('⚠️ Widget clearActiveRound failed: $e');
    }
  }

  static Future<void> reloadAll() async {
    if (!_supported) return;
    try {
      await HomeWidget.updateWidget(iOSName: _kCaddyPlayKind);
      await HomeWidget.updateWidget(iOSName: _kMindSessionKind);
      await HomeWidget.updateWidget(iOSName: _kGolfChatKind);
    } catch (e) {
      if (kDebugMode) print('⚠️ Widget reloadAll failed: $e');
    }
  }

  static Future<void> _reloadCaddyPlay() async {
    try {
      await HomeWidget.updateWidget(iOSName: _kCaddyPlayKind);
    } catch (_) {}
  }
}
