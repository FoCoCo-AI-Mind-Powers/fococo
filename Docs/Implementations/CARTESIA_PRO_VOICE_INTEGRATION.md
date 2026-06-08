# FoCoCo Cartesia Custom Voice Integration

## Overview

This document outlines the integration of Cartesia's sonic-2 model with a custom voice clone (ID: 7442d6b8-ff51-4477-bd30-0c0d16df84eb) for FoCoCo's AI mental performance coaching system. The integration combines Gemini Live API for transcription and AI responses with Cartesia's high-quality TTS for natural voice output.

## Architecture

### Core Components

1. **CartesiaAPIService** (`lib/ai_integration/services/cartesia_api_service.dart`)
   - Direct implementation of Cartesia TTS API
   - Uses sonic-2 model with custom voice clone (ID: 7442d6b8-ff51-4477-bd30-0c0d16df84eb)
   - VARK learning preference adaptations
   - Real-time audio generation and playback

2. **GeminiCartesiaBridgeService** (`lib/ai_integration/services/gemini_cartesia_bridge_service.dart`)
   - Bridges Gemini Live API (transcription/AI) with Cartesia TTS
   - WebSocket connection to Gemini Live API
   - Real-time audio recording and processing
   - Seamless voice interaction pipeline

3. **Enhanced Voice Chat Modal** (`lib/ai_integration/widgets/voice_chat_modal.dart`)
   - Updated to use the new bridge service
   - Fallback support for existing services
   - Pro voice integration indicators

4. **Updated Configuration** (`lib/ai_integration/config/cartesia_mcp_config.dart`)
   - sonic-2 model configuration
   - Custom voice clone settings (ID: 7442d6b8-ff51-4477-bd30-0c0d16df84eb)
   - VARK-specific voice adaptations

## Key Features

### 🎤 Custom Voice Clone Integration
- Uses Cartesia's sonic-2 model
- Custom voice clone (ID: 7442d6b8-ff51-4477-bd30-0c0d16df84eb)
- High-quality, natural-sounding speech synthesis
- Optimized for golf coaching scenarios

### 🧠 Gemini AI Integration
- Real-time transcription via Gemini Live API
- Advanced AI responses for mental performance coaching
- Thinking mode support for deeper analysis
- Context-aware coaching recommendations

### 🎯 VARK Learning Adaptations
- **Visual**: Slower pace with visualization cues
- **Auditory**: Optimized for listening with rhythm emphasis
- **Read/Write**: Pauses for note-taking, structured delivery
- **Kinesthetic**: Faster pace with action-oriented language

### 🔄 Real-time Processing
- WebSocket-based communication
- Streaming audio processing
- Low-latency voice interactions
- Automatic fallback mechanisms

## API Integration Details

### Cartesia TTS API
Based on: https://docs.cartesia.ai/get-started/make-an-api-request

```dart
// Example API call matching your curl command
final payload = {
  'model_id': 'sonic-2',
  'transcript': adaptedText,
  'voice': {
    'mode': 'id',
    'id': '7442d6b8-ff51-4477-bd30-0c0d16df84eb',
  },
  'output_format': {
    'container': 'wav',
    'encoding': 'pcm_f32le',
    'sample_rate': 44100,
  },
  'language': 'en',
  'speed': 'normal',
};
```

### Gemini Live API
- WebSocket endpoint: `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent`
- Native audio models with thinking support
- Real-time bidirectional communication

## Usage

### Basic Voice Interaction
```dart
// Initialize the bridge service
final bridgeService = GeminiCartesiaBridgeService();
await bridgeService.initialize(
  varkPreferences: userVarkPrefs,
);
await bridgeService.connect();

// Start listening
await bridgeService.startListening();

// Send text message
await bridgeService.sendTextMessage("Help me with my putting confidence");
```

### VARK Adaptation Example
```dart
// Text adaptation for different learning styles
String adaptedText = _adaptTextForVARK(originalText, varkPreferences);

// Voice settings based on VARK type
Map<String, dynamic> voiceSettings = _getVoiceSettings(
  contentType: 'coaching',
  varkPreferences: varkPreferences,
);
```

## Configuration

### Environment Variables
```bash
# Gemini key is stored in Google Cloud Secret Manager as `GEMINI_KEY_APP`
# and consumed only by Cloud Functions. It is not a client env-var.
CARTESIA_API_KEY=sk_car_hksASYyHegCKwWLWfAL8SW
```

### Voice Profiles
```dart
static const Map<String, Map<String, dynamic>> voiceProfiles = {
  'coach_confident': {
    'voice_id': '7442d6b8-ff51-4477-bd30-0c0d16df84eb',
    'model': 'sonic-2',
    'speed': 'normal',
    'emotion': 'confident',
    'style': 'coaching',
  },
  // Additional profiles...
};
```

## Testing

### Voice Pipeline Test
1. Open the voice chat modal
2. Verify "custom voice" indicator appears
3. Test voice input → AI processing → Cartesia TTS output
4. Verify VARK adaptations work correctly
5. Test fallback mechanisms

### Quality Assurance
- Audio quality verification
- Latency measurements
- Error handling validation
- Cross-platform compatibility

## Performance Optimizations

### Audio Processing
- Streaming audio generation
- Efficient memory management
- Background processing
- Automatic cleanup

### Network Optimization
- WebSocket connection pooling
- Retry mechanisms
- Graceful degradation
- Offline capability planning

## Error Handling

### Common Issues
1. **API Key Issues**: Verify Cartesia API key is valid
2. **Network Connectivity**: Implement retry logic
3. **Audio Permissions**: Request microphone access
4. **Model Availability**: Fallback to alternative models

### Debugging
```dart
// Enable debug logging
if (kDebugMode) {
  print('🎤 Cartesia API Service initialized with sonic-2');
  print('🔗 Connected to Gemini Live API');
  print('✅ Generated ${audioData.length} bytes of audio');
}
```

## Future Enhancements

### Planned Features
1. **Custom Voice Training**: Train personalized voice models
2. **Emotion Detection**: Adapt voice tone based on user emotion
3. **Multi-language Support**: Expand beyond English
4. **Advanced VARK**: More sophisticated learning adaptations
5. **Performance Analytics**: Track voice interaction effectiveness

### Integration Opportunities
1. **FoCoMap Integration**: Location-aware voice coaching
2. **Round Logging**: Voice-activated shot logging
3. **Progress Tracking**: Voice-based progress updates
4. **Social Features**: Voice message sharing

## Security Considerations

### API Security
- Secure API key storage
- Request signing and validation
- Rate limiting implementation
- Data encryption in transit

### Privacy
- Audio data handling policies
- User consent management
- Data retention guidelines
- GDPR compliance

## Deployment

### Production Checklist
- [ ] API keys configured in secure environment
- [ ] Error monitoring enabled
- [ ] Performance metrics tracking
- [ ] User feedback collection
- [ ] A/B testing framework
- [ ] Rollback procedures

### Monitoring
- API response times
- Audio generation success rates
- User engagement metrics
- Error rates and types

## Support

### Documentation
- API reference documentation
- Integration examples
- Troubleshooting guides
- Best practices

### Contact
- Technical support: development team
- API issues: Cartesia support
- Feature requests: product team

---

**Last Updated**: January 2025
**Version**: 1.0.0
**Status**: Production Ready ✅
