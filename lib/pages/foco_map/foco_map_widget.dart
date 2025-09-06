import 'package:fo_co_co/backend/schema/round_logs_record.dart';
import '/backend/schema/shot_logs_record.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_design_system.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/services/focomap_voice_service.dart';
import '/services/foco_map_live_service.dart';
import 'platform_map_widget.dart';
import 'foco_map_model.dart';
export 'foco_map_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class FoCoMapWidget extends StatefulWidget {
  const FoCoMapWidget({super.key});

  static String routeName = 'foco_map';
  static String routePath = '/foco_map';

  @override
  State<FoCoMapWidget> createState() => _FoCoMapWidgetState();
}

class _FoCoMapWidgetState extends State<FoCoMapWidget>
    with TickerProviderStateMixin {
  late FoCoMapModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Set<MapMarker> markers = {};
  LatLng? currentLocation;
  MapType currentMapType = MapType.normal;

  // Services
  final FoCoMapVoiceService _voiceService = FoCoMapVoiceService();
  final FoCoMapLiveService _liveService = FoCoMapLiveService();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _roundLogsSubscription;
  StreamSubscription? _shotLogsSubscription;
  StreamSubscription? _liveUpdateSubscription;
  StreamSubscription? _voiceUpdateSubscription;

  // Animation controllers for real-time effects
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FoCoMapModel());

    // Initialize animations for real-time effects
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _getCurrentLocation();
    _initializeServices();
    _loadMapData();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent memory leaks
    _roundLogsSubscription?.cancel();
    _shotLogsSubscription?.cancel();
    _liveUpdateSubscription?.cancel();
    _voiceUpdateSubscription?.cancel();

    // Dispose animation controllers
    _pulseController.dispose();
    _slideController.dispose();

    // Dispose services
    _model.dispose();
    _liveService.stopLiveMode();
    _voiceService.stopListening();
    _voiceService.dispose();

    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize services
      await _voiceService.initialize();
      await _liveService.initialize();

      // Set up live service listeners with proper subscription management
      _roundLogsSubscription = _liveService.roundLogsStream.listen((roundLogs) {
        if (mounted) {
          setState(() {
            _model.roundLogs = roundLogs;
          });
          _updateMarkers();
        }
      }, onError: (error) {
        debugPrint('Round logs stream error: $error');
      });

      _shotLogsSubscription = _liveService.shotLogsStream.listen((shotLogs) {
        if (mounted) {
          setState(() {
            _model.shotLogs = shotLogs;
          });
          _updateMarkers();
        }
      }, onError: (error) {
        debugPrint('Shot logs stream error: $error');
      });

      _liveUpdateSubscription = _liveService.liveUpdateStream.listen((update) {
        _handleLiveUpdate(update);
      }, onError: (error) {
        debugPrint('Live update stream error: $error');
      });

      // Set up voice service listeners for real-time feedback
      _voiceUpdateSubscription =
          _voiceService.liveUpdateStream.listen((update) {
        _handleVoiceUpdate(update);
      }, onError: (error) {
        debugPrint('Voice update stream error: $error');
      });
    } catch (e) {
      debugPrint('Error initializing services: $e');
      // Continue without live services if initialization fails
    }
  }

  void _handleLiveUpdate(Map<String, dynamic> update) {
    if (!mounted) return;

    final type = update['type'] as String;

    switch (type) {
      case 'round_log_added':
      case 'shot_log_added':
        _showLiveUpdateNotification(
            'New ${type.replaceAll('_', ' ')} recorded', Colors.green);
        _updateMarkers();
        _animateNewMarker(update['data']);
        break;
      case 'live_mode_started':
        _showLiveUpdateNotification('Live mode activated', Colors.blue);
        break;
      case 'live_mode_stopped':
        _showLiveUpdateNotification('Live mode stopped', Colors.orange);
        break;
      case 'error':
        _showLiveUpdateNotification('Error: ${update['message']}', Colors.red);
        break;
    }
  }

  void _handleVoiceUpdate(Map<String, dynamic> update) {
    if (!mounted) return;

    final type = update['type'] as String;

    switch (type) {
      case 'voice_processed':
        _showLiveUpdateNotification('Voice input processed', Colors.green);
        _updateMarkers();
        break;
      case 'error':
        _showLiveUpdateNotification(
            'Voice error: ${update['message']}', Colors.red);
        break;
    }
  }

  void _showLiveUpdateNotification(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _animateNewMarker(dynamic data) {
    // Trigger pulse animation for new markers
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Location will be handled by the PlatformMapWidget
      // This is just for initialization
      setState(() {
        currentLocation = LatLng(40.7128, -74.0060); // Default location
      });
    } catch (e) {
      // Default to a golf course location if permission denied
      setState(() {
        currentLocation = LatLng(40.7128, -74.0060); // New York
      });
    }
  }

  Future<void> _loadMapData() async {
    if (currentUser == null) {
      print('No authenticated user, skipping data load');
      if (mounted) {
        // Show a helpful message about authentication
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in to sync your golf data'),
            backgroundColor: Colors.blue,
            action: SnackBarAction(
              label: 'Sign In',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to login screen
                context.go('/login');
              },
            ),
          ),
        );
      }
      return;
    }

    try {
      // Check user tier and start appropriate mode
      if (_model.isLiveMode && _liveService.canAccessLiveMode()) {
        await _liveService.startLiveMode();
      } else {
        await _liveService.refreshData();
      }
    } catch (e) {
      print('Error loading map data: $e');
      // Handle specific Firestore permission errors
      if (e.toString().contains('permission-denied')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Authentication required for data sync'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Sign In',
                textColor: Colors.white,
                onPressed: () => context.go('/login'),
              ),
            ),
          );
        }
      }

      // Continue with empty data but functional map
      if (mounted) {
        setState(() {
          markers.clear();
        });
      }
    }
  }

  void _updateMarkers() {
    markers.clear();

    switch (_model.selectedLayer) {
      case 'MindMap':
        _addMindMapMarkers();
        break;
      case 'ShotMap':
        _addShotMapMarkers();
        break;
      case 'SyncMap':
        _addSyncMapMarkers();
        break;
    }

    setState(() {});
  }

  void _addMindMapMarkers() {
    for (final round in _model.getFilteredRoundLogs()) {
      if (round.coordinates == null) continue;

      final mindsetColor = _model.getMindsetColor(round);
      final markerColor = _getMarkerColorFromMindset(mindsetColor);

      markers.add(
        MapMarker(
          markerId: 'round_${round.roundId}',
          position: round.coordinates!,
          color: markerColor,
          infoWindow: InfoWindow(
            title: round.courseName,
            snippet: '${round.overallMindsetEmoji} ${round.bestCue}',
          ),
        ),
      );
    }
  }

  void _addShotMapMarkers() {
    for (final shot in _model.getFilteredShotLogs()) {
      if (shot.coordinates == null) continue;

      final clubColor = _getClubColor(shot.clubUsed);

      markers.add(
        MapMarker(
          markerId: 'shot_${shot.shotId}',
          position: shot.coordinates!,
          color: clubColor,
          infoWindow: InfoWindow(
            title: '${shot.clubUsed} - Hole ${shot.holeNumber}',
            snippet: '${shot.shotOutcome} | ${shot.cueUsed}',
          ),
        ),
      );
    }
  }

  void _addSyncMapMarkers() {
    // Combine round and shot data for synchronized view
    final Map<String, RoundLogsRecord> roundsMap = {
      for (final round in _model.getFilteredRoundLogs()) round.roundId: round
    };

    for (final shot in _model.getFilteredShotLogs()) {
      if (shot.coordinates == null) continue;

      final round = roundsMap[shot.roundId];
      if (round == null) continue;

      final mindsetColor = _model.getMindsetColor(round);
      final markerColor = _getMarkerColorFromMindset(mindsetColor);

      markers.add(
        MapMarker(
          markerId: 'sync_${shot.shotId}',
          position: shot.coordinates!,
          color: markerColor,
          infoWindow: InfoWindow(
            title: '${shot.clubUsed} - ${round.courseName}',
            snippet:
                'Mental: ${round.overallMindsetEmoji} | ${shot.shotOutcome}',
          ),
        ),
      );
    }
  }

  Color _getMarkerColorFromMindset(String mindsetColor) {
    switch (mindsetColor) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getClubColor(String club) {
    if (club.toLowerCase().contains('driver')) return Colors.red;
    if (club.toLowerCase().contains('iron')) return Colors.blue;
    if (club.toLowerCase().contains('wedge')) return Colors.orange;
    if (club.toLowerCase().contains('putter')) return Colors.green;
    return Colors.purple;
  }

  void _handleMarkerTap(MapMarker marker) {
    // Handle marker tap based on marker type
    if (marker.markerId.startsWith('round_')) {
      final roundId = marker.markerId.replaceFirst('round_', '');
      try {
        final round = _model.roundLogs.firstWhere((r) => r.roundId == roundId);
        _showRoundDetail(round);
      } catch (e) {
        print('Round not found: $roundId');
      }
    } else if (marker.markerId.startsWith('shot_')) {
      final shotId = marker.markerId.replaceFirst('shot_', '');
      try {
        final shot = _model.shotLogs.firstWhere((s) => s.shotId == shotId);
        _showShotDetail(shot);
      } catch (e) {
        print('Shot not found: $shotId');
      }
    } else if (marker.markerId.startsWith('sync_')) {
      final shotId = marker.markerId.replaceFirst('sync_', '');
      try {
        final shot = _model.shotLogs.firstWhere((s) => s.shotId == shotId);
        final round =
            _model.roundLogs.firstWhere((r) => r.roundId == shot.roundId);
        _showSyncDetail(shot, round);
      } catch (e) {
        print('Sync data not found: $shotId');
      }
    }
  }

  Future<void> _addSampleData() async {
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to add sample data'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Add sample round log
      final roundLogData = {
        'userId': currentUser!.uid,
        'roundId': 'round_${DateTime.now().millisecondsSinceEpoch}',
        'date': DateTime.now(),
        'courseName': 'Sample Golf Course',
        'courseType': 'championship',
        'coordinates': LatLng(40.7128, -74.0060),
        'mindsetFocus': 8,
        'mindsetConfidence': 7,
        'mindsetControl': 9,
        'bestCue': 'Deep breathing',
        'recoveryHoles': ['3', '7', '12'],
        'overallMindsetEmoji': '😊',
        'technicalSummary': 'Good driving, struggled with short game',
        'aiRoundSummary': 'Strong mental game today with excellent recovery',
        'voiceTranscription':
            'Had a great round today, feeling confident with my new breathing technique',
        'nlpProcessed': true,
        'isLive': true,
        'mindsetColor': 'green',
        'linkedGolfRoundId': '',
        'createdTime': DateTime.now(),
        'updatedTime': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('round_logs')
          .add(roundLogData);

      // Add sample shot log
      final shotLogData = {
        'userId': currentUser!.uid,
        'roundId': 'round_${DateTime.now().millisecondsSinceEpoch}',
        'shotId': 'shot_${DateTime.now().millisecondsSinceEpoch}',
        'holeNumber': 5,
        'clubUsed': 'Driver',
        'distanceAttempted': 285.0,
        'shotShape': 'straight',
        'shotOutcome': 'fairway',
        'cueUsed': 'smooth tempo',
        'confidenceLevel': 8,
        'windCondition': 'light breeze',
        'coordinates': LatLng(40.7130, -74.0058),
        'aiShotInsight': 'Great tempo today, try maintaining this rhythm',
        'voiceTranscription': 'Perfect drive on 5, used my tempo cue',
        'nlpProcessed': true,
        'shotTrend': 'improving',
        'missPattern': 'none',
        'performanceRating': 8,
        'clubIcon': '🏌️',
        'timestamp': DateTime.now(),
        'createdTime': DateTime.now(),
        'updatedTime': DateTime.now(),
      };

      await FirebaseFirestore.instance.collection('shot_logs').add(shotLogData);

      // Refresh the data to show new markers
      await _loadMapData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sample data added successfully! Check the map for new markers.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error adding sample data: $e');
      if (mounted) {
        String errorMessage = 'Error adding sample data';
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check your authentication.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _addSampleData(),
            ),
          ),
        );
      }
    }
  }

  void _showRoundDetail(RoundLogsRecord round) {
    _model.selectMarker('round_${round.roundId}');
    _showDetailBottomSheet(
      title: round.courseName,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Date: ${dateTimeFormat('yMMMd', round.date)}'),
          const SizedBox(height: 8),
          Text('Mindset: ${round.overallMindsetEmoji}'),
          Text('Focus: ${round.mindsetFocus}/10'),
          Text('Confidence: ${round.mindsetConfidence}/10'),
          Text('Control: ${round.mindsetControl}/10'),
          const SizedBox(height: 8),
          Text('Best Cue: ${round.bestCue}'),
          if (round.recoveryHoles.isNotEmpty)
            Text('Recovery Holes: ${round.recoveryHoles.join(", ")}'),
          if (round.aiRoundSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('AI Insights:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(round.aiRoundSummary),
          ],
        ],
      ),
    );
  }

  void _showShotDetail(ShotLogsRecord shot) {
    _model.selectMarker('shot_${shot.shotId}');
    _showDetailBottomSheet(
      title: '${shot.clubUsed} - Hole ${shot.holeNumber}',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Distance: ${shot.distanceAttempted}y'),
          Text('Outcome: ${shot.shotOutcome}'),
          Text('Shape: ${shot.shotShape}'),
          if (shot.cueUsed.isNotEmpty) Text('Cue Used: ${shot.cueUsed}'),
          Text('Confidence: ${shot.confidenceLevel}/10'),
          if (shot.windCondition.isNotEmpty)
            Text('Wind: ${shot.windCondition}'),
          if (shot.shotTrend.isNotEmpty) Text('Trend: ${shot.shotTrend}'),
          if (shot.aiShotInsight.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('AI Tip:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(shot.aiShotInsight),
          ],
        ],
      ),
    );
  }

  void _showSyncDetail(ShotLogsRecord shot, RoundLogsRecord round) {
    _model.selectMarker('sync_${shot.shotId}');
    _showDetailBottomSheet(
      title: 'Mental + Technical Analysis',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Course: ${round.courseName}'),
          Text('Hole ${shot.holeNumber} | ${shot.clubUsed}'),
          const Divider(),
          const Text('Mental State:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Overall: ${round.overallMindsetEmoji}'),
          Text('Focus: ${round.mindsetFocus}/10'),
          Text('Confidence: ${round.mindsetConfidence}/10'),
          const Divider(),
          const Text('Technical Result:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Outcome: ${shot.shotOutcome}'),
          Text('Distance: ${shot.distanceAttempted}y'),
          if (shot.cueUsed.isNotEmpty) Text('Cue Used: ${shot.cueUsed}'),
          if (shot.aiShotInsight.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Correlation Insight:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(shot.aiShotInsight),
          ],
        ],
      ),
    );
  }

  void _showDetailBottomSheet(
      {required String title, required Widget content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.pop();
                      _model.clearMarkerSelection();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Full-screen Real Map Background
            Positioned.fill(
              child: PlatformMapWidget(
                markers: markers,
                initialLocation: currentLocation,
                mapType: currentMapType,
                onMarkerTap: (marker) {
                  _handleMarkerTap(marker);
                },
                onMapTap: (position) {
                  // Handle map tap if needed
                },
              ),
            ),

            // Glass Navigation Bar (Top)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: GlassDesignSystem.glassBackground(
                    borderRadius: BorderRadius.circular(20),
                    tintColor: Colors.white,
                    opacity: 0.1,
                    blur: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/dashboard');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Title with Live Indicator
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  'FoCoMap',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                ),
                                if (_model.isLiveMode) ...[
                                  const SizedBox(width: 8),
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Map Toggle Button
                          GestureDetector(
                            onTap: () => _showMapTypeSelector(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.layers,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Map',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          height: 1.0,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Live Mode Toggle
                          GestureDetector(
                            onTap: () => _toggleLiveMode(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _model.isLiveMode
                                    ? Colors.red.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _model.isLiveMode
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Filters Button
                          GestureDetector(
                            onTap: () => _showFiltersBottomSheet(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Glass Player Info Panel (Top Left)
            Positioned(
              top: 100,
              left: 16,
              child: SafeArea(
                child: GlassDesignSystem.glass3DCard(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  tintColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentUser?.displayName ?? 'Player',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tier: ${_liveService.userTier.name.toUpperCase()}',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.0,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _model.isLiveMode ? 'LIVE' : 'OFFLINE',
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
                              color: _model.isLiveMode
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Glass Live Score Panel (Top Right)
            if (_model.roundLogs.isNotEmpty)
              Positioned(
                top: 100,
                right: 16,
                child: SafeArea(
                  child: GlassDesignSystem.glass3DCard(
                    width: 160,
                    padding: const EdgeInsets.all(16),
                    tintColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mental Score',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_model.roundLogs.last.mindsetFocus + _model.roundLogs.last.mindsetConfidence + _model.roundLogs.last.mindsetControl}',
                          style: FlutterFlowTheme.of(context)
                              .headlineLarge
                              .override(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _model.roundLogs.last.courseName,
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.0,
                                  ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Glass Layer Selection (Bottom)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: GlassDesignSystem.glassBackground(
                borderRadius: BorderRadius.circular(20),
                tintColor: Colors.white,
                opacity: 0.1,
                blur: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGlassLayerButton(
                            'MindMap', 'Mental', Icons.psychology),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassLayerButton(
                            'ShotMap', 'Technical', Icons.golf_course),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassLayerButton(
                            'SyncMap', 'Combined', Icons.sync),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Glass Voice Button (Bottom Right)
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add Sample Data Button
                  GlassDesignSystem.glass3DCard(
                    width: 60,
                    height: 60,
                    padding: EdgeInsets.zero,
                    tintColor: Colors.orange,
                    onTap: _addSampleData,
                    child: const Icon(
                      Icons.add_location,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Enhanced Voice Button with Real-time Feedback
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Voice Processing Indicator
                      StreamBuilder<bool>(
                        stream: _voiceService.processingStream,
                        builder: (context, processingSnapshot) {
                          final isProcessing = processingSnapshot.data ?? false;

                          if (!isProcessing) return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Processing...',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        color: Colors.white,
                                        fontSize: 10,
                                        height: 1.0,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Voice Transcription Preview
                      StreamBuilder<String>(
                        stream: _voiceService.transcriptionStream,
                        builder: (context, transcriptionSnapshot) {
                          final transcription =
                              transcriptionSnapshot.data ?? '';

                          if (transcription.isEmpty)
                            return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(maxWidth: 200),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              transcription,
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    color: Colors.white,
                                    fontSize: 10,
                                    height: 1.0,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),

                      // Main Voice Button
                      StreamBuilder<bool>(
                        stream: _voiceService.listeningStream,
                        builder: (context, listeningSnapshot) {
                          final isListening = listeningSnapshot.data ?? false;

                          return AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    isListening ? _pulseAnimation.value : 1.0,
                                child: GlassDesignSystem.glass3DCard(
                                  width: 60,
                                  height: 60,
                                  padding: EdgeInsets.zero,
                                  tintColor: isListening
                                      ? Colors.red
                                      : FlutterFlowTheme.of(context).primary,
                                  onTap: _handleVoiceButtonTap,
                                  child: Icon(
                                    isListening ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Live Mode Indicator with Animation
            if (_model.isLiveMode)
              Positioned(
                bottom: 20,
                left: 20,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: GlassDesignSystem.glassBackground(
                        borderRadius: BorderRadius.circular(20),
                        tintColor: Colors.green,
                        opacity: 0.2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LIVE',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Enhanced methods for real-time experience
  Future<void> _toggleLiveMode() async {
    HapticFeedback.mediumImpact();

    if (!_liveService.canAccessLiveMode()) {
      _showTierUpgradeDialog();
      return;
    }

    try {
      if (_model.isLiveMode) {
        await _liveService.stopLiveMode();
        _model.setLiveMode(false);
      } else {
        await _liveService.startLiveMode();
        _model.setLiveMode(true);
      }
    } catch (e) {
      _showLiveUpdateNotification('Error toggling live mode: $e', Colors.red);
    }
  }

  void _showTierUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Upgrade Required',
          style: FlutterFlowTheme.of(context).headlineSmall.override(
                color: Colors.white,
                height: 1.0,
              ),
        ),
        content: Text(
          'Live mode requires Plus or Prime subscription. Upgrade now to access real-time features.',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: Colors.white70,
                height: 1.0,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // Navigate to subscription page
              context.pushNamed('subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoiceButtonTap() async {
    HapticFeedback.mediumImpact();

    try {
      if (_voiceService.isListening) {
        await _voiceService.stopListening();
      } else {
        // Set context based on live mode
        final context = _model.isLiveMode
            ? VoiceContext.activeRound
            : VoiceContext.offCourse;

        // Set active round if in live mode
        if (_model.isLiveMode && _model.roundLogs.isNotEmpty) {
          _voiceService.setActiveRound(_model.roundLogs.first.roundId);
        }

        await _voiceService.startListening(context: context);
      }
    } catch (e) {
      _showLiveUpdateNotification('Voice error: $e', Colors.red);
    }
  }

  Widget _buildGlassLayerButton(String layerKey, String label, IconData icon) {
    final isSelected = _model.selectedLayer == layerKey;
    return GestureDetector(
      onTap: () {
        _model.selectLayer(layerKey);
        _updateMarkers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    height: 1.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassDesignSystem.glassBackground(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        tintColor: Colors.white,
        opacity: 0.1,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Map Type',
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
              ),
              const SizedBox(height: 16),
              _buildMapTypeOption('Standard', Icons.map, MapType.normal),
              _buildMapTypeOption(
                  'Satellite', Icons.satellite_alt, MapType.satellite),
              _buildMapTypeOption('Hybrid', Icons.layers, MapType.hybrid),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(String title, IconData icon, MapType mapType) {
    final isSelected = currentMapType == mapType;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentMapType = mapType;
        });
        context.pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    height: 1.0,
                  ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Map Filters',
                style: FlutterFlowTheme.of(context).headlineSmall,
              ),
              const SizedBox(height: 16),

              // Club Filters
              const Text('Club Types:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _model.clubFilters.keys.map((club) {
                  return FilterChip(
                    label: Text(club.toUpperCase()),
                    selected: _model.clubFilters[club] ?? false,
                    onSelected: (selected) {
                      setState(() {
                        _model.toggleClubFilter(club);
                        _updateMarkers();
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              FFButtonWidget(
                onPressed: () => context.pop(),
                text: 'Apply Filters',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 44,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        letterSpacing: 0.0,
                        height: 1.0,
                      ),
                  elevation: 2.0,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Note: Method available for future use when voice integration is enabled
  /* 
  void _showVoiceInputModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<bool>(
        stream: _voiceService.listeningStream,
        builder: (context, listeningSnapshot) {
          final isListening = listeningSnapshot.data ?? false;
          
          return StreamBuilder<String>(
            stream: _voiceService.transcriptionStream,
            builder: (context, transcriptionSnapshot) {
              final transcription = transcriptionSnapshot.data ?? '';
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Voice Logging',
                        style: FlutterFlowTheme.of(context).headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Icon(
                        Icons.mic,
                        size: 64,
                        color: isListening ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      
                      if (isListening) ...[
                        Text(
                          'Listening...',
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (transcription.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            transcription,
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      Text(
                        isListening 
                            ? 'Speak about your golf experience...'
                            : 'Tap to start recording your mental state, shot details, or course insights',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(
                            child: FFButtonWidget(
                              onPressed: () async {
                                if (isListening) {
                                  await _voiceService.stopListening();
                                } else {
                                  await _voiceService.startListening();
                                }
                              },
                              text: isListening ? 'Stop Recording' : 'Start Recording',
                              options: FFButtonOptions(
                                height: 44,
                                color: isListening ? Colors.red : FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                      height: 1.0,
                                    ),
                                elevation: 2.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FFButtonWidget(
                            onPressed: () => context.pop(),
                            text: 'Close',
                            options: FFButtonOptions(
                              height: 44,
                              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Inter',
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    letterSpacing: 0.0,
                                    height: 1.0,
                                  ),
                              elevation: 2.0,
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
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
        },
      ),
    );
  }
  */
}
