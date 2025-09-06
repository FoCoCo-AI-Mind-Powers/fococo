import 'package:fo_co_co/backend/schema/round_logs_record.dart';
import 'package:fo_co_co/backend/schema/shot_logs_record.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'foco_map_widget.dart' show FoCoMapWidget;
import 'package:flutter/material.dart';

class FoCoMapModel extends FlutterFlowModel<FoCoMapWidget> with ChangeNotifier {
  /// State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;

  /// Map Layer Selection
  String selectedLayer = 'MindMap'; // MindMap, ShotMap, SyncMap

  /// Live Mode Toggle
  bool isLiveMode = false;

  /// Filter states
  Map<String, bool> clubFilters = {
    'driver': true,
    'iron': true,
    'wedge': true,
    'putter': true,
  };

  Map<String, bool> cueFilters = {};
  Map<String, bool> weatherFilters = {};

  /// Data streams
  List<RoundLogsRecord> roundLogs = [];
  List<ShotLogsRecord> shotLogs = [];

  /// Selected round for replay
  String? selectedRoundId;

  /// Map zoom level
  double currentZoom = 10.0;

  /// Selected marker for detail view
  String? selectedMarkerId;
  bool showMarkerDetail = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    pageViewController?.dispose();
    super.dispose();
  }

  /// Layer selection methods
  void selectLayer(String layer) {
    selectedLayer = layer;
    notifyListeners();
  }

  /// Toggle live mode
  void toggleLiveMode() {
    isLiveMode = !isLiveMode;
    notifyListeners();
  }

  void setLiveMode(bool enabled) {
    isLiveMode = enabled;
    notifyListeners();
  }

  /// Filter methods
  void toggleClubFilter(String club) {
    clubFilters[club] = !(clubFilters[club] ?? false);
    notifyListeners();
  }

  void toggleCueFilter(String cue) {
    cueFilters[cue] = !(cueFilters[cue] ?? false);
    notifyListeners();
  }

  /// Marker selection
  void selectMarker(String markerId) {
    selectedMarkerId = markerId;
    showMarkerDetail = true;
    notifyListeners();
  }

  void clearMarkerSelection() {
    selectedMarkerId = null;
    showMarkerDetail = false;
    notifyListeners();
  }

  /// Get mindset color for round
  String getMindsetColor(RoundLogsRecord round) {
    final avgMindset =
        (round.mindsetFocus + round.mindsetConfidence + round.mindsetControl) /
            3;
    if (avgMindset >= 8) return 'green';
    if (avgMindset >= 5) return 'yellow';
    return 'red';
  }

  /// Get filtered round logs based on current filters
  List<RoundLogsRecord> getFilteredRoundLogs() {
    return roundLogs.where((round) {
      // Apply filters here based on selectedLayer and active filters
      return true; // Placeholder
    }).toList();
  }

  /// Get filtered shot logs based on current filters
  List<ShotLogsRecord> getFilteredShotLogs() {
    return shotLogs.where((shot) {
      // Apply club filters
      if (clubFilters.isNotEmpty) {
        final clubType = _getClubType(shot.clubUsed);
        if (clubFilters[clubType] == false) return false;
      }

      // Apply other filters
      return true;
    }).toList();
  }

  String _getClubType(String club) {
    if (club.toLowerCase().contains('driver')) return 'driver';
    if (club.toLowerCase().contains('iron') ||
        club.toLowerCase().contains('hybrid')) return 'iron';
    if (club.toLowerCase().contains('wedge') ||
        club.toLowerCase().contains('sand')) return 'wedge';
    if (club.toLowerCase().contains('putter')) return 'putter';
    return 'iron'; // default
  }
}
