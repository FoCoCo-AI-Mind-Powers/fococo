import 'dart:async';
import 'package:flutter/material.dart';
import '/backend/schema/index.dart';
import '/auth/firebase_auth/auth_util.dart';

class FoCoMapLiveService {
  static final FoCoMapLiveService _instance = FoCoMapLiveService._internal();
  factory FoCoMapLiveService() => _instance;
  FoCoMapLiveService._internal();

  // Stream controllers for real-time data
  final StreamController<List<RoundLogsRecord>> _roundLogsController = 
      StreamController<List<RoundLogsRecord>>.broadcast();
  final StreamController<List<ShotLogsRecord>> _shotLogsController = 
      StreamController<List<ShotLogsRecord>>.broadcast();
  final StreamController<Map<String, dynamic>> _liveUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Firestore listeners
  StreamSubscription<QuerySnapshot>? _roundLogsSubscription;
  StreamSubscription<QuerySnapshot>? _shotLogsSubscription;

  // Current data cache
  List<RoundLogsRecord> _currentRoundLogs = [];
  List<ShotLogsRecord> _currentShotLogs = [];

  // Getters for streams
  Stream<List<RoundLogsRecord>> get roundLogsStream => _roundLogsController.stream;
  Stream<List<ShotLogsRecord>> get shotLogsStream => _shotLogsController.stream;
  Stream<Map<String, dynamic>> get liveUpdateStream => _liveUpdateController.stream;

  // Current data getters
  List<RoundLogsRecord> get currentRoundLogs => List.from(_currentRoundLogs);
  List<ShotLogsRecord> get currentShotLogs => List.from(_currentShotLogs);

  bool _isActive = false;
  bool get isActive => _isActive;

  /// Start live monitoring for Plus/Prime tier users
  Future<void> startLiveMode({
    int roundLogsLimit = 50,
    int shotLogsLimit = 500,
    Duration? timeWindow,
  }) async {
    if (_isActive || currentUser == null) return;

    _isActive = true;

    try {
      // Set up round logs listener
      Query roundLogsQuery = FirebaseFirestore.instance
          .collection('round_logs')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('createdTime', descending: true)
          .limit(roundLogsLimit);

      // Add time window filter if specified
      if (timeWindow != null) {
        final cutoffTime = DateTime.now().subtract(timeWindow);
        roundLogsQuery = roundLogsQuery.where('createdTime', isGreaterThan: cutoffTime);
      }

      _roundLogsSubscription = roundLogsQuery.snapshots().listen(
        _onRoundLogsUpdate,
        onError: _onError,
      );

      // Set up shot logs listener  
      Query shotLogsQuery = FirebaseFirestore.instance
          .collection('shot_logs')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .limit(shotLogsLimit);

      if (timeWindow != null) {
        final cutoffTime = DateTime.now().subtract(timeWindow);
        shotLogsQuery = shotLogsQuery.where('timestamp', isGreaterThan: cutoffTime);
      }

      _shotLogsSubscription = shotLogsQuery.snapshots().listen(
        _onShotLogsUpdate,
        onError: _onError,
      );

      debugPrint('FoCoMap Live Mode: Started');
    } catch (e) {
      debugPrint('Error starting live mode: $e');
      _isActive = false;
    }
  }

  /// Stop live monitoring
  Future<void> stopLiveMode() async {
    if (!_isActive) return;

    await _roundLogsSubscription?.cancel();
    await _shotLogsSubscription?.cancel();
    
    _roundLogsSubscription = null;
    _shotLogsSubscription = null;
    _isActive = false;

    debugPrint('FoCoMap Live Mode: Stopped');
  }

  void _onRoundLogsUpdate(QuerySnapshot snapshot) {
    try {
      final newRoundLogs = snapshot.docs
          .map((doc) => RoundLogsRecord.fromSnapshot(doc))
          .toList();

      // Check for new entries (live updates)
      final newEntries = _findNewEntries(_currentRoundLogs, newRoundLogs);
      if (newEntries.isNotEmpty) {
        _liveUpdateController.add({
          'type': 'round_log',
          'action': 'added',
          'data': newEntries,
          'timestamp': DateTime.now(),
        });
      }

      // Update cache and notify listeners
      _currentRoundLogs = newRoundLogs;
      _roundLogsController.add(newRoundLogs);

    } catch (e) {
      debugPrint('Error processing round logs update: $e');
    }
  }

  void _onShotLogsUpdate(QuerySnapshot snapshot) {
    try {
      final newShotLogs = snapshot.docs
          .map((doc) => ShotLogsRecord.fromSnapshot(doc))
          .toList();

      // Check for new entries (live updates)
      final newEntries = _findNewShotEntries(_currentShotLogs, newShotLogs);
      if (newEntries.isNotEmpty) {
        _liveUpdateController.add({
          'type': 'shot_log',
          'action': 'added',
          'data': newEntries,
          'timestamp': DateTime.now(),
        });
      }

      // Update cache and notify listeners
      _currentShotLogs = newShotLogs;
      _shotLogsController.add(newShotLogs);

    } catch (e) {
      debugPrint('Error processing shot logs update: $e');
    }
  }

