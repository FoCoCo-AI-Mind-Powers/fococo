# FoCoCo Voice Chat Setup Guide

## Overview
The FoCoCo Voice Chat Modal provides both text-to-text chat and voice agent functionality with multiple fallback layers to ensure reliability.

## Current Status ✅
- **Text Chat**: Fully functional with UnifiedAIService fallback
- **Voice Features**: Requires API key configuration
- **Cartesia Voice**: Pre-configured and ready
- **Error Handling**: Graceful fallbacks implemented

## API Key Configuration

### 1. Gemini API Key (Required for Voice Features)

#### Get Your API Key:
1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Create a new API key
4. Copy the key (starts with `AIza...`)

#### Set the API Key:
```bash
# Method 1: Command line (Recommended for development)
fvm flutter run --dart-define=GEMINI_API_KEY=your_actual_api_key_here

# Method 2: Environment variable
export GEMINI_API_KEY=your_actual_api_key_here
fvm flutter run

# Method 3: Create .env file (not recommended for production)
echo "GEMINI_API_KEY=your_actual_api_key_here" > .env
```

### 2. Cartesia API Key (Pre-configured)
The Cartesia API key is already configured in the code:
- **Key**: `sk_car_hksASYyHegCKwWLWfAL8SW`
- **Voice Model**: `sonic-2-2025-05-08`
- **Voice ID**: `694f9389-aac1-45b6-b726-9d9369183238` (Pro voice clone)

### 3. OpenAI API Key (Optional - for enhanced AI features)
```bash
fvm flutter run --dart-define=OPENAI_API_KEY=your_openai_key_here
```

## Service Architecture

### 1. Primary Services (Best Experience)
- **GeminiCartesiaBridgeService**: Gemini AI + Cartesia Pro Voice
- **Features**: Real-time voice, thinking mode, VARK adaptation

### 2. Fallback Services (Good Experience)
- **GeminiLiveAPIService**: Gemini Live API for voice
- **CartesiaAPIService**: Pro voice synthesis
- **Features**: Voice interaction, standard TTS

### 3. Ultimate Fallback (Always Works)
- **UnifiedAIService**: Firebase AI + Flutter TTS
- **Features**: Text chat, basic voice playback
- **Reliability**: Works without any API keys

## Testing Guide

### 1. Test Text Chat (Should Always Work)
```dart
// Open voice chat modal
// Type any message like: "Help me with my putting confidence"
// Should receive AI response immediately
```

### 2. Test Voice Features (Requires Gemini API Key)
```dart
// With API key configured:
// 1. Tap microphone button
// 2. Grant microphone permission
// 3. Speak your message
// 4. Should hear AI response with Cartesia voice
```

### 3. Test Deep Thinking Mode
```dart
// Toggle "Deep Thinking Mode" switch
// Ask complex question: "How can I develop a complete pre-shot routine?"
// Should receive more detailed, analytical response
```

## Error Messages & Solutions

### "Gemini API key not configured"
**Solution**: Add API key using one of the methods above

### "Microphone permission needed"
**Solution**: 
1. Tap microphone button
2. Allow permission when prompted
3. Or go to device Settings > FoCoCo > Microphone

### "Voice features limited"
**Fallback**: Text chat still works perfectly
**Solution**: Configure Gemini API key for full features

## VARK Learning Preferences

The voice chat adapts to user learning styles:

### Visual Learners
- Slower speech pace
- Visualization cues
- Descriptive language

### Auditory Learners  
- Optimized rhythm
- Sound-based metaphors
- Musical elements

### Read/Write Learners
- Structured delivery
- Note-taking pauses
- List-based responses

### Kinesthetic Learners
- Faster pace
- Action-oriented language
- Physical sensations

## Development Commands

### Run with Gemini API Key
```bash
fvm flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### Run with All API Keys
```bash
fvm flutter run \
  --dart-define=GEMINI_API_KEY=your_gemini_key \
  --dart-define=OPENAI_API_KEY=your_openai_key
```

### Debug Voice Services
```bash
# Enable debug logging
fvm flutter run --debug
# Check console for service initialization messages
```

## Troubleshooting

### Voice Chat Not Opening
- Check if modal is properly imported
- Verify navigation context
- Check for widget tree errors

### No AI Response
- Verify internet connection
- Check API key configuration
- Look for error messages in debug console

### Voice Not Working
- Check microphone permissions
- Verify Gemini API key
- Test with text chat first

### Poor Voice Quality
- Ensure Cartesia service is initialized
- Check network connection
- Verify voice model configuration

## Production Deployment

### Security Considerations
1. **Never commit API keys** to version control
2. **Use environment variables** in production
3. **Implement key rotation** for security
4. **Monitor API usage** and costs

### Performance Optimization
1. **Cache voice responses** when possible
2. **Implement request queuing** for high load
3. **Use connection pooling** for WebSocket connections
4. **Monitor service health** and failover automatically

## Support

For issues or questions:
1. Check debug console for error messages
2. Verify API key configuration
3. Test with fallback services
4. Review this guide for solutions

The voice chat system is designed to be resilient - even if advanced features fail, basic text chat will always work to help users with their mental game training.
