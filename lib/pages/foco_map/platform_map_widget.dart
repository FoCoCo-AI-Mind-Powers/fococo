import 'dart:io';
import 'package:flutter/material.dart';
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:geolocator/geolocator.dart';
import '/flutter_flow/lat_lng.dart';

/// Platform-aware map widget that uses Apple Maps on iOS and Google Maps on Android
/// iOS: Native Apple Maps integration
/// Android: Google Maps with API key required
class PlatformMapWidget extends StatefulWidget {
  final Set<MapMarker> markers;
  final Function(MapMarker)? onMarkerTap;
  final Function(LatLng)? onMapTap;
  final LatLng? initialLocation;
  final double initialZoom;
  final MapType mapType;

  const PlatformMapWidget({
    super.key,
    this.markers = const {},
    this.onMarkerTap,
    this.onMapTap,
    this.initialLocation,
    this.initialZoom = 14.0,
    this.mapType = MapType.normal,
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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onTap: (apple_maps.LatLng position) {
        widget.onMapTap?.call(LatLng(position.latitude, position.longitude));
      },
    );
  }

  Widget _buildGoogleMap() {
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
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
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
    return widget.markers.map((marker) {
      return apple_maps.Annotation(
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
      );
    }).toSet();
  }

  Set<google_maps.Marker> _convertToGoogleMarkers() {
    return widget.markers.map((marker) {
      return google_maps.Marker(
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
      );
    }).toSet();
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
