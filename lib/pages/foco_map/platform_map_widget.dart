import 'dart:io';
import 'package:flutter/material.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:geolocator/geolocator.dart';
import '/flutter_flow/lat_lng.dart';

/// Enhanced Platform-aware map widget with clustering and performance optimization
/// iOS: Native Apple Maps integration with clustering
/// Android: Google Maps with clustering support
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
  });

  @override
  State<PlatformMapWidget> createState() => _PlatformMapWidgetState();
}

class _PlatformMapWidgetState extends State<PlatformMapWidget> {
  apple_maps.AppleMapController? _appleMapController;
  google_maps.GoogleMapController? _googleMapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _platformViewFailed = false;

  // Enhanced state management for clustering and performance
  double _currentZoom = 14.0;
  Set<MapMarker> _visibleMarkers = {};
  Set<MapCluster> _clusters = {};
  bool _needsClusterUpdate = true;

  // Performance optimization
  DateTime? _lastClusterUpdate;
  static const Duration _clusterUpdateThrottle = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.initialZoom;
    _initializeLocation();
  }

  @override
  void didUpdateWidget(PlatformMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if markers changed and need clustering update
    if (widget.markers != oldWidget.markers) {
      _needsClusterUpdate = true;
      _updateClustering();
    }
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLocation != null) {
        _currentLocation = widget.initialLocation;
      } else {
        final position = await _getCurrentPosition();
        _currentLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      // Default to a golf course location if permission denied
      _currentLocation = const LatLng(40.7128, -74.0060); // New York
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
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
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Use platform-specific maps with fallback
    if (_platformViewFailed) {
      return _buildFallbackMap();
    }

    try {
      if (Platform.isIOS) {
        return _buildAppleMap();
      } else {
        return _buildGoogleMap();
      }
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

  Widget _buildAppleMap() {
    // Update clustering if needed
    if (_needsClusterUpdate) {
      _updateClustering();
    }

    return apple_maps.AppleMap(
      initialCameraPosition: apple_maps.CameraPosition(
        target: apple_maps.LatLng(
            _currentLocation!.latitude, _currentLocation!.longitude),
        zoom: widget.initialZoom,
      ),
      onMapCreated: (apple_maps.AppleMapController controller) {
        _appleMapController = controller;
      },
      annotations: _convertToAppleAnnotations(),
      mapType: _convertToAppleMapType(widget.mapType),
      myLocationEnabled: widget.showUserLocation,
      myLocationButtonEnabled: false,
      scrollGesturesEnabled: widget.enableScrollGestures,
      zoomGesturesEnabled: widget.enableZoomGestures,
      onCameraMove: (apple_maps.CameraPosition position) {
        _onCameraMove(position.zoom);
      },
      onTap: (apple_maps.LatLng position) {
        widget.onMapTap?.call(LatLng(position.latitude, position.longitude));
      },
    );
  }

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
      ),
      onMapCreated: (google_maps.GoogleMapController controller) {
        _googleMapController = controller;
      },
      markers: _convertToGoogleMarkers(),
      mapType: _convertToGoogleMapType(widget.mapType),
      myLocationEnabled: widget.showUserLocation,
      myLocationButtonEnabled: false,
      scrollGesturesEnabled: widget.enableScrollGestures,
      zoomGesturesEnabled: widget.enableZoomGestures,
      onCameraMove: (google_maps.CameraPosition position) {
        _onCameraMove(position.zoom);
      },
      onTap: (google_maps.LatLng position) {
        widget.onMapTap?.call(LatLng(position.latitude, position.longitude));
      },
    );
  }

  Widget _buildFallbackMap() {
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
                        Platform.isIOS ? Icons.apple : Icons.android,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Platform.isIOS
                            ? 'Apple Maps Fallback'
                            : 'Google Maps Fallback',
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
                        'Retry ${Platform.isIOS ? 'Apple' : 'Google'} Maps',
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

  Set<apple_maps.Annotation> _convertToAppleAnnotations() {
    final annotations = <apple_maps.Annotation>{};

    // Add individual markers
    for (final marker in _visibleMarkers) {
      annotations.add(
        apple_maps.Annotation(
          annotationId: apple_maps.AnnotationId(marker.markerId),
          position: apple_maps.LatLng(
              marker.position.latitude, marker.position.longitude),
          infoWindow: apple_maps.InfoWindow(
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
      annotations.add(
        apple_maps.Annotation(
          annotationId: apple_maps.AnnotationId(cluster.clusterId),
          position: apple_maps.LatLng(
              cluster.center.latitude, cluster.center.longitude),
          infoWindow: apple_maps.InfoWindow(
            title: '${cluster.markers.length} locations',
            snippet: 'Tap to expand cluster',
          ),
          onTap: () {
            _handleClusterTap(cluster);
          },
        ),
      );
    }

    return annotations;
  }

  Set<google_maps.Marker> _convertToGoogleMarkers() {
    final markers = <google_maps.Marker>{};

    // Add individual markers
    for (final marker in _visibleMarkers) {
      markers.add(
        google_maps.Marker(
          markerId: google_maps.MarkerId(marker.markerId),
          position: google_maps.LatLng(
              marker.position.latitude, marker.position.longitude),
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

  apple_maps.MapType _convertToAppleMapType(MapType mapType) {
    switch (mapType) {
      case MapType.satellite:
        return apple_maps.MapType.satellite;
      case MapType.hybrid:
        return apple_maps.MapType.hybrid;
      case MapType.normal:
        return apple_maps.MapType.standard;
    }
  }

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
    if (Platform.isIOS && _appleMapController != null) {
      await _appleMapController!.animateCamera(
        apple_maps.CameraUpdate.newCameraPosition(
          apple_maps.CameraPosition(
            target: apple_maps.LatLng(location.latitude, location.longitude),
            zoom: zoom ?? widget.initialZoom,
          ),
        ),
      );
    } else if (Platform.isAndroid && _googleMapController != null) {
      await _googleMapController!.animateCamera(
        google_maps.CameraUpdate.newCameraPosition(
          google_maps.CameraPosition(
            target: google_maps.LatLng(location.latitude, location.longitude),
            zoom: zoom ?? widget.initialZoom,
          ),
        ),
      );
    }
  }
}

/// Universal Map Marker class
class MapMarker {
  final String markerId;
  final LatLng position;
  final InfoWindow infoWindow;
  final Color? color;

  const MapMarker({
    required this.markerId,
    required this.position,
    required this.infoWindow,
    this.color,
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
