# FoCo Map Real-Time Voice Experience with Gemini Models

## Overview

This implementation provides a complete real-time voice experience for FoCo Map using only Gemini models, following the 4-stage pipeline:

1. **Real-Time Audio Capture**: Continuous audio recording with voice activity detection
2. **Speech-to-Text**: Using Gemini's multimodal capabilities
3. **Natural Language Understanding**: Using Gemini Pro for intent recognition
4. **Custom Instruction Generation**: Using Gemini for personalized responses

## Architecture

### 1. FoCoMapGeminiVoiceService (`focomap_gemini_voice_service.dart`)

The core service that implements the 4-stage pipeline:

```dart
// Key components:
- Real-time audio streaming with 500ms chunks
- Voice Activity Detection (VAD)
- Gemini multimodal API for STT
- Gemini Pro for NLU and instruction generation
- Gemini Robotics model for spatial analysis
```

**Features:**
- **Low Latency**: Processes audio every 500ms for near real-time response
- **Context Awareness**: Maintains conversation history and golf context
- **Spatial Analysis**: Uses robotics model for trajectory and dispersion analysis
- **Smart Actions**: Automatically saves mental logs, shot logs, and provides insights

### 2. AIInsightGeminiWidget (`ai_insight_gemini_widget.dart`)

The UI component that provides visual feedback:

```dart
// Visual elements:
- Real-time audio waveform visualization
- Conversation history with chat-like interface
- Voice state indicators with animations
- Suggestion chips for quick actions
- Spatial visualization preview
```

**User Experience:**
- **Visual Feedback**: Animated waves show audio levels
- **State Indicators**: Clear visual cues for listening, processing, etc.
- **Conversational UI**: Natural chat interface with AI responses
- **Quick Actions**: Tap suggestions for common commands

### 3. Integration with FoCo Map

The voice service integrates seamlessly with the existing map features:

```dart
// Map integration:
- Real-time marker updates from voice commands
- Spatial analysis visualization on map
- Voice-triggered navigation
- Context-aware logging based on location
```

## Implementation Steps

### Step 1: Initialize Voice Service

```dart
// In FoCoMapWidget
await _geminiVoiceService.initialize();

// Subscribe to voice insights
_geminiVoiceService.insightStream.listen((insight) {
  // Update map with spatial data
  if (insight.spatialData != null) {
    _updateMapVisualization(insight.spatialData);
  }
});
```

### Step 2: Start Voice Listening

```dart
// Start listening with context
await _geminiVoiceService.startListening(
  context: VoiceContext.activeRound,
  roundId: _activeRoundId,
  metadata: {
    'enableSpatialAnalysis': true,
    'currentHole': 5,
  },
);
```

### Step 3: Process Voice Commands

The service automatically:
1. Captures audio in real-time
2. Converts to text using Gemini
3. Understands intent and extracts entities
4. Generates appropriate actions
5. Executes commands (save logs, update map, etc.)

### Step 4: Visual Feedback

```dart
// Add the widget to your UI
AIInsightGeminiWidget(
  activeRoundId: _activeRoundId,
  initialContext: VoiceContext.activeRound,
  onInstructionGenerated: (instruction) {
    // Handle custom instructions
  },
  onInsightReceived: (insight) {
    // Update UI with insights
  },
)
```

## Voice Command Examples

### Mental State Logging
**User**: "Feeling really confident on this tee shot, using my breath and release cue"
**AI Response**: "Great mindset! I've logged your confidence level and breath/release cue. Your recent confidence trend is improving."

### Shot Logging
**User**: "Hit driver 250 yards, slight fade into the fairway"
**AI Response**: "Nice drive! 250-yard fade recorded. Your fairway percentage with driver is now 78% this round."

### Course Navigation
**User**: "What's the best approach to this green?"
**AI Response**: "Based on your position and wind conditions, I recommend a 7-iron to the left side of the green. The pin is back right with a false front."

### Round Analysis
**User**: "How's my mental game today compared to last week?"
**AI Response**: "Your mental performance is trending up! Focus is 15% higher and you're recovering faster from bad shots. Keep using that breath cue."

## Technical Implementation

### Audio Processing
```dart
// Real-time audio capture
final audioStream = await _audioRecorder.startStream(
  codec: Codec.pcm16WAV,
  sampleRate: 16000,
  numChannels: 1,
);

// Process in chunks
audioStream.listen((buffer) {
  _audioChunks.add(buffer);
  if (_shouldProcess()) {
    _processAccumulatedAudio();
  }
});
```

### Gemini API Integration
```dart
// Speech-to-Text
final response = await geminiAPI.generateContent(
  model: 'gemini-1.5-flash',
  content: [
    InlineData(mimeType: 'audio/wav', data: audioBase64),
    Text('Transcribe this golf audio...'),
  ],
);

// Natural Language Understanding
final nluResponse = await geminiAPI.generateContent(
  model: 'gemini-1.5-pro',
  content: [
    Text(contextPrompt + transcription),
  ],
  generationConfig: GenerationConfig(
    responseMimeType: 'application/json',
  ),
);
```

### Spatial Analysis
```dart
// Using Robotics model for trajectory
final spatialResponse = await geminiAPI.generateContent(
  model: 'gemini-robotics-er-1.5-preview',
  content: [
    Text('Analyze golf shot trajectory...'),
  ],
);
```

## Best Practices

1. **Context Management**: Always provide appropriate context for better understanding
2. **Error Handling**: Gracefully handle API failures with fallback options
3. **Privacy**: Process audio locally when possible, send only necessary data
4. **Performance**: Use streaming APIs for real-time response
5. **User Feedback**: Provide clear visual and audio feedback for all states

## Configuration

### API Keys
```dart
// Set in environment
const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
```

### Permissions
```dart
// Required permissions
- Microphone access
- Location (for GPS tagging)
```

### Dependencies
```yaml
dependencies:
  record: ^5.0.0  # For audio recording
  http: ^1.0.0    # For API calls
  permission_handler: ^11.0.0  # For permissions
```

## Future Enhancements

1. **Offline Mode**: Cache common responses for offline use
2. **Multi-language**: Support for multiple languages
3. **Voice Profiles**: Learn user's speaking patterns
4. **Advanced Coaching**: Real-time swing analysis from audio
5. **Group Features**: Voice commands for group play

## Conclusion

This implementation provides a comprehensive real-time voice experience that enhances the FoCo Map with natural language interaction. By using only Gemini models, we ensure consistency and leverage Google's latest AI capabilities for the best possible user experience.

