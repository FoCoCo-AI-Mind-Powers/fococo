/// Enhanced Permission Service for FoCoCo
/// Handles microphone and other permissions with proper fallback and retry mechanisms
/// Uses AudioRecorder's permission check as primary source of truth (more reliable than permission_handler)
/// Based on pattern from coelle project and issue #574: https://github.com/Baseflow/flutter-permission-handler/issues/574

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';

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
  
  // AudioRecorder instance for reliable permission checking
  // Using recorder's permission check as primary source of truth
  AudioRecorder? _audioRecorder;
  
  /// Initialize audio recorder for permission checking
  Future<void> _ensureRecorderInitialized() async {
    if (_audioRecorder == null) {
      try {
        _audioRecorder = AudioRecorder();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not initialize AudioRecorder for permission check: $e');
        }
        // Continue without recorder - will use permission_handler only
      }
    }
  }

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
  /// Uses AudioRecorder's permission check as PRIMARY source of truth (more reliable)
  /// Falls back to permission_handler if recorder is unavailable
  /// Based on pattern from coelle project - fixes issue #574 where permission_handler incorrectly reports denied
  Future<PermissionServiceState> checkMicrophonePermission() async {
    try {
      _updateMicrophoneState(PermissionServiceState.checking);
      
      await _ensureRecorderInitialized();

      // PRIMARY CHECK: Use AudioRecorder's permission check as it's more reliable
      // This fixes the issue where permission_handler incorrectly reports denied
      // even when permission is actually granted (issue #574)
      if (_audioRecorder != null) {
        try {
          final recorderHasPermission = await _audioRecorder!.hasPermission();
          if (recorderHasPermission) {
            _updateMicrophoneState(PermissionServiceState.granted);
            if (kDebugMode) {
              print('✅ Microphone permission granted (verified by AudioRecorder)');
            }
            return PermissionServiceState.granted;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error checking AudioRecorder permission: $e');
          }
        }
      }

      // SECONDARY CHECK: Use permission_handler as fallback
      // Only trust it if it says granted - don't trust denied status
      final status = await ph.Permission.microphone.status;
      
      // Return granted only if explicitly granted or limited
      if (status.isGranted || status.isLimited) {
        _updateMicrophoneState(PermissionServiceState.granted);
        if (kDebugMode) {
          print('✅ Microphone permission granted (verified by permission_handler)');
        }
        return PermissionServiceState.granted;
      }

      // Convert to our internal state for denied/permanentlyDenied cases
      final state = _convertPermissionStatus(status);
      _updateMicrophoneState(state);

      if (kDebugMode) {
        print('🎤 Microphone permission status: $status (isGranted: ${status.isGranted})');
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
  
  /// Refresh microphone permission status (useful when returning from settings)
  Future<PermissionServiceState> refreshMicrophonePermission() async {
    if (kDebugMode) {
      print('🔄 Refreshing microphone permission status...');
    }
    return await checkMicrophonePermission();
  }

  /// Request microphone permission with enhanced handling
  /// Fixed based on https://github.com/Baseflow/flutter-permission-handler/issues/574
  /// Uses AudioRecorder's permission check as primary verification
  Future<PermissionServiceState> requestMicrophonePermission({
    bool showRationale = true,
  }) async {
    try {
      _updateMicrophoneState(PermissionServiceState.checking);
      
      await _ensureRecorderInitialized();

      // PRIMARY CHECK: Use AudioRecorder's permission check first
      if (_audioRecorder != null) {
        try {
          final recorderHasPermission = await _audioRecorder!.hasPermission();
          if (recorderHasPermission) {
            _updateMicrophoneState(PermissionServiceState.granted);
            if (kDebugMode) {
              print('✅ Microphone permission already granted (verified by AudioRecorder)');
            }
            return PermissionServiceState.granted;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error checking AudioRecorder permission: $e');
          }
        }
      }

      // Check current status using permission_handler
      final currentStatus = await ph.Permission.microphone.status;

      // If already granted, return granted
      if (currentStatus.isGranted) {
        _updateMicrophoneState(PermissionServiceState.granted);
        if (kDebugMode) {
          print('✅ Microphone permission already granted');
        }
        return PermissionServiceState.granted;
      }

      // If permanently denied, we cannot request again - user must go to settings
      if (currentStatus.isPermanentlyDenied) {
        _updateMicrophoneState(PermissionServiceState.permanentlyDenied);
        if (kDebugMode) {
          print('⚠️ Microphone permission permanently denied. User needs to enable in settings.');
        }
        return PermissionServiceState.permanentlyDenied;
      }

      // If denied but not permanently, request permission
      ph.PermissionStatus status = currentStatus;
      if (currentStatus.isDenied) {
        status = await ph.Permission.microphone.request();
      }

      // Verify with AudioRecorder after request
      if (_audioRecorder != null) {
        try {
          final recorderHasPermission = await _audioRecorder!.hasPermission();
          if (recorderHasPermission) {
            _updateMicrophoneState(PermissionServiceState.granted);
            if (kDebugMode) {
              print('✅ Microphone permission granted (verified by AudioRecorder after request)');
            }
            return PermissionServiceState.granted;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error verifying AudioRecorder permission after request: $e');
          }
        }
      }

      // Convert permission_handler result
      final state = _convertPermissionStatus(status);
      _updateMicrophoneState(state);

      if (kDebugMode) {
        print('🎤 Microphone permission requested: $status (isGranted: ${status.isGranted})');
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
  
  /// Check if permission is permanently denied
  /// IMPORTANT: Only check this AFTER verifying permission is NOT granted via checkMicrophonePermission()
  /// Fixed based on issue #574 - don't assume denied = permanently denied
  Future<bool> isPermanentlyDenied() async {
    try {
      await _ensureRecorderInitialized();

      // FIRST: Check if we actually have permission using recorder (more reliable)
      // If recorder says we have permission, then it's NOT permanently denied
      if (_audioRecorder != null) {
        try {
          final recorderHasPermission = await _audioRecorder!.hasPermission();
          if (recorderHasPermission) {
            // We have permission, so it's definitely not permanently denied
            return false;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error checking recorder permission in isPermanentlyDenied: $e');
          }
        }
      }

      // SECOND: Check permission_handler status
      // Only check permanently denied if recorder confirmed we don't have permission
      final status = await ph.Permission.microphone.status;

      // Only return true if explicitly permanently denied
      // Don't assume denied = permanently denied (that's the bug from issue #574)
      return status.isPermanentlyDenied;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking if permission is permanently denied: $e');
      }
      return false;
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
      final opened = await ph.openAppSettings();

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
  PermissionServiceState _convertPermissionStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionServiceState.granted;
      case ph.PermissionStatus.denied:
        return PermissionServiceState.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionServiceState.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionServiceState.restricted;
      case ph.PermissionStatus.limited:
        return PermissionServiceState.granted; // Treat limited as granted
      case ph.PermissionStatus.provisional:
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
    _audioRecorder?.dispose();
    _audioRecorder = null;
  }
}
