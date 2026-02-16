/// Voice Coach Service
/// Orchestrates Gemini Live API sessions with map integration and real-time updates

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '/ai_integration/services/gemini_live_api_service.dart';
import '/services/map_update_service.dart';
import '/services/map_style_controller.dart';
import '/services/location_permission_service.dart';
import '/services/audio_stream_service.dart';
import '/models/voice_session_model.dart';
import '/services/voice_backend_service.dart';
import 'dart:typed_data';

/// Voice Coach Service for managing voice coaching sessions
class VoiceCoachService extends ChangeNotifier {
  static final VoiceCoachService _instance = VoiceCoachService._internal();
  factory VoiceCoachService() => _instance;
  VoiceCoachService._internal();

  // Services
  final GeminiLiveAPIService _geminiService = GeminiLiveAPIService();
  final MapUpdateService _mapUpdateService = MapUpdateService();
  final MapStyleController _mapStyleController = MapStyleController();
  final LocationPermissionService _locationService = LocationPermissionService();
  final AudioStreamService _audioStreamService = AudioStreamService();
  final VoiceBackendService _backendService = VoiceBackendService();

  // Session state
  bool _isSessionActive = false;
  String? _currentSessionId;
  VoiceSession? _currentSession;
  List<VoiceInteraction> _interactions = [];
  
  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  Position? _currentPosition;
  
  // Stream subscriptions
  StreamSubscription<GeminiLiveState>? _geminiStateSubscription;
  StreamSubscription<String>? _geminiResponseSubscription;
  StreamSubscription<Uint8List>? _geminiAudioSubscription;

  // Getters
  bool get isSessionActive => _isSessionActive;
  String? get currentSessionId => _currentSessionId;
  VoiceSession? get currentSession => _currentSession;
  List<VoiceInteraction> get interactions => List.unmodifiable(_interactions);
  Position? get currentPosition => _currentPosition;

