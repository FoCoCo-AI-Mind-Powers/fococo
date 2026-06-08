import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../ai_integration/services/audio_session_service.dart';
import '../ai_integration/services/cartesia_api_service.dart';
import '../ai_integration/services/cartesia_voice_service.dart';

/// Coordinates voice audio across app-lifecycle transitions and OS audio
/// interruptions so background voice behaves predictably:
///
/// - Cartesia TTS **playback continues** when the app is backgrounded /
///   the screen is locked (handled by `just_audio_background`).
/// - Microphone **recording is foreground-only** — an in-progress voice
///   capture is cancelled when the app leaves the foreground.
/// - OS interruptions (calls, Siri, headphone unplug) pause playback and
///   resume it when the system says it is safe to.
class BackgroundAudioService with WidgetsBindingObserver {
  BackgroundAudioService._();

  static final BackgroundAudioService instance = BackgroundAudioService._();

  bool _initialized = false;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  void init() {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    _interruptionSub =
        AudioSessionService.interruptions.listen(_handleInterruption);
  }

  void dispose() {
    if (!_initialized) return;
    _initialized = false;
    WidgetsBinding.instance.removeObserver(this);
    _interruptionSub?.cancel();
    _interruptionSub = null;
  }

  Future<void> _handleInterruption(AudioInterruptionEvent event) async {
    final cartesia = CartesiaAPIService.instance;
    switch (event) {
      case AudioInterruptionEvent.began:
      case AudioInterruptionEvent.routeLost:
        await cartesia.pausePlayback();
        break;
      case AudioInterruptionEvent.endedShouldResume:
        await cartesia.resumePlayback();
        break;
      case AudioInterruptionEvent.ended:
        // Interruption ended but the OS did not request a resume — leave
        // playback paused; the user can resume from the controls.
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Microphone capture is foreground-only — cancel any in-progress
      // recording so it does not get stuck. TTS playback is left running
      // so voice continues in the background.
      final voice = CartesiaVoiceService.maybeInstance;
      if (voice != null && voice.isListening) {
        unawaited(voice.cancelListening());
        if (kDebugMode) {
          print('🎙️ Background: cancelled in-progress voice capture');
        }
      }
    }
  }
}
