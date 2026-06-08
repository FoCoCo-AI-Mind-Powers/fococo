import 'dart:typed_data';

/// Wrap mono PCM s16le bytes in a WAV container for [just_audio].
Uint8List pcm16MonoToWav(
  Uint8List pcmData, {
  int sampleRate = 22050,
}) {
  final byteData = ByteData(44 + pcmData.length);
  byteData.setUint32(0, 0x52494646, Endian.big); // RIFF
  byteData.setUint32(4, 36 + pcmData.length, Endian.little);
  byteData.setUint32(8, 0x57415645, Endian.big); // WAVE
  byteData.setUint32(12, 0x666D7420, Endian.big); // fmt
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little); // PCM
  byteData.setUint16(22, 1, Endian.little); // mono
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  byteData.setUint32(36, 0x64617461, Endian.big); // data
  byteData.setUint32(40, pcmData.length, Endian.little);
  final wavBytes = byteData.buffer.asUint8List();
  wavBytes.setRange(44, 44 + pcmData.length, pcmData);
  return wavBytes;
}

/// Cartesia streaming TTS output — raw PCM @ 22.05 kHz keeps payloads small
/// and time-to-first-byte low vs 44.1 kHz WAV through Cloud Functions.
const int kCartesiaStreamingSampleRate = 22050;
