import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/schema/index.dart';
import '/auth/firebase_auth/auth_util.dart';
// Removed glass imports - using custom container styling instead
import '/services/voice_logging_service.dart';
import '/services/foco_map_live_service.dart';
import 'foco_map_model.dart';
export 'foco_map_model.dart';

import 'package:flutter/material.dart';
// NOTE: Commented out until dependency conflicts are resolved
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';

// Mock classes for Google Maps functionality until dependencies are resolved
class GoogleMapController {}
class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}
class Marker {
  final String markerId;
  final LatLng position;
  final String icon;
  final String infoWindow;
  final VoidCallback? onTap;
  const Marker({required this.markerId, required this.position, required this.icon, required this.infoWindow, this.onTap});
}
class MarkerId {
  final String value;
  const MarkerId(this.value);
}
class InfoWindow {
  final String? title;
  final String? snippet;
  const InfoWindow({this.title, this.snippet});
}
class BitmapDescriptor {
  static const String defaultMarker = 'default';
  static String defaultMarkerWithHue(double hue) => 'marker_$hue';
  static const double hueRed = 0.0;
  static const double hueBlue = 240.0;
  static const double hueGreen = 120.0;
  static const double hueYellow = 60.0;
  static const double hueOrange = 30.0;
  static const double hueViolet = 270.0;
}
class CameraPosition {
  final LatLng target;
  final double zoom;
  const CameraPosition({required this.target, required this.zoom});
}
class MapType {
  static const String normal = 'normal';
}
class Location {
  Future<LocationData> getLocation() async => LocationData(latitude: 40.7128, longitude: -74.0060);
}
class LocationData {
  final double? latitude;
  final double? longitude;
  LocationData({this.latitude, this.longitude});
}

class FoCoMapWidget extends StatefulWidget {
  const FoCoMapWidget({super.key});

  @override
  State<FoCoMapWidget> createState() => _FoCoMapWidgetState();
}

class _FoCoMapWidgetState extends State<FoCoMapWidget> {
  late FoCoMapModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? currentLocation;
  
