import 'package:fo_co_co/backend/schema/round_logs_record.dart';
import 'package:fo_co_co/backend/schema/shot_logs_record.dart';
import 'package:fo_co_co/backend/schema/golf_rounds_record.dart';
import 'package:fo_co_co/backend/schema/scorecard_record.dart';

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

  /// Filter states - Enhanced for comprehensive testing
  Map<String, bool> clubFilters = {
    'driver': true,
    'wood': true,
    'iron': true,
    'wedge': true,
    'putter': true,
  };

  Map<String, bool> cueFilters = {
    'Visualization': true,
    'Breathing': true,
    'Self-Talk': true,
    'Letting Go': true,
    'Focus Point': true,
    'Routine': true,
  };

  Map<String, bool> weatherFilters = {
    'Calm': true,
    'Light Breeze': true,
    'Windy': true,
    'Strong Wind': true,
    'Light Rain': true,
    'Heavy Rain': true,
  };

  Map<String, bool> courseFilters = {
    'Coastal': true,
    'Links': true,
    'Parkland': true,
    'Resort': true,
    'Mountain': true,
  };

  Map<String, bool> mindsetFilters = {
    'excellent': true, // 4.5-5.0 average
    'good': true, // 3.5-4.4 average
    'average': true, // 2.5-3.4 average
    'poor': true, // 1.0-2.4 average
  };

  /// Performance filters
  Map<String, bool> performanceFilters = {
    'excellent': true, // 9-10 rating
    'good': true, // 7-8 rating
    'average': true, // 5-6 rating
    'poor': true, // 1-4 rating
  };

  /// Data streams - Enhanced for performance
  List<RoundLogsRecord> roundLogs = [];
  List<ShotLogsRecord> shotLogs = [];
  List<GolfRoundsRecord> golfRounds = [];
  List<ScorecardRecord> scorecards = [];
  List<RoundLogsRecord> _filteredRoundLogs = [];
  List<ShotLogsRecord> _filteredShotLogs = [];
  List<GolfRoundsRecord> _filteredGolfRounds = [];
  List<ScorecardRecord> _filteredScorecards = [];

  /// Date range filtering
  DateTime? filterStartDate;
  DateTime? filterEndDate;

  /// Data type visibility toggles
  bool showRoundLogs = true;
  bool showShotLogs = true;
  bool showGolfRounds = true;
  bool showScorecards = true;

  /// Selected round for replay
  String? selectedRoundId;

  /// Map zoom level and bounds
  double currentZoom = 10.0;
  double minZoom = 8.0;
  double maxZoom = 18.0;

  /// Selected marker for detail view
  String? selectedMarkerId;
  bool showMarkerDetail = false;

  /// Performance metrics cache
  Map<String, dynamic> _performanceCache = {};
  DateTime? _lastCacheUpdate;

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

  /// Enhanced Filter methods with performance optimization
  void toggleClubFilter(String club) {
    clubFilters[club] = !(clubFilters[club] ?? false);
    _invalidateCache();
    notifyListeners();
  }

  void toggleCueFilter(String cue) {
    cueFilters[cue] = !(cueFilters[cue] ?? false);
    _invalidateCache();
    notifyListeners();
  }

  void toggleWeatherFilter(String weather) {
    weatherFilters[weather] = !(weatherFilters[weather] ?? false);
    _invalidateCache();
    notifyListeners();
  }

  void toggleCourseFilter(String courseType) {
    courseFilters[courseType] = !(courseFilters[courseType] ?? false);
    _invalidateCache();
    notifyListeners();
  }

  void toggleMindsetFilter(String mindsetLevel) {
    mindsetFilters[mindsetLevel] = !(mindsetFilters[mindsetLevel] ?? false);
    _invalidateCache();
    notifyListeners();
  }

  void togglePerformanceFilter(String performanceLevel) {
    performanceFilters[performanceLevel] =
        !(performanceFilters[performanceLevel] ?? false);
    _invalidateCache();
    notifyListeners();
  }

  /// Date range filtering
  void setDateRange(DateTime? start, DateTime? end) {
    filterStartDate = start;
    filterEndDate = end;
    _invalidateCache();
    notifyListeners();
  }

  void clearDateRange() {
    filterStartDate = null;
    filterEndDate = null;
    _invalidateCache();
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    clubFilters.updateAll((key, value) => true);
    cueFilters.updateAll((key, value) => true);
    weatherFilters.updateAll((key, value) => true);
    courseFilters.updateAll((key, value) => true);
    mindsetFilters.updateAll((key, value) => true);
    performanceFilters.updateAll((key, value) => true);
    clearDateRange();
    _invalidateCache();
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

  /// Enhanced mindset color calculation
  String getMindsetColor(RoundLogsRecord round) {
    final avgMindset = _calculateAverageMindset(round);
    if (avgMindset >= 4.5) return 'green';
    if (avgMindset >= 3.5) return 'yellow';
    if (avgMindset >= 2.5) return 'orange';
    return 'red';
  }

  double _calculateAverageMindset(RoundLogsRecord round) {
    return (round.mindsetFocus +
            round.mindsetConfidence +
            round.mindsetControl) /
        3.0;
  }

  /// Get mindset category for filtering
  String _getMindsetCategory(RoundLogsRecord round) {
    final avgMindset = _calculateAverageMindset(round);
    if (avgMindset >= 4.5) return 'excellent';
    if (avgMindset >= 3.5) return 'good';
    if (avgMindset >= 2.5) return 'average';
    return 'poor';
  }

  /// Get performance category for shots
  String _getPerformanceCategory(ShotLogsRecord shot) {
    if (shot.performanceRating >= 9) return 'excellent';
    if (shot.performanceRating >= 7) return 'good';
    if (shot.performanceRating >= 5) return 'average';
    return 'poor';
  }

  /// Enhanced filtered round logs with comprehensive filtering
  List<RoundLogsRecord> getFilteredRoundLogs() {
    if (_shouldUseCache('rounds')) {
      return _filteredRoundLogs;
    }

    _filteredRoundLogs = roundLogs.where((round) {
      // Date range filter
      if (filterStartDate != null &&
          round.date != null &&
          round.date!.isBefore(filterStartDate!)) {
        return false;
      }
      if (filterEndDate != null &&
          round.date != null &&
          round.date!.isAfter(filterEndDate!)) {
        return false;
      }

      // Course type filter
      if (courseFilters.isNotEmpty &&
          courseFilters[round.courseType] == false) {
        return false;
      }

      // Mindset filter
      final mindsetCategory = _getMindsetCategory(round);
      if (mindsetFilters.isNotEmpty &&
          mindsetFilters[mindsetCategory] == false) {
        return false;
      }

      // Cue filter (check if round's best cue matches any enabled cue)
      if (cueFilters.isNotEmpty) {
        final roundCue = _extractCueName(round.bestCue);
        if (cueFilters[roundCue] == false) {
          return false;
        }
      }

      return true;
    }).toList();

    _updateCache('rounds');
    return _filteredRoundLogs;
  }

  /// Enhanced filtered shot logs with comprehensive filtering
  List<ShotLogsRecord> getFilteredShotLogs() {
    if (_shouldUseCache('shots')) {
      return _filteredShotLogs;
    }

    _filteredShotLogs = shotLogs.where((shot) {
      // Date range filter (using timestamp)
      if (filterStartDate != null &&
          shot.timestamp != null &&
          shot.timestamp!.isBefore(filterStartDate!)) {
        return false;
      }
      if (filterEndDate != null &&
          shot.timestamp != null &&
          shot.timestamp!.isAfter(filterEndDate!)) {
        return false;
      }

      // Club filter
      final clubType = _getClubType(shot.clubUsed);
      if (clubFilters.isNotEmpty && clubFilters[clubType] == false) {
        return false;
      }

      // Performance filter
      final performanceCategory = _getPerformanceCategory(shot);
      if (performanceFilters.isNotEmpty &&
          performanceFilters[performanceCategory] == false) {
        return false;
      }

      // Cue filter
      if (cueFilters.isNotEmpty) {
        final shotCue = _extractCueName(shot.cueUsed);
        if (cueFilters[shotCue] == false) {
          return false;
        }
      }

      return true;
    }).toList();

    _updateCache('shots');
    return _filteredShotLogs;
  }

  /// Enhanced club type detection
  String _getClubType(String club) {
    final clubLower = club.toLowerCase();
    if (clubLower.contains('driver')) return 'driver';
    if (clubLower.contains('wood') || clubLower.contains('hybrid'))
      return 'wood';
    if (clubLower.contains('iron')) return 'iron';
    if (clubLower.contains('wedge') || clubLower.contains('sand'))
      return 'wedge';
    if (clubLower.contains('putter')) return 'putter';
    return 'iron'; // default
  }

  /// Extract cue name from emoji + name format
  String _extractCueName(String cueWithEmoji) {
    if (cueWithEmoji.isEmpty) return '';

    // Remove emoji and extract name
    final parts = cueWithEmoji.split(' ');
    if (parts.length > 1) {
      return parts.skip(1).join(' '); // Skip emoji, join rest
    }
    return cueWithEmoji;
  }

  /// Performance metrics and analytics
  Map<String, dynamic> getPerformanceMetrics() {
    if (_shouldUseCache('metrics')) {
      return _performanceCache['metrics'] ?? {};
    }

    final filteredRounds = getFilteredRoundLogs();
    final filteredShots = getFilteredShotLogs();

    final metrics = {
      'totalRounds': filteredRounds.length,
      'totalShots': filteredShots.length,
      'avgMindsetScore': _calculateAverageMetric(
          filteredRounds, (round) => _calculateAverageMindset(round)),
      'avgPerformanceRating': _calculateAverageMetric(
          filteredShots, (shot) => shot.performanceRating.toDouble()),
      'mostUsedCue': _getMostUsedCue(filteredRounds, filteredShots),
      'bestCourseType': _getBestCourseType(filteredRounds),
      'clubPerformance': _getClubPerformanceBreakdown(filteredShots),
      'courseTypePerformance': _getCourseTypePerformance(filteredRounds),
      'recoveryRate': _calculateRecoveryRate(filteredRounds),
    };

    _performanceCache['metrics'] = metrics;
    _updateCache('metrics');
    return metrics;
  }

  /// Cache management for performance optimization
  bool _shouldUseCache(String type) {
    if (_lastCacheUpdate == null) return false;

    final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
    return cacheAge.inSeconds < 30; // Cache valid for 30 seconds
  }

  void _updateCache(String type) {
    _lastCacheUpdate = DateTime.now();
  }

  void _invalidateCache() {
    _lastCacheUpdate = null;
    _performanceCache.clear();
  }

  /// Helper methods for analytics
  double _calculateAverageMetric<T>(
      List<T> items, double Function(T) getValue) {
    if (items.isEmpty) return 0.0;
    final sum = items.fold(0.0, (sum, item) => sum + getValue(item));
    return sum / items.length;
  }

  String _getMostUsedCue(
      List<RoundLogsRecord> rounds, List<ShotLogsRecord> shots) {
    final cueCount = <String, int>{};

    for (final round in rounds) {
      final cue = _extractCueName(round.bestCue);
      cueCount[cue] = (cueCount[cue] ?? 0) + 1;
    }

    for (final shot in shots) {
      final cue = _extractCueName(shot.cueUsed);
      cueCount[cue] = (cueCount[cue] ?? 0) + 1;
    }

    if (cueCount.isEmpty) return '';

    return cueCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getBestCourseType(List<RoundLogsRecord> rounds) {
    final coursePerformance = <String, List<double>>{};

    for (final round in rounds) {
      final courseType = round.courseType;
      final avgMindset = _calculateAverageMindset(round);

      coursePerformance.putIfAbsent(courseType, () => []).add(avgMindset);
    }

    String bestCourseType = '';
    double bestAvg = 0.0;

    coursePerformance.forEach((courseType, scores) {
      if (scores.isEmpty) return;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestCourseType = courseType;
      }
    });

    return bestCourseType;
  }

  Map<String, double> _getClubPerformanceBreakdown(List<ShotLogsRecord> shots) {
    final clubPerformance = <String, List<double>>{};

    for (final shot in shots) {
      final clubType = _getClubType(shot.clubUsed);
      clubPerformance
          .putIfAbsent(clubType, () => [])
          .add(shot.performanceRating.toDouble());
    }

    return clubPerformance.map((club, ratings) {
      if (ratings.isEmpty) return MapEntry(club, 0.0);
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      return MapEntry(club, avg);
    });
  }

  Map<String, double> _getCourseTypePerformance(List<RoundLogsRecord> rounds) {
    final coursePerformance = <String, List<double>>{};

    for (final round in rounds) {
      final courseType = round.courseType;
      final avgMindset = _calculateAverageMindset(round);

      coursePerformance.putIfAbsent(courseType, () => []).add(avgMindset);
    }

    return coursePerformance.map((course, scores) {
      if (scores.isEmpty) return MapEntry(course, 0.0);
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return MapEntry(course, avg);
    });
  }

  double _calculateRecoveryRate(List<RoundLogsRecord> rounds) {
    if (rounds.isEmpty) return 0.0;

    final totalRecoveryHoles =
        rounds.fold(0, (sum, round) => sum + round.recoveryHoles.length);

    final totalHoles = rounds.length * 18; // Assuming 18 holes per round
    return (totalRecoveryHoles / totalHoles) * 100;
  }
}
