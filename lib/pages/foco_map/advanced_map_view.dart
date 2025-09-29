import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/pages/foco_map/platform_map_widget.dart';

/// Advanced map viewing modes for FoCo Map
enum MapViewMode {
  standard,
  satellite,
  hybrid,
  terrain,
  threeDimensional,
  augmentedReality,
  heatmap,
  trajectory,
}

/// Advanced map controls and viewing options
class AdvancedMapView extends StatefulWidget {
  final List<MapMarker> markers;
  final LatLng? initialLocation;
  final MapType mapType;
  final Function(MapMarker) onMarkerTap;
  final Function(LatLng) onMapTap;
  final MapViewMode viewMode;
  final bool showCompass;
  final bool showScale;
  final bool showUserLocation;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final bool enable3D;
  final bool enableAR;
  final List<HeatmapData>? heatmapData;
  final List<TrajectoryData>? trajectoryData;

  const AdvancedMapView({
    super.key,
    required this.markers,
    this.initialLocation,
    this.mapType = MapType.normal,
    required this.onMarkerTap,
    required this.onMapTap,
    this.viewMode = MapViewMode.standard,
    this.showCompass = true,
    this.showScale = true,
    this.showUserLocation = true,
    this.initialZoom = 15.0,
    this.minZoom = 10.0,
    this.maxZoom = 20.0,
    this.enable3D = true,
    this.enableAR = false,
    this.heatmapData,
    this.trajectoryData,
  });

  @override
  State<AdvancedMapView> createState() => _AdvancedMapViewState();
}

