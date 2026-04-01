import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/shot_logs_record.dart';

/// Enhanced Live Service for FoCoMap Real-Time Experience
/// Manages real-time data sync, live updates, and tier-based access
class FoCoMapLiveService {
  static final FoCoMapLiveService _instance = FoCoMapLiveService._internal();
  factory FoCoMapLiveService() => _instance;
  FoCoMapLiveService._internal();

  // Stream controllers for real-time data
  final _roundLogsController =
      StreamController<List<RoundLogsRecord>>.broadcast();
  final _shotLogsController =
      StreamController<List<ShotLogsRecord>>.broadcast();
  final _liveUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _filterUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Firestore listeners
  StreamSubscription? _roundLogsSubscription;
  StreamSubscription? _shotLogsSubscription;
  StreamSubscription? _aiInsightsSubscription;

  // State management
  bool _isLiveMode = false;
  String? _activeRoundId;
  UserTier _userTier = UserTier.base;

  // Data caching
  List<RoundLogsRecord> _cachedRoundLogs = [];
  List<ShotLogsRecord> _cachedShotLogs = [];
  Map<String, dynamic> _activeFilters = {};

  // Streams
  Stream<List<RoundLogsRecord>> get roundLogsStream =>
      _roundLogsController.stream;
  Stream<List<ShotLogsRecord>> get shotLogsStream => _shotLogsController.stream;
  Stream<Map<String, dynamic>> get liveUpdateStream =>
      _liveUpdateController.stream;
  Stream<Map<String, dynamic>> get filterUpdateStream =>
      _filterUpdateController.stream;

  // Getters
  bool get isLiveMode => _isLiveMode;
  String? get activeRoundId => _activeRoundId;
  UserTier get userTier => _userTier;
  List<RoundLogsRecord> get cachedRoundLogs => _cachedRoundLogs;
  List<ShotLogsRecord> get cachedShotLogs => _cachedShotLogs;

  /// Initialize the live service with user tier detection
  Future<void> initialize() async {
    try {
      // Detect user tier (implement based on your subscription system)
      _userTier = await _detectUserTier();

      debugPrint('FoCoMap Live Service initialized - Tier: ${_userTier.name}');
    } catch (e) {
      debugPrint('Error initializing FoCoMap Live Service: $e');
    }
  }

