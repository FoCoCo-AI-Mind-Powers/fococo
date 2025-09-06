# Cartesia TTS Integration for FoCoCo

This document outlines the integration of Cartesia's high-quality text-to-speech (TTS) service with FoCoCo's AI coaching system.

## Overview

Cartesia TTS provides professional-grade voice synthesis that enhances the FoCoCo experience by:
- Converting AI insights to natural-sounding speech
- Supporting VARK learning preferences (especially auditory learners)
- Providing multiple voice profiles for different content types
- Delivering high-quality 44.1kHz audio output

## Installation & Setup

### 1. Cartesia CLI Installation
The Cartesia CLI has been installed and is ready for authentication:
```bash
cartesia auth login
```

### 2. API Key Configuration
You'll need to obtain an API key from [Cartesia](https://play.cartesia.ai/keys) and configure it in the app.

### 3. Dependencies
The following packages are already included in `pubspec.yaml`:
- `http: ^1.2.2` - For API communication
- `just_audio: ^0.9.42` - For audio playback
- `path_provider: ^2.1.5` - For temporary file storage

## Architecture

### Core Components

#### 1. CartesiaTTSService (`services/cartesia_tts_service.dart`)
Main service class that handles:
- Text-to-speech generation via Cartesia API
- Voice selection based on content type and VARK preferences
- Audio playback using just_audio
- Temporary file management

#### 2. Enhanced AI Models (`models/ai_models.dart`)
New response models that support audio:
- `AIInsightWithAudioResponse`
- `AIRecommendationWithAudioResponse`
- `AIContentWithAudioResponse`

#### 3. Audio Player Widget (`widgets/ai_insight_audio_player.dart`)
Specialized widget for playing AI insights with:
- Play/pause/stop controls
- Progress tracking
- Wave animation during playback
- VARK-aware styling

#### 4. Enhanced AI Client (`ai_client.dart`)
Extended with audio-enabled methods:
- `generateGolfInsightWithAudio()`
- `generateMentalCoachingRecommendationsWithAudio()`
- `generatePersonalizedContentWithAudio()`
- `speakInsight()`

## Voice Profiles

### Available Voices

| Voice ID | Name | Gender | Style | Use Case |
|----------|------|--------|-------|----------|
| `a0e99841-438c-4a64-b679-ae501e7d6091` | Alex | Male | Coaching | General coaching content |
| `b7d50908-b17c-442d-ad8d-810c63997ed9` | Sarah | Female | Coaching | Professional coaching |
| `79a125e8-cd45-4c13-8a67-188112f4dd22` | Marcus | Male | Meditation | Mindfulness exercises |
| `bb510827-3708-4930-b031-6917d4adc0b6` | Luna | Female | Meditation | Relaxation content |
| `ee7ea9f8-c0c1-498c-9279-764d6b87d4fd` | - | Male | Instruction | Tutorial content |
| `f114a467-c40c-4db8-bc49-e984fd10f7c1` | - | Female | Instruction | Clear instructions |
| `a167e0f3-df7e-4d52-a9c3-f949145eadb6` | - | Male | Motivation | Energetic content |
| `c45bc5ec-81f6-4f68-9d9d-6c6c98a2b2a1` | - | Female | Motivation | Inspiring messages |

### Voice Selection Logic

The service automatically selects voices based on:
1. **Content Type**: coaching, meditation, instruction, motivation
2. **VARK Preferences**: Future enhancement for voice characteristics
3. **User Settings**: Configurable voice preferences

## Usage Examples

### Basic TTS
```dart
final ttsService = CartesiaTTSService.instance;

await ttsService.speakText(
  text: 'Your mental focus improved significantly today!',
  varkPreferences: userVarkPrefs,
  contentType: 'coaching',
);
```

### AI Insight with Audio
```dart
final aiClient = AIClient.instance;

final insightWithAudio = await aiClient.generateGolfInsightWithAudio(
  userId: currentUser.uid,
  golfRound: latestRound,
  userProfile: userProfile,
  includeAudio: true,
);

// Use the audio player widget
AIInsightAudioPlayer(
  insightWithAudio: insightWithAudio,
  varkPreferences: userProfile.varkPreferences,
  contentType: 'coaching',
  autoPlay: true,
)
```