class _AdvancedMapViewState extends State<AdvancedMapView>
    with TickerProviderStateMixin {
  // Map controllers
  gmaps.GoogleMapController? _googleMapController;

  // Animation controllers
  late AnimationController _rotationController;
  late AnimationController _tiltController;
  late AnimationController _zoomController;

  // Map state
  double _currentZoom = 15.0;
  double _currentTilt = 0.0;
  double _currentBearing = 0.0;
  LatLng? _currentCenter;
  bool _is3DMode = false;
  bool _isARMode = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation ?? const LatLng(40.7128, -74.0060);
    _currentZoom = widget.initialZoom;

    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _tiltController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Enable 3D mode if supported and requested
    if (widget.enable3D && widget.viewMode == MapViewMode.threeDimensional) {
      _enable3DMode();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _tiltController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use platform-specific map implementation
    if (Platform.isIOS) {
      return _buildIOSMap();
    } else {
      return _buildAndroidMap();
    }
  }

  /// Build iOS-specific map with advanced features
  Widget _buildIOSMap() {
    return Stack(
      children: [
        // Main map view
        gmaps.GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: gmaps.CameraPosition(
            target: gmaps.LatLng(
              _currentCenter!.latitude,
              _currentCenter!.longitude,
            ),
            zoom: _currentZoom,
            tilt: _currentTilt,
            bearing: _currentBearing,
          ),
          markers: _convertToGoogleMarkers(),
          mapType: _getGoogleMapType(),
          compassEnabled: widget.showCompass,
          myLocationEnabled: widget.showUserLocation,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          tiltGesturesEnabled: widget.enable3D,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          minMaxZoomPreference: gmaps.MinMaxZoomPreference(
            widget.minZoom,
            widget.maxZoom,
          ),
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
          onTap: (position) => widget.onMapTap(
            LatLng(position.latitude, position.longitude),
          ),
          // Advanced iOS features
          buildingsEnabled: _is3DMode,
          indoorViewEnabled: false,
          trafficEnabled: false,
          // Heatmap overlay
          circles: _buildHeatmapCircles(),
          // Trajectory polylines
          polylines: _buildTrajectoryPolylines(),
        ),

        // Advanced controls overlay
        _buildAdvancedControls(),

        // AR mode overlay (iOS 11+)
        if (_isARMode && widget.enableAR) _buildAROverlay(),

        // Scale indicator
        if (widget.showScale) _buildScaleIndicator(),

        // 3D mode indicator
        if (_is3DMode) _build3DIndicator(),
      ],
    );
  }

  /// Build Android-specific map with advanced features
  Widget _buildAndroidMap() {
    // Android uses Google Maps same as iOS
    return _buildIOSMap();
  }

  /// Build advanced map controls
  Widget _buildAdvancedControls() {
    return Positioned(
      right: 16,
      top: 100,
      child: Column(
        children: [
          // Zoom controls
          _buildControlButton(
            icon: Icons.add,
            onTap: _zoomIn,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.remove,
            onTap: _zoomOut,
          ),
          const SizedBox(height: 16),

          // 3D toggle
          if (widget.enable3D)
            _buildControlButton(
              icon: Icons.view_in_ar,
              onTap: _toggle3DMode,
              isActive: _is3DMode,
            ),
          const SizedBox(height: 8),

          // Compass
          if (widget.showCompass) _buildCompassControl(),
          const SizedBox(height: 8),

          // Layer selector
          _buildControlButton(
            icon: Icons.layers,
            onTap: _showLayerSelector,
          ),

          // AR mode toggle (if supported)
          if (widget.enableAR && _isARSupported())
            Column(
              children: [
                const SizedBox(height: 16),
                _buildControlButton(
                  icon: Icons.camera,
                  onTap: _toggleARMode,
                  isActive: _isARMode,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? FlutterFlowTheme.of(context).primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  /// Build compass control
  Widget _buildCompassControl() {
    return GestureDetector(
      onTap: _resetBearing,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: -_currentBearing * (pi / 180),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation,
                color: Colors.red,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build scale indicator
  Widget _buildScaleIndicator() {
    final metersPerPixel = _calculateMetersPerPixel();
    final scaleWidth = 100.0;
    final scaleMeters = (metersPerPixel * scaleWidth).round();

    String scaleText;
    if (scaleMeters >= 1000) {
      scaleText = '${(scaleMeters / 1000).toStringAsFixed(1)} km';
    } else {
      scaleText = '$scaleMeters m';
    }

    return Positioned(
      bottom: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              scaleText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: scaleWidth,
              height: 2,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  /// Build 3D mode indicator
  Widget _build3DIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.view_in_ar,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '3D Mode',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build AR overlay for iOS
  Widget _buildAROverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'AR Mode Active',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                    color: Colors.white,
                    height: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Point camera at the golf course',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    color: Colors.white70,
                    height: 1.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  void _onMapCreated(gmaps.GoogleMapController controller) {
    _googleMapController = controller;

    // Apply custom map style if needed
    if (widget.viewMode == MapViewMode.heatmap) {
      _applyHeatmapStyle();
    }
  }

  void _onCameraMove(gmaps.CameraPosition position) {
    setState(() {
      _currentZoom = position.zoom;
      _currentTilt = position.tilt;
      _currentBearing = position.bearing;
      _currentCenter = LatLng(
        position.target.latitude,
        position.target.longitude,
      );
    });
  }

  void _onCameraIdle() {
    // Update any dependent UI or fetch new data
  }

  void _zoomIn() {
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.zoomIn(),
    );
  }

  void _zoomOut() {
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.zoomOut(),
    );
  }

  void _toggle3DMode() {
    setState(() {
      _is3DMode = !_is3DMode;
    });

    if (_is3DMode) {
      _enable3DMode();
    } else {
      _disable3DMode();
    }
  }

  void _enable3DMode() {
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(
            _currentCenter!.latitude,
            _currentCenter!.longitude,
          ),
          zoom: _currentZoom,
          tilt: 45.0, // 45-degree tilt for 3D effect
          bearing: _currentBearing,
        ),
      ),
    );
  }

  void _disable3DMode() {
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(
            _currentCenter!.latitude,
            _currentCenter!.longitude,
          ),
          zoom: _currentZoom,
          tilt: 0.0, // Flat view
          bearing: _currentBearing,
        ),
      ),
    );
  }

  void _resetBearing() {
    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(
            _currentCenter!.latitude,
            _currentCenter!.longitude,
          ),
          zoom: _currentZoom,
          tilt: _currentTilt,
          bearing: 0.0, // North-up
        ),
      ),
    );
  }

  void _toggleARMode() {
    setState(() {
      _isARMode = !_isARMode;
    });

    if (_isARMode) {
      // Initialize AR session
      _initializeAR();
    } else {
      // Clean up AR session
      _cleanupAR();
    }
  }

  void _showLayerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Layers',
              style: FlutterFlowTheme.of(context).headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildLayerOption('Standard', MapViewMode.standard),
            _buildLayerOption('Satellite', MapViewMode.satellite),
            _buildLayerOption('Hybrid', MapViewMode.hybrid),
            _buildLayerOption('Terrain', MapViewMode.terrain),
            if (widget.heatmapData != null)
              _buildLayerOption('Heat Map', MapViewMode.heatmap),
            if (widget.trajectoryData != null)
              _buildLayerOption('Trajectories', MapViewMode.trajectory),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerOption(String title, MapViewMode mode) {
    final isSelected = widget.viewMode == mode;
    return ListTile(
      title: Text(title),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        // Update view mode through parent widget
        Navigator.pop(context);
        // Trigger callback to parent to update view mode
      },
    );
  }

  gmaps.MapType _getGoogleMapType() {
    switch (widget.mapType) {
      case MapType.normal:
        return gmaps.MapType.normal;
      case MapType.satellite:
        return gmaps.MapType.satellite;
      case MapType.hybrid:
        return gmaps.MapType.hybrid;
    }
  }

  Set<gmaps.Marker> _convertToGoogleMarkers() {
    return widget.markers.map((marker) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(marker.markerId),
        position: gmaps.LatLng(
          marker.position.latitude,
          marker.position.longitude,
        ),
        icon: marker.icon ?? gmaps.BitmapDescriptor.defaultMarker,
        infoWindow: gmaps.InfoWindow(
          title: marker.infoWindow.title,
          snippet: marker.infoWindow.snippet,
        ),
        onTap: () => widget.onMarkerTap(marker),
      );
    }).toSet();
  }

  Set<gmaps.Circle> _buildHeatmapCircles() {
    if (widget.heatmapData == null) return {};

    return widget.heatmapData!.map((data) {
      return gmaps.Circle(
        circleId: gmaps.CircleId('heatmap_${data.id}'),
        center: gmaps.LatLng(data.position.latitude, data.position.longitude),
        radius: data.radius,
        fillColor: data.color.withValues(alpha: data.intensity * 0.5),
        strokeWidth: 0,
      );
    }).toSet();
  }

  Set<gmaps.Polyline> _buildTrajectoryPolylines() {
    if (widget.trajectoryData == null) return {};

    return widget.trajectoryData!.map((trajectory) {
      return gmaps.Polyline(
        polylineId: gmaps.PolylineId('trajectory_${trajectory.id}'),
        points: trajectory.points.map((point) {
          return gmaps.LatLng(point.latitude, point.longitude);
        }).toList(),
        color: trajectory.color,
        width: trajectory.width.toInt(),
        patterns: trajectory.isDashed
            ? [
                gmaps.PatternItem.dash(20),
                gmaps.PatternItem.gap(10),
              ]
            : [],
      );
    }).toSet();
  }

  double _calculateMetersPerPixel() {
    final lat = _currentCenter?.latitude ?? 0;
    final zoom = _currentZoom;
    return 156543.03392 * cos(lat * pi / 180) / pow(2, zoom);
  }

  bool _isARSupported() {
    // Check platform capabilities
    if (Platform.isIOS) {
      // iOS 11+ supports ARKit
      return true;
    } else if (Platform.isAndroid) {
      // Check for ARCore support
      return true; // Simplified, would need actual ARCore check
    }
    return false;
  }

  void _initializeAR() {
    // Initialize AR session
    // This would integrate with ARKit (iOS) or ARCore (Android)
  }

  void _cleanupAR() {
    // Clean up AR resources
  }

  void _applyHeatmapStyle() {
    // Apply custom map style for better heatmap visibility
    const String style = '''[
      {
        "elementType": "geometry",
        "stylers": [{"color": "#212121"}]
      },
      {
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      }
    ]''';

    _googleMapController?.setMapStyle(style);
  }
}

// Data models

class HeatmapData {
  final String id;
  final LatLng position;
  final double radius;
  final Color color;
  final double intensity;

  HeatmapData({
    required this.id,
    required this.position,
    required this.radius,
    required this.color,
    required this.intensity,
  });
}

class TrajectoryData {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool isDashed;

  TrajectoryData({
    required this.id,
    required this.points,
    required this.color,
    this.width = 3.0,
    this.isDashed = false,
  });
}
