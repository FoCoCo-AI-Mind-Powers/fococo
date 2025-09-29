import 'package:fo_co_co/backend/schema/round_logs_record.dart';
import '/backend/schema/shot_logs_record.dart';
import '/backend/schema/golf_rounds_record.dart';
import '/backend/schema/scorecard_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/glass_design_system.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/services/focomap_voice_service.dart' as voice;
import '/services/foco_map_live_service.dart';
import '/services/live_location_service.dart';
import '/services/focomap_tutorial_service.dart';
import '/services/focomap_ai_service.dart';
import '/services/focomap_custom_markers.dart';
import 'platform_map_widget.dart';
import 'advanced_map_view.dart';
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
  MapViewMode _currentViewMode = MapViewMode.standard;
  bool _useAdvancedView = false;
  double _currentZoom = 15.0;

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

  // Animation controllers for real-time effects
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FoCoMapModel());

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

    // Initialize AI service with API key
    _aiService = FoCoMapAIService(
        apiKey: const String.fromEnvironment('GEMINI_API_KEY'));

    _getCurrentLocation();
    _initializeServices();
    _loadMapData();
    _checkAndShowTutorial();

    // Initialize custom markers
    FoCoMapCustomMarkers.initialize();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions to prevent memory leaks
    _roundLogsSubscription?.cancel();
    _shotLogsSubscription?.cancel();
    _golfRoundsSubscription?.cancel();
    _scorecardsSubscription?.cancel();
    _liveUpdateSubscription?.cancel();
    _voiceUpdateSubscription?.cancel();
    _locationSubscription?.cancel();
    _courseContextSubscription?.cancel();
    _spatialAnalysisSubscription?.cancel();
    _patternInsightSubscription?.cancel();

    // Dispose animation controllers
    _pulseController.dispose();

    // Stop live session if active
    _liveSessionTimer?.cancel();
    if (_isLiveSession) {
      _stopLiveSession();
    }

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

  Future<void> _initializeServices() async {
    try {
      // Initialize services
      await _voiceService.initialize();
      await _liveService.initialize();
      await _locationService.initialize();
      await _aiService.initialize();

      // Set up live service listeners with proper subscription management
      _roundLogsSubscription = _liveService.roundLogsStream.listen((roundLogs) {
        if (mounted) {
          setState(() {
            _model.roundLogs = roundLogs;
          });
          _updateMarkers();
          _performAIAnalysis();
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

    // Show insights notification
    if (analysis.patterns.isNotEmpty) {
      _showLiveUpdateNotification(
        'Pattern detected: ${analysis.patterns.first}',
        Colors.blue,
      );
    }
  }

  void _handlePatternInsight(PatternInsight insight) {
    if (!mounted) return;

    // Show recommendations
    if (insight.recommendations.isNotEmpty) {
      _showLiveUpdateNotification(
        insight.recommendations.first,
        Colors.green,
      );
    }

    // Update UI with trends
    if (insight.trends.isNotEmpty) {
      final trend = insight.trends.first;
      if (trend.type == 'mindset_improvement') {
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

                      // Date Range Filter
                      _buildFilterSection(
                        'Date Range',
                        Icons.date_range,
                        isDarkTheme,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDateButton(
                                'From: ${_formatDate(_model.filterStartDate)}',
                                isDarkTheme,
                                () => _selectStartDate(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDateButton(
                                'To: ${_formatDate(_model.filterEndDate)}',
                                isDarkTheme,
                                () => _selectEndDate(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Data Type Filter
                      _buildFilterSection(
                        'Data Types',
                        Icons.layers,
                        isDarkTheme,
                        child: Column(
                          children: [
                            _buildFilterToggle(
                                'Round Logs', _model.showRoundLogs, isDarkTheme,
                                (value) {
                              setState(() {
                                _model.showRoundLogs = value;
                              });
                              _refreshMapData();
                            }),
                            _buildFilterToggle(
                                'Shot Logs', _model.showShotLogs, isDarkTheme,
                                (value) {
                              setState(() {
                                _model.showShotLogs = value;
                              });
                              _refreshMapData();
                            }),
                            _buildFilterToggle('Golf Rounds',
                                _model.showGolfRounds, isDarkTheme, (value) {
                              setState(() {
                                _model.showGolfRounds = value;
                              });
                              _refreshMapData();
                            }),
                            _buildFilterToggle('Scorecards',
                                _model.showScorecards, isDarkTheme, (value) {
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
    final date = await showDatePicker(
      context: context,
      initialDate: _model.filterStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _model.filterStartDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _model.filterEndDate ?? DateTime.now(),
      firstDate: _model.filterStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _model.filterEndDate = date;
      });
    }
  }

  void _refreshMapData() {
    _loadMapData();
    _updateMarkers();
  }

  /// Update map markers from real data
  Future<void> _updateMarkers() async {
    markers.clear();

    try {
      // Handle layer-based display first
      switch (_model.selectedLayer) {
        case 'MindMap':
          await _addMindMapMarkers();
          break;
        case 'ShotMap':
          await _addShotMapMarkers();
          break;
        case 'SyncMap':
          await _addSyncMapMarkers();
          break;
        default:
          // Default to showing all data types based on filters
          await _addFilteredMarkers();
          break;
      }

      setState(() {});
      debugPrint('Updated ${markers.length} markers on map');
    } catch (e) {
      debugPrint('Error updating markers: $e');
    }
  }

  /// Add markers based on current filters (new unified approach)
  Future<void> _addFilteredMarkers() async {
    final Set<MapMarker> newMarkers = {};

    // Get data from live service
    final roundLogs = _liveService.cachedRoundLogs;
    final shotLogs = _liveService.cachedShotLogs;
    final golfRounds = _liveService.cachedGolfRounds;
    final scorecards = _liveService.cachedScorecards;

    // Add round log markers
    for (final roundLog in roundLogs) {
      if (roundLog.coordinates != null && _shouldIncludeByDate(roundLog.date)) {
        final marker = await _createRoundLogMarker(roundLog);
        if (marker != null) newMarkers.add(marker);
      }
    }

    // Add shot log markers
    for (final shotLog in shotLogs) {
      if (shotLog.coordinates != null &&
          _shouldIncludeByDate(shotLog.timestamp)) {
        final marker = await _createShotLogMarker(shotLog);
        if (marker != null) newMarkers.add(marker);
      }
    }

    // Add golf round markers (need to find matching round logs for coordinates)
    for (final golfRound in golfRounds) {
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
      final matchingRoundLog = roundLogs
          .where((roundLog) => roundLog.roundId == scorecard.roundId)
          .firstOrNull;

      if (matchingRoundLog?.coordinates != null) {
        final marker =
            await _createScorecardMarker(scorecard, matchingRoundLog!);
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
            title: round.courseName,
            snippet: '${round.overallMindsetEmoji} ${round.bestCue}',
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
            title: '${shot.clubUsed} - Hole ${shot.holeNumber}',
            snippet: '${shot.shotOutcome} | ${shot.cueUsed}',
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
            title: '${shot.clubUsed} - ${round.courseName}',
            snippet:
                'Mental: ${round.overallMindsetEmoji} | ${shot.shotOutcome}',
          ),
        ),
      );
    }
  }

  /// Check if data should be included based on date filters
  bool _shouldIncludeByDate(DateTime? date) {
    if (date == null) return false;

    if (_model.filterStartDate != null &&
        date.isBefore(_model.filterStartDate!)) {
      return false;
    }

    if (_model.filterEndDate != null && date.isAfter(_model.filterEndDate!)) {
      return false;
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
          title: '${roundLog.courseName}',
          snippet:
              '${dateTimeFormat('MMM d, y', roundLog.date)} - Mental: ${_calculateAverageMindset(roundLog)}/10',
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
          title: '${shotLog.clubUsed} - ${shotLog.shotOutcome}',
          snippet:
              'Confidence: ${shotLog.confidenceLevel}/10 - ${shotLog.distanceAttempted}y',
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
          title: '${golfRound.courseName}',
          snippet:
              'Score: ${golfRound.score} (${_getScoreToPar(golfRound)}) - ${dateTimeFormat('MMM d', golfRound.date)}',
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
          title: 'Scorecard - ${scorecard.courseName}',
          snippet: 'Score: ${scorecard.totalScore}',
        ),
      );
    } catch (e) {
      debugPrint('Error creating scorecard marker: $e');
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
    final focus = roundLog.mindsetFocus ?? 5;
    final confidence = roundLog.mindsetConfidence ?? 5;
    final control = roundLog.mindsetControl ?? 5;
    return ((focus + confidence + control) / 3).round();
  }

  /// Get score to par string
  String _getScoreToPar(GolfRoundsRecord golfRound) {
    return golfRound.scoreToPar > 0
        ? '+${golfRound.scoreToPar}'
        : '${golfRound.scoreToPar}';
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

      // Update markers from loaded data
      await _updateMarkers();
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
        'coordinates': GeoPoint(40.7128, -74.0060),
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
        'coordinates': GeoPoint(40.7130, -74.0058),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Golf Round Details',
              style: FlutterFlowTheme.of(context).headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('Course: ${golfRound.courseName ?? 'Unknown'}'),
            Text(
                'Date: ${golfRound.date != null ? dateTimeFormat("yMd", golfRound.date) : 'Unknown'}'),
            Text('Score: ${golfRound.score ?? 'N/A'}'),
            Text('Score to Par: ${golfRound.scoreToPar ?? 'N/A'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // Show scorecard details
  void _showScorecardDetail(ScorecardRecord scorecard) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scorecard Details',
              style: FlutterFlowTheme.of(context).headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('Course: ${scorecard.courseName ?? 'Unknown'}'),
            Text('Total Score: ${scorecard.totalScore ?? 'N/A'}'),
            Text(
                'Holes Completed: N/A'), // scorecard.holes property not available
            Text('Score Differential: ${scorecard.scoreDifferential ?? 'N/A'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
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
              child: _useAdvancedView
                  ? AdvancedMapView(
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

            // Glass Player Info Panel (Top Left)
            Positioned(
              top: 100,
              left: 16,
              child: SafeArea(
                child: Container(
                  key: _locationPanelKey,
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
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.0,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _model.isLiveMode ? 'LIVE' : 'OFFLINE',
                          style:
                              FlutterFlowTheme.of(context).bodyLarge.override(
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
                        child: _buildGlassLayerButton('MindMap', 'Mental',
                            Icons.psychology, _layerMindMapKey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassLayerButton('ShotMap', 'Technical',
                            Icons.golf_course, _layerShotMapKey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGlassLayerButton('SyncMap', 'Combined',
                            Icons.sync, _layerSyncMapKey),
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
                  Container(
                    key: _addDataKey,
                    child: GlassDesignSystem.glass3DCard(
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
                  ),
                  const SizedBox(height: 12),
                  // Enhanced Voice Button with Real-time Feedback
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enhanced Voice Interaction Panel
                      // Voice interaction panel removed due to undefined service

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
                                child: Container(
                                  key: _voiceButtonKey,
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
        // Stop live session
        await _stopLiveSession();
        await _liveService.stopLiveMode();
        await _locationService.stopTracking();
        _model.setLiveMode(false);
        _showLiveUpdateNotification('Live golf session ended', Colors.orange);
      } else {
        // Start live session with enhanced features
        await _startLiveSession();
        await _liveService.startLiveMode();
        await _locationService.startTracking();
        _model.setLiveMode(true);
        _showLiveUpdateNotification(
            '🏌️ Live golf session started!', Colors.green);

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
              context.pushNamed('subscription_management');
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

  String _getVoiceTip() {
    final tips = [
      'Try: "Felt confident on that drive"',
      'Say: "7 iron from 150, pushed it right"',
      'Example: "Used breathing cue, great recovery"',
      'Tip: Mention club, distance, and outcome',
      'Include: Mental state and cues used',
    ];

    // Rotate through tips based on time
    final index = (DateTime.now().second ~/ 12) % tips.length;
    return tips[index];
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
