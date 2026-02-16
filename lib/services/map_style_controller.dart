/// Map Style Controller
/// Manages map style switching (MindMap, ShotMap, SyncMap) with animations and persistence

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Map style types
enum MapStyle {
  mindMap,
  shotMap,
  syncMap,
}

/// Map Style Controller for managing map visualization modes
class MapStyleController extends ChangeNotifier {
  static final MapStyleController _instance = MapStyleController._internal();
  factory MapStyleController() => _instance;
  MapStyleController._internal();

  static const String _prefsKey = 'focomap_selected_style';

  MapStyle _currentStyle = MapStyle.mindMap;
  bool _isTransitioning = false;

  // Color schemes for each mode
  static const Map<MapStyle, List<Color>> colorSchemes = {
    MapStyle.mindMap: [
      Color(0xFF64B5F6), // Blue 300
      Color(0xFF1976D2), // Blue 700
    ],
    MapStyle.shotMap: [
      Color(0xFFFFB74D), // Orange 300
      Color(0xFFE64A19), // Red 700
    ],
    MapStyle.syncMap: [
      Color(0xFF81C784), // Green 300
      Color(0xFF388E3C), // Green 700
    ],
  };

  // Style names
  static const Map<MapStyle, String> styleNames = {
    MapStyle.mindMap: 'MindMap',
    MapStyle.shotMap: 'ShotMap',
    MapStyle.syncMap: 'SyncMap',
  };

  // Style descriptions
  static const Map<MapStyle, String> styleDescriptions = {
    MapStyle.mindMap: 'Mental performance visualization',
    MapStyle.shotMap: 'Technical shots and outcomes',
    MapStyle.syncMap: 'Combined mental + technical view',
  };

  // Getters
  MapStyle get currentStyle => _currentStyle;
  bool get isTransitioning => _isTransitioning;
  List<Color> get currentColors => colorSchemes[_currentStyle] ?? colorSchemes[MapStyle.mindMap]!;
  String get currentStyleName => styleNames[_currentStyle] ?? 'MindMap';
  String get currentDescription => styleDescriptions[_currentStyle] ?? '';

  /// Initialize and load saved style
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStyleIndex = prefs.getInt(_prefsKey);
      
      if (savedStyleIndex != null && savedStyleIndex >= 0 && savedStyleIndex < MapStyle.values.length) {
        _currentStyle = MapStyle.values[savedStyleIndex];
        notifyListeners();
        debugPrint('✅ MapStyleController: Loaded saved style: ${styleNames[_currentStyle]}');
      }
    } catch (e) {
      debugPrint('⚠️ MapStyleController: Error loading saved style: $e');
    }
  }

  /// Toggle to next map style
  Future<void> toggleMapStyle({Duration? transitionDuration}) async {
    final nextStyleIndex = (_currentStyle.index + 1) % MapStyle.values.length;
    await setMapStyle(
      MapStyle.values[nextStyleIndex],
      transitionDuration: transitionDuration,
    );
  }

  /// Set map style with smooth transition
  Future<void> setMapStyle(
    MapStyle style, {
    Duration? transitionDuration,
  }) async {
    if (_currentStyle == style || _isTransitioning) {
      return;
    }

    try {
      _isTransitioning = true;
      notifyListeners();

      final duration = transitionDuration ?? const Duration(milliseconds: 300);
      await Future.delayed(duration);

      _currentStyle = style;
      _isTransitioning = false;

      // Persist selection
      await _persistStyle();

      notifyListeners();
      debugPrint('✅ MapStyleController: Changed to ${styleNames[style]}');
    } catch (e) {
      _isTransitioning = false;
      notifyListeners();
      debugPrint('❌ MapStyleController: Error changing style: $e');
    }
  }

  /// Get style configuration
  Map<String, dynamic> getMapStyleConfig(MapStyle style) {
    final colors = colorSchemes[style] ?? colorSchemes[MapStyle.mindMap]!;
    
    return {
      'style': styleNames[style],
      'primaryColor': colors[0].value,
      'secondaryColor': colors[1].value,
      'description': styleDescriptions[style],
      'markerColor': colors[1].value,
      'pathColor': colors[0].value,
      'highlightColor': colors[0].withOpacity(0.3).value,
    };
  }

  /// Get current style configuration
  Map<String, dynamic> get currentStyleConfig => getMapStyleConfig(_currentStyle);

  /// Persist style selection
  Future<void> _persistStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, _currentStyle.index);
    } catch (e) {
      debugPrint('⚠️ MapStyleController: Error persisting style: $e');
    }
  }

  /// Get icon for style
  IconData getStyleIcon(MapStyle style) {
    switch (style) {
      case MapStyle.mindMap:
        return Icons.psychology;
      case MapStyle.shotMap:
        return Icons.golf_course;
      case MapStyle.syncMap:
        return Icons.sync;
    }
  }

  /// Get current style icon
  IconData get currentStyleIcon => getStyleIcon(_currentStyle);
}