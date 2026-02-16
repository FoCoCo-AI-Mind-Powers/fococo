/// Location Permission Service with Progressive Timeout Strategy
/// Handles location permissions with retry logic and graceful fallbacks

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission request result
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  timeout,
}

/// Service for handling location permissions with progressive retry strategy
class LocationPermissionService {
  static final LocationPermissionService _instance =
      LocationPermissionService._internal();
  factory LocationPermissionService() => _instance;
  LocationPermissionService._internal();

  /// Progressive timeout strategy: 5s → 10s → 30s
  static const List<Duration> _timeoutStages = [
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  /// Request location permission with progressive retry
  /// Returns the permission result and position if successful
  Future<({LocationPermissionResult result, Position? position})>
      requestLocationPermission({
    bool enableHighAccuracy = true,
    int maxRetries = 3,
  }) async {
    try {
      // Stage 1: Check if location service is enabled
      final serviceEnabled = await _checkLocationService();
      if (!serviceEnabled) {
        return (result: LocationPermissionResult.serviceDisabled, position: null);
      }

      // Stage 2: Request permission with progressive timeout
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        final timeout = _timeoutStages[
            attempt < _timeoutStages.length ? attempt : _timeoutStages.length - 1];

        debugPrint(
            '🎯 LocationPermissionService: Attempt ${attempt + 1}/$maxRetries with timeout ${timeout.inSeconds}s');

        try {
          // Check permission status
          LocationPermission permission = await Geolocator.checkPermission();

          // Request permission if needed
          if (permission == LocationPermission.denied) {
            debugPrint('🎯 Requesting location permission...');
            permission = await Geolocator.requestPermission();
          }

          // Handle permission states
          if (permission == LocationPermission.denied) {
            debugPrint('⚠️ Location permission denied');
            return (result: LocationPermissionResult.denied, position: null);
          }

          if (permission == LocationPermission.deniedForever) {
            debugPrint('⚠️ Location permission permanently denied');
            return (
              result: LocationPermissionResult.deniedForever,
              position: null
            );
          }

          // Permission granted, try to get location with timeout
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            debugPrint('✅ Permission granted, getting location...');

            try {
              final position = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                  accuracy: enableHighAccuracy
                      ? LocationAccuracy.high
                      : LocationAccuracy.medium,
                  timeLimit: timeout,
                ),
              ).timeout(timeout, onTimeout: () {
                throw TimeoutException(
                  'Location request timed out after ${timeout.inSeconds}s',
                  timeout,
                );
              });

              debugPrint(
                  '✅ Location acquired: ${position.latitude}, ${position.longitude}');
              return (result: LocationPermissionResult.granted, position: position);
            } on TimeoutException catch (e) {
              debugPrint('⚠️ Location timeout on attempt ${attempt + 1}: $e');
              if (attempt < maxRetries - 1) {
                // Wait before retry with exponential backoff
                await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
                continue;
              }
              return (result: LocationPermissionResult.timeout, position: null);
            } catch (e) {
              debugPrint('❌ Error getting location: $e');
              if (attempt < maxRetries - 1) {
                await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
                continue;
              }
              rethrow;
            }
          }
        } catch (e) {
          debugPrint('❌ Error on attempt ${attempt + 1}: $e');
          if (attempt < maxRetries - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            continue;
          }
          rethrow;
        }
      }

      // All retries exhausted
      return (result: LocationPermissionResult.timeout, position: null);
    } catch (e) {
      debugPrint('❌ LocationPermissionService error: $e');
      return (result: LocationPermissionResult.denied, position: null);
    }
  }

  /// Check if location service is enabled
  Future<bool> _checkLocationService() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        // Try to open location settings
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          return false;
        }
        // Wait a moment for settings to update
        await Future.delayed(const Duration(milliseconds: 500));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }
      return serviceEnabled;
    } catch (e) {
      debugPrint('❌ Error checking location service: $e');
      return false;
    }
  }

  /// Check current permission status
  Future<LocationPermissionResult> checkPermissionStatus() async {
    try {
      // Check location service first
      final serviceEnabled = await _checkLocationService();
      if (!serviceEnabled) {
        return LocationPermissionResult.serviceDisabled;
      }

      // Check permission status
      final permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionResult.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionResult.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionResult.granted;
        case LocationPermission.unableToDetermine:
          return LocationPermissionResult.denied;
      }
    } catch (e) {
      debugPrint('❌ Error checking permission status: $e');
      return LocationPermissionResult.denied;
    }
  }

  /// Handle permission denied by guiding user to settings
  Future<bool> handlePermissionDenied() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        // Open app settings for permanent denial
        return await openAppSettings();
      } else if (permission == LocationPermission.denied) {
        // Try requesting again
        final newPermission = await Geolocator.requestPermission();
        return newPermission == LocationPermission.whileInUse ||
            newPermission == LocationPermission.always;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error handling permission denied: $e');
      return false;
    }
  }

  /// Get location with retry mechanism
  /// Simplified version that returns position directly
  Future<Position?> getLocationWithRetry({
    bool enableHighAccuracy = true,
    int maxRetries = 3,
  }) async {
    final result = await requestLocationPermission(
      enableHighAccuracy: enableHighAccuracy,
      maxRetries: maxRetries,
    );

    if (result.result == LocationPermissionResult.granted) {
      return result.position;
    }

    return null;
  }

  /// Get user-friendly message for permission status
  String getPermissionStatusMessage(LocationPermissionResult result) {
    switch (result) {
      case LocationPermissionResult.granted:
        return 'Location permission granted';
      case LocationPermissionResult.denied:
        return 'Location permission denied. Please grant permission in settings.';
      case LocationPermissionResult.deniedForever:
        return 'Location permission permanently denied. Please enable in app settings.';
      case LocationPermissionResult.serviceDisabled:
        return 'Location services are disabled. Please enable in device settings.';
      case LocationPermissionResult.timeout:
        return 'Location request timed out. Please check your GPS and try again.';
    }
  }
}