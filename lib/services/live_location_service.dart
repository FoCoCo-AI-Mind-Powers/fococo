import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart' hide LocationAccuracy;
import '/flutter_flow/lat_lng.dart';

/// Live Location Service for FoCoMap
/// Provides real-time GPS tracking with golf course context awareness
class LiveLocationService {
  static final LiveLocationService _instance = LiveLocationService._internal();
  factory LiveLocationService() => _instance;
  LiveLocationService._internal();

  final Location _location = Location();

  // Stream controllers for real-time updates
  final _locationController = StreamController<LatLng>.broadcast();
  final _accuracyController = StreamController<double>.broadcast();
  final _speedController = StreamController<double>.broadcast();
  final _headingController = StreamController<double>.broadcast();
  final _courseContextController = StreamController<CourseContext>.broadcast();

  // State management
  bool _isTracking = false;
  bool _isInitialized = false;
  LatLng? _currentLocation;
  double _currentAccuracy = 0.0;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  StreamSubscription<LocationData>? _locationSubscription;

  // Golf course context
  CourseContext _currentContext = CourseContext.unknown;
  List<GolfCourse> _nearbyGolfCourses = [];
  GolfCourse? _activeGolfCourse;

  // Location tracking settings
  static const double _minAccuracy = 10.0; // meters
  static const double _minDistanceFilter = 2.0; // meters
  static const Duration _locationInterval = Duration(seconds: 2);

  // Streams
  Stream<LatLng> get locationStream => _locationController.stream;
  Stream<double> get accuracyStream => _accuracyController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get headingStream => _headingController.stream;
  Stream<CourseContext> get courseContextStream =>
      _courseContextController.stream;

  // Getters
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;
  LatLng? get currentLocation => _currentLocation;
  double get currentAccuracy => _currentAccuracy;
  double get currentSpeed => _currentSpeed;
  double get currentHeading => _currentHeading;
  CourseContext get currentContext => _currentContext;
  GolfCourse? get activeGolfCourse => _activeGolfCourse;

