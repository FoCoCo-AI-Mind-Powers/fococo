import 'package:fo_co_co/backend/schema/round_logs_record.dart';
import '/backend/schema/shot_logs_record.dart';
import '/backend/schema/golf_rounds_record.dart';
import '/backend/schema/scorecard_record.dart';
import '/backend/schema/activity_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/services/focomap_voice_service.dart' as voice;
import '/services/foco_map_live_service.dart';
import '/services/live_location_service.dart';
import '/services/focomap_tutorial_service.dart';
import '/services/focomap_ai_service.dart';
import '/services/focomap_custom_markers.dart';
import '/ai_integration/config/gemini_live_config.dart';
import 'platform_map_widget.dart';
import 'advanced_map_view.dart';
import 'foco_map_model.dart';
export 'foco_map_model.dart';
import '/pages/golf_rounds/golf_round_modal_grint_style.dart';

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
  MapViewMode _currentViewMode = MapViewMode.standard;
  bool _useAdvancedView = false;
  double _currentZoom = 15.0;

  // Map controller keys for location animation
  final GlobalKey _platformMapKey = GlobalKey();
  final GlobalKey _advancedMapKey = GlobalKey();

  // Live Session Mode
  bool _isLiveSession = false;
  String? _liveSessionRoundId;
  Timer? _liveSessionTimer;

  // Services
  final voice.FoCoMapVoiceService _voiceService = voice.FoCoMapVoiceService();
  // Gemini voice service ready for integration
  // final gemini_voice.FoCoMapGeminiVoiceService _geminiVoiceService = gemini_voice.FoCoMapGeminiVoiceService();
  final FoCoMapLiveService _liveService = FoCoMapLiveService();
  final LiveLocationService _locationService = LiveLocationService();
  final FoCoMapTutorialService _tutorialService = FoCoMapTutorialService();
  late FoCoMapAIService _aiService;

  // AI analysis data
  List<HeatmapData> _heatmapData = [];
  List<TrajectoryData> _trajectoryData = [];

  // AI response tooltip management
  OverlayEntry? _aiTooltipOverlay;
  Timer? _tooltipTimer;

  // Activity records
  List<ActivityRecord> _activityRecords = [];
  StreamSubscription? _activitySubscription;

  // Tutorial target keys
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _mapTypeKey = GlobalKey();
  final GlobalKey _liveToggleKey = GlobalKey();
  final GlobalKey _filtersKey = GlobalKey();
  final GlobalKey _layerMindMapKey = GlobalKey();
  final GlobalKey _layerShotMapKey = GlobalKey();
  final GlobalKey _layerSyncMapKey = GlobalKey();
  final GlobalKey _voiceButtonKey = GlobalKey();
  final GlobalKey _addDataKey = GlobalKey();
  final GlobalKey _liveIndicatorKey = GlobalKey();
  final GlobalKey _locationPanelKey = GlobalKey();
  final GlobalKey _scorePanelKey = GlobalKey();

  // Stream subscriptions for proper cleanup
  StreamSubscription? _roundLogsSubscription;
  StreamSubscription? _shotLogsSubscription;
  StreamSubscription? _golfRoundsSubscription;
  StreamSubscription? _scorecardsSubscription;
  StreamSubscription? _liveUpdateSubscription;
  StreamSubscription? _voiceUpdateSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _courseContextSubscription;
  StreamSubscription? _spatialAnalysisSubscription;
  StreamSubscription? _patternInsightSubscription;
  StreamSubscription? _guidanceSubscription;

  // Animation controllers for real-time effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FoCoMapModel());

    debugPrint('🎯 FoCoMap: Initializing...');

    // Initialize animations for real-time effects
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Initialize AI service with API key from centralized config
    final apiKey = GeminiLiveAPIConfig.apiKey;
    if (apiKey.isEmpty) {
      debugPrint(
          '⚠️ FoCoMap: GEMINI_API_KEY not set. AI features will be disabled.');
    }
    _aiService = FoCoMapAIService(apiKey: apiKey);

    // Initialize custom markers (lightweight, can be done immediately)
    debugPrint('🎯 FoCoMap: Initializing custom markers...');
    FoCoMapCustomMarkers.initialize();

    // Load map location first (critical for map display)
    debugPrint('🎯 FoCoMap: Getting current location for map display...');
    _getCurrentLocation();

    // Defer heavy data loading until after first frame renders
    // This ensures map shows immediately, then data loads in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
          '🎯 FoCoMap: First frame rendered, starting background data load...');
      _initializeServicesInBackground();
    });

    debugPrint(
        '✅ FoCoMap: Map initialization complete - map will display immediately');
  }

  @override
  void dispose() {
    debugPrint('🎯 FoCoMap: Disposing...');

    // Cancel all stream subscriptions to prevent memory leaks
    _roundLogsSubscription?.cancel();
    _shotLogsSubscription?.cancel();
    _golfRoundsSubscription?.cancel();
    _scorecardsSubscription?.cancel();
    _activitySubscription?.cancel();
    _liveUpdateSubscription?.cancel();
    _voiceUpdateSubscription?.cancel();
    _locationSubscription?.cancel();
    _courseContextSubscription?.cancel();
    _spatialAnalysisSubscription?.cancel();
    _patternInsightSubscription?.cancel();
    _guidanceSubscription?.cancel();

    debugPrint('🎯 FoCoMap: All subscriptions cancelled');

    // Dispose animation controllers
    _pulseController.dispose();

    // Stop live session if active
    _liveSessionTimer?.cancel();
    if (_isLiveSession) {
      _stopLiveSession();
    }

    // Remove AI tooltip overlay
    _hideAITooltip();
    _tooltipTimer?.cancel();

    // Dispose services
    _model.dispose();
    _liveService.stopLiveMode();
    _voiceService.stopListening();
    _voiceService.dispose();
    _locationService.stopTracking();
    _locationService.dispose();
    _tutorialService.dispose();
    _aiService.dispose();
    FoCoMapCustomMarkers.clearCache();

    super.dispose();
  }

  /// Initialize services in background after map is displayed
  Future<void> _initializeServicesInBackground() async {
    try {
      debugPrint('🎯 FoCoMap: Background initialization started...');

      // Initialize core services first (non-blocking)
      await _initializeServices();

      // Load map data in background
      debugPrint('🎯 FoCoMap: Loading map data in background...');
      _loadMapData(); // Don't await - let it load asynchronously

      // Check tutorial after a delay (non-critical)
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          debugPrint('🎯 FoCoMap: Checking tutorial...');
          _checkAndShowTutorial();
        }
      });

      debugPrint('✅ FoCoMap: Background initialization complete');
    } catch (e) {
      debugPrint('❌ FoCoMap: Error in background initialization: $e');
    }
  }

  Future<void> _initializeServices() async {
    try {
      debugPrint('🎯 FoCoMap: Initializing voice service...');
      // Initialize services
      await _voiceService.initialize();

      debugPrint('🎯 FoCoMap: Initializing live service...');
      await _liveService.initialize();

      debugPrint('🎯 FoCoMap: Initializing location service...');
      await _locationService.initialize();

      debugPrint('🎯 FoCoMap: Initializing AI service...');
      await _aiService.initialize();

      // Set up activity records listener in background (non-critical)
      // Don't await - let it fail silently if permissions are denied
      _setupActivityRecordsListener().catchError((error) {
        debugPrint(
            '⚠️ FoCoMap: Activity records setup failed (non-critical): $error');
      });

      // Set up live service listeners with proper subscription management
      _roundLogsSubscription = _liveService.roundLogsStream.listen((roundLogs) {
        if (mounted) {
          setState(() {
            _model.roundLogs = roundLogs;
          });
          _updateMarkers();
          _performAIAnalysis();

          // Generate new guidance when new round data arrives
          if (_model.isLiveMode && roundLogs.isNotEmpty) {
            _generateRealtimeGuidance();
          }
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
          _performAIAnalysis();

          // Generate new guidance when new shot data arrives (throttled)
          if (_model.isLiveMode && shotLogs.length % 5 == 0) {
            _generateRealtimeGuidance();
          }
        }
      }, onError: (error) {
        debugPrint('Shot logs stream error: $error');
      });

      _golfRoundsSubscription =
          _liveService.golfRoundsStream.listen((golfRounds) {
        if (mounted) {
          setState(() {
            _model.golfRounds = golfRounds;
          });
          _updateMarkers();
        }
      }, onError: (error) {
        debugPrint('Golf rounds stream error: $error');
      });

      _scorecardsSubscription =
          _liveService.scorecardsStream.listen((scorecards) {
        if (mounted) {
          setState(() {
            _model.scorecards = scorecards;
          });
          _updateMarkers();
        }
      }, onError: (error) {
        debugPrint('Scorecards stream error: $error');
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

      // Set up location service listeners
      _locationSubscription =
          _locationService.locationStream.listen((location) {
        if (mounted) {
          setState(() {
            currentLocation = location;
          });
        }
      }, onError: (error) {
        debugPrint('Location stream error: $error');
      });

      _courseContextSubscription =
          _locationService.courseContextStream.listen((context) {
        _handleCourseContextChange(context);
      }, onError: (error) {
        debugPrint('Course context stream error: $error');
      });

      // Set up AI service listeners
      _spatialAnalysisSubscription =
          _aiService.spatialAnalysisStream.listen((analysis) {
        if (mounted) {
          _handleSpatialAnalysis(analysis);
        }
      });

      _patternInsightSubscription = _aiService.patternStream.listen((insight) {
        if (mounted) {
          _handlePatternInsight(insight);
        }
      });

      // Set up real-time guidance listener
      _guidanceSubscription = _aiService.guidanceStream.listen((guidance) {
        if (mounted) {
          _handleRealtimeGuidance(guidance);
        }
      });

      debugPrint('🎯 FoCoMap: All services initialized successfully');
    } catch (e) {
      debugPrint('❌ FoCoMap: Error initializing services: $e');
      // Continue without live services if initialization fails
    }
  }

  /// Setup activity records listener
  Future<void> _setupActivityRecordsListener() async {
    if (currentUser == null) {
      debugPrint('⚠️ FoCoMap: No user, skipping activity records');
      return;
    }

    try {
      debugPrint('🎯 FoCoMap: Setting up activity records stream...');
      _activitySubscription = FirebaseFirestore.instance
          .collection('activities')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('activityType', isEqualTo: 'round')
          .orderBy('activityDate', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          debugPrint(
              '🎯 FoCoMap: Activity records updated: ${snapshot.docs.length}');
          setState(() {
            _activityRecords = snapshot.docs
                .map((doc) => ActivityRecord.fromSnapshot(doc))
                .toList();
          });
          _updateMarkers();
        }
      }, onError: (error) {
        // Handle permission errors gracefully
        if (error.toString().contains('permission-denied')) {
          debugPrint(
              '⚠️ FoCoMap: Activity records permission denied - skipping activity records');
          // Don't show error to user, just skip this feature
          setState(() {
            _activityRecords = [];
          });
        } else {
          debugPrint('❌ FoCoMap: Activity records stream error: $error');
        }
      });

      debugPrint('✅ FoCoMap: Activity records listener active');
    } catch (e) {
      // Handle permission errors gracefully
      if (e.toString().contains('permission-denied')) {
        debugPrint(
            '⚠️ FoCoMap: Activity records permission denied - skipping activity records');
        setState(() {
          _activityRecords = [];
        });
      } else {
        debugPrint('❌ FoCoMap: Error setting up activity records: $e');
      }
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

  void _handleCourseContextChange(CourseContext context) {
    if (!mounted) return;

    switch (context) {
      case CourseContext.onCourse:
        _showLiveUpdateNotification(
            'On course: ${_locationService.activeGolfCourse?.name ?? "Unknown"}',
            Colors.green);
        break;
      case CourseContext.nearCourse:
        _showLiveUpdateNotification(
            'Near: ${_locationService.activeGolfCourse?.name ?? "Unknown"}',
            Colors.blue);
        break;
      case CourseContext.approachingCourse:
        _showLiveUpdateNotification(
            'Approaching: ${_locationService.activeGolfCourse?.name ?? "Unknown"}',
            Colors.orange);
        break;
      default:
        break;
    }
  }

  Future<void> _checkAndShowTutorial() async {
    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final hasCompletedTutorial =
        await _tutorialService.hasCompletedMainTutorial();
    if (!hasCompletedTutorial) {
      _startMainTutorial();
    }
  }

  void _startMainTutorial() {
    _tutorialService.startMainTutorial(
      context,
      backButtonKey: _backButtonKey,
      titleKey: _titleKey,
      mapTypeKey: _mapTypeKey,
      liveToggleKey: _liveToggleKey,
      filtersKey: _filtersKey,
      layerMindMapKey: _layerMindMapKey,
      layerShotMapKey: _layerShotMapKey,
      layerSyncMapKey: _layerSyncMapKey,
      voiceButtonKey: _voiceButtonKey,
      addDataKey: _addDataKey,
    );
  }

  void _startLiveModeTutorial() {
    _tutorialService.startLiveModeTutorial(
      context,
      liveIndicatorKey: _liveIndicatorKey,
      locationPanelKey: _locationPanelKey,
      scorePanelKey: _scorePanelKey,
    );
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

  // AI Analysis Methods

  Future<void> _performAIAnalysis() async {
    if (_model.roundLogs.isEmpty && _model.shotLogs.isEmpty) return;

    try {
      // Analyze spatial patterns
      final positions = <LatLng>[];
      for (final round in _model.roundLogs) {
        if (round.coordinates != null) {
          positions.add(round.coordinates!);
        }
      }
      for (final shot in _model.shotLogs) {
        if (shot.coordinates != null) {
          positions.add(shot.coordinates!);
        }
      }

      if (positions.isNotEmpty) {
        final contextData = {
          'courseName': _model.roundLogs.isNotEmpty
              ? _model.roundLogs.first.courseName
              : 'Unknown',
          'weather': 'Clear',
          'playerSkill': _liveService.userTier.name,
        };

        await _aiService.analyzeSpatialPatterns(
          positions: positions,
          contextData: contextData,
        );
      }

      // Analyze performance patterns
      await _aiService.analyzePerformancePatterns(
        rounds: _model.roundLogs,
        shots: _model.shotLogs,
      );

      // Cluster markers if needed
      if (markers.length > 20 && _currentZoom < 14) {
        final clusters = await _aiService.clusterMarkers(
          markers: markers.toList(),
          zoomLevel: _currentZoom,
        );
        // Process clusters to create cluster markers
        for (final cluster in clusters) {
          if (cluster.markers.length > 1) {
            // Create cluster marker
            final clusterIcon = await FoCoMapCustomMarkers.createClusterMarker(
              count: cluster.markers.length,
              primaryType: MarkerType.roundLog,
              isSelected: false,
            );
            markers.add(
              MapMarker(
                markerId:
                    'cluster_${cluster.center.latitude}_${cluster.center.longitude}',
                position: cluster.center,
                icon: clusterIcon,
                infoWindow: InfoWindow(
                  title: '${cluster.markers.length} items',
                  snippet: 'Tap to zoom in',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error performing AI analysis: $e');
    }
  }

  void _handleSpatialAnalysis(SpatialAnalysis analysis) {
    if (!mounted) return;

    setState(() {
      // Convert hotspots to heatmap data
      _heatmapData = analysis.hotspots
          .map((hotspot) => HeatmapData(
                id: 'hotspot_${DateTime.now().millisecondsSinceEpoch}',
                position: hotspot.center,
                radius: hotspot.radius,
                color: Colors.red,
                intensity: hotspot.intensity,
              ))
          .toList();

      // Convert trajectories to trajectory data
      _trajectoryData = analysis.trajectories
          .map((trajectory) => TrajectoryData(
                id: 'trajectory_${DateTime.now().millisecondsSinceEpoch}',
                points: trajectory.points,
                color: _getTrajectoryColor(trajectory.type),
                width: 3.0,
                isDashed: trajectory.confidence < 0.7,
              ))
          .toList();
    });

    // Show insights as tooltip dialogue
    if (analysis.patterns.isNotEmpty) {
      final patternMessage = analysis.patterns.first;
      _showAITooltip(patternMessage, Colors.blue);

      // Also show notification
      _showLiveUpdateNotification(
        'Pattern detected: $patternMessage',
        Colors.blue,
      );
    }

    // Show hotspot insights
    if (analysis.hotspots.isNotEmpty) {
      final hotspot = analysis.hotspots.first;
      if (hotspot.description.isNotEmpty) {
        _showAITooltip(hotspot.description, Colors.orange);
      }
    }
  }

  void _handlePatternInsight(PatternInsight insight) {
    if (!mounted) return;

    // Show recommendations as tooltip dialogue
    if (insight.recommendations.isNotEmpty) {
      final recommendation = insight.recommendations.first;
      _showAITooltip(recommendation, Colors.green);

      // Also show notification
      _showLiveUpdateNotification(
        recommendation,
        Colors.green,
      );
    }

    // Update UI with trends
    if (insight.trends.isNotEmpty) {
      final trend = insight.trends.first;
      if (trend.type == 'mindset_improvement') {
        _showAITooltip(trend.description, Colors.green);
        _showLiveUpdateNotification(
          trend.description,
          Colors.green,
        );
      }
    }
  }

  Color _getTrajectoryColor(String type) {
    switch (type) {
      case 'improvement':
        return Colors.green;
      case 'decline':
        return Colors.red;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Show AI response as tooltip dialogue
  void _showAITooltip(String message, Color color) {
    if (!mounted) return;

    // Hide existing tooltip first
    _hideAITooltip();

    // Create overlay entry for tooltip
    _aiTooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 120,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _hideAITooltip,
            child: GlassDesignSystem.glassBackground(
              borderRadius: BorderRadius.circular(16),
              tintColor: color,
              opacity: 0.2,
              blur: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 18),
                      onPressed: _hideAITooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_aiTooltipOverlay!);

    // Auto-hide after 8 seconds
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(seconds: 8), () {
      _hideAITooltip();
    });
  }

  /// Hide AI tooltip dialogue
  void _hideAITooltip() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;

    if (_aiTooltipOverlay != null) {
      _aiTooltipOverlay!.remove();
      _aiTooltipOverlay = null;
    }
  }

  /// Zoom map to fit all markers
  Future<void> _zoomToFitAllMarkers() async {
    if (markers.isEmpty) {
      debugPrint('⚠️ FoCoMap: No markers to zoom to');
      return;
    }

    try {
      // Calculate bounds from all markers
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      for (final marker in markers) {
        final lat = marker.position.latitude;
        final lng = marker.position.longitude;

        minLat = minLat < lat ? minLat : lat;
        maxLat = maxLat > lat ? maxLat : lat;
        minLng = minLng < lng ? minLng : lng;
        maxLng = maxLng > lng ? maxLng : lng;
      }

      // Calculate center
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final center = LatLng(centerLat, centerLng);

      // Calculate zoom level based on bounds
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      // Adjust zoom based on spread (lower zoom for wider spread)
      double targetZoom = 15.0;
      if (maxDiff > 0.1) {
        targetZoom = 12.0; // Wide view
      } else if (maxDiff > 0.05) {
        targetZoom = 13.0;
      } else if (maxDiff > 0.01) {
        targetZoom = 14.0;
      } else {
        targetZoom = 15.0; // Close view
      }

      // Add padding to bounds
      final padding = maxDiff * 0.2; // 20% padding
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      debugPrint(
          '🎯 FoCoMap: Zooming to fit ${markers.length} markers - Center: ($centerLat, $centerLng), Zoom: $targetZoom');

      // Update state
      setState(() {
        currentLocation = center;
        _currentZoom = targetZoom;
      });

      // Animate map to bounds if using platform map
      if (!_useAdvancedView) {
        await PlatformMapWidget.animateToLocationFromKey(
          _platformMapKey,
          center,
          zoom: targetZoom,
        );
      }

      debugPrint('✅ FoCoMap: Map zoomed to fit all markers');
    } catch (e) {
      debugPrint('❌ FoCoMap: Error zooming to fit markers: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // First try to get last round location for better initial view
      final lastRoundLocation = await _getLastRoundLocation();
      if (lastRoundLocation != null) {
        setState(() {
          currentLocation = lastRoundLocation;
          _currentZoom = 16.0; // Good zoom level for golf course view
        });
        debugPrint(
            'Set initial location to last round: ${lastRoundLocation.latitude}, ${lastRoundLocation.longitude}');
        return;
      }

      // Fallback to current GPS location
      await _locationService.initialize();
      final position = _locationService.currentLocation;
      if (position != null) {
        setState(() {
          currentLocation = position;
          _currentZoom = 15.0; // Standard zoom for current location
        });
        debugPrint('Set initial location to current GPS position');
      }
    } catch (e) {
      debugPrint('Error getting initial location: $e');
      // Set default golf course location (Pebble Beach)
      setState(() {
        currentLocation = const LatLng(36.5669, -121.9508);
        _currentZoom = 15.0;
      });
    }
  }

  /// Get the location of user's most recent round for better initial map view
  Future<LatLng?> _getLastRoundLocation() async {
    try {
      final user = currentUser;
      if (user?.uid == null) return null;

      // Query the most recent round log with coordinates
      final roundLogsQuery = await FirebaseFirestore.instance
          .collection('round_logs')
          .where('userId', isEqualTo: user!.uid)
          .where('coordinates', isNotEqualTo: null)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (roundLogsQuery.docs.isNotEmpty) {
        final roundData = roundLogsQuery.docs.first.data();
        final coordinates = roundData['coordinates'];
        if (coordinates != null) {
          return LatLng(coordinates.latitude, coordinates.longitude);
        }
      }

      // Fallback to shot logs if no round logs with coordinates
      final shotLogsQuery = await FirebaseFirestore.instance
          .collection('shot_logs')
          .where('userId', isEqualTo: user.uid)
          .where('coordinates', isNotEqualTo: null)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (shotLogsQuery.docs.isNotEmpty) {
        final shotData = shotLogsQuery.docs.first.data();
        final coordinates = shotData['coordinates'];
        if (coordinates != null) {
          return LatLng(coordinates.latitude, coordinates.longitude);
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching last round location: $e');
      return null;
    }
  }

  /// Start live golf session mode
  Future<void> _startLiveSession() async {
    try {
      setState(() {
        _isLiveSession = true;
        _currentZoom = 18.0; // Closer zoom for live play
      });

      // Generate round ID for this session
      _liveSessionRoundId = 'live_${DateTime.now().millisecondsSinceEpoch}';

      // Start location tracking
      await _locationService.startTracking();

      // Start voice service for live logging
      _voiceService.setActiveRound(_liveSessionRoundId);

      // Start live data service
      await _liveService.startLiveMode(roundId: _liveSessionRoundId);

      // Auto-refresh location every 10 seconds during live session
      _liveSessionTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _updateCurrentLocationInLiveMode();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🏌️ Live golf session started!'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('Live golf session started with ID: $_liveSessionRoundId');
    } catch (e) {
      debugPrint('Error starting live session: $e');
      setState(() {
        _isLiveSession = false;
      });
    }
  }

  /// Stop live golf session mode
  Future<void> _stopLiveSession() async {
    try {
      setState(() {
        _isLiveSession = false;
        _currentZoom = 15.0; // Return to normal zoom
      });

      // Stop timers and services
      _liveSessionTimer?.cancel();
      await _locationService.stopTracking();
      await _liveService.stopLiveMode();

      // Show session summary
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Live golf session ended'),
            backgroundColor: Colors.blue.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Reset session data
      _liveSessionRoundId = null;

      debugPrint('Live golf session ended');
    } catch (e) {
      debugPrint('Error stopping live session: $e');
    }
  }

  /// Update current location during live session
  Future<void> _updateCurrentLocationInLiveMode() async {
    if (!_isLiveSession) return;

    try {
      final position = _locationService.currentLocation;
      if (position != null) {
        setState(() {
          currentLocation = position;
        });
      }
    } catch (e) {
      debugPrint('Error updating live location: $e');
    }
  }

  /// Get glass color based on current theme
  Color _getGlassColorForTheme() {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  /// Get glass opacity based on current theme
  double _getGlassOpacityForTheme() {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? 0.1 : 0.2;
  }

  /// Show filters bottom sheet with theme support
  void _showFiltersBottomSheet() {
    final brightness = Theme.of(context).brightness;
    final isDarkTheme = brightness == Brightness.dark;

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDarkTheme ? Colors.grey[900] : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: GlassDesignSystem.glassBackground(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                tintColor: _getGlassColorForTheme(),
                opacity: _getGlassOpacityForTheme(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkTheme ? Colors.white54 : Colors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Map Filters',
                        style: FlutterFlowTheme.of(context)
                            .headlineSmall
                            .override(
                              color: isDarkTheme ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Date Range Filter - Fixed
                      _buildFilterSection(
                        'Date Range',
                        Icons.date_range,
                        isDarkTheme,
                        child: Row(
                          children: [
                            Expanded(
                              child: StatefulBuilder(
                                builder: (context, setSheetState) {
                                  return _buildDateButton(
                                    'From: ${_formatDate(_model.filterStartDate)}',
                                    isDarkTheme,
                                    () async {
                                      debugPrint(
                                          '🎯 FoCoMap: Selecting start date...');
                                      await _selectStartDate();
                                      debugPrint(
                                          '✅ FoCoMap: Start date selected: ${_model.filterStartDate}');
                                      // Update the bottom sheet UI
                                      setSheetState(() {});
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatefulBuilder(
                                builder: (context, setSheetState) {
                                  return _buildDateButton(
                                    'To: ${_formatDate(_model.filterEndDate)}',
                                    isDarkTheme,
                                    () async {
                                      debugPrint(
                                          '🎯 FoCoMap: Selecting end date...');
                                      await _selectEndDate();
                                      debugPrint(
                                          '✅ FoCoMap: End date selected: ${_model.filterEndDate}');
                                      // Update the bottom sheet UI
                                      setSheetState(() {});
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Data Type Filter - Fixed
                      _buildFilterSection(
                        'Data Types',
                        Icons.layers,
                        isDarkTheme,
                        child: Column(
                          children: [
                            _buildFilterToggle(
                                'Round Logs', _model.showRoundLogs, isDarkTheme,
                                (value) {
                              debugPrint(
                                  '🎯 FoCoMap: Toggling Round Logs: $value');
                              setState(() {
                                _model.showRoundLogs = value;
                              });
                              _refreshMapData();
                            }),
                            _buildFilterToggle(
                                'Shot Logs', _model.showShotLogs, isDarkTheme,
                                (value) {
                              debugPrint(
                                  '🎯 FoCoMap: Toggling Shot Logs: $value');
                              setState(() {
                                _model.showShotLogs = value;
                              });
                              _refreshMapData();
                            }),
                            _buildFilterToggle('Golf Rounds',
                                _model.showGolfRounds, isDarkTheme, (value) {
                              debugPrint(
                                  '🎯 FoCoMap: Toggling Golf Rounds: $value');
                              setState(() {
                                _model.showGolfRounds = value;
                              });
                              _refreshMapData();
                            }),
                            _buildFilterToggle('Scorecards',
                                _model.showScorecards, isDarkTheme, (value) {
                              debugPrint(
                                  '🎯 FoCoMap: Toggling Scorecards: $value');
                              setState(() {
                                _model.showScorecards = value;
                              });
                              _refreshMapData();
                            }),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Apply/Clear buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Clear all filters
                                setState(() {
                                  _model.filterStartDate = null;
                                  _model.filterEndDate = null;
                                  _model.showRoundLogs = true;
                                  _model.showShotLogs = true;
                                  _model.showGolfRounds = true;
                                  _model.showScorecards = true;
                                });
                                _refreshMapData();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _refreshMapData();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    FlutterFlowTheme.of(context).primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
  }

  Widget _buildFilterSection(String title, IconData icon, bool isDarkTheme,
      {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: isDarkTheme ? Colors.white70 : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    color: isDarkTheme ? Colors.white70 : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateButton(
      String text, bool isDarkTheme, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkTheme ? Colors.grey[600]! : Colors.grey[400]!,
          ),
        ),
        child: Text(
          text,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: isDarkTheme ? Colors.white : Colors.black,
                height: 1.0,
              ),
        ),
      ),
    );
  }

  Widget _buildFilterToggle(
      String title, bool value, bool isDarkTheme, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  color: isDarkTheme ? Colors.white : Colors.black,
                  height: 1.0,
                ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: FlutterFlowTheme.of(context).primary,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select';
    return dateTimeFormat('MMM d, y', date);
  }

  Future<void> _selectStartDate() async {
    debugPrint('🎯 FoCoMap: Opening start date picker...');
    final date = await showDatePicker(
      context: context,
      initialDate: _model.filterStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: _model.filterEndDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlutterFlowTheme.of(context).primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      // Normalize date to start of day for proper comparison
      final normalizedDate = DateTime(date.year, date.month, date.day);
      debugPrint('✅ FoCoMap: Start date selected: $normalizedDate');
      setState(() {
        _model.filterStartDate = normalizedDate;
        _model.setDateRange(normalizedDate, _model.filterEndDate);
      });
      // Refresh map immediately
      _refreshMapData();
    } else {
      debugPrint('⚠️ FoCoMap: Start date selection cancelled');
    }
  }

  Future<void> _selectEndDate() async {
    debugPrint('🎯 FoCoMap: Opening end date picker...');
    final date = await showDatePicker(
      context: context,
      initialDate: _model.filterEndDate ?? DateTime.now(),
      firstDate: _model.filterStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: FlutterFlowTheme.of(context).primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      // Normalize date to end of day for proper comparison
      final normalizedDate =
          DateTime(date.year, date.month, date.day, 23, 59, 59);
      debugPrint('✅ FoCoMap: End date selected: $normalizedDate');
      setState(() {
        _model.filterEndDate = normalizedDate;
        _model.setDateRange(_model.filterStartDate, normalizedDate);
      });
      // Refresh map immediately
      _refreshMapData();
    } else {
      debugPrint('⚠️ FoCoMap: End date selection cancelled');
    }
  }

  void _refreshMapData() {
    debugPrint('🎯 FoCoMap: Refreshing map data...');
    _loadMapData();
    _updateMarkers();
    debugPrint('✅ FoCoMap: Map data refreshed');
  }

  /// Update map markers from real data
  Future<void> _updateMarkers() async {
    debugPrint('🎯 FoCoMap: Updating markers...');
    markers.clear();

    try {
      // Handle layer-based display first
      switch (_model.selectedLayer) {
        case 'MindMap':
          debugPrint('🎯 FoCoMap: Adding MindMap markers...');
          await _addMindMapMarkers();
          break;
        case 'ShotMap':
          debugPrint('🎯 FoCoMap: Adding ShotMap markers...');
          await _addShotMapMarkers();
          break;
        case 'SyncMap':
          debugPrint('🎯 FoCoMap: Adding SyncMap markers...');
          await _addSyncMapMarkers();
          break;
        default:
          // Default to showing all data types based on filters
          debugPrint('🎯 FoCoMap: Adding filtered markers (all types)...');
          await _addFilteredMarkers();
          break;
      }

      setState(() {});
      debugPrint('✅ FoCoMap: Updated ${markers.length} markers on map');

      // Auto-zoom to fit all markers when markers are loaded
      if (markers.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _zoomToFitAllMarkers();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ FoCoMap: Error updating markers: $e');
    }
  }

  /// Add markers based on current filters (new unified approach)
  Future<void> _addFilteredMarkers() async {
    debugPrint('🎯 FoCoMap: Adding filtered markers...');
    final Set<MapMarker> newMarkers = {};

    // Get data from live service
    final roundLogs = _liveService.cachedRoundLogs;
    final shotLogs = _liveService.cachedShotLogs;
    final golfRounds = _liveService.cachedGolfRounds;
    final scorecards = _liveService.cachedScorecards;

    debugPrint(
        '🎯 FoCoMap: Data counts - RoundLogs: ${roundLogs.length}, ShotLogs: ${shotLogs.length}, GolfRounds: ${golfRounds.length}, Scorecards: ${scorecards.length}, Activities: ${_activityRecords.length}');

    // Add round log markers
    for (final roundLog in roundLogs) {
      if (!_model.showRoundLogs) continue;

      if (roundLog.coordinates != null && _shouldIncludeByDate(roundLog.date)) {
        final marker = await _createRoundLogMarker(roundLog);
        if (marker != null) newMarkers.add(marker);
      }
    }

    // Add shot log markers
    for (final shotLog in shotLogs) {
      if (!_model.showShotLogs) continue;

      if (shotLog.coordinates != null &&
          _shouldIncludeByDate(shotLog.timestamp)) {
        final marker = await _createShotLogMarker(shotLog);
        if (marker != null) newMarkers.add(marker);
      }
    }

    // Add golf round markers (need to find matching round logs for coordinates)
    for (final golfRound in golfRounds) {
      if (!_model.showGolfRounds) continue;

      final matchingRoundLog = roundLogs
          .where((roundLog) =>
              roundLog.date?.day == golfRound.date?.day &&
              roundLog.date?.month == golfRound.date?.month &&
              roundLog.date?.year == golfRound.date?.year)
          .firstOrNull;

      if (matchingRoundLog?.coordinates != null &&
          _shouldIncludeByDate(golfRound.date)) {
        final marker =
            await _createGolfRoundMarker(golfRound, matchingRoundLog!);
        if (marker != null) newMarkers.add(marker);
      }
    }

    // Add scorecard markers (need to find matching round logs for coordinates)
    for (final scorecard in scorecards) {
      if (!_model.showScorecards) continue;

      final matchingRoundLog = roundLogs
          .where((roundLog) => roundLog.roundId == scorecard.roundId)
          .firstOrNull;

      if (matchingRoundLog?.coordinates != null &&
          _shouldIncludeByDate(scorecard.roundDate)) {
        final marker =
            await _createScorecardMarker(scorecard, matchingRoundLog!);
        if (marker != null) newMarkers.add(marker);
      }
    }

    // Add activity markers
    for (final activity in _activityRecords) {
      // Activities don't have direct coordinates, try to match with round logs
      final matchingRoundLog = roundLogs
          .where((roundLog) =>
              roundLog.courseName == activity.courseName &&
              roundLog.date != null &&
              activity.activityDate != null &&
              roundLog.date!.day == activity.activityDate!.day &&
              roundLog.date!.month == activity.activityDate!.month &&
              roundLog.date!.year == activity.activityDate!.year)
          .firstOrNull;

      if (matchingRoundLog?.coordinates != null &&
          _shouldIncludeByDate(activity.activityDate)) {
        final marker = await _createActivityMarker(activity, matchingRoundLog!);
        if (marker != null) newMarkers.add(marker);
      }
    }

    // Apply clustering if needed
    final clusteredMarkers = _shouldClusterMarkers(newMarkers)
        ? await _applyMarkerClustering(newMarkers)
        : newMarkers;

    markers.addAll(clusteredMarkers);
  }

  /// Add markers for MindMap layer (mental focus)
  Future<void> _addMindMapMarkers() async {
    for (final round in _model.getFilteredRoundLogs()) {
      if (round.coordinates == null) continue;

      final isSelected = _model.selectedMarkerId == 'round_${round.roundId}';
      final customIcon = await FoCoMapCustomMarkers.createRoundLogMarker(
        round: round,
        isSelected: isSelected,
      );

      markers.add(
        MapMarker(
          markerId: 'round_${round.roundId}',
          position: round.coordinates!,
          icon: customIcon,
          infoWindow: InfoWindow(
            title: '${round.overallMindsetEmoji} ${round.courseName}',
            snippet: round.bestCue.isNotEmpty
                ? round.bestCue
                : 'Mental: ${_calculateAverageMindset(round)}/10',
          ),
        ),
      );
    }
  }

  /// Add markers for ShotMap layer (technical focus)
  Future<void> _addShotMapMarkers() async {
    for (final shot in _model.getFilteredShotLogs()) {
      if (shot.coordinates == null) continue;

      final isSelected = _model.selectedMarkerId == 'shot_${shot.shotId}';
      final customIcon = await FoCoMapCustomMarkers.createShotLogMarker(
        shot: shot,
        isSelected: isSelected,
      );

      markers.add(
        MapMarker(
          markerId: 'shot_${shot.shotId}',
          position: shot.coordinates!,
          icon: customIcon,
          infoWindow: InfoWindow(
            title:
                '${shot.clubIcon.isNotEmpty ? shot.clubIcon : '🏌️'} ${shot.clubUsed} - Hole ${shot.holeNumber}',
            snippet: shot.cueUsed.isNotEmpty
                ? '${shot.cueUsed} • ${shot.shotOutcome}'
                : '${shot.shotOutcome} • Confidence: ${shot.confidenceLevel}/10',
          ),
        ),
      );
    }
  }

  /// Add markers for SyncMap layer (combined view)
  Future<void> _addSyncMapMarkers() async {
    // Combine round and shot data for synchronized view
    final Map<String, RoundLogsRecord> roundsMap = {
      for (final round in _model.getFilteredRoundLogs()) round.roundId: round
    };

    for (final shot in _model.getFilteredShotLogs()) {
      if (shot.coordinates == null) continue;

      final round = roundsMap[shot.roundId];
      if (round == null) continue;

      // Use round log marker with shot info overlay
      final isSelected = _model.selectedMarkerId == 'sync_${shot.shotId}';
      final customIcon = await FoCoMapCustomMarkers.createRoundLogMarker(
        round: round,
        isSelected: isSelected,
      );

      markers.add(
        MapMarker(
          markerId: 'sync_${shot.shotId}',
          position: shot.coordinates!,
          icon: customIcon,
          infoWindow: InfoWindow(
            title: '${round.overallMindsetEmoji} ${round.courseName}',
            snippet: shot.cueUsed.isNotEmpty
                ? '${shot.cueUsed} • ${shot.shotOutcome}'
                : 'Mental: ${round.overallMindsetEmoji} • ${shot.shotOutcome}',
          ),
        ),
      );
    }
  }

  /// Check if data should be included based on date filters
  bool _shouldIncludeByDate(DateTime? date) {
    if (date == null) return false;

    // Normalize dates to day level for proper comparison
    final dataDate = DateTime(date.year, date.month, date.day);

    if (_model.filterStartDate != null) {
      final startDate = DateTime(
        _model.filterStartDate!.year,
        _model.filterStartDate!.month,
        _model.filterStartDate!.day,
      );
      if (dataDate.isBefore(startDate)) {
        debugPrint(
            '🔍 FoCoMap: Filtering out date $dataDate (before start: $startDate)');
        return false;
      }
    }

    if (_model.filterEndDate != null) {
      final endDate = DateTime(
        _model.filterEndDate!.year,
        _model.filterEndDate!.month,
        _model.filterEndDate!.day,
      );
      if (dataDate.isAfter(endDate)) {
        debugPrint(
            '🔍 FoCoMap: Filtering out date $dataDate (after end: $endDate)');
        return false;
      }
    }

    return true;
  }

  /// Create a map marker for a round log
  Future<MapMarker?> _createRoundLogMarker(RoundLogsRecord roundLog) async {
    try {
      final icon = await FoCoMapCustomMarkers.createRoundLogMarker(
        round: roundLog,
        isSelected: false,
      );

      return MapMarker(
        markerId: 'round_log_${roundLog.roundId}',
        position: LatLng(
          roundLog.coordinates!.latitude,
          roundLog.coordinates!.longitude,
        ),
        icon: icon,
        infoWindow: InfoWindow(
          title: '${roundLog.overallMindsetEmoji} ${roundLog.courseName}',
          snippet: roundLog.bestCue.isNotEmpty
              ? '${roundLog.bestCue} • ${dateTimeFormat('MMM d', roundLog.date)}'
              : 'Mental: ${_calculateAverageMindset(roundLog)}/10 • ${dateTimeFormat('MMM d', roundLog.date)}',
        ),
      );
    } catch (e) {
      debugPrint('Error creating round log marker: $e');
      return null;
    }
  }

  /// Create a map marker for a shot log
  Future<MapMarker?> _createShotLogMarker(ShotLogsRecord shotLog) async {
    try {
      final icon = await FoCoMapCustomMarkers.createShotLogMarker(
        shot: shotLog,
        isSelected: false,
      );

      return MapMarker(
        markerId: 'shot_log_${shotLog.shotId}',
        position: LatLng(
          shotLog.coordinates!.latitude,
          shotLog.coordinates!.longitude,
        ),
        icon: icon,
        infoWindow: InfoWindow(
          title:
              '${shotLog.clubIcon.isNotEmpty ? shotLog.clubIcon : '🏌️'} ${shotLog.clubUsed} - Hole ${shotLog.holeNumber}',
          snippet: shotLog.cueUsed.isNotEmpty
              ? '${shotLog.cueUsed} • ${shotLog.shotOutcome}'
              : '${shotLog.shotOutcome} • Confidence: ${shotLog.confidenceLevel}/10',
        ),
      );
    } catch (e) {
      debugPrint('Error creating shot log marker: $e');
      return null;
    }
  }

  /// Create a map marker for a golf round (requires round log for coordinates)
  Future<MapMarker?> _createGolfRoundMarker(
      GolfRoundsRecord golfRound, RoundLogsRecord roundLog) async {
    try {
      final icon = await FoCoMapCustomMarkers.createGolfRoundMarker(
        round: golfRound,
        isSelected: false,
      );

      return MapMarker(
        markerId: 'golf_round_${golfRound.reference.id}',
        position: LatLng(
          roundLog.coordinates!.latitude,
          roundLog.coordinates!.longitude,
        ),
        icon: icon,
        infoWindow: InfoWindow(
          title: '⛳ ${golfRound.courseName}',
          snippet:
              'Score: ${golfRound.score} (${_getScoreToPar(golfRound)}) • ${dateTimeFormat('MMM d', golfRound.date)}',
        ),
      );
    } catch (e) {
      debugPrint('Error creating golf round marker: $e');
      return null;
    }
  }

  /// Create a map marker for a scorecard (requires round log for coordinates)
  Future<MapMarker?> _createScorecardMarker(
      ScorecardRecord scorecard, RoundLogsRecord roundLog) async {
    try {
      final icon = await FoCoMapCustomMarkers.createScorecardMarker(
        scorecard: scorecard,
        isSelected: false,
      );

      return MapMarker(
        markerId: 'scorecard_${scorecard.reference.id}',
        position: LatLng(
          roundLog.coordinates!.latitude,
          roundLog.coordinates!.longitude,
        ),
        icon: icon,
        infoWindow: InfoWindow(
          title: '📋 ${scorecard.courseName}',
          snippet: scorecard.scoreDifferential.isNotEmpty
              ? 'Score: ${scorecard.totalScore} • Diff: ${scorecard.scoreDifferential}'
              : 'Score: ${scorecard.totalScore}',
        ),
      );
    } catch (e) {
      debugPrint('❌ FoCoMap: Error creating scorecard marker: $e');
      return null;
    }
  }

  /// Create a map marker for an activity
  Future<MapMarker?> _createActivityMarker(
      ActivityRecord activity, RoundLogsRecord roundLog) async {
    try {
      // Use round log marker style for activities
      final icon = await FoCoMapCustomMarkers.createRoundLogMarker(
        round: roundLog,
        isSelected: false,
      );

      return MapMarker(
        markerId: 'activity_${activity.reference.id}',
        position: LatLng(
          roundLog.coordinates!.latitude,
          roundLog.coordinates!.longitude,
        ),
        icon: icon,
        infoWindow: InfoWindow(
          title: activity.title.isNotEmpty
              ? '📊 ${activity.title}'
              : '📊 Activity',
          snippet: activity.subtitle.isNotEmpty
              ? activity.subtitle
              : 'Score: ${activity.score}',
        ),
      );
    } catch (e) {
      debugPrint('❌ FoCoMap: Error creating activity marker: $e');
      return null;
    }
  }

  /// Apply marker clustering if there are too many markers
  Future<Set<MapMarker>> _applyMarkerClustering(Set<MapMarker> markers) async {
    // Use AI service for intelligent clustering
    final clusters = await _aiService.clusterMarkers(
      markers: markers.toList(),
      zoomLevel: _currentZoom,
    );
    final Set<MapMarker> clusteredMarkers = {};

    for (final cluster in clusters) {
      if (cluster.markers.length == 1) {
        // Single marker, add as-is
        clusteredMarkers.add(cluster.markers.first);
      } else {
        // Create cluster marker
        final clusterIcon = await FoCoMapCustomMarkers.createClusterMarker(
          count: cluster.markers.length,
          primaryType: MarkerType.cluster,
          isSelected: false,
        );

        clusteredMarkers.add(MapMarker(
          markerId:
              'cluster_${cluster.center.latitude}_${cluster.center.longitude}',
          position: cluster.center,
          icon: clusterIcon,
          infoWindow: InfoWindow(
            title: '${cluster.markers.length} Golf Records',
            snippet: 'Tap to zoom in and see individual markers',
          ),
        ));
      }
    }

    return clusteredMarkers;
  }

  /// Check if markers should be clustered based on zoom level and count
  bool _shouldClusterMarkers(Set<MapMarker> markers) {
    return markers.length > 50 && _currentZoom < 16.0;
  }

  /// Calculate average mindset from round log
  int _calculateAverageMindset(RoundLogsRecord roundLog) {
    final focus = roundLog.mindsetFocus;
    final confidence = roundLog.mindsetConfidence;
    final control = roundLog.mindsetControl;
    return ((focus + confidence + control) / 3).round();
  }

  /// Get score to par string
  String _getScoreToPar(GolfRoundsRecord golfRound) {
    return golfRound.scoreToPar > 0
        ? '+${golfRound.scoreToPar}'
        : '${golfRound.scoreToPar}';
  }

  /// Generate real-time guidance using Robotics-ER 1.5 and embeddings
  Future<void> _generateRealtimeGuidance() async {
    try {
      // Get recent activity
      final recentRounds = _liveService.cachedRoundLogs.take(5).toList();
      final recentShots = _liveService.cachedShotLogs.take(10).toList();

      if (recentRounds.isEmpty && recentShots.isEmpty) {
        return; // No data to analyze
      }

      debugPrint('🎯 FoCoMap: Generating real-time guidance...');

      final mapContext = {
        'totalRounds': _liveService.cachedRoundLogs.length,
        'totalShots': _liveService.cachedShotLogs.length,
        'userTier': _liveService.userTier.name,
        'isLiveMode': _model.isLiveMode,
      };

      await _aiService.generateRealtimeGuidance(
        recentRounds: recentRounds,
        recentShots: recentShots,
        currentPosition: currentLocation,
        mapContext: mapContext,
      );

      debugPrint('✅ FoCoMap: Real-time guidance generated');
    } catch (e) {
      debugPrint('❌ FoCoMap: Error generating guidance: $e');
    }
  }

  /// Handle real-time guidance from AI service
  void _handleRealtimeGuidance(RealtimeGuidance guidance) {
    if (!mounted || guidance.isEmpty) return;

    // Show immediate guidance as tooltip
    if (guidance.immediateGuidance.isNotEmpty) {
      _showAITooltip(guidance.immediateGuidance, Colors.blue);
    }

    // Show actionable tip separately if different from guidance
    if (guidance.actionableTip.isNotEmpty &&
        guidance.actionableTip != guidance.immediateGuidance) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _showAITooltip('💡 Tip: ${guidance.actionableTip}', Colors.green);
        }
      });
    }

    // Show spatial insight if available
    if (guidance.spatialInsight.isNotEmpty) {
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) {
          _showAITooltip('📍 ${guidance.spatialInsight}', Colors.orange);
        }
      });
    }

    // Also show notification
    _showLiveUpdateNotification(
      guidance.immediateGuidance.isNotEmpty
          ? guidance.immediateGuidance
          : guidance.actionableTip,
      Colors.blue,
    );
  }

  Future<void> _loadMapData() async {
    debugPrint('🎯 FoCoMap: Loading map data...');

    if (currentUser == null) {
      debugPrint('⚠️ FoCoMap: No authenticated user, skipping data load');
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
      debugPrint('🎯 FoCoMap: User authenticated: ${currentUser!.uid}');

      // Always refresh data - no tier restrictions for viewing
      debugPrint('🎯 FoCoMap: Refreshing data from Firestore...');
      await _liveService.refreshData();

      debugPrint(
          '🎯 FoCoMap: Data refreshed - RoundLogs: ${_liveService.cachedRoundLogs.length}, ShotLogs: ${_liveService.cachedShotLogs.length}, GolfRounds: ${_liveService.cachedGolfRounds.length}, Scorecards: ${_liveService.cachedScorecards.length}');

      // Update markers from loaded data
      await _updateMarkers();

      // Generate real-time guidance based on last activity
      final hasRecentData = _liveService.cachedRoundLogs.isNotEmpty ||
          _liveService.cachedShotLogs.isNotEmpty;
      if (hasRecentData) {
        _generateRealtimeGuidance();
      }

      // Zoom to fit all markers after loading (always, not just when empty)
      if (markers.isNotEmpty) {
        // Small delay to ensure markers are rendered
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _zoomToFitAllMarkers();
          }
        });
      } else {
        // If no markers, keep current location view
        debugPrint('⚠️ FoCoMap: No markers found to display');
      }

      debugPrint('✅ FoCoMap: Map data loaded successfully');
    } catch (e) {
      debugPrint('❌ FoCoMap: Error loading map data: $e');
      // Handle specific Firestore permission errors
      if (e.toString().contains('permission-denied')) {
        debugPrint('❌ FoCoMap: Permission denied error');
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

  /// Show custom glass sheet to log round
  void _showLogRoundSheet() {
    debugPrint('🎯 FoCoMap: Showing log round sheet...');
    final theme = FlutterFlowTheme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => GolfRoundModalGrintStyle(theme: theme),
    );
  }

  // Handle marker tap to show details
  void _handleMarkerTap(MapMarker marker) {
    final markerId = marker.markerId;

    if (markerId.startsWith('round_log_')) {
      final roundId = markerId.substring(10); // Remove 'round_log_' prefix
      final roundLog = _model.roundLogs.firstWhere(
        (log) => log.roundId == roundId,
        orElse: () => throw Exception('Round log not found'),
      );
      _showRoundDetail(roundLog);
    } else if (markerId.startsWith('shot_log_')) {
      final shotId = markerId.substring(9); // Remove 'shot_log_' prefix
      final shotLog = _model.shotLogs.firstWhere(
        (log) => log.shotId == shotId,
        orElse: () => throw Exception('Shot log not found'),
      );
      _showShotDetail(shotLog);
    } else if (markerId.startsWith('golf_round_')) {
      final roundId = markerId.substring(11); // Remove 'golf_round_' prefix
      final golfRound = _model.golfRounds.firstWhere(
        (round) => round.reference.id == roundId,
        orElse: () => throw Exception('Golf round not found'),
      );
      _showGolfRoundDetail(golfRound);
    } else if (markerId.startsWith('scorecard_')) {
      final roundId = markerId.substring(10); // Remove 'scorecard_' prefix
      final scorecard = _model.scorecards.firstWhere(
        (card) => card.reference.id == roundId,
        orElse: () => throw Exception('Scorecard not found'),
      );
      _showScorecardDetail(scorecard);
    }
  }

  // Show golf round details
  void _showGolfRoundDetail(GolfRoundsRecord golfRound) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => GlassDesignSystem.glassBackground(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        tintColor: _getGlassColorForTheme(),
        opacity: _getGlassOpacityForTheme(),
        blur: 20,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getScoreColor(golfRound.scoreToPar)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⛳',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          golfRound.courseName.isNotEmpty
                              ? golfRound.courseName
                              : 'Unknown Course',
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                        ),
                        Text(
                          golfRound.date != null
                              ? dateTimeFormat('EEEE, MMM d, y', golfRound.date)
                              : 'Unknown Date',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Score Card
              GlassDesignSystem.glass3DCard(
                padding: const EdgeInsets.all(20),
                tintColor: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${golfRound.score}',
                          style: FlutterFlowTheme.of(context)
                              .headlineLarge
                              .override(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                        ),
                        Text(
                          'Score',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Column(
                      children: [
                        Text(
                          golfRound.scoreToPar > 0
                              ? '+${golfRound.scoreToPar}'
                              : golfRound.scoreToPar == 0
                                  ? 'E'
                                  : '${golfRound.scoreToPar}',
                          style: FlutterFlowTheme.of(context)
                              .headlineLarge
                              .override(
                                color: _getScoreColor(golfRound.scoreToPar),
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                        ),
                        Text(
                          'To Par',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int scoreToPar) {
    if (scoreToPar < -2) return Colors.purple;
    if (scoreToPar < 0) return Colors.blue;
    if (scoreToPar == 0) return Colors.green;
    if (scoreToPar <= 2) return Colors.orange;
    return Colors.red;
  }

  // Show scorecard details
  void _showScorecardDetail(ScorecardRecord scorecard) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => GlassDesignSystem.glassBackground(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        tintColor: _getGlassColorForTheme(),
        opacity: _getGlassOpacityForTheme(),
        blur: 20,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '📋',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scorecard',
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                        ),
                        Text(
                          scorecard.courseName.isNotEmpty
                              ? scorecard.courseName
                              : 'Unknown Course',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Score Card
              GlassDesignSystem.glass3DCard(
                padding: const EdgeInsets.all(20),
                tintColor: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${scorecard.totalScore}',
                              style: FlutterFlowTheme.of(context)
                                  .headlineLarge
                                  .override(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                            ),
                            Text(
                              'Total Score',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                            ),
                          ],
                        ),
                        if (scorecard.scoreDifferential.isNotEmpty) ...[
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          Column(
                            children: [
                              Text(
                                scorecard.scoreDifferential,
                                style: FlutterFlowTheme.of(context)
                                    .headlineLarge
                                    .override(
                                      color: Colors.indigo.shade300,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                              ),
                              Text(
                                'Differential',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      height: 1.0,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoundDetail(RoundLogsRecord round) {
    _model.selectMarker('round_${round.roundId}');
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => GlassDesignSystem.glassBackground(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        tintColor: _getGlassColorForTheme(),
        opacity: _getGlassOpacityForTheme(),
        blur: 20,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with emoji and course name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getMindsetColor(round.mindsetColor)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      round.overallMindsetEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          round.courseName,
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                        ),
                        Text(
                          dateTimeFormat('EEEE, MMM d, y', round.date),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _model.clearMarkerSelection();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Mental Performance Scores
              GlassDesignSystem.glass3DCard(
                padding: const EdgeInsets.all(16),
                tintColor: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mental Performance',
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreCard(
                              'Focus', round.mindsetFocus, Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildScoreCard('Confidence',
                              round.mindsetConfidence, Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildScoreCard(
                              'Control', round.mindsetControl, Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Best Cue
              if (round.bestCue.isNotEmpty)
                GlassDesignSystem.glass3DCard(
                  padding: const EdgeInsets.all(16),
                  tintColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb,
                              color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Best Cue',
                            style: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .override(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        round.bestCue,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.2,
                            ),
                      ),
                    ],
                  ),
                ),

              // Recovery Holes
              if (round.recoveryHoles.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassDesignSystem.glass3DCard(
                  padding: const EdgeInsets.all(16),
                  tintColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.refresh,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Recovery Holes',
                            style: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .override(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: round.recoveryHoles.map((hole) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'Hole $hole',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              // AI Insights
              if (round.aiRoundSummary.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassDesignSystem.glass3DCard(
                  padding: const EdgeInsets.all(16),
                  tintColor: Colors.blue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI Insights',
                            style: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .override(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        round.aiRoundSummary,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.0,
                ),
          ),
        ],
      ),
    );
  }

  Color _getMindsetColor(String color) {
    switch (color.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showShotDetail(ShotLogsRecord shot) {
    _model.selectMarker('shot_${shot.shotId}');
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => GlassDesignSystem.glassBackground(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        tintColor: _getGlassColorForTheme(),
        opacity: _getGlassOpacityForTheme(),
        blur: 20,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _getClubColor(shot.clubUsed).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      shot.clubIcon.isNotEmpty ? shot.clubIcon : '🏌️',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${shot.clubUsed} - Hole ${shot.holeNumber}',
                          style: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .override(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                        ),
                        Text(
                          '${shot.distanceAttempted.toInt()} yards',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _model.clearMarkerSelection();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Shot Details Grid
              Row(
                children: [
                  Expanded(
                    child: GlassDesignSystem.glass3DCard(
                      padding: const EdgeInsets.all(12),
                      tintColor: Colors.white,
                      child: Column(
                        children: [
                          Text(
                            'Outcome',
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.0,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shot.shotOutcome,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassDesignSystem.glass3DCard(
                      padding: const EdgeInsets.all(12),
                      tintColor: Colors.white,
                      child: Column(
                        children: [
                          Text(
                            'Shape',
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.0,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shot.shotShape,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassDesignSystem.glass3DCard(
                      padding: const EdgeInsets.all(12),
                      tintColor: Colors.white,
                      child: Column(
                        children: [
                          Text(
                            'Confidence',
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.0,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${shot.confidenceLevel}/10',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Cue Used
              if (shot.cueUsed.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassDesignSystem.glass3DCard(
                  padding: const EdgeInsets.all(16),
                  tintColor: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.psychology,
                          color: Colors.purple, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mental Cue',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                            ),
                            Text(
                              shot.cueUsed,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Conditions
              if (shot.windCondition.isNotEmpty ||
                  shot.shotTrend.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassDesignSystem.glass3DCard(
                  padding: const EdgeInsets.all(16),
                  tintColor: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shot.windCondition.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.air, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Wind: ${shot.windCondition}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.0,
                                  ),
                            ),
                          ],
                        ),
                        if (shot.shotTrend.isNotEmpty)
                          const SizedBox(height: 8),
                      ],
                      if (shot.shotTrend.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.trending_up,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Trend: ${shot.shotTrend}',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.0,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],

              // AI Insight
              if (shot.aiShotInsight.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassDesignSystem.glass3DCard(
                  padding: const EdgeInsets.all(16),
                  tintColor: Colors.blue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI Tip',
                            style: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .override(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shot.aiShotInsight,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Color _getClubColor(String club) {
    final clubLower = club.toLowerCase();
    if (clubLower.contains('driver')) return Colors.red;
    if (clubLower.contains('wood')) return Colors.orange;
    if (clubLower.contains('iron')) return Colors.blue;
    if (clubLower.contains('wedge')) return Colors.purple;
    if (clubLower.contains('putter')) return Colors.green;
    return Colors.grey;
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
              child: _useAdvancedView
                  ? AdvancedMapView(
                      key: _advancedMapKey,
                      markers: markers.toList(),
                      initialLocation: currentLocation,
                      mapType: currentMapType,
                      viewMode: _currentViewMode,
                      onMarkerTap: (marker) {
                        _handleMarkerTap(marker);
                      },
                      onMapTap: (position) {
                        // Handle map tap if needed
                      },
                      heatmapData: _heatmapData,
                      trajectoryData: _trajectoryData,
                      enable3D: true,
                      enableAR: _liveService.userTier == UserTier.prime,
                    )
                  : PlatformMapWidget(
                      key: _platformMapKey,
                      markers: markers,
                      initialLocation: currentLocation,
                      initialZoom: _currentZoom,
                      mapType: currentMapType,
                      onMarkerTap: (marker) {
                        _handleMarkerTap(marker);
                      },
                      onMapTap: (position) {
                        // Handle map tap if needed
                      },
                      onZoomChanged: (zoom) {
                        // Update zoom state when user zooms
                        if (mounted) {
                          setState(() {
                            _currentZoom = zoom;
                          });
                        }
                      },
                    ),
            ),

            // Glass Navigation Bar (Top) - Conditionally shown based on live session mode
            if (!_isLiveSession ||
                _model
                    .isLiveMode) // Show if not in live session OR show minimal controls in live mode
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    child: GlassDesignSystem.glassBackground(
                      borderRadius: BorderRadius.circular(20),
                      tintColor: _getGlassColorForTheme(),
                      opacity: _getGlassOpacityForTheme(),
                      blur: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            // Back Button
                            GestureDetector(
                              key: _backButtonKey,
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
                                key: _titleKey,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'FoCoMap',
                                      style: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .override(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                      overflow: TextOverflow.ellipsis,
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
                              key: _mapTypeKey,
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

                            // Advanced View Toggle
                            if (_liveService.userTier == UserTier.prime)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _useAdvancedView = !_useAdvancedView;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _useAdvancedView
                                        ? Colors.blue.withValues(alpha: 0.8)
                                        : Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _useAdvancedView
                                        ? Icons.view_in_ar
                                        : Icons.map,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),

                            const SizedBox(width: 8),

                            // Live Mode Toggle
                            GestureDetector(
                              key: _liveToggleKey,
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
                              key: _filtersKey,
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

            // Zoom to Fit All Markers Button (Bottom Right - Above Location Button)
            if (markers.isNotEmpty)
              Positioned(
                bottom: 300,
                right: 20,
                child: SafeArea(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _zoomToFitAllMarkers();
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.9),
                          ),
                          child: const Icon(
                            Icons.fit_screen,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Floating Location Toggle Button (Bottom Right - Above Microphone) - Green Circle
            Positioned(
              bottom: 240,
              right: 20,
              child: SafeArea(
                child: Container(
                  key: _locationPanelKey,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlutterFlowTheme.of(context).tertiary, // Green
                    boxShadow: [
                      BoxShadow(
                        color: FlutterFlowTheme.of(context)
                            .tertiary
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        // Refocus map to current location
                        debugPrint(
                            '🎯 FoCoMap: Location button tapped - refocusing to current location');
                        try {
                          // Get current location
                          final position = _locationService.currentLocation;
                          if (position != null) {
                            setState(() {
                              currentLocation = position;
                              _currentZoom = 18.0; // Close zoom for focus mode
                            });

                            // Animate map to location if controllers are available
                            if (!_useAdvancedView) {
                              await PlatformMapWidget.animateToLocationFromKey(
                                _platformMapKey,
                                position,
                                zoom: 18.0,
                              );
                            }

                            debugPrint(
                                '✅ FoCoMap: Map refocused to current location');
                          } else {
                            // Try to get fresh location
                            await _getCurrentLocation();
                            if (currentLocation != null) {
                              setState(() {
                                _currentZoom = 18.0;
                              });
                              if (!_useAdvancedView) {
                                await PlatformMapWidget
                                    .animateToLocationFromKey(
                                  _platformMapKey,
                                  currentLocation!,
                                  zoom: 18.0,
                                );
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint('❌ FoCoMap: Error refocusing map: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _model.isLiveMode
                              ? FlutterFlowTheme.of(context).tertiary
                              : FlutterFlowTheme.of(context)
                                  .tertiary
                                  .withValues(alpha: 0.7),
                        ),
                        child: Icon(
                          _model.isLiveMode
                              ? Icons.my_location
                              : Icons.location_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
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
                  child: Container(
                    key: _scorePanelKey,
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
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
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
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
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
              ),

            // Glass Layer Selection (Bottom) - Moved lower
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: GlassDesignSystem.glassBackground(
                borderRadius: BorderRadius.circular(20),
                tintColor: _getGlassColorForTheme(),
                opacity: _getGlassOpacityForTheme(),
                blur: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildGlassLayerButton('MindMap', 'MindMap',
                            Icons.psychology, _layerMindMapKey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassLayerButton('ShotMap', 'ShotMap',
                            Icons.golf_course, _layerShotMapKey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassLayerButton(
                            'SyncMap', 'SyncMap', Icons.sync, _layerSyncMapKey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating Microphone Toggle Button (Bottom Right - Above Add Button) - Orange Circle
            Positioned(
              bottom: 190,
              right: 20,
              child: SafeArea(
                child: StreamBuilder<bool>(
                  stream: _voiceService.listeningStream,
                  builder: (context, listeningSnapshot) {
                    final isListening = listeningSnapshot.data ?? false;

                    return AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isListening ? _pulseAnimation.value : 1.0,
                          child: Container(
                            key: _voiceButtonKey,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: FlutterFlowTheme.of(context)
                                  .primary, // Orange
                              boxShadow: [
                                BoxShadow(
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleVoiceButtonTap,
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isListening
                                        ? Colors.red
                                        : FlutterFlowTheme.of(context).primary,
                                  ),
                                  child: Icon(
                                    isListening ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Add Round Button (Bottom Right - Next to Microphone) - Shows log round sheet
            Positioned(
              bottom: 120,
              right: 20,
              child: SafeArea(
                child: Container(
                  key: _addDataKey,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlutterFlowTheme.of(context).primary,
                    boxShadow: [
                      BoxShadow(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showLogRoundSheet,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Enhanced Live Mode Indicator with Animation - Near Header (Top Right)
            if (_model.isLiveMode)
              Positioned(
                top: 100,
                right: 180,
                child: SafeArea(
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
                            key: _liveIndicatorKey,
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
              ),
          ],
        ),
      ),
    );
  }

  // Enhanced methods for real-time experience
  Future<void> _toggleLiveMode() async {
    debugPrint('🎯 FoCoMap: Toggling live mode...');
    HapticFeedback.mediumImpact();

    // Remove tier restriction - play mode is available to all users
    try {
      if (_model.isLiveMode) {
        debugPrint('🎯 FoCoMap: Stopping live session...');
        // Stop live session
        await _stopLiveSession();
        await _liveService.stopLiveMode();
        await _locationService.stopTracking();
        _model.setLiveMode(false);
        _showLiveUpdateNotification('Live golf session ended', Colors.orange);
        debugPrint('✅ FoCoMap: Live session stopped');
      } else {
        debugPrint('🎯 FoCoMap: Starting live session...');
        // Start live session with enhanced features
        await _startLiveSession();

        // Zoom to user location for play mode
        if (currentLocation != null) {
          debugPrint(
              '🎯 FoCoMap: Zooming to user location: ${currentLocation!.latitude}, ${currentLocation!.longitude}');
          setState(() {
            _currentZoom = 18.0; // Close zoom for play mode
          });
        }

        await _locationService.startTracking();
        _model.setLiveMode(true);
        _showLiveUpdateNotification(
            '🏌️ Live golf session started!', Colors.green);
        debugPrint('✅ FoCoMap: Live session started');

        // Show live mode tutorial if first time
        final hasSeenIntro = await _tutorialService.hasSeenLiveModeIntro();
        if (!hasSeenIntro) {
          // Delay to let live mode UI appear
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _startLiveModeTutorial();
          });
        }
      }

      // Update state for UI changes
      setState(() {
        _isLiveSession = _model.isLiveMode;
      });
    } catch (e) {
      debugPrint('❌ FoCoMap: Error toggling live mode: $e');
      _showLiveUpdateNotification('Error toggling live mode: $e', Colors.red);
    }
  }

  Future<void> _handleVoiceButtonTap() async {
    HapticFeedback.mediumImpact();

    try {
      if (_voiceService.isListening) {
        await _voiceService.stopListening();
      } else {
        // Set context based on live mode
        final context = _model.isLiveMode
            ? voice.VoiceContext.activeRound
            : voice.VoiceContext.offCourse;

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

  Widget _buildGlassLayerButton(
      String layerKey, String label, IconData icon, GlobalKey key) {
    final isSelected = _model.selectedLayer == layerKey;
    return GestureDetector(
      key: key,
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
