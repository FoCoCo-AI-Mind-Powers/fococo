/// Enhanced Permission Service for FoCoCo
/// Handles microphone and other permissions with proper fallback and retry mechanisms

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission service states
enum PermissionServiceState {
  unknown,
  checking,
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

/// Enhanced Permission Service
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // State management
  final StreamController<PermissionServiceState> _microphoneStateController =
      StreamController<PermissionServiceState>.broadcast();

  PermissionServiceState _microphoneState = PermissionServiceState.unknown;

  // Getters
  Stream<PermissionServiceState> get microphoneStateStream =>
      _microphoneStateController.stream;
  PermissionServiceState get microphoneState => _microphoneState;
  bool get hasMicrophonePermission =>
      _microphoneState == PermissionServiceState.granted;

  /// Initialize permission service
  Future<void> initialize() async {
    await checkMicrophonePermission();

    if (kDebugMode) {
      print('🔐 Permission Service initialized');
    }
  }

  /// Check current microphone permission status
  Future<PermissionServiceState> checkMicrophonePermission() async {
    try {
      _updateMicrophoneState(PermissionServiceState.checking);

      final status = await Permission.microphone.status;
      final state = _convertPermissionStatus(status);

      _updateMicrophoneState(state);

      if (kDebugMode) {
        print('🎤 Microphone permission status: $status');
      }

      return state;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking microphone permission: $e');
      }
      _updateMicrophoneState(PermissionServiceState.denied);
      return PermissionServiceState.denied;
    }
  }

  /// Request microphone permission with enhanced handling
  Future<PermissionServiceState> requestMicrophonePermission({
    bool showRationale = true,
  }) async {
    try {
      _updateMicrophoneState(PermissionServiceState.checking);

      // Check current status first
      final currentStatus = await Permission.microphone.status;

      if (currentStatus == PermissionStatus.granted) {
        _updateMicrophoneState(PermissionServiceState.granted);
        return PermissionServiceState.granted;
      }

      // If permanently denied, guide user to settings
      if (currentStatus == PermissionStatus.permanentlyDenied) {
        _updateMicrophoneState(PermissionServiceState.permanentlyDenied);
        return PermissionServiceState.permanentlyDenied;
      }

      // Request permission
      final status = await Permission.microphone.request();
      final state = _convertPermissionStatus(status);

      _updateMicrophoneState(state);

      if (kDebugMode) {
        print('🎤 Microphone permission requested: $status');
      }

      return state;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting microphone permission: $e');
      }
      _updateMicrophoneState(PermissionServiceState.denied);
      return PermissionServiceState.denied;
    }
  }

  /// Request microphone permission with retry mechanism
  Future<bool> requestMicrophoneWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final state = await requestMicrophonePermission();

        if (state == PermissionServiceState.granted) {
          return true;
        }

        if (state == PermissionServiceState.permanentlyDenied) {
          // No point in retrying if permanently denied
          break;
        }

        if (i < maxRetries - 1) {
          if (kDebugMode) {
            print(
                '🔄 Retrying microphone permission request (${i + 1}/$maxRetries)');
          }
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error in retry attempt ${i + 1}: $e');
        }
      }
    }

    return false;
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    try {
      final opened = await openAppSettings();

      if (kDebugMode) {
        print('⚙️ App settings opened: $opened');
      }

      return opened;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening app settings: $e');
      }
      return false;
    }
  }

  /// Get user-friendly permission status message
  String getPermissionStatusMessage(PermissionServiceState state) {
    switch (state) {
      case PermissionServiceState.unknown:
        return 'Microphone permission status unknown';
      case PermissionServiceState.checking:
        return 'Checking microphone permission...';
      case PermissionServiceState.granted:
        return 'Microphone permission granted';
      case PermissionServiceState.denied:
        return 'Microphone permission denied. Voice features unavailable.';
      case PermissionServiceState.permanentlyDenied:
        return 'Microphone permission permanently denied. Please enable in Settings.';
      case PermissionServiceState.restricted:
        return 'Microphone access restricted by device policy';
    }
  }

  /// Get suggested action for permission state
  String getPermissionAction(PermissionServiceState state) {
    switch (state) {
      case PermissionServiceState.unknown:
      case PermissionServiceState.checking:
        return 'Please wait...';
      case PermissionServiceState.granted:
        return 'Voice features available';
      case PermissionServiceState.denied:
        return 'Tap to request microphone permission';
      case PermissionServiceState.permanentlyDenied:
        return 'Open Settings to enable microphone';
      case PermissionServiceState.restricted:
        return 'Contact device administrator';
    }
  }

  /// Handle permission state changes (for UI updates)
  void handlePermissionStateChange(PermissionServiceState state) {
    switch (state) {
      case PermissionServiceState.granted:
        HapticFeedback.lightImpact();
        break;
      case PermissionServiceState.denied:
      case PermissionServiceState.permanentlyDenied:
        HapticFeedback.heavyImpact();
        break;
      default:
        break;
    }
  }

  /// Convert PermissionStatus to PermissionServiceState
  PermissionServiceState _convertPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return PermissionServiceState.granted;
      case PermissionStatus.denied:
        return PermissionServiceState.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionServiceState.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionServiceState.restricted;
      case PermissionStatus.limited:
        return PermissionServiceState.granted; // Treat limited as granted
      case PermissionStatus.provisional:
        return PermissionServiceState.granted; // Treat provisional as granted
    }
  }

  /// Update microphone state and notify listeners
  void _updateMicrophoneState(PermissionServiceState newState) {
    if (_microphoneState != newState) {
      _microphoneState = newState;
      _microphoneStateController.add(newState);

      // Handle UI feedback
      handlePermissionStateChange(newState);

      if (kDebugMode) {
        print('🔄 Microphone permission state: $newState');
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    _microphoneStateController.close();
  }
}