  List<RoundLogsRecord> _findNewEntries(
    List<RoundLogsRecord> oldList, 
    List<RoundLogsRecord> newList
  ) {
    if (oldList.isEmpty) return [];
    
    final oldIds = oldList.map((r) => r.roundId).toSet();
    return newList.where((r) => !oldIds.contains(r.roundId)).toList();
  }

  List<ShotLogsRecord> _findNewShotEntries(
    List<ShotLogsRecord> oldList, 
    List<ShotLogsRecord> newList
  ) {
    if (oldList.isEmpty) return [];
    
    final oldIds = oldList.map((s) => s.shotId).toSet();
    return newList.where((s) => !oldIds.contains(s.shotId)).toList();
  }

  void _onError(error) {
    debugPrint('FoCoMap Live Service Error: $error');
    _liveUpdateController.add({
      'type': 'error',
      'message': error.toString(),
      'timestamp': DateTime.now(),
    });
  }

  /// Get filtered data based on map layer and filters
  List<RoundLogsRecord> getFilteredRoundLogs({
    Map<String, bool>? filters,
    String? courseFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = List<RoundLogsRecord>.from(_currentRoundLogs);

    // Apply date filters
    if (startDate != null) {
      filtered = filtered.where((r) => 
        r.date != null && r.date!.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((r) => 
        r.date != null && r.date!.isBefore(endDate)).toList();
    }

    // Apply course filter
    if (courseFilter != null && courseFilter.isNotEmpty) {
      filtered = filtered.where((r) => 
        r.courseName.toLowerCase().contains(courseFilter.toLowerCase())).toList();
    }

    return filtered;
  }

  List<ShotLogsRecord> getFilteredShotLogs({
    Map<String, bool>? clubFilters,
    Map<String, bool>? cueFilters,
    String? roundIdFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = List<ShotLogsRecord>.from(_currentShotLogs);

    // Apply date filters
    if (startDate != null) {
      filtered = filtered.where((s) => 
        s.timestamp != null && s.timestamp!.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((s) => 
        s.timestamp != null && s.timestamp!.isBefore(endDate)).toList();
    }

    // Apply club filters
    if (clubFilters != null && clubFilters.isNotEmpty) {
      filtered = filtered.where((s) {
        final clubType = _getClubType(s.clubUsed);
        return clubFilters[clubType] ?? true;
      }).toList();
    }

    // Apply round filter
    if (roundIdFilter != null && roundIdFilter.isNotEmpty) {
      filtered = filtered.where((s) => s.roundId == roundIdFilter).toList();
    }

    return filtered;
  }

  String _getClubType(String club) {
    final clubLower = club.toLowerCase();
    if (clubLower.contains('driver')) return 'driver';
    if (clubLower.contains('iron') || clubLower.contains('hybrid')) return 'iron';
    if (clubLower.contains('wedge') || clubLower.contains('sand')) return 'wedge';
    if (clubLower.contains('putter')) return 'putter';
    return 'iron';
  }

  /// Manual refresh for Base tier users
  Future<void> refreshData({
    int roundLogsLimit = 50,
    int shotLogsLimit = 500,
  }) async {
    if (currentUser == null) return;

    try {
      // Fetch round logs
      final roundLogsSnapshot = await FirebaseFirestore.instance
          .collection('round_logs')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('createdTime', descending: true)
          .limit(roundLogsLimit)
          .get();

      final roundLogs = roundLogsSnapshot.docs
          .map((doc) => RoundLogsRecord.fromSnapshot(doc))
          .toList();

      // Fetch shot logs
      final shotLogsSnapshot = await FirebaseFirestore.instance
          .collection('shot_logs')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .limit(shotLogsLimit)
          .get();

      final shotLogs = shotLogsSnapshot.docs
          .map((doc) => ShotLogsRecord.fromSnapshot(doc))
          .toList();

      // Update cache and notify
      _currentRoundLogs = roundLogs;
      _currentShotLogs = shotLogs;

      _roundLogsController.add(roundLogs);
      _shotLogsController.add(shotLogs);

      debugPrint('FoCoMap: Manual refresh completed');
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  /// Get last 5 rounds for pulse animation
  List<RoundLogsRecord> getRecentRounds() {
    final recent = List<RoundLogsRecord>.from(_currentRoundLogs);
    recent.sort((a, b) => b.date?.compareTo(a.date ?? DateTime(1970)) ?? 0);
    return recent.take(5).toList();
  }

  /// Get round by ID for replay
  RoundLogsRecord? getRoundById(String roundId) {
    try {
      return _currentRoundLogs.firstWhere((r) => r.roundId == roundId);
    } catch (e) {
      return null;
    }
  }

  /// Get shots for specific round
  List<ShotLogsRecord> getShotsForRound(String roundId) {
    return _currentShotLogs.where((s) => s.roundId == roundId).toList();
  }

  /// Cleanup resources
  void dispose() {
    stopLiveMode();
    _roundLogsController.close();
    _shotLogsController.close();
    _liveUpdateController.close();
  }
}

