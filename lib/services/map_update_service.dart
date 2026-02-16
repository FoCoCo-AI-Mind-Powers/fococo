/// Map Update Service
/// Handles real-time map updates during voice sessions

import 'dart:async';
import 'package:flutter/foundation.dart';
import '/models/voice_session_model.dart';
import '/services/map_style_controller.dart' show MapStyle;

/// Map Update Service for voice coaching sessions
class MapUpdateService {
  static final MapUpdateService _instance = MapUpdateService._internal();
  factory MapUpdateService() => _instance;
  MapUpdateService._internal();

  // Map markers and paths
  final List<VoiceInteraction> _voiceMarkers = [];
  final List<({double lat, double lng})> _voicePath = [];
  
  // Current map style
  MapStyle _currentMapStyle = MapStyle.mindMap;

  // Stream controllers for map updates
  final StreamController<List<VoiceInteraction>> _markersController =
      StreamController<List<VoiceInteraction>>.broadcast();
  final StreamController<List<({double lat, double lng})>> _pathController =
      StreamController<List<({double lat, double lng})>>.broadcast();
  final StreamController<MapStyle> _styleController =
      StreamController<MapStyle>.broadcast();

  // Getters
  Stream<List<VoiceInteraction>> get markersStream => _markersController.stream;
  Stream<List<({double lat, double lng})>> get pathStream => _pathController.stream;
  Stream<MapStyle> get styleStream => _styleController.stream;
  List<VoiceInteraction> get voiceMarkers => List.unmodifiable(_voiceMarkers);
  List<({double lat, double lng})> get voicePath => List.unmodifiable(_voicePath);
  MapStyle get currentMapStyle => _currentMapStyle;

  /// Add voice interaction marker to map
  Future<void> addVoiceInteractionMarker({
    required VoiceInteraction interaction,
    required MapStyle mapStyle,
  }) async {
    try {
      _voiceMarkers.add(interaction);
      
      // Add to path if location changed
      if (_voicePath.isEmpty ||
          _voicePath.last.lat != interaction.location.lat ||
          _voicePath.last.lng != interaction.location.lng) {
        _voicePath.add(interaction.location);
      }

      _currentMapStyle = mapStyle;
      
      // Notify listeners
      _markersController.add(_voiceMarkers);
      _pathController.add(_voicePath);
      _styleController.add(_currentMapStyle);

      debugPrint(
          '📍 MapUpdateService: Added marker at ${interaction.location.lat}, ${interaction.location.lng}');
    } catch (e) {
      debugPrint('❌ MapUpdateService: Error adding marker: $e');
    }
  }

  /// Update current location indicator
  Future<void> updateCurrentLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Update path with current location
      if (_voicePath.isEmpty ||
          _voicePath.last.lat != latitude ||
          _voicePath.last.lng != longitude) {
        _voicePath.add((lat: latitude, lng: longitude));
        _pathController.add(_voicePath);
      }

      debugPrint('📍 MapUpdateService: Updated location to $latitude, $longitude');
    } catch (e) {
      debugPrint('❌ MapUpdateService: Error updating location: $e');
    }
  }

  /// Process navigation guidance from Gemini
  Future<void> processNavigationGuidance({
    required String responseText,
    required ({double lat, double lng}) currentLocation,
  }) async {
    try {
      // Extract navigation instructions from response
      // This is a simplified implementation
      // In production, you might use NLP to extract structured navigation data

      debugPrint('🗺️ MapUpdateService: Processing navigation guidance: $responseText');
      
      // Add navigation marker
      final navigationMarker = VoiceInteraction(
        timestamp: DateTime.now(),
        speaker: 'assistant',
        text: responseText,
        location: currentLocation,
        context: {'type': 'navigation'},
      );

      await addVoiceInteractionMarker(
        interaction: navigationMarker,
        mapStyle: _currentMapStyle,
      );
    } catch (e) {
      debugPrint('❌ MapUpdateService: Error processing navigation: $e');
    }
  }

  /// Draw navigation path
  Future<void> drawNavigationPath({
    required List<({double lat, double lng})> path,
  }) async {
    try {
      _voicePath.addAll(path);
      _pathController.add(_voicePath);
      
      debugPrint('🗺️ MapUpdateService: Drew navigation path with ${path.length} points');
    } catch (e) {
      debugPrint('❌ MapUpdateService: Error drawing path: $e');
    }
  }

  /// Highlight point of interest
  Future<void> highlightPOI({
    required ({double lat, double lng}) location,
    required String name,
    String? description,
  }) async {
    try {
      final poiMarker = VoiceInteraction(
        timestamp: DateTime.now(),
        speaker: 'assistant',
        text: 'POI: $name${description != null ? " - $description" : ""}',
        location: location,
        context: {
          'type': 'poi',
          'name': name,
          'description': description,
        },
      );

      await addVoiceInteractionMarker(
        interaction: poiMarker,
        mapStyle: _currentMapStyle,
      );
      
      debugPrint('📍 MapUpdateService: Highlighted POI: $name at ${location.lat}, ${location.lng}');
    } catch (e) {
      debugPrint('❌ MapUpdateService: Error highlighting POI: $e');
    }
  }

  /// Update map style
  void updateMapStyle(MapStyle style) {
    if (_currentMapStyle != style) {
      _currentMapStyle = style;
      _styleController.add(_currentMapStyle);
      debugPrint('🎨 MapUpdateService: Updated map style to $style');
    }
  }

  /// Clear all markers and paths
  void clear() {
    _voiceMarkers.clear();
    _voicePath.clear();
    _markersController.add(_voiceMarkers);
    _pathController.add(_voicePath);
    debugPrint('🗑️ MapUpdateService: Cleared all markers and paths');
  }

  /// Dispose resources
  void dispose() {
    _markersController.close();
    _pathController.close();
    _styleController.close();
  }
}