import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show BitmapDescriptor;
import 'package:geolocator/geolocator.dart';
import '/flutter_flow/lat_lng.dart';
import '/services/focomap_custom_markers.dart';

// Export BitmapDescriptor for custom markers
export 'package:google_maps_flutter/google_maps_flutter.dart'
    show BitmapDescriptor;

/// Enhanced Platform-aware map widget with clustering, 3D view, and polyline drawing
/// Uses Google Maps on both iOS and Android platforms
/// Apple Maps code is preserved but commented out for future reference
class PlatformMapWidget extends StatefulWidget {
  final Set<MapMarker> markers;
  final Function(MapMarker)? onMarkerTap;
  final Function(LatLng)? onMapTap;
  final Function(double)? onZoomChanged;
  final LatLng? initialLocation;
  final double initialZoom;
  final MapType mapType;
  final bool enableClustering;
  final int maxMarkersBeforeClustering;
  final bool showUserLocation;
  final bool enableScrollGestures;
  final bool enableZoomGestures;
  final bool enable3DView;
  final double tilt;
  final double bearing;
  final Set<MapPolyline> polylines;
  final bool enablePolylineDrawing;
  final Function(List<LatLng>)? onPolylineDrawn;
  final Function(double)? onTiltChanged;
  final Function(double)? onBearingChanged;

  const PlatformMapWidget({
    super.key,
    this.markers = const {},
    this.onMarkerTap,
    this.onMapTap,
    this.onZoomChanged,
    this.initialLocation,
    this.initialZoom = 14.0,
    this.mapType = MapType.normal,
    this.enableClustering = true,
    this.maxMarkersBeforeClustering = 100,
    this.showUserLocation = true,
    this.enableScrollGestures = true,
    this.enableZoomGestures = true,
    this.enable3DView = false,
    this.tilt = 0.0,
    this.bearing = 0.0,
    this.polylines = const {},
    this.enablePolylineDrawing = false,
    this.onPolylineDrawn,
    this.onTiltChanged,
    this.onBearingChanged,
  });

  @override
  State<PlatformMapWidget> createState() => _PlatformMapWidgetState();

  /// Public method to animate to a location
  static Future<void> animateToLocationFromKey(GlobalKey key, LatLng location,
      {double? zoom}) async {
    final state = key.currentState;
    if (state is _PlatformMapWidgetState) {
      await state.animateToLocation(location, zoom: zoom);
    }
  }
}

class _PlatformMapWidgetState extends State<PlatformMapWidget> {
  // Apple Maps controller - COMMENTED OUT: Using Google Maps on all platforms now
  // apple_maps.AppleMapController? _appleMapController;
  google_maps.GoogleMapController? _googleMapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _platformViewFailed = false;
  bool _isMapCreated = false;

  // Enhanced state management for clustering and performance
  double _currentZoom = 14.0;
  Set<MapMarker> _visibleMarkers = {};
  Set<MapCluster> _clusters = {};
  bool _needsClusterUpdate = true;

  // 3D view state
  bool _is3DViewEnabled = false;
  double _currentTilt = 0.0;
  double _currentBearing = 0.0;

  // Polyline drawing state
  bool _isDrawingPolyline = false;
  List<LatLng> _currentPolylinePoints = [];
  Set<MapPolyline> _polylines = {};

  // Performance optimization
  DateTime? _lastClusterUpdate;
  static const Duration _clusterUpdateThrottle = Duration(milliseconds: 500);

  // Live location tracking
  StreamSubscription<Position>? _locationSubscription;