  /// Start voice coaching session
  Future<void> startVoiceCoaching({
    double? initialLatitude,
    double? initialLongitude,
  }) async {
    if (_isSessionActive) {
      debugPrint('⚠️ VoiceCoachService: Session already active');
      return;
    }

    try {
      debugPrint('🎯 VoiceCoachService: Starting voice coaching session...');

      // 1. Get location if not provided
      Position? position;
      if (initialLatitude != null && initialLongitude != null) {
        position = Position(
          latitude: initialLatitude,
          longitude: initialLongitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      } else {
        final locationResult = await _locationService.requestLocationPermission();
        if (locationResult.result == LocationPermissionResult.granted &&
            locationResult.position != null) {
          position = locationResult.position;
        }
      }

      if (position == null) {
        throw Exception('Unable to get location for voice coaching session');
      }

      _currentPosition = position;

      // 2. Initialize Gemini Live with Maps Grounding
      await _geminiService.initializeWithLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      // 3. Connect to Gemini Live
      await _geminiService.connect();

      // 4. Setup stream subscriptions
      _setupStreamSubscriptions();

      // 5. Start location tracking
      _startLocationTracking();

      // 6. Start audio streaming
      await _audioStreamService.startRecording();
      _audioStreamService.audioStream.listen((audioChunk) {
        if (_isSessionActive) {
          // Audio chunks will be sent via Gemini service's audio streaming
          // This is handled by the AudioStreamService integration
        }
      });

      // 7. Initialize Gemini listening
      await _geminiService.startListening();

      // 8. Create session
      _currentSessionId = 'voice_session_${DateTime.now().millisecondsSinceEpoch}';
      _currentSession = VoiceSession(
        sessionId: _currentSessionId!,
        startTime: DateTime.now(),
        interactions: [],
        path: [
          (lat: position.latitude, lng: position.longitude),
        ],
        metadata: {
          'initial_location': {
            'lat': position.latitude,
            'lng': position.longitude,
          },
        },
      );

      _isSessionActive = true;
      notifyListeners();

      // 9. Send initial context to Gemini
      await _sendInitialContext(position);

      debugPrint('✅ VoiceCoachService: Session started successfully');
    } catch (e) {
      debugPrint('❌ VoiceCoachService: Error starting session: $e');
      await stopVoiceCoaching();
      rethrow;
    }
  }

  /// Stop voice coaching session
  Future<void> stopVoiceCoaching() async {
    if (!_isSessionActive) {
      return;
    }

    try {
      debugPrint('🛑 VoiceCoachService: Stopping voice coaching session...');

      // 1. Stop audio streaming
      await _audioStreamService.stopRecording();

      // 2. Stop location tracking
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // 3. Stop Gemini listening
      await _geminiService.stopListening();

      // 4. Cancel stream subscriptions
      await _geminiStateSubscription?.cancel();
      await _geminiResponseSubscription?.cancel();
      await _geminiAudioSubscription?.cancel();

      // 5. Save session
      if (_currentSession != null && _currentSessionId != null) {
        _currentSession = _currentSession!.copyWith(
          endTime: DateTime.now(),
          interactions: _interactions,
        );

        // Save to backend
        await _backendService.saveVoiceSession(_currentSession!);
      }

      // 6. Disconnect from Gemini (optional - keep connected for quick restart)
      // await _geminiService.disconnect();

      // 7. Clear state
      _isSessionActive = false;
      final sessionId = _currentSessionId;
      _currentSessionId = null;
      _interactions.clear();

      notifyListeners();

      debugPrint('✅ VoiceCoachService: Session stopped: $sessionId');
    } catch (e) {
      debugPrint('❌ VoiceCoachService: Error stopping session: $e');
      _isSessionActive = false;
      notifyListeners();
    }
  }

  /// Update map from Gemini response
  Future<void> updateMapFromResponse(String responseText) async {
    if (!_isSessionActive || _currentPosition == null) return;

    try {
      // 1. Log interaction
      final interaction = VoiceInteraction(
        timestamp: DateTime.now(),
        speaker: 'assistant',
        text: responseText,
        location: (lat: _currentPosition!.latitude, lng: _currentPosition!.longitude),
      );

      _interactions.add(interaction);
      
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          interactions: [..._currentSession!.interactions, interaction],
        );
      }

      // 2. Update map with response
      await _mapUpdateService.addVoiceInteractionMarker(
        interaction: interaction,
        mapStyle: _mapStyleController.currentStyle,
      );

      // 3. Process any navigation guidance in response
      await _processNavigationGuidance(responseText);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ VoiceCoachService: Error updating map: $e');
    }
  }

  /// Log user interaction
  Future<void> logUserInteraction(String userText) async {
    if (!_isSessionActive || _currentPosition == null) return;

    try {
      final interaction = VoiceInteraction(
        timestamp: DateTime.now(),
        speaker: 'user',
        text: userText,
        location: (lat: _currentPosition!.latitude, lng: _currentPosition!.longitude),
      );

      _interactions.add(interaction);
      
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          interactions: [..._currentSession!.interactions, interaction],
        );
      }

      // Update map
      await _mapUpdateService.addVoiceInteractionMarker(
        interaction: interaction,
        mapStyle: _mapStyleController.currentStyle,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ VoiceCoachService: Error logging user interaction: $e');
    }
  }

  /// Setup stream subscriptions
  void _setupStreamSubscriptions() {
    // Gemini state changes
    _geminiStateSubscription = _geminiService.stateStream.listen((state) {
      debugPrint('🔄 VoiceCoachService: Gemini state changed to $state');
      notifyListeners();
    });

    // Gemini text responses
    _geminiResponseSubscription = _geminiService.responseStream.listen((response) {
      updateMapFromResponse(response);
    });

    // Gemini audio responses
    _geminiAudioSubscription = _geminiService.audioDataStream.listen((audioData) {
      _audioStreamService.playAudioResponse(audioData);
    });
  }

  /// Start location tracking
  void _startLocationTracking() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((position) {
      _currentPosition = position;

      // Update Gemini with new location
      if (_isSessionActive) {
        _geminiService.updateLocationContext(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          heading: position.heading,
          speed: position.speed,
        );

        // Update session path
        if (_currentSession != null) {
          _currentSession = _currentSession!.copyWith(
            path: [
              ..._currentSession!.path,
              (lat: position.latitude, lng: position.longitude),
            ],
          );
        }

        // Update map
        _mapUpdateService.updateCurrentLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    });
  }

  /// Send initial context to Gemini
  Future<void> _sendInitialContext(Position position) async {
    final contextMessage = '''
Starting voice coaching session at location: ${position.latitude}, ${position.longitude}.
You are helping the user navigate and explore this location. 
Provide real-time guidance based on their current position and destination.
Use Maps Grounding to provide location-aware assistance.
''';

    await _geminiService.sendTextMessage(contextMessage);
  }

  /// Process navigation guidance from response
  Future<void> _processNavigationGuidance(String responseText) async {
    // Simple heuristic: check for navigation keywords
    final navigationKeywords = [
      'turn left',
      'turn right',
      'go straight',
      'head north',
      'head south',
      'head east',
      'head west',
      'destination',
      'route',
      'direction',
    ];

    final hasNavigation = navigationKeywords.any(
      (keyword) => responseText.toLowerCase().contains(keyword),
    );

    if (hasNavigation && _currentPosition != null) {
      await _mapUpdateService.processNavigationGuidance(
        responseText: responseText,
        currentLocation: (
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
        ),
      );
    }
  }

  @override
  void dispose() {
    stopVoiceCoaching();
    _geminiStateSubscription?.cancel();
    _geminiResponseSubscription?.cancel();
    _geminiAudioSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}