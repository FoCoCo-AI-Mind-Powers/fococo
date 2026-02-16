/// Enhanced Permission Service for FoCoCo
/// Handles microphone and other permissions with proper fallback and retry mechanisms
/// Uses AudioRecorder's permission check as primary source of truth (more reliable than permission_handler)
/// Based on pattern from coelle project and issue #574: https://github.com/Baseflow/flutter-permission-handler/issues/574

import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  
  // Guard to prevent concurrent permission checks
  bool _isCheckingPermission = false;
  Completer<PermissionServiceState>? _pendingPermissionCheck;
  
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
  /// LAZY INITIALIZATION: Does NOT check permissions automatically
  /// Permissions are only checked when explicitly requested (e.g., user clicks microphone)
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔐 Permission Service initializing (lazy - no permission check)');
    }
    
    // Just initialize the service structure without checking permissions
    // Permissions will be checked on-demand when user interacts with voice features
    // This prevents unnecessary permission prompts on app startup
    
    if (kDebugMode) {
      print('🔐 Permission Service initialized (permissions will be checked on-demand)');
    }
  }

  /// Check current microphone permission status
  /// Uses permission_handler as PRIMARY source (per official documentation)
  /// Adds robust timeout to prevent hanging in "checking" state
  /// Verifies with AudioRecorder after permission_handler check (if available)
  /// Prevents concurrent checks to avoid deadlocks
  Future<PermissionServiceState> checkMicrophonePermission() async {
    // If already checking, return the pending check result
    if (_isCheckingPermission && _pendingPermissionCheck != null) {
      if (kDebugMode) {
        print('🔍 [DEBUG] Permission check already in progress, waiting for result');
      }
      return await _pendingPermissionCheck!.future;
    }
    
    // If already granted, return immediately
    if (_microphoneState == PermissionServiceState.granted) {
      if (kDebugMode) {
        print('🔍 [DEBUG] Permission already granted, returning immediately');
      }
      return PermissionServiceState.granted;
    }
    
    if (kDebugMode) {
      print('🔍 [DEBUG] checkMicrophonePermission ENTRY - currentState: $_microphoneState');
    }
    
    // Set up guard and completer
    _isCheckingPermission = true;
    _pendingPermissionCheck = Completer<PermissionServiceState>();
    
    // Immediately set state to checking
    _updateMicrophoneState(PermissionServiceState.checking);
    
    // Use Future.any to race between permission check and timeout
    // This ensures timeout ALWAYS wins if permission check hangs
    try {
      if (kDebugMode) {
        print('🔍 [DEBUG] Starting permission check with 2-second timeout');
      }
      
      // Create a timeout future that will definitely complete
      final timeoutFuture = Future<ph.PermissionStatus>.delayed(
        const Duration(seconds: 2),
        () {
          if (kDebugMode) {
            print('⚠️ [DEBUG] TIMEOUT: Permission check took too long, defaulting to denied');
          }
          return ph.PermissionStatus.denied;
        },
      );
      
      // Race between actual permission check and timeout
      final status = await Future.any<ph.PermissionStatus>([
        ph.Permission.microphone.status.catchError((e) {
          if (kDebugMode) {
            print('⚠️ [DEBUG] Permission check error: $e');
          }
          return ph.PermissionStatus.denied;
        }),
        timeoutFuture,
      ]);
      
      if (kDebugMode) {
        print('🔍 [DEBUG] Permission status received: $status (isGranted: ${status.isGranted})');
      }
      
      // Handle granted or limited status immediately
      PermissionServiceState resultState;
      if (status.isGranted || status.isLimited) {
        resultState = PermissionServiceState.granted;
        _updateMicrophoneState(resultState);
        if (kDebugMode) {
          print('✅ Microphone permission granted (verified by permission_handler)');
        }
        
        // Optional verification with AudioRecorder (non-blocking)
        _verifyWithAudioRecorder();
      } else {
        // Convert to our internal state for denied/permanentlyDenied cases
        resultState = _convertPermissionStatus(status);
        _updateMicrophoneState(resultState);

        if (kDebugMode) {
          print('🎤 Microphone permission status: $status (isGranted: ${status.isGranted})');
        }
      }
      
      // Complete the pending check and clear guard
      _isCheckingPermission = false;
      if (!_pendingPermissionCheck!.isCompleted) {
        _pendingPermissionCheck!.complete(resultState);
      }
      _pendingPermissionCheck = null;
      
      return resultState;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [DEBUG] EXCEPTION in checkMicrophonePermission: $e');
        print('❌ [DEBUG] StackTrace: $stackTrace');
      }
      
      // Ensure we always update state even on error
      final errorState = PermissionServiceState.denied;
      _updateMicrophoneState(errorState);
      
      // Complete the pending check and clear guard
      _isCheckingPermission = false;
      if (_pendingPermissionCheck != null && !_pendingPermissionCheck!.isCompleted) {
        _pendingPermissionCheck!.complete(errorState);
      }
      _pendingPermissionCheck = null;
      
      return errorState;
    }
  }
  
  /// Verify permission with AudioRecorder (non-blocking, runs in background)
  void _verifyWithAudioRecorder() {
    _ensureRecorderInitialized().then((_) {
      if (_audioRecorder != null) {
        _audioRecorder!.hasPermission()
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () => false,
            )
            .then((hasPermission) {
          if (hasPermission && _microphoneState != PermissionServiceState.granted) {
            if (kDebugMode) {
              print('✅ Microphone permission verified by AudioRecorder');
            }
            _updateMicrophoneState(PermissionServiceState.granted);
          }
        }).catchError((e) {
          if (kDebugMode) {
            print('⚠️ AudioRecorder verification failed (non-critical): $e');
          }
        });
      }
    });
  }
  
  /// Refresh microphone permission status (useful when returning from settings)
  Future<PermissionServiceState> refreshMicrophonePermission() async {
    if (kDebugMode) {
      print('🔄 Refreshing microphone permission status...');
    }
    return await checkMicrophonePermission();
  }

  /// Request microphone permission with enhanced handling
  /// Follows permission_handler documentation best practices
  /// Uses permission_handler as primary source with timeout protection
  Future<PermissionServiceState> requestMicrophonePermission({
    bool showRationale = true,
  }) async {
    try {
      _updateMicrophoneState(PermissionServiceState.checking);
      
      // PRIMARY CHECK: Use permission_handler.status (per official docs)
      // Check current status first with timeout
      final currentStatus = await ph.Permission.microphone.status.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) {
            print('⚠️ Permission status check timeout');
          }
          return ph.PermissionStatus.denied;
        },
      );

      // If already granted, return granted immediately
      if (currentStatus.isGranted || currentStatus.isLimited) {
        _updateMicrophoneState(PermissionServiceState.granted);
        if (kDebugMode) {
          print('✅ Microphone permission already granted');
        }
        _verifyWithAudioRecorder();
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

      // If denied but not permanently, request permission with timeout
      ph.PermissionStatus status = currentStatus;
      if (currentStatus.isDenied) {
        status = await ph.Permission.microphone.request().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            if (kDebugMode) {
              print('⚠️ Permission request timeout');
            }
            return ph.PermissionStatus.denied;
          },
        );
      }

      // Handle the result immediately
      if (status.isGranted || status.isLimited) {
        _updateMicrophoneState(PermissionServiceState.granted);
        if (kDebugMode) {
          print('✅ Microphone permission granted after request');
        }
        _verifyWithAudioRecorder();
        return PermissionServiceState.granted;
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
    // #region agent log
    final logEntry = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'C',
      'location': 'permission_service.dart:_updateMicrophoneState',
      'message': '_updateMicrophoneState ENTRY',
      'data': {'oldState': _microphoneState.toString(), 'newState': newState.toString()},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
        .writeAsStringSync('${jsonEncode(logEntry)}\n', mode: FileMode.append);
    // #endregion
    
    if (_microphoneState != newState) {
      _microphoneState = newState;
      
      // #region agent log
      final logEntry2 = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'C',
        'location': 'permission_service.dart:_updateMicrophoneState',
        'message': 'BEFORE stream.add',
        'data': {'state': newState.toString()},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(logEntry2)}\n', mode: FileMode.append);
      // #endregion
      
      _microphoneStateController.add(newState);

      // #region agent log
      final logEntry3 = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'C',
        'location': 'permission_service.dart:_updateMicrophoneState',
        'message': 'AFTER stream.add',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(logEntry3)}\n', mode: FileMode.append);
      // #endregion

      // Handle UI feedback
      handlePermissionStateChange(newState);

      if (kDebugMode) {
        print('🔄 Microphone permission state: $newState');
      }
      
      // #region agent log
      final logEntry4 = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'C',
        'location': 'permission_service.dart:_updateMicrophoneState',
        'message': '_updateMicrophoneState EXIT',
        'data': {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File('/Users/mac/Documents/Projects Code/fococo/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(logEntry4)}\n', mode: FileMode.append);
      // #endregion
    }
  }

  /// Dispose of resources
  void dispose() {
    _microphoneStateController.close();
    _audioRecorder?.dispose();
    _audioRecorder = null;
  }
}