### Generate Audio for Existing Content
```dart
final audioData = await ttsService.generateInsightWithSpeech(
  insightText: existingInsight.summaryText,
  varkPreferences: userVarkPrefs,
  contentType: 'coaching',
);

// audioData contains:
// - audioPath: Local file path
// - audioSize: File size in bytes
// - voiceId: Selected voice ID
// - generatedAt: Timestamp
```

## VARK Integration

### Auditory Learners
- Automatic audio generation for users with `aural: true`
- Voice selection optimized for learning preferences
- Audio-first content delivery

### Content Type Mapping
```dart
final contentTypeVoices = {
  'coaching': 'coaching_female',
  'meditation': 'meditation_female', 
  'instruction': 'instruction_female',
  'motivation': 'motivation_female',
};
```

### Future Enhancements
- Voice speed adjustment based on VARK preferences
- Tone and style adaptation
- Multi-language support

## Audio Player Features

### Controls
- **Play/Pause**: Toggle playback
- **Stop**: Stop and reset position
- **Progress Bar**: Visual progress indication
- **Time Display**: Current/total duration

### Visual Elements
- **Wave Animation**: Animated bars during playback
- **Loading States**: Progress indicators
- **Quality Badge**: "High Quality" indicator for Cartesia audio
- **Branding**: "Powered by Cartesia" attribution

### Customization
```dart
AIInsightAudioPlayer(
  insightWithAudio: insight,
  primaryColor: Colors.blue,
  backgroundColor: Colors.white,
  autoPlay: false,
  onPlayComplete: () => print('Playback finished'),
)
```

## Error Handling

### Common Issues
1. **Missing API Key**: Service gracefully degrades to text-only
2. **Network Errors**: Retry logic with user feedback
3. **Audio Playback Errors**: Fallback to system TTS
4. **File System Errors**: Temporary file cleanup

### Error Messages
- Clear user-facing error messages
- Debug logging for development
- Graceful degradation to text-only mode

## Performance Considerations

### Audio Generation
- On-demand generation to save storage
- Temporary file management
- Background processing for large content

### Caching Strategy
- Audio files stored temporarily
- Automatic cleanup after playback
- Future: Persistent caching for frequently accessed content

### Network Usage
- Efficient API calls
- Compressed audio format (WAV PCM)
- Rate limiting awareness

## Security

### API Key Management
- Secure storage using flutter_secure_storage (to be implemented)
- Environment variable support
- No hardcoded keys in source code

### Audio File Security
- Temporary files only
- Automatic cleanup
- No persistent audio storage without user consent

## Testing

### Demo Widget
Use `CartesiaDemoWidget` to test integration:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CartesiaDemoWidget(),
  ),
);
```

### Test Scenarios
1. Direct TTS with sample text
2. AI insight audio generation
3. Audio player controls
4. Error handling (no API key)
5. VARK preference integration

## Future Enhancements

### Planned Features
1. **Voice Customization**: User-selectable voices
2. **Speed Control**: Playback speed adjustment
3. **Offline Mode**: Cached audio for offline use
4. **Multi-language**: Support for multiple languages
5. **Voice Training**: Custom voice profiles

### VARK Enhancements
1. **Adaptive Voices**: Voice characteristics based on learning style
2. **Content Adaptation**: Audio-specific content formatting
3. **Engagement Tracking**: Audio engagement metrics

### Integration Opportunities
1. **Coaching Modules**: Audio versions of all modules
2. **Daily Check-ins**: Voice prompts and responses
3. **Goal Setting**: Audio goal reminders
4. **Progress Celebrations**: Voice congratulations

## Troubleshooting

### Common Issues

#### "API Key not found"
1. Ensure Cartesia API key is configured
2. Check secure storage implementation
3. Verify API key validity

#### "Audio generation failed"
1. Check network connectivity
2. Verify API key permissions
3. Check Cartesia service status

#### "Playback failed"
1. Check device audio permissions
2. Verify audio file integrity
3. Test with system audio

### Debug Mode
Enable debug logging:
```dart
// Set kDebugMode to true for detailed logs
if (kDebugMode) {
  print('🎵 Cartesia TTS Debug Info');
}
```

## Support

For issues related to:
- **Cartesia API**: [Cartesia Support](https://cartesia.ai/support)
- **Flutter Audio**: [just_audio documentation](https://pub.dev/packages/just_audio)
- **FoCoCo Integration**: Internal development team

---

*This integration enhances FoCoCo's accessibility and provides a premium audio experience for all users, especially those with auditory learning preferences.*


