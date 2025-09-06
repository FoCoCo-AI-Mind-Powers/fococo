/// Simplified Gemini Live API Service for FoCoCo
/// A stable version without complex WebSocket streaming to avoid VM crashes

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Gemini Live API Service States
enum GeminiLiveServiceState {
  disconnected,
  connecting,
  connected,
  listening,
  thinking,
  speaking,
  error,
}

/// Simplified Gemini Live Service (Stable Version)
class GeminiLiveService {
  static final GeminiLiveService _instance = GeminiLiveService._internal();
  factory GeminiLiveService() => _instance;
  GeminiLiveService._internal();

  // State management
  final StreamController<GeminiLiveServiceState> _stateController =
      StreamController<GeminiLiveServiceState>.broadcast();
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  GeminiLiveServiceState _currentState = GeminiLiveServiceState.disconnected;

  // Getters
  Stream<GeminiLiveServiceState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  GeminiLiveServiceState get currentState => _currentState;
  bool get isConnected => _currentState != GeminiLiveServiceState.disconnected;
  bool get isListening => _currentState == GeminiLiveServiceState.listening;

  /// Initialize the service
  Future<void> initialize() async {
    debugPrint('GeminiLiveService: Initialized (Simple Version)');
  }

  /// Connect to service (simulated)
  Future<void> connect() async {
    if (_currentState != GeminiLiveServiceState.disconnected) {
      debugPrint('GeminiLiveService: Already connected or connecting');
      return;
    }

    try {
      _updateState(GeminiLiveServiceState.connecting);

      // Simulate connection delay
      await Future.delayed(const Duration(milliseconds: 500));

      _updateState(GeminiLiveServiceState.connected);
      debugPrint('GeminiLiveService: Connected successfully (Simulated)');
    } catch (e) {
      debugPrint('GeminiLiveService: Connection failed: $e');
      _updateState(GeminiLiveServiceState.error);
      rethrow;
    }
  }

  /// Disconnect from service
  Future<void> disconnect() async {
    try {
      await stopListening();
      _updateState(GeminiLiveServiceState.disconnected);
      debugPrint('GeminiLiveService: Disconnected');
    } catch (e) {
      debugPrint('GeminiLiveService: Disconnect error: $e');
    }
  }

  /// Start listening (simulated)
  Future<void> startListening() async {
    if (!isConnected) return;

    try {
      _updateState(GeminiLiveServiceState.listening);
      debugPrint('GeminiLiveService: Started listening (Simulated)');

      // Simulate listening for 3 seconds, then thinking, then response
      Future.delayed(const Duration(seconds: 3), () {
        if (_currentState == GeminiLiveServiceState.listening) {
          _simulateThinkingAndResponse();
        }
      });
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to start listening: $e');
      _updateState(GeminiLiveServiceState.error);
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (isConnected && _currentState != GeminiLiveServiceState.connected) {
        _updateState(GeminiLiveServiceState.connected);
      }
      debugPrint('GeminiLiveService: Stopped listening');
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to stop listening: $e');
    }
  }

  /// Send text message (simulated)
  Future<void> sendTextMessage(String text) async {
    if (!isConnected) {
      throw Exception('Not connected to Gemini Live API');
    }

    try {
      debugPrint('GeminiLiveService: Sent text message: $text');
      _simulateThinkingAndResponse();
    } catch (e) {
      debugPrint('GeminiLiveService: Failed to send text message: $e');
      rethrow;
    }
  }

  /// Simulate AI thinking and response
  void _simulateThinkingAndResponse() async {
    _updateState(GeminiLiveServiceState.thinking);

    // Simulate thinking time
    await Future.delayed(const Duration(seconds: 2));

    if (_currentState == GeminiLiveServiceState.thinking) {
      _updateState(GeminiLiveServiceState.speaking);

      // Simulate response
      _transcriptController
          .add("This is a simulated AI response for testing purposes.");

      // Simulate speaking time
      await Future.delayed(const Duration(seconds: 3));

      if (_currentState == GeminiLiveServiceState.speaking) {
        _updateState(GeminiLiveServiceState.connected);
      }
    }
  }

  /// Update service state and notify listeners
  void _updateState(GeminiLiveServiceState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      debugPrint('GeminiLiveService: State changed to $newState');
    }
  }

  /// Dispose of the service
  void dispose() {
    disconnect();
    _stateController.close();
    _transcriptController.close();
  }
}

/// Extension for easy access to Gemini Live Service
extension GeminiLiveServiceExtension on GeminiLiveService {
  /// Quick start voice conversation
  Future<void> startVoiceConversation() async {
    if (!isConnected) {
      await connect();
    }
    await startListening();
  }

  /// Quick stop voice conversation
  Future<void> stopVoiceConversation() async {
    await stopListening();
  }

  /// Toggle listening state
  Future<void> toggleListening() async {
    if (isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }
}