  /// Initialize the location service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw LocationException('Location service is disabled');
        }
      }

      // Check permissions
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw LocationException('Location permission denied');
        }
      }

      // Configure location settings for golf course accuracy
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: _locationInterval.inMilliseconds,
        distanceFilter: _minDistanceFilter,
      );

      // Load nearby golf courses
      await _loadNearbyGolfCourses();

      _isInitialized = true;
      debugPrint('LiveLocationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LiveLocationService: $e');
      rethrow;
    }
  }

  /// Start live location tracking
  Future<void> startTracking() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isTracking) return;

    try {
      _isTracking = true;

      // Get initial location
      final initialLocation = await _location.getLocation();
      _updateLocationData(initialLocation);

      // Start continuous tracking
      _locationSubscription = _location.onLocationChanged.listen(
        _updateLocationData,
        onError: (error) {
          debugPrint('Location tracking error: $error');
          _handleLocationError(error);
        },
      );

      debugPrint('Live location tracking started');
    } catch (e) {
      _isTracking = false;
      debugPrint('Error starting location tracking: $e');
      rethrow;
    }
  }

  /// Stop live location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _isTracking = false;
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    debugPrint('Live location tracking stopped');
  }

  /// Update location data and context
  void _updateLocationData(LocationData locationData) {
    if (locationData.latitude == null || locationData.longitude == null) return;

    final newLocation = LatLng(locationData.latitude!, locationData.longitude!);
    final accuracy = locationData.accuracy ?? 0.0;
    final speed = locationData.speed ?? 0.0;
    final heading = locationData.heading ?? 0.0;

    // Only update if accuracy is acceptable
    if (accuracy > 0 && accuracy <= _minAccuracy * 3) {
      _currentLocation = newLocation;
      _currentAccuracy = accuracy;
      _currentSpeed = speed * 3.6; // Convert m/s to km/h
      _currentHeading = heading;

      // Update streams
      _locationController.add(newLocation);
      _accuracyController.add(accuracy);
      _speedController.add(_currentSpeed);
      _headingController.add(heading);

      // Update golf course context
      _updateCourseContext(newLocation);
    }
  }

  /// Update golf course context based on current location
  void _updateCourseContext(LatLng location) {
    CourseContext newContext = CourseContext.unknown;
    GolfCourse? nearestCourse;
    double minDistance = double.infinity;

    // Find nearest golf course
    for (final course in _nearbyGolfCourses) {
      final distance = _calculateDistance(location, course.centerLocation);

      if (distance < minDistance) {
        minDistance = distance;
        nearestCourse = course;
      }
    }

    // Determine context based on distance to nearest course
    if (nearestCourse != null) {
      if (minDistance <= 0.1) {
        // Within 100m - on course
        newContext = CourseContext.onCourse;
        _activeGolfCourse = nearestCourse;
      } else if (minDistance <= 0.5) {
        // Within 500m - near course
        newContext = CourseContext.nearCourse;
        _activeGolfCourse = nearestCourse;
      } else if (minDistance <= 2.0) {
        // Within 2km - approaching course
        newContext = CourseContext.approachingCourse;
        _activeGolfCourse = nearestCourse;
      } else {
        newContext = CourseContext.offCourse;
        _activeGolfCourse = null;
      }
    }

    // Update context if changed
    if (newContext != _currentContext) {
      _currentContext = newContext;
      _courseContextController.add(newContext);

      debugPrint('Course context changed to: ${newContext.name}');
      if (_activeGolfCourse != null) {
        debugPrint('Active course: ${_activeGolfCourse!.name}');
      }
    }
  }

  /// Load nearby golf courses (Portuguese courses from sample data)
  Future<void> _loadNearbyGolfCourses() async {
    _nearbyGolfCourses = [
      GolfCourse(
        id: 'quinta_lago_north',
        name: 'Quinta do Lago North',
        centerLocation: LatLng(37.0234, -8.0051),
        type: CourseType.coastal,
      ),
      GolfCourse(
        id: 'troia_golf',
        name: 'Troia Golf',
        centerLocation: LatLng(38.4897, -8.9089),
        type: CourseType.links,
      ),
      GolfCourse(
        id: 'dom_pedro_victoria',
        name: 'Dom Pedro Victoria',
        centerLocation: LatLng(37.1089, -8.1234),
        type: CourseType.parkland,
      ),
      GolfCourse(
        id: 'vale_do_lobo_ocean',
        name: 'Vale do Lobo Ocean',
        centerLocation: LatLng(37.0789, -8.0456),
        type: CourseType.resort,
      ),
      GolfCourse(
        id: 'penha_longa_atlantic',
        name: 'Penha Longa Atlantic',
        centerLocation: LatLng(38.7967, -9.3789),
        type: CourseType.mountain,
      ),
      GolfCourse(
        id: 'oitavos_dunes',
        name: 'Oitavos Dunes',
        centerLocation: LatLng(38.7234, -9.4678),
        type: CourseType.links,
      ),
      GolfCourse(
        id: 'aroeira_challenge',
        name: 'Aroeira Challenge',
        centerLocation: LatLng(38.5567, -8.9234),
        type: CourseType.parkland,
      ),
      GolfCourse(
        id: 'palmares_beach',
        name: 'Palmares Beach',
        centerLocation: LatLng(37.1456, -8.5789),
        type: CourseType.coastal,
      ),
    ];
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000; // Convert to kilometers
  }

  /// Handle location errors
  void _handleLocationError(dynamic error) {
    debugPrint('Location error: $error');
    // Could emit error events here if needed
  }

  /// Get location accuracy description
  String getAccuracyDescription() {
    if (_currentAccuracy <= 3)
      return 'Excellent (${_currentAccuracy.toStringAsFixed(1)}m)';
    if (_currentAccuracy <= 10)
      return 'Good (${_currentAccuracy.toStringAsFixed(1)}m)';
    if (_currentAccuracy <= 30)
      return 'Fair (${_currentAccuracy.toStringAsFixed(1)}m)';
    return 'Poor (${_currentAccuracy.toStringAsFixed(1)}m)';
  }

  /// Get speed description
  String getSpeedDescription() {
    if (_currentSpeed < 1) return 'Stationary';
    if (_currentSpeed < 5)
      return 'Walking (${_currentSpeed.toStringAsFixed(1)} km/h)';
    if (_currentSpeed < 15)
      return 'Cart (${_currentSpeed.toStringAsFixed(1)} km/h)';
    return 'Driving (${_currentSpeed.toStringAsFixed(1)} km/h)';
  }

  /// Get heading description
  String getHeadingDescription() {
    if (_currentHeading >= 337.5 || _currentHeading < 22.5) return 'North';
    if (_currentHeading >= 22.5 && _currentHeading < 67.5) return 'Northeast';
    if (_currentHeading >= 67.5 && _currentHeading < 112.5) return 'East';
    if (_currentHeading >= 112.5 && _currentHeading < 157.5) return 'Southeast';
    if (_currentHeading >= 157.5 && _currentHeading < 202.5) return 'South';
    if (_currentHeading >= 202.5 && _currentHeading < 247.5) return 'Southwest';
    if (_currentHeading >= 247.5 && _currentHeading < 292.5) return 'West';
    return 'Northwest';
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _locationController.close();
    _accuracyController.close();
    _speedController.close();
    _headingController.close();
    _courseContextController.close();
  }
}

/// Golf course context for location awareness
enum CourseContext {
  unknown('Unknown'),
  offCourse('Off Course'),
  approachingCourse('Approaching Course'),
  nearCourse('Near Course'),
  onCourse('On Course');

  const CourseContext(this.displayName);
  final String displayName;
}

/// Course type enumeration
enum CourseType {
  coastal('Coastal'),
  links('Links'),
  parkland('Parkland'),
  resort('Resort'),
  mountain('Mountain');

  const CourseType(this.displayName);
  final String displayName;
}

/// Golf course model
class GolfCourse {
  final String id;
  final String name;
  final LatLng centerLocation;
  final CourseType type;

  const GolfCourse({
    required this.id,
    required this.name,
    required this.centerLocation,
    required this.type,
  });
}

/// Location exception class
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
