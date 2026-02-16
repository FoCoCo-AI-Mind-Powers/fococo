/// Audio Stream Service
/// Handles microphone capture and audio playback for voice sessions

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

/// Audio Stream Service for voice coaching
class AudioStreamService {
  static final AudioStreamService _instance = AudioStreamService._internal();
  factory AudioStreamService() => _instance;
  AudioStreamService._internal();

  // Audio recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordStreamSubscription;
  bool _isRecording = false;

  // Audio playback
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Uint8List> _audioQueue = [];
  bool _isPlaying = false;

  // Stream controller for audio chunks
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();

  // Configuration
  static const int sampleRate = 16000; // 16kHz
  static const int bitDepth = 16; // 16-bit
  static const int channels = 1; // Mono

  // Getters
  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  /// Start recording audio
  Future<void> startRecording() async {
    if (_isRecording) {
      debugPrint('⚠️ AudioStreamService: Already recording');
      return;
    }

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission denied');
      }

      // Start recording stream
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: channels,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _recordStreamSubscription = stream.listen((chunk) {
        if (_isRecording) {
          _audioStreamController.add(chunk);
        }
      });

      _isRecording = true;
      debugPrint('🎤 AudioStreamService: Started recording');
    } catch (e) {
      debugPrint('❌ AudioStreamService: Error starting recording: $e');
      rethrow;
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      await _recordStreamSubscription?.cancel();
      await _audioRecorder.stop();
      _recordStreamSubscription = null;
      _isRecording = false;
      debugPrint('🛑 AudioStreamService: Stopped recording');
    } catch (e) {
      debugPrint('❌ AudioStreamService: Error stopping recording: $e');
    }
  }

  /// Play audio response from Gemini
  Future<void> playAudioResponse(Uint8List audioData) async {
    try {
      // Add to queue
      _audioQueue.add(audioData);

      // If not currently playing, start playback
      if (!_isPlaying && _audioQueue.isNotEmpty) {
        _playNextInQueue();
      }
    } catch (e) {
      debugPrint('❌ AudioStreamService: Error queuing audio: $e');
    }
  }

  /// Play next audio in queue
  Future<void> _playNextInQueue() async {
    if (_audioQueue.isEmpty) {
      _isPlaying = false;
      return;
    }

    try {
      _isPlaying = true;
      final audioData = _audioQueue.removeAt(0);

      // Convert PCM audio to playable format
      // Note: just_audio may need audio format conversion
      // For now, we'll create a temporary audio source
      // In production, you may need to use a PCM-to-WAV converter

      // This is a simplified implementation
      // Real implementation would convert PCM to a playable format
      await Future.delayed(Duration(milliseconds: audioData.length ~/ 32));
      // Simulate playback duration based on audio data length

      // Continue with next in queue
      _playNextInQueue();
    } catch (e) {
      debugPrint('❌ AudioStreamService: Error playing audio: $e');
      _isPlaying = false;
    }
  }

  /// Stop audio playback
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _audioQueue.clear();
      _isPlaying = false;
      debugPrint('🛑 AudioStreamService: Stopped playback');
    } catch (e) {
      debugPrint('❌ AudioStreamService: Error stopping playback: $e');
    }
  }

  /// Detect voice activity in audio chunk
  bool detectVoiceActivity(Uint8List audioChunk) {
    // Simple VAD based on amplitude
    if (audioChunk.length < 2) return false;

    int sum = 0;
    int maxAmplitude = 0;

    for (int i = 0; i < audioChunk.length - 1; i += 2) {
      // Read 16-bit PCM sample (little-endian)
      final sample = (audioChunk[i + 1] << 8) | audioChunk[i];
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      final amplitude = signedSample.abs();
      
      sum += amplitude;
      if (amplitude > maxAmplitude) {
        maxAmplitude = amplitude;
      }
    }

    final average = sum / (audioChunk.length / 2);
    
    // Threshold for voice detection
    // Adjust these values based on testing
    return average > 500 || maxAmplitude > 2000;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopRecording();
    await stopPlayback();
    await _audioStreamController.close();
    await _audioRecorder.dispose();
    await _audioPlayer.dispose();
  }
}