  /// Start live mode with tier-based access control
  Future<void> startLiveMode({String? roundId}) async {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Check tier permissions
    if (!canAccessLiveMode()) {
      throw Exception('Live mode requires Plus or Prime subscription');
    }

    try {
      _isLiveMode = true;
      _activeRoundId = roundId;

      // Start real-time listeners based on tier
      await _startRoundLogsListener();

      if (_userTier == UserTier.prime) {
        await _startShotLogsListener();
        await _startAIInsightsListener();
      }

      _liveUpdateController.add({
        'type': 'live_mode_started',
        'tier': _userTier.name,
        'roundId': roundId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint(
          'Live mode started - Round: $roundId, Tier: ${_userTier.name}');
    } catch (e) {
      debugPrint('Error starting live mode: $e');
      _isLiveMode = false;
      rethrow;
    }
  }

  /// Stop live mode and clean up listeners
  Future<void> stopLiveMode() async {
    try {
      _isLiveMode = false;
      _activeRoundId = null;

      // Cancel all listeners
      await _roundLogsSubscription?.cancel();
      await _shotLogsSubscription?.cancel();
      await _aiInsightsSubscription?.cancel();

      _liveUpdateController.add({
        'type': 'live_mode_stopped',
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('Live mode stopped');
    } catch (e) {
      debugPrint('Error stopping live mode: $e');
    }
  }

  /// Refresh data manually (for Base tier users)
  Future<void> refreshData() async {
    if (currentUser == null) return;

    try {
      // Fetch round logs
      final roundLogsQuery = FirebaseFirestore.instance
          .collection('round_logs')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('date', descending: true)
          .limit(50);

      final roundLogsSnapshot = await roundLogsQuery.get();
      _cachedRoundLogs = roundLogsSnapshot.docs
          .map((doc) => RoundLogsRecord.fromSnapshot(doc))
          .toList();

      _roundLogsController.add(_cachedRoundLogs);

      // Fetch shot logs (Prime tier only)
      if (_userTier == UserTier.prime) {
        final shotLogsQuery = FirebaseFirestore.instance
            .collection('shot_logs')
            .where('userId', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .limit(100);

        final shotLogsSnapshot = await shotLogsQuery.get();
        _cachedShotLogs = shotLogsSnapshot.docs
            .map((doc) => ShotLogsRecord.fromSnapshot(doc))
            .toList();

        _shotLogsController.add(_cachedShotLogs);
      }

      _liveUpdateController.add({
        'type': 'data_refreshed',
        'roundLogs': _cachedRoundLogs.length,
        'shotLogs': _cachedShotLogs.length,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint(
          'Data refreshed - Rounds: ${_cachedRoundLogs.length}, Shots: ${_cachedShotLogs.length}');
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      _liveUpdateController.add({
        'type': 'error',
        'message': 'Failed to refresh data: $e',
      });
    }
  }

  /// Apply filters to the data
  void applyFilters(Map<String, dynamic> filters) {
    _activeFilters = Map.from(filters);

    // Filter cached data
    final filteredRoundLogs = _filterRoundLogs(_cachedRoundLogs);
    final filteredShotLogs = _filterShotLogs(_cachedShotLogs);

    // Emit filtered data
    _roundLogsController.add(filteredRoundLogs);
    _shotLogsController.add(filteredShotLogs);

    _filterUpdateController.add({
      'type': 'filters_applied',
      'filters': _activeFilters,
      'results': {
        'roundLogs': filteredRoundLogs.length,
        'shotLogs': filteredShotLogs.length,
      },
    });

    debugPrint('Filters applied: $_activeFilters');
  }

  /// Clear all filters
  void clearFilters() {
    _activeFilters.clear();
    _roundLogsController.add(_cachedRoundLogs);
    _shotLogsController.add(_cachedShotLogs);

    _filterUpdateController.add({
      'type': 'filters_cleared',
    });
  }

  /// Get filtered data for specific layer
  List<RoundLogsRecord> getFilteredRoundLogs() {
    return _filterRoundLogs(_cachedRoundLogs);
  }

  List<ShotLogsRecord> getFilteredShotLogs() {
    return _filterShotLogs(_cachedShotLogs);
  }

  /// Start real-time round logs listener
  Future<void> _startRoundLogsListener() async {
    final query = FirebaseFirestore.instance
        .collection('round_logs')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('date', descending: true)
        .limit(50);

    _roundLogsSubscription = query.snapshots().listen(
      (snapshot) {
        try {
          _cachedRoundLogs = snapshot.docs
              .map((doc) => RoundLogsRecord.fromSnapshot(doc))
              .toList();

          final filteredData = _filterRoundLogs(_cachedRoundLogs);
          _roundLogsController.add(filteredData);

          // Check for new entries
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final newRecord = RoundLogsRecord.fromSnapshot(change.doc);
              _liveUpdateController.add({
                'type': 'round_log_added',
                'data': newRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          }
        } catch (e) {
          debugPrint('Error in round logs listener: $e');
        }
      },
      onError: (error) {
        debugPrint('Round logs stream error: $error');
        _liveUpdateController.add({
          'type': 'error',
          'message': 'Round logs sync error: $error',
        });
      },
    );
  }

  /// Start real-time shot logs listener (Prime tier only)
  Future<void> _startShotLogsListener() async {
    if (_userTier != UserTier.prime) return;

    final query = FirebaseFirestore.instance
        .collection('shot_logs')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .limit(100);

    _shotLogsSubscription = query.snapshots().listen(
      (snapshot) {
        try {
          _cachedShotLogs = snapshot.docs
              .map((doc) => ShotLogsRecord.fromSnapshot(doc))
              .toList();

          final filteredData = _filterShotLogs(_cachedShotLogs);
          _shotLogsController.add(filteredData);

          // Check for new entries
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final newRecord = ShotLogsRecord.fromSnapshot(change.doc);
              _liveUpdateController.add({
                'type': 'shot_log_added',
                'data': newRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          }
        } catch (e) {
          debugPrint('Error in shot logs listener: $e');
        }
      },
      onError: (error) {
        debugPrint('Shot logs stream error: $error');
        _liveUpdateController.add({
          'type': 'error',
          'message': 'Shot logs sync error: $error',
        });
      },
    );
  }

  /// Start AI insights listener (Prime tier only)
  Future<void> _startAIInsightsListener() async {
    if (_userTier != UserTier.prime) return;

    final query = FirebaseFirestore.instance
        .collection('ai_insights')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .limit(20);

    _aiInsightsSubscription = query.snapshots().listen(
      (snapshot) {
        try {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              if (change.doc.data()?['insightType'] == 'fococo_daily') {
                continue;
              }
              _liveUpdateController.add({
                'type': 'ai_insight_added',
                'data': change.doc.data(),
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          }
        } catch (e) {
          debugPrint('Error in AI insights listener: $e');
        }
      },
      onError: (error) {
        debugPrint('AI insights stream error: $error');
      },
    );
  }

  /// Filter round logs based on active filters
  List<RoundLogsRecord> _filterRoundLogs(List<RoundLogsRecord> logs) {
    if (_activeFilters.isEmpty) return logs;

    return logs.where((log) {
      // Date range filter
      if (_activeFilters.containsKey('dateRange')) {
        final dateRange = _activeFilters['dateRange'] as Map<String, DateTime>;
        if (log.date != null) {
          if (log.date!.isBefore(dateRange['start']!) ||
              log.date!.isAfter(dateRange['end']!)) {
            return false;
          }
        }
      }

      // Course type filter
      if (_activeFilters.containsKey('courseType')) {
        final courseTypes = _activeFilters['courseType'] as List<String>;
        if (!courseTypes.contains(log.courseType)) {
          return false;
        }
      }

      // Mindset filter
      if (_activeFilters.containsKey('mindsetColor')) {
        final colors = _activeFilters['mindsetColor'] as List<String>;
        if (!colors.contains(log.mindsetColor)) {
          return false;
        }
      }

      // Cue filter
      if (_activeFilters.containsKey('cueUsed')) {
        final cues = _activeFilters['cueUsed'] as List<String>;
        if (!cues.contains(log.bestCue)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Filter shot logs based on active filters
  List<ShotLogsRecord> _filterShotLogs(List<ShotLogsRecord> logs) {
    if (_activeFilters.isEmpty) return logs;

    return logs.where((log) {
      // Club filter
      if (_activeFilters.containsKey('clubUsed')) {
        final clubs = _activeFilters['clubUsed'] as List<String>;
        if (!clubs.contains(log.clubUsed)) {
          return false;
        }
      }

      // Shot outcome filter
      if (_activeFilters.containsKey('shotOutcome')) {
        final outcomes = _activeFilters['shotOutcome'] as List<String>;
        if (!outcomes.contains(log.shotOutcome)) {
          return false;
        }
      }

      // Wind condition filter
      if (_activeFilters.containsKey('windCondition')) {
        final conditions = _activeFilters['windCondition'] as List<String>;
        if (!conditions.contains(log.windCondition)) {
          return false;
        }
      }

      // Performance rating filter
      if (_activeFilters.containsKey('performanceRating')) {
        final minRating = _activeFilters['performanceRating'] as int;
        if (log.performanceRating < minRating) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Detect user tier based on subscription
  Future<UserTier> _detectUserTier() async {
    if (currentUser == null) return UserTier.junior;

    try {
      // Check user subscription in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUser!.uid)
          .get();

      if (!userDoc.exists) return UserTier.junior;

      final userData = userDoc.data()!;
      final subscription = userData['subscription'] as String?;

      switch (subscription?.toLowerCase()) {
        case 'prime':
          return UserTier.prime;
        case 'plus':
          return UserTier.plus;
        case 'base':
          return UserTier.base;
        default:
          return UserTier.junior;
      }
    } catch (e) {
      debugPrint('Error detecting user tier: $e');
      return UserTier.junior;
    }
  }

  /// Check if user can access live mode
  bool canAccessLiveMode() {
    return _userTier == UserTier.plus || _userTier == UserTier.prime;
  }

  /// Check if user can access technical data
  bool canAccessTechnicalData() {
    return _userTier == UserTier.prime;
  }

  /// Check if user can access sync map
  bool canAccessSyncMap() {
    return _userTier == UserTier.prime;
  }

  /// Get available layers based on tier
  List<MapLayer> getAvailableLayers() {
    switch (_userTier) {
      case UserTier.junior:
        return [];
      case UserTier.base:
        return [MapLayer.mindMap];
      case UserTier.plus:
        return [MapLayer.mindMap];
      case UserTier.prime:
        return [MapLayer.mindMap, MapLayer.shotMap, MapLayer.syncMap];
    }
  }

  /// Dispose resources
  void dispose() {
    _roundLogsController.close();
    _shotLogsController.close();
    _liveUpdateController.close();
    _filterUpdateController.close();

    _roundLogsSubscription?.cancel();
    _shotLogsSubscription?.cancel();
    _aiInsightsSubscription?.cancel();
  }
}

/// User tier enumeration
enum UserTier {
  junior,
  base,
  plus,
  prime,
}

/// Map layer enumeration
enum MapLayer {
  mindMap,
  shotMap,
  syncMap,
}
