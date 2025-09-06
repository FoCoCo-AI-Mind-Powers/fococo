import 'package:fo_co_co/backend/backend.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/foco_map_live_service.dart';
import 'foco_map_model.dart';
export 'foco_map_model.dart';

import 'package:flutter/material.dart';

class FoCoMapPlaceholderWidget extends StatefulWidget {
  const FoCoMapPlaceholderWidget({super.key});

  @override
  State<FoCoMapPlaceholderWidget> createState() => _FoCoMapPlaceholderWidgetState();
}

class _FoCoMapPlaceholderWidgetState extends State<FoCoMapPlaceholderWidget> {
  late FoCoMapModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Services
  final FoCoMapLiveService _liveService = FoCoMapLiveService();
  
  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FoCoMapModel());
    _initializeServices();
    _loadMapData();
  }

  @override
  void dispose() {
    _model.dispose();
    _liveService.stopLiveMode();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Set up live service listeners
    _liveService.roundLogsStream.listen((roundLogs) {
      setState(() {
        _model.roundLogs = roundLogs;
      });
    });

    _liveService.shotLogsStream.listen((shotLogs) {
      setState(() {
        _model.shotLogs = shotLogs;
      });
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
    } else if (type == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Live update error: ${update['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadMapData() async {
    if (currentUser == null) return;
    
    if (_model.isLiveMode) {
      await _liveService.startLiveMode();
    } else {
      await _liveService.refreshData();
    }
  }

  Future<void> _addSampleData() async {
    if (currentUser == null) return;

    // Add sample round log
    final roundLogData = {
      'userId': currentUser!.uid,
      'roundId': 'round_${DateTime.now().millisecondsSinceEpoch}',
      'date': DateTime.now(),
      'courseName': 'Sample Golf Course',
      'courseType': 'championship',
      'coordinates': const GeoPoint(40.7128, -74.0060),
      'mindsetFocus': 8,
      'mindsetConfidence': 7,
      'mindsetControl': 9,
      'bestCue': 'Deep breathing',
      'recoveryHoles': ['3', '7', '12'],
      'overallMindsetEmoji': '😊',
      'technicalSummary': 'Good driving, struggled with short game',
      'aiRoundSummary': 'Strong mental game today with excellent recovery',
      'voiceTranscription': 'Had a great round today, feeling confident with my new breathing technique',
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
      'coordinates': const GeoPoint(40.7130, -74.0058),
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

    await FirebaseFirestore.instance
        .collection('shot_logs')
        .add(shotLogData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample data added successfully!'),
        backgroundColor: Colors.green,
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
            'FoCoMap - Live Golf Experience',
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
            
            // Map Placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 100,
                      color: FlutterFlowTheme.of(context).primaryText.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'FoCoMap Implementation Ready',
                      style: FlutterFlowTheme.of(context).headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Firebase collections and data structures are configured.\n\n'
                      'Current Layer: ${_model.selectedLayer}\n'
                      'Live Mode: ${_model.isLiveMode ? "ON" : "OFF"}\n'
                      'Round Logs: ${_model.roundLogs.length}\n'
                      'Shot Logs: ${_model.shotLogs.length}',
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'To enable the full map functionality, add these dependencies to pubspec.yaml:\n\n'
                      '• google_maps_flutter: ^2.5.0\n'
                      '• location: ^5.0.0\n'
                      '• speech_to_text: ^6.6.0\n'
                      '• geolocator: ^10.1.0',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Courier',
                        height: 1.0,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 32),
                    FFButtonWidget(
                      onPressed: _addSampleData,
                      text: 'Add Sample Data',
                      options: FFButtonOptions(
                        width: 200,
                        height: 44,
                        padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              letterSpacing: 0.0,
                              height: 1.0,
                            ),
                        elevation: 2.0,
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
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
                      'LIVE MODE - Real-time data streaming active',
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
        
        // Data display section
        bottomSheet: _model.roundLogs.isNotEmpty || _model.shotLogs.isNotEmpty
            ? Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Data (${_model.selectedLayer})',
                      style: FlutterFlowTheme.of(context).headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _model.selectedLayer == 'ShotMap' 
                            ? _model.shotLogs.length 
                            : _model.roundLogs.length,
                        itemBuilder: (context, index) {
                          if (_model.selectedLayer == 'ShotMap') {
                            final shot = _model.shotLogs[index];
                            return Card(
                              child: ListTile(
                                leading: Text(shot.clubIcon),
                                title: Text('${shot.clubUsed} - Hole ${shot.holeNumber}'),
                                subtitle: Text('${shot.shotOutcome} | ${shot.cueUsed}'),
                                trailing: Text('${shot.confidenceLevel}/10'),
                              ),
                            );
                          } else {
                            final round = _model.roundLogs[index];
                            return Card(
                              child: ListTile(
                                leading: Text(round.overallMindsetEmoji),
                                title: Text(round.courseName),
                                subtitle: Text('Focus: ${round.mindsetFocus}/10 | ${round.bestCue}'),
                                trailing: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _model.getMindsetColor(round) == 'green' 
                                        ? Colors.green 
                                        : _model.getMindsetColor(round) == 'yellow'
                                            ? Colors.yellow
                                            : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLayerButton(String layerKey, String label, IconData icon) {
    final isSelected = _model.selectedLayer == layerKey;
    return FFButtonWidget(
      onPressed: () {
        _model.selectLayer(layerKey);
      },
      text: label,
      icon: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : FlutterFlowTheme.of(context).primary,
      ),
      options: FFButtonOptions(
        width: double.infinity,
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
}