  // Services
  final VoiceLoggingService _voiceService = VoiceLoggingService();
  final FoCoMapLiveService _liveService = FoCoMapLiveService();
  
  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FoCoMapModel());
    _getCurrentLocation();
    _initializeServices();
    _loadMapData();
  }

  @override
  void dispose() {
    _model.dispose();
    _liveService.stopLiveMode();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Initialize voice service
    await _voiceService.initialize();
    
    // Set up live service listeners
    _liveService.roundLogsStream.listen((roundLogs) {
      setState(() {
        _model.roundLogs = roundLogs;
      });
      _updateMarkers();
    });

    _liveService.shotLogsStream.listen((shotLogs) {
      setState(() {
        _model.shotLogs = shotLogs;
      });
      _updateMarkers();
    });

    _liveService.liveUpdateStream.listen((update) {
      _handleLiveUpdate(update);
    });
  }

  void _handleLiveUpdate(Map<String, dynamic> update) {
    final type = update['type'] as String;
    
    if (type == 'round_log' || type == 'shot_log') {
      // Show live update notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New ${type.replaceAll('_', ' ')} recorded'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
      // Update markers immediately
      _updateMarkers();
    } else if (type == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Live update error: ${update['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = Location();
    try {
      final locationData = await location.getLocation();
      setState(() {
        currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
    } catch (e) {
      // Default to a golf course location if permission denied
      setState(() {
        currentLocation = const LatLng(40.7128, -74.0060); // New York
      });
    }
  }

  Future<void> _loadMapData() async {
    if (currentUser == null) return;
    
    // Check user tier to determine if live mode is available
    // For now, enable live mode for all users - implement tier checking later
    if (_model.isLiveMode) {
      await _liveService.startLiveMode();
    } else {
      // Manual refresh for Base tier users
      await _liveService.refreshData();
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
      final markerColor = _getMarkerColor(mindsetColor);
      
      markers.add(
        Marker(
          markerId: 'round_${round.roundId}',
          position: LatLng(round.coordinates!.latitude, round.coordinates!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: '${round.courseName}: ${round.overallMindsetEmoji} ${round.bestCue}',
          onTap: () => _showRoundDetail(round),
        ),
      );
    }
  }

  void _addShotMapMarkers() {
    for (final shot in _model.getFilteredShotLogs()) {
      if (shot.coordinates == null) continue;
      
      final clubColor = _getClubColor(shot.clubUsed);
      
      markers.add(
        Marker(
          markerId: 'shot_${shot.shotId}',
          position: LatLng(shot.coordinates!.latitude, shot.coordinates!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(clubColor),
          infoWindow: '${shot.clubUsed} - Hole ${shot.holeNumber}: ${shot.shotOutcome} | ${shot.cueUsed}',
          onTap: () => _showShotDetail(shot),
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
      final markerColor = _getMarkerColor(mindsetColor);
      
      markers.add(
        Marker(
          markerId: 'sync_${shot.shotId}',
          position: LatLng(shot.coordinates!.latitude, shot.coordinates!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: '${shot.clubUsed} - ${round.courseName}: Mental: ${round.overallMindsetEmoji} | ${shot.shotOutcome}',
          onTap: () => _showSyncDetail(shot, round),
        ),
      );
    }
  }

  double _getMarkerColor(String mindsetColor) {
    switch (mindsetColor) {
      case 'green':
        return BitmapDescriptor.hueGreen;
      case 'yellow':
        return BitmapDescriptor.hueYellow;
      case 'red':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  double _getClubColor(String club) {
    if (club.toLowerCase().contains('driver')) return BitmapDescriptor.hueRed;
    if (club.toLowerCase().contains('iron')) return BitmapDescriptor.hueBlue;
    if (club.toLowerCase().contains('wedge')) return BitmapDescriptor.hueOrange;
    if (club.toLowerCase().contains('putter')) return BitmapDescriptor.hueGreen;
    return BitmapDescriptor.hueViolet;
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
            const Text('AI Insights:', style: TextStyle(fontWeight: FontWeight.bold)),
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
          if (shot.cueUsed.isNotEmpty)
            Text('Cue Used: ${shot.cueUsed}'),
          Text('Confidence: ${shot.confidenceLevel}/10'),
          if (shot.windCondition.isNotEmpty)
            Text('Wind: ${shot.windCondition}'),
          if (shot.shotTrend.isNotEmpty)
            Text('Trend: ${shot.shotTrend}'),
          if (shot.aiShotInsight.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('AI Tip:', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text('Mental State:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Overall: ${round.overallMindsetEmoji}'),
          Text('Focus: ${round.mindsetFocus}/10'),
          Text('Confidence: ${round.mindsetConfidence}/10'),
          const Divider(),
          const Text('Technical Result:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Outcome: ${shot.shotOutcome}'),
          Text('Distance: ${shot.distanceAttempted}y'),
          if (shot.cueUsed.isNotEmpty)
            Text('Cue Used: ${shot.cueUsed}'),
          if (shot.aiShotInsight.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Correlation Insight:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(shot.aiShotInsight),
          ],
        ],
      ),
    );
  }

  void _showDetailBottomSheet({required String title, required Widget content}) {
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
                      Navigator.pop(context);
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: Text(
            'FoCoMap',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Inter Tight',
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  height: 1.0,
                ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                _model.toggleLiveMode();
                if (_model.isLiveMode) {
                  await _liveService.startLiveMode();
                } else {
                  await _liveService.stopLiveMode();
                }
              },
              icon: Icon(
                _model.isLiveMode ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => _showFiltersBottomSheet(),
              icon: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: Column(
          children: [
            // Layer Selection
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLayerButton('MindMap', 'Mental', Icons.psychology),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLayerButton('ShotMap', 'Technical', Icons.golf_course),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLayerButton('SyncMap', 'Combined', Icons.sync),
                  ),
                ],
              ),
            ),
            
            // Map
            Expanded(
              child: currentLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Google Maps Placeholder',
                            style: FlutterFlowTheme.of(context).headlineSmall.override(
                              color: Colors.grey[600],
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Layer: ${_model.selectedLayer}',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Colors.grey[600],
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Markers: ${markers.length}',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              color: Colors.grey[600],
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateMarkers,
                            child: Text('Update Markers'),
                          ),
                        ],
                      ),
                    ),
            ),
            
            // Live Mode Indicator
            if (_model.isLiveMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.green,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.live_tv, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE MODE - Voice logging active',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        // Floating Voice Button
        floatingActionButton: StreamBuilder<bool>(
          stream: _voiceService.listeningStream,
          builder: (context, snapshot) {
            final isListening = snapshot.data ?? false;
            return FloatingActionButton(
              onPressed: () async {
                if (isListening) {
                  await _voiceService.stopListening();
                } else {
                  await _voiceService.startListening();
                }
              },
              backgroundColor: isListening 
                  ? Colors.red 
                  : FlutterFlowTheme.of(context).primary,
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayerButton(String layerKey, String label, IconData icon) {
    final isSelected = _model.selectedLayer == layerKey;
    return FFButtonWidget(
      onPressed: () {
        _model.selectLayer(layerKey);
        _updateMarkers();
      },
      text: label,
      icon: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : FlutterFlowTheme.of(context).primary,
      ),
      options: FFButtonOptions(
        height: 40,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
        iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
        color: isSelected 
            ? FlutterFlowTheme.of(context).primary 
            : FlutterFlowTheme.of(context).secondaryBackground,
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
              fontFamily: 'Inter',
              color: isSelected 
                  ? Colors.white 
                  : FlutterFlowTheme.of(context).primary,
              fontSize: 12,
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
              const Text('Club Types:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: () => Navigator.pop(context),
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
                            onPressed: () => Navigator.pop(context),
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