  // Dark mode map style for Google Maps
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#64779e"}]},
  {"featureType": "administrative.province", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [{"color": "#334e87"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
  {"featureType": "poi", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#3C7680"}]},
  {"featureType": "poi.sports_complex", "elementType": "geometry.fill", "stylers": [{"color": "#1a472a"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "road", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#b0d5ce"}]},
  {"featureType": "road.highway", "elementType": "labels.text.stroke", "stylers": [{"color": "#023e58"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "transit", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "transit.line", "elementType": "geometry.fill", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#3a4762"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
]
''';

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _is3DViewEnabled = widget.enable3DView ?? false;
    _currentTilt = widget.tilt ?? 0.0;
    _currentBearing = widget.bearing ?? 0.0;
    _polylines = widget.polylines;
    _isDrawingPolyline = widget.enablePolylineDrawing ?? false;
    _initializeLocation();
  }

  @override
  void dispose() {
    // Stop location tracking
    _locationSubscription?.cancel();
    _locationSubscription = null;

    // Clear controller references (controllers don't have dispose methods)
    // The platform will handle cleanup automatically
    // _appleMapController = null; // COMMENTED OUT: Using Google Maps on all platforms
    _googleMapController = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(PlatformMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update location/zoom without recreating the map
    if (widget.initialLocation != oldWidget.initialLocation ||
        widget.initialZoom != oldWidget.initialZoom) {
      _updateCameraPosition();
    }

    // Update 3D view settings - use null-aware operators to handle potential null values
    final newEnable3D = widget.enable3DView ?? false;
    final oldEnable3D = oldWidget.enable3DView ?? false;
    final newTilt = widget.tilt ?? 0.0;
    final oldTilt = oldWidget.tilt ?? 0.0;
    final newBearing = widget.bearing ?? 0.0;
    final oldBearing = oldWidget.bearing ?? 0.0;

    if (newEnable3D != oldEnable3D ||
        newTilt != oldTilt ||
        newBearing != oldBearing) {
      setState(() {
        _is3DViewEnabled = newEnable3D;
        _currentTilt = newTilt;
        _currentBearing = newBearing;
      });
      // Apple Maps 3D view code commented out - using Google Maps on all platforms
      // if (Platform.isIOS && _is3DViewEnabled && _appleMapController != null) {
      //   _applyAppleMaps3DView();
      // } else {
      _updateCameraPosition();
      // }
    }

    // Update polylines
    if (widget.polylines != oldWidget.polylines) {
      _polylines = widget.polylines;
      if (_isMapCreated) {
        setState(() {});
      }
    }

    // Check if markers changed and need clustering update
    if (widget.markers != oldWidget.markers) {
      _needsClusterUpdate = true;
      if (_isMapCreated) {
        _updateClustering();
      }
    }
  }

  // Track previous brightness to detect theme changes
  Brightness? _previousBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Detect theme change and update map style
    final brightness = MediaQuery.platformBrightnessOf(context);
    if (_previousBrightness != null && _previousBrightness != brightness) {
      _applyMapStyle();
    }
    _previousBrightness = brightness;
  }

  /// Update camera position without recreating the map
  Future<void> _updateCameraPosition() async {
    if (!_isMapCreated) return;

    final newLocation = widget.initialLocation ?? _currentLocation;
    if (newLocation == null) return;

    try {
      // Apple Maps code commented out - using Google Maps on all platforms
      // if (Platform.isIOS && _appleMapController != null) {
      //   await _appleMapController!.animateCamera(
      //     apple_maps.CameraUpdate.newCameraPosition(
      //       apple_maps.CameraPosition(
      //         target: apple_maps.LatLng(newLocation.latitude, newLocation.longitude),
      //         zoom: widget.initialZoom,
      //       ),
      //     ),
      //   );
      // } else
      if (_googleMapController != null) {
        final cameraPosition = google_maps.CameraPosition(
          target:
              google_maps.LatLng(newLocation.latitude, newLocation.longitude),
          zoom: widget.initialZoom,
          tilt: _is3DViewEnabled ? _currentTilt : 0.0,
          bearing: _currentBearing,
        );
        await _googleMapController!.animateCamera(
          google_maps.CameraUpdate.newCameraPosition(cameraPosition),
        );
      }

      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _currentZoom = widget.initialZoom;
        });
      }
    } catch (e) {
      debugPrint('Error updating camera position: $e');
    }
  }

  /// Toggle 3D view
  void toggle3DView() {
    setState(() {
      _is3DViewEnabled = !_is3DViewEnabled;
      if (_is3DViewEnabled) {
        _currentTilt = 45.0; // Default tilt for 3D view
      } else {
        _currentTilt = 0.0;
      }
    });
    _updateCameraPosition();
  }

  /// Update tilt angle
  void updateTilt(double tilt) {
    setState(() {
      _currentTilt = tilt.clamp(0.0, 90.0);
    });
    widget.onTiltChanged?.call(_currentTilt);
    _updateCameraPosition();
  }

  /// Update bearing (rotation)
  void updateBearing(double bearing) {
    setState(() {
      _currentBearing = bearing % 360.0;
    });
    widget.onBearingChanged?.call(_currentBearing);
    _updateCameraPosition();
  }

  /// Start drawing a polyline
  void startDrawingPolyline() {
    if (!(widget.enablePolylineDrawing ?? false)) return;
    setState(() {
      _isDrawingPolyline = true;
      _currentPolylinePoints = [];
    });
  }

  /// Add point to current polyline
  void addPolylinePoint(LatLng point) {
    if (!_isDrawingPolyline) return;
    setState(() {
      _currentPolylinePoints.add(point);
    });
  }

  /// Finish drawing polyline
  void finishDrawingPolyline() {
    if (!_isDrawingPolyline || _currentPolylinePoints.isEmpty) return;

    widget.onPolylineDrawn?.call(_currentPolylinePoints);

    setState(() {
      _isDrawingPolyline = false;
      _currentPolylinePoints = [];
    });
  }

  /// Cancel drawing polyline
  void cancelDrawingPolyline() {
    setState(() {
      _isDrawingPolyline = false;
      _currentPolylinePoints = [];
    });
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLocation != null) {
        _currentLocation = widget.initialLocation;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Get actual current location - no defaults
      final position = await _getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);

      // Start live location tracking for real-time updates
      _startLocationTracking();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      // No default location - wait for actual location or show error
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Keep _currentLocation as null - map will handle this gracefully
        });
      }
    }
  }

  /// Start live location tracking for real-time updates
  void _startLocationTracking() {
    // Cancel existing subscription if any
    _locationSubscription?.cancel();

    // Start listening to position stream for live updates
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(seconds: 30), // Timeout after 30 seconds
      ),
    ).listen(
      (Position position) {
        if (mounted) {
          final newLocation = LatLng(position.latitude, position.longitude);

          // Only update if location changed significantly
          if (_currentLocation == null ||
              _calculateDistance(_currentLocation!, newLocation) > 0.01) {
            setState(() {
              _currentLocation = newLocation;
            });

            // Update camera position if map is created
            if (_isMapCreated) {
              _updateCameraPosition();
            }
          }
        }
      },
      onError: (error) {
        debugPrint('⚠️ Location stream error: $error');
        // Don't set default - just log the error
      },
    );
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable location services in your device settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permissions are denied. Please grant location permission to use this feature.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable location permission in app settings.');
    }

    // Get current position with high accuracy and explicit timeout
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit:
              Duration(seconds: 10), // Reduced timeout for faster failure
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Location request timed out after 10 seconds. Please check your location settings and try again.',
            const Duration(seconds: 10),
          );
        },
      );
    } on TimeoutException catch (e) {
      debugPrint('⚠️ Location timeout: $e');
      // Try with lower accuracy as fallback
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy:
                LocationAccuracy.medium, // Lower accuracy for faster response
            timeLimit: Duration(seconds: 5),
          ),
        ).timeout(const Duration(seconds: 5));
      } catch (fallbackError) {
        debugPrint('⚠️ Fallback location also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// Enhanced clustering algorithm for performance optimization
  void _updateClustering() {
    if (!widget.enableClustering ||
        widget.markers.length <= widget.maxMarkersBeforeClustering) {
      _visibleMarkers = widget.markers;
      _clusters.clear();
      return;
    }

    // Throttle clustering updates for performance
    final now = DateTime.now();
    if (_lastClusterUpdate != null &&
        now.difference(_lastClusterUpdate!) < _clusterUpdateThrottle) {
      return;
    }

    _lastClusterUpdate = now;
    _clusters.clear();
    _visibleMarkers.clear();

    // Group markers by proximity based on zoom level
    final clusterDistance = _getClusterDistance(_currentZoom);
    final processed = <String>{};

    for (final marker in widget.markers) {
      if (processed.contains(marker.markerId)) continue;

      final cluster = MapCluster(
        clusterId: 'cluster_${marker.markerId}',
        center: marker.position,
        markers: [marker],
      );

      processed.add(marker.markerId);

      // Find nearby markers to cluster
      for (final otherMarker in widget.markers) {
        if (processed.contains(otherMarker.markerId)) continue;

        final distance =
            _calculateDistance(marker.position, otherMarker.position);
        if (distance <= clusterDistance) {
          cluster.markers.add(otherMarker);
          processed.add(otherMarker.markerId);
        }
      }

      if (cluster.markers.length > 1) {
        _clusters.add(cluster);
      } else {
        _visibleMarkers.add(marker);
      }
    }

    _needsClusterUpdate = false;
  }

  double _getClusterDistance(double zoom) {
    // Adjust clustering distance based on zoom level
    if (zoom >= 16) return 0.0001; // Very close clustering at high zoom
    if (zoom >= 14) return 0.0005; // Medium clustering
    if (zoom >= 12) return 0.001; // Wider clustering
    return 0.002; // Very wide clustering at low zoom
  }

  double _calculateDistance(LatLng pos1, LatLng pos2) {
    return Geolocator.distanceBetween(
          pos1.latitude,
          pos1.longitude,
          pos2.latitude,
          pos2.longitude,
        ) /
        1000; // Convert to kilometers
  }

  void _onCameraMove(double zoom) {
    if ((_currentZoom - zoom).abs() > 0.5) {
      // Significant zoom change
      _currentZoom = zoom;
      _needsClusterUpdate = true;
      _updateClustering();
      widget.onZoomChanged?.call(zoom);

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait for actual location - no default fallback
    if (_isLoading || _currentLocation == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[800]!,
              Colors.green[600]!,
              Colors.blue[400]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _isLoading
                    ? 'Getting your location...'
                    : 'Location not available. Please enable location services.',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Use platform-specific maps with fallback
    if (_platformViewFailed) {
      return _buildFallbackMap();
    }

    try {
      // Use Google Maps on both iOS and Android
      // Apple Maps code is commented out but preserved below
      // if (Platform.isIOS) {
      //   return _buildAppleMap();
      // } else {
      return _buildGoogleMap();
      // }
    } catch (e) {
      print('Platform view error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _platformViewFailed = true;
          });
        }
      });
      return _buildFallbackMap();
    }
  }

  /// Apply 3D view settings for Apple Maps
  /// COMMENTED OUT: Using Google Maps on all platforms now
  // Future<void> _applyAppleMaps3DView() async {
  //   if (!_isMapCreated || _appleMapController == null) return;
  //
  //   final location = widget.initialLocation ?? _currentLocation;
  //   if (location == null) return;
  //
  //   try {
  //     // For Apple Maps, we enable pitch gestures and let users tilt manually
  //     // Apple Maps doesn't support programmatic pitch setting in the plugin
  //     // But we can ensure the map is ready for 3D gestures
  //     debugPrint('🎯 Apple Maps: 3D view enabled - pitch gestures active');
  //
  //     // The pitchGesturesEnabled property in the widget will handle enabling gestures
  //     // Users can now use two-finger drag up/down to tilt the map
  //   } catch (e) {
  //     debugPrint('❌ Error applying Apple Maps 3D view: $e');
  //   }
  // }

  /// Build Apple Maps widget
  /// COMMENTED OUT: Using Google Maps on all platforms now
  //   // Widget _buildAppleMap() {
  //   // Update clustering if needed
  //   if (_needsClusterUpdate) {
  //     _updateClustering();
  //   }
  //
  //   return apple_maps.AppleMap(
  //     initialCameraPosition: apple_maps.CameraPosition(
  //       target: apple_maps.LatLng(
  //           _currentLocation!.latitude, _currentLocation!.longitude),
  //       zoom: widget.initialZoom,
  //     ),
  //     onMapCreated: (apple_maps.AppleMapController controller) {
  //       _appleMapController = controller;
  //       _isMapCreated = true;
  //       // Apply 3D view if enabled
  //       if (_is3DViewEnabled) {
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (mounted) {
  //             _applyAppleMaps3DView();
  //           }
  //         });
  //       }
  //       // Update markers after map is created
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (mounted && _needsClusterUpdate) {
  //           _updateClustering();
  //         }
  //       });
  //     },
  //     annotations: _convertToAppleAnnotations(),
  //     polylines: _convertToApplePolylines(),
  //     mapType: _convertToAppleMapType(widget.mapType),
  //     myLocationEnabled: true, // Always show current location on Apple Maps
  //     myLocationButtonEnabled: false, // We have custom location button
  //     scrollGesturesEnabled: widget.enableScrollGestures,
  //     zoomGesturesEnabled: widget.enableZoomGestures,
  //     // Enable pitch gestures when 3D view is enabled - allows two-finger tilt
  //     pitchGesturesEnabled: _is3DViewEnabled,
  //     // Always enable rotate gestures for better 3D experience
  //     rotateGesturesEnabled: true,
  //     onCameraMove: (apple_maps.CameraPosition position) {
  //       _onCameraMove(position.zoom);
  //       // Apple Maps doesn't expose tilt/bearing in CameraPosition
  //       // These are handled through gesture controls (pitchGesturesEnabled)
  //     },
  //     onTap: (apple_maps.LatLng position) {
  //       final latLng = LatLng(position.latitude, position.longitude);
  //       if (_isDrawingPolyline) {
  //         addPolylinePoint(latLng);
  //       } else {
  //         widget.onMapTap?.call(latLng);
  //       }
  //     },
  //     onLongPress: (apple_maps.LatLng position) {
  //       if ((widget.enablePolylineDrawing ?? false) && !_isDrawingPolyline) {
  //         startDrawingPolyline();
  //         addPolylinePoint(LatLng(position.latitude, position.longitude));
  //       }
  //     },
  //   );
  // }

  Widget _buildGoogleMap() {
    // Update clustering if needed
    if (_needsClusterUpdate) {
      _updateClustering();
    }

    return google_maps.GoogleMap(
      initialCameraPosition: google_maps.CameraPosition(
        target: google_maps.LatLng(
            _currentLocation!.latitude, _currentLocation!.longitude),
        zoom: widget.initialZoom,
        tilt: _is3DViewEnabled ? _currentTilt : 0.0,
        bearing: _currentBearing,
      ),
      onMapCreated: (google_maps.GoogleMapController controller) async {
        _googleMapController = controller;
        _isMapCreated = true;

        // Apply dark mode style if system is in dark mode
        _applyMapStyle();

        // Update markers after map is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _needsClusterUpdate) {
            _updateClustering();
          }
        });
      },
      markers: _convertToGoogleMarkers(),
      polylines: _convertToGooglePolylines(),
      mapType: _convertToGoogleMapType(widget.mapType),
      myLocationEnabled: true, // Always show current location on Google Maps
      myLocationButtonEnabled: false, // We have custom location button
      scrollGesturesEnabled: widget.enableScrollGestures,
      zoomGesturesEnabled: widget.enableZoomGestures,
      tiltGesturesEnabled: _is3DViewEnabled,
      rotateGesturesEnabled: true,
      buildingsEnabled: _is3DViewEnabled,
      onCameraMove: (google_maps.CameraPosition position) {
        _onCameraMove(position.zoom);
        _currentTilt = position.tilt;
        _currentBearing = position.bearing;
        widget.onTiltChanged?.call(_currentTilt);
        widget.onBearingChanged?.call(_currentBearing);
      },
      onTap: (google_maps.LatLng position) {
        final latLng = LatLng(position.latitude, position.longitude);
        if (_isDrawingPolyline) {
          addPolylinePoint(latLng);
        } else {
          widget.onMapTap?.call(latLng);
        }
      },
      onLongPress: (google_maps.LatLng position) {
        if ((widget.enablePolylineDrawing ?? false) && !_isDrawingPolyline) {
          startDrawingPolyline();
          addPolylinePoint(LatLng(position.latitude, position.longitude));
        }
      },
    );
  }

  /// Apply map style based on system theme (dark/light mode)
  void _applyMapStyle() {
    if (_googleMapController == null) return;

    // Check if system is in dark mode
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = brightness == Brightness.dark;

    if (isDarkMode) {
      _googleMapController!.setMapStyle(_darkMapStyle);
      debugPrint('🌙 Map: Dark mode style applied');
    } else {
      // Use default light style (null clears custom style)
      _googleMapController!.setMapStyle(null);
      debugPrint('☀️ Map: Light mode style applied');
    }
  }

  Widget _buildFallbackMap() {
    // If no location available, show error message
    if (_currentLocation == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[800]!,
              Colors.green[600]!,
              Colors.blue[400]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Location not available',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enable location services to use the map',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[800]!,
            Colors.green[600]!,
            Colors.blue[400]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Custom painted map background
          CustomPaint(
            painter: _FallbackMapPainter(_currentLocation!, widget.markers),
            size: Size.infinite,
          ),

          // Overlay markers as positioned widgets
          ..._buildFallbackMarkers(),

          // Map info overlay
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Google Maps Fallback',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fully functional golf tracking',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _platformViewFailed = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Retry Google Maps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFallbackMarkers() {
    return widget.markers.map((marker) {
      // Convert lat/lng to screen position (simplified)
      final centerLat = _currentLocation!.latitude;
      final centerLng = _currentLocation!.longitude;

      // Simple projection (not accurate but functional for demo)
      final deltaLat = marker.position.latitude - centerLat;
      final deltaLng = marker.position.longitude - centerLng;

      // Convert to screen coordinates (rough approximation)
      final screenX =
          (deltaLng * 1000000) + (MediaQuery.of(context).size.width / 2);
      final screenY =
          (-deltaLat * 1000000) + (MediaQuery.of(context).size.height / 2);

      // Only show markers that are roughly on screen
      if (screenX < -50 ||
          screenX > MediaQuery.of(context).size.width + 50 ||
          screenY < -50 ||
          screenY > MediaQuery.of(context).size.height + 50) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: screenX - 12,
        top: screenY - 24,
        child: GestureDetector(
          onTap: () => widget.onMarkerTap?.call(marker),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: marker.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.place,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Convert markers to Apple Maps annotations
  /// COMMENTED OUT: Using Google Maps on all platforms now
  // Set<apple_maps.Annotation> _convertToAppleAnnotations() {
  //   final annotations = <apple_maps.Annotation>{};
  //
  //   // Add individual markers with custom icons
  //   for (final marker in _visibleMarkers) {
  //     // Get icon bytes from marker (preferred) or try to extract from descriptor
  //     Uint8List? iconBytes = marker.iconBytes;
  //     if (iconBytes == null && marker.icon != null) {
  //       // Fallback: try to get bytes from custom marker service cache
  //       iconBytes = FoCoMapCustomMarkers.getBytesFromDescriptor(marker.icon!);
  //     }
  //
  //     // Create annotation - Apple Maps Annotation may support custom icons via:
  //     // - annotationIcon property (Uint8List)
  //     // - icon property (Uint8List or UIImage)
  //     // Check apple_maps_flutter 1.4.0 API documentation for exact property name
  //     final annotation = apple_maps.Annotation(
  //       annotationId: apple_maps.AnnotationId(marker.markerId),
  //       position: apple_maps.LatLng(
  //           marker.position.latitude, marker.position.longitude),
  //       infoWindow: apple_maps.InfoWindow(
  //         title: marker.infoWindow.title,
  //         snippet: marker.infoWindow.snippet,
  //       ),
  //       // TODO: Add custom icon support once we verify the API property name
  //       // If apple_maps_flutter supports: annotationIcon: iconBytes
  //       // or icon: iconBytes (check actual API)
  //       onTap: () {
  //         widget.onMarkerTap?.call(marker);
  //       },
  //     );
  //
  //     annotations.add(annotation);
  //
  //     if (iconBytes != null) {
  //       debugPrint('✅ Apple Maps: Custom icon bytes ready for marker ${marker.markerId} (${iconBytes.length} bytes) - Note: Need to verify API property name');
  //     } else {
  //       debugPrint('⚠️ Apple Maps: No custom icon bytes for marker ${marker.markerId} - will use default pin');
  //     }
  //   }
  //
  //   // Add cluster markers
  //   for (final cluster in _clusters) {
  //     annotations.add(
  //       apple_maps.Annotation(
  //         annotationId: apple_maps.AnnotationId(cluster.clusterId),
  //         position: apple_maps.LatLng(
  //             cluster.center.latitude, cluster.center.longitude),
  //         infoWindow: apple_maps.InfoWindow(
  //           title: '${cluster.markers.length} locations',
  //           snippet: 'Tap to expand cluster',
  //         ),
  //         onTap: () {
  //           _handleClusterTap(cluster);
  //         },
  //       ),
  //     );
  //   }
  //
  //   return annotations;
  // }

  Set<google_maps.Marker> _convertToGoogleMarkers() {
    final markers = <google_maps.Marker>{};

    // Add individual markers
    for (final marker in _visibleMarkers) {
      markers.add(
        google_maps.Marker(
          markerId: google_maps.MarkerId(marker.markerId),
          position: google_maps.LatLng(
              marker.position.latitude, marker.position.longitude),
          icon: marker.icon ?? google_maps.BitmapDescriptor.defaultMarker,
          infoWindow: google_maps.InfoWindow(
            title: marker.infoWindow.title,
            snippet: marker.infoWindow.snippet,
          ),
          onTap: () {
            widget.onMarkerTap?.call(marker);
          },
        ),
      );
    }

    // Add cluster markers
    for (final cluster in _clusters) {
      markers.add(
        google_maps.Marker(
          markerId: google_maps.MarkerId(cluster.clusterId),
          position: google_maps.LatLng(
              cluster.center.latitude, cluster.center.longitude),
          infoWindow: google_maps.InfoWindow(
            title: '${cluster.markers.length} locations',
            snippet: 'Tap to expand cluster',
          ),
          onTap: () {
            _handleClusterTap(cluster);
          },
        ),
      );
    }

    return markers;
  }

  void _handleClusterTap(MapCluster cluster) {
    // Zoom in to expand cluster or show cluster details
    if (_currentZoom < 16) {
      // Zoom in to expand cluster
      animateToLocation(cluster.center, zoom: _currentZoom + 2);
    } else {
      // Show cluster details in a bottom sheet or dialog
      _showClusterDetails(cluster);
    }
  }

  void _showClusterDetails(MapCluster cluster) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cluster Details (${cluster.markers.length} items)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cluster.markers.length,
                  itemBuilder: (context, index) {
                    final marker = cluster.markers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: marker.color ?? Colors.blue,
                        child: const Icon(Icons.place, color: Colors.white),
                      ),
                      title: Text(marker.infoWindow.title ?? 'Location'),
                      subtitle: Text(marker.infoWindow.snippet ?? ''),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onMarkerTap?.call(marker);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convert MapType to Apple Maps format
  /// COMMENTED OUT: Using Google Maps on all platforms now
  // apple_maps.MapType _convertToAppleMapType(MapType mapType) {
  //   switch (mapType) {
  //     case MapType.satellite:
  //       return apple_maps.MapType.satellite;
  //     case MapType.hybrid:
  //       return apple_maps.MapType.hybrid;
  //     case MapType.normal:
  //       return apple_maps.MapType.standard;
  //   }
  // }

  google_maps.MapType _convertToGoogleMapType(MapType mapType) {
    switch (mapType) {
      case MapType.satellite:
        return google_maps.MapType.satellite;
      case MapType.hybrid:
        return google_maps.MapType.hybrid;
      case MapType.normal:
        return google_maps.MapType.normal;
    }
  }

  Future<void> animateToLocation(LatLng location, {double? zoom}) async {
    // Apple Maps code commented out - using Google Maps on all platforms
    // if (Platform.isIOS && _appleMapController != null) {
    //   await _appleMapController!.animateCamera(
    //     apple_maps.CameraUpdate.newCameraPosition(
    //       apple_maps.CameraPosition(
    //         target: apple_maps.LatLng(location.latitude, location.longitude),
    //         zoom: zoom ?? widget.initialZoom,
    //       ),
    //     ),
    //   );
    // } else
    if (_googleMapController != null) {
      await _googleMapController!.animateCamera(
        google_maps.CameraUpdate.newCameraPosition(
          google_maps.CameraPosition(
            target: google_maps.LatLng(location.latitude, location.longitude),
            zoom: zoom ?? widget.initialZoom,
            tilt: _is3DViewEnabled ? _currentTilt : 0.0,
            bearing: _currentBearing,
          ),
        ),
      );
    }
  }

  /// Convert polylines to Apple Maps format
  /// COMMENTED OUT: Using Google Maps on all platforms now
  // Set<apple_maps.Polyline> _convertToApplePolylines() {
  //   final applePolylines = <apple_maps.Polyline>{};
  //
  //   // Add existing polylines
  //   for (final polyline in _polylines) {
  //     applePolylines.add(
  //       apple_maps.Polyline(
  //         polylineId: apple_maps.PolylineId(polyline.polylineId),
  //         points: polyline.points.map((p) => apple_maps.LatLng(p.latitude, p.longitude)).toList(),
  //         color: polyline.color,
  //         width: polyline.width.toInt(),
  //         patterns: polyline.pattern.map((p) => apple_maps.PatternItem.dash(p.toDouble())).toList(),
  //       ),
  //     );
  //   }
  //
  //     // Add current drawing polyline if active
  //     if (_isDrawingPolyline && _currentPolylinePoints.isNotEmpty) {
  //       applePolylines.add(
  //         apple_maps.Polyline(
  //           polylineId: apple_maps.PolylineId('drawing_polyline'),
  //           points: _currentPolylinePoints.map((p) => apple_maps.LatLng(p.latitude, p.longitude)).toList(),
  //           color: Colors.blue,
  //           width: 4,
  //         ),
  //       );
  //     }
  //
  //   return applePolylines;
  // }

  /// Convert polylines to Google Maps format
  Set<google_maps.Polyline> _convertToGooglePolylines() {
    final googlePolylines = <google_maps.Polyline>{};

    // Add existing polylines
    for (final polyline in _polylines) {
      googlePolylines.add(
        google_maps.Polyline(
          polylineId: google_maps.PolylineId(polyline.polylineId),
          points: polyline.points
              .map((p) => google_maps.LatLng(p.latitude, p.longitude))
              .toList(),
          color: polyline.color,
          width: polyline.width.toInt(),
          patterns: polyline.pattern
              .map((p) => google_maps.PatternItem.dash(p.toDouble()))
              .toList(),
          geodesic: polyline.geodesic,
          zIndex: polyline.zIndex,
        ),
      );
    }

    // Add current drawing polyline if active
    if (_isDrawingPolyline && _currentPolylinePoints.isNotEmpty) {
      googlePolylines.add(
        google_maps.Polyline(
          polylineId: google_maps.PolylineId('drawing_polyline'),
          points: _currentPolylinePoints
              .map((p) => google_maps.LatLng(p.latitude, p.longitude))
              .toList(),
          color: Colors.blue,
          width: 4,
          geodesic: true,
        ),
      );
    }

    return googlePolylines;
  }
}

/// Universal Map Marker class
class MapMarker {
  final String markerId;
  final LatLng position;
  final InfoWindow infoWindow;
  final Color? color;
  final BitmapDescriptor? icon;
  final Uint8List? iconBytes; // PNG bytes for Apple Maps

  const MapMarker({
    required this.markerId,
    required this.position,
    required this.infoWindow,
    this.color,
    this.icon,
    this.iconBytes,
  });
}

/// Universal InfoWindow class
class InfoWindow {
  final String? title;
  final String? snippet;

  const InfoWindow({
    this.title,
    this.snippet,
  });
}

/// Universal MapType enum
enum MapType {
  normal,
  satellite,
  hybrid,
}

/// Map Cluster class for grouping nearby markers
class MapCluster {
  final String clusterId;
  final LatLng center;
  final List<MapMarker> markers;

  MapCluster({
    required this.clusterId,
    required this.center,
    required this.markers,
  });

  /// Calculate the center point of all markers in the cluster
  LatLng calculateCenter() {
    if (markers.isEmpty) return center;

    double totalLat = 0;
    double totalLng = 0;

    for (final marker in markers) {
      totalLat += marker.position.latitude;
      totalLng += marker.position.longitude;
    }

    return LatLng(
      totalLat / markers.length,
      totalLng / markers.length,
    );
  }

  /// Get the dominant color of markers in this cluster
  Color getDominantColor() {
    if (markers.isEmpty) return Colors.blue;

    final colorCounts = <Color, int>{};
    for (final marker in markers) {
      final color = marker.color ?? Colors.blue;
      colorCounts[color] = (colorCounts[color] ?? 0) + 1;
    }

    return colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Map Polyline class for drawing paths on the map
class MapPolyline {
  final String polylineId;
  final List<LatLng> points;
  final Color color;
  final double width;
  final List<int> pattern;
  final bool geodesic;
  final int zIndex;

  const MapPolyline({
    required this.polylineId,
    required this.points,
    this.color = Colors.blue,
    this.width = 5.0,
    this.pattern = const [],
    this.geodesic = true,
    this.zIndex = 0,
  });
}

/// Custom painter for fallback map when platform views fail
class _FallbackMapPainter extends CustomPainter {
  final LatLng center;
  final Set<MapMarker> markers;

  _FallbackMapPainter(this.center, this.markers);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw map background with grid pattern
    paint.color = Colors.green[700]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw grid lines to simulate map
    paint.color = Colors.green[600]!;
    paint.strokeWidth = 1;

    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw center point
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      8,
      paint,
    );

    // Draw center border
    paint.color = Colors.blue;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      8,
      paint,
    );

    // Draw some decorative elements to make it look more map-like
    paint.color = Colors.green[500]!;
    paint.style = PaintingStyle.fill;

    // Draw some "terrain" features
    for (int i = 0; i < 5; i++) {
      final x = (i * 0.2 + 0.1) * size.width;
      final y = (i * 0.15 + 0.2) * size.height;
      canvas.drawCircle(Offset(x, y), 20 + (i * 5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
