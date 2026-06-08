/// Prepares text for Cartesia Sonic TTS per
/// https://docs.cartesia.ai/build-with-cartesia/capability-guides/prompting-tips
/// and [volume/speed/emotion](https://docs.cartesia.ai/build-with-cartesia/capability-guides/volume-speed-emotion)
/// via `generation_config` (preferred for sonic-3+).
class CartesiaSpeechPrompt {
  CartesiaSpeechPrompt._();

  /// Cartesia `generation_config.speed` valid range (multiplier on default).
  static const double minSpeed = 0.6;
  static const double maxSpeed = 1.5;

  static double clampSpeed(double value) =>
      value.clamp(minSpeed, maxSpeed).toDouble();

  /// Calm golf mental-coach delivery — natural pace, not slowed down.
  static const CartesiaSpeechProfile mentorCalm = CartesiaSpeechProfile(
    speedRatio: 1.0,
    volumeRatio: 1.0,
    emotion: 'calm',
  );

  /// GolfChat reflection — serene, slightly upbeat.
  static const CartesiaSpeechProfile golfReflection = CartesiaSpeechProfile(
    speedRatio: 1.05,
    volumeRatio: 1.0,
    emotion: 'content',
  );

  /// FoCoCo daily insight read-aloud — crisp, engaging.
  static const CartesiaSpeechProfile dailyInsight = CartesiaSpeechProfile(
    speedRatio: 1.08,
    volumeRatio: 1.0,
    emotion: 'content',
  );

  /// Strip markdown / machine-shaped text before TTS.
  static String prepareForTts(
    String raw, {
    CartesiaSpeechProfile profile = mentorCalm,
    bool stripMarkdown = true,
    bool inlineProsodyTags = false,
  }) {
    var text = raw.trim();
    if (text.isEmpty) return text;

    if (stripMarkdown) {
      text = text
          .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
          .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
          .replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '')
          .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
          .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
          .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    text = _ensureTerminalPunctuation(text);
    text = _applyBrandPronunciations(text);

    final prefix = StringBuffer();
    if (inlineProsodyTags) {
      if (profile.prependEmotionTag && profile.emotion != null) {
        prefix.write('<emotion value="${profile.emotion}"/> ');
      }
      if (profile.prependSpeedTag && profile.speedRatio != null) {
        prefix.write('<speed ratio="${profile.speedRatio}"/> ');
      }
      if (profile.prependVolumeTag && profile.volumeRatio != null) {
        prefix.write('<volume ratio="${profile.volumeRatio}"/> ');
      }
    }

    return '${prefix.toString()}$text';
  }

  /// Build generation_config for sonic-3+ ([Cartesia
  /// docs](https://docs.cartesia.ai/build-with-cartesia/capability-guides/volume-speed-emotion)).
  static Map<String, dynamic> generationConfig(CartesiaSpeechProfile profile) {
    final config = <String, dynamic>{};
    if (profile.speedRatio != null) {
      config['speed'] = clampSpeed(profile.speedRatio!);
    }
    if (profile.volumeRatio != null) {
      config['volume'] = profile.volumeRatio!.clamp(0.5, 2.0);
    }
    if (profile.emotion != null && profile.emotion!.isNotEmpty) {
      config['emotion'] = profile.emotion;
    }
    return config;
  }

  static String _ensureTerminalPunctuation(String text) {
    if (text.isEmpty) return text;
    final last = text[text.length - 1];
    if ('.?!'.contains(last)) return text;
    return '$text.';
  }

  /// Inline `<spell>` tags for brand terms until a server pronunciation dict is set.
  static String _applyBrandPronunciations(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'\bFoCoCo\b', caseSensitive: false),
          (_) => spellOut('FoCoCo'),
        )
        .replaceAllMapped(
          RegExp(r'\bfococo\b', caseSensitive: false),
          (_) => spellOut('FoCoCo'),
        );
  }

  /// Wrap confirmation-style tokens for deterministic spelling (Sonic 3.5).
  static String spellOut(String token) => '<spell>${token.trim()}</spell>';
}

class CartesiaSpeechProfile {
  const CartesiaSpeechProfile({
    this.speedRatio,
    this.volumeRatio,
    this.emotion,
    this.prependEmotionTag = false,
    this.prependSpeedTag = false,
    this.prependVolumeTag = false,
  });

  final double? speedRatio;
  final double? volumeRatio;
  final String? emotion;
  final bool prependEmotionTag;
  final bool prependSpeedTag;
  final bool prependVolumeTag;
}
