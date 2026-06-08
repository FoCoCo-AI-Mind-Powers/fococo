import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Audio interruption / route-change events forwarded from the native iOS
/// audio session so the voice layer can pause and resume cleanly.
enum AudioInterruptionEvent {
  /// An interruption began (incoming call, Siri, another app took audio).
  began,

  /// The interruption ended and the OS suggests resuming playback.
  endedShouldResume,

  /// The interruption ended; do not auto-resume.
  ended,

  /// The output route became unavailable (e.g. headphones unplugged).
  routeLost,
}

/// Thin wrapper over the native iOS audio session (`AudioSessionManager`).
class AudioSessionService {
  static const _channel = MethodChannel('com.fococo.audio/session');

  static final StreamController<AudioInterruptionEvent> _interruptions =
      StreamController<AudioInterruptionEvent>.broadcast();
  static bool _handlerInstalled = false;

  /// Stream of audio interruption / route-change events (iOS only).
  static Stream<AudioInterruptionEvent> get interruptions {
    _ensureHandler();
    return _interruptions.stream;
  }

  static void _ensureHandler() {
    if (_handlerInstalled || kIsWeb || !Platform.isIOS) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'interruption':
          final args = (call.arguments as Map?) ?? const {};
          if (args['type'] == 'began') {
            _interruptions.add(AudioInterruptionEvent.began);
          } else {
            _interruptions.add(args['shouldResume'] == true
                ? AudioInterruptionEvent.endedShouldResume
                : AudioInterruptionEvent.ended);
          }
          break;
        case 'routeChange':
          _interruptions.add(AudioInterruptionEvent.routeLost);
          break;
      }
      return null;
    });
  }

  /// Activate the session for a two-way voice conversation (mic + speaker).
  static Future<void> activateVoiceChat() async {
    if (kIsWeb || !Platform.isIOS) return;
    _ensureHandler();
    try {
      await _channel.invokeMethod<void>('activate');
    } on PlatformException catch (e) {
      if (kDebugMode) print('⚠️ AudioSession activate error: ${e.message}');
    }
  }

  /// Activate the session for background-friendly TTS playback only.
  static Future<void> activatePlayback() async {
    if (kIsWeb || !Platform.isIOS) return;
    _ensureHandler();
    try {
      await _channel.invokeMethod<void>('activatePlayback');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('⚠️ AudioSession activatePlayback error: ${e.message}');
      }
    }
  }

  static Future<void> deactivateVoiceChat() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('deactivate');
    } on PlatformException catch (e) {
      if (kDebugMode) print('⚠️ AudioSession deactivate error: ${e.message}');
    }
  }
}
