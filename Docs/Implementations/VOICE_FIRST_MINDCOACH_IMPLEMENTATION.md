# Voice-First MindCoach UX Implementation

## Overview

This document describes the implementation of the voice-first MindCoach UX with LiveKit integration, following the specifications from `mindCoachUX.md`.

## Architecture

### Components

1. **MindCoachVoiceSessionWidget** (`lib/pages/coaching_modules/mind_coach_voice_session_widget.dart`)
   - Minimal UI widget for voice-first sessions
   - Implements line-by-line text display with fade animations
   - Handles session lifecycle and logging

2. **MindCoachVoiceService** (`lib/services/mind_coach_voice_service.dart`)
   - Orchestration service for context detection and auto-triggering
   - Monitors user state and detects stress indicators
   - Selects appropriate templates based on context

3. **GeminiLiveAgentService** (`lib/ai_integration/services/gemini_live_agent_service.dart`)
   - LiveKit agent integration with Gemini Live API
   - Handles real-time audio processing and bidirectional communication
   - Manages connection lifecycle

4. **MindCoachVoiceIntegration** (`lib/pages/coaching_modules/mind_coach_voice_integration.dart`)
   - Helper class for easy integration from anywhere in the app
   - Provides static methods for triggering voice sessions

## UI Specifications

### Voice-First Session UI

Following the minimal UX design from `mindCoachUX.md`:

1. **Top Bar** (small text):
   - Template name • Duration estimate
   - Example: "Reset • ~60 seconds"
   - Fade-in animation

2. **Center Content** (large text, line-by-line):
   - Coaching text displayed one line at a time
   - Each line fades in with delay
   - Large, readable typography (28px)
   - No scrolling - single screen view

3. **Bottom Indicators**:
   - Microphone icon (shows active state)
   - Subtle progress ring (fills as lines appear)
   - No buttons, menus, or chat bubbles

4. **Session End**:
   - Final line fades out
   - "Session complete." text appears
   - Auto-return to previous view
   - No rating, feedback, or summary

## Usage

### Manual Trigger

```dart
import '/pages/coaching_modules/mind_coach_voice_integration.dart';

// Show voice session manually
await MindCoachVoiceIntegration.showVoiceSession(
  context: context,
  templateId: 'MC_T03_POST_SHOT_RECOVERY',
  templateName: 'Reset',
  coachingText: 'Pause.\nTake one slow breath in.\nLet the last shot go.',
  durationEstimate: 60,
);
```

### Auto-Trigger

```dart
// Set context for auto-triggering
MindCoachVoiceIntegration.setActiveRound(roundId);
MindCoachVoiceIntegration.setContext(UserContext.duringRound);

// Auto-trigger based on voice input or mindset
final triggered = await MindCoachVoiceIntegration.autoTriggerVoiceSession(
  context: context,
  userVoiceInput: "I'm rushed",
  currentMindsetRating: 2, // Stress detected
  sessionContext: {
    'pressure_level': 'high',
    'during_round': true,
  },
);
```

## Context Detection

The service automatically detects when to trigger voice sessions:

1. **During Round + Stress Detected**:
   - Mindset rating <= 2
   - User says trigger phrases ("I'm rushed", "I need help", etc.)

2. **Time-Based Throttling**:
   - Minimum 5 minutes between auto-triggered sessions

3. **Template Selection**:
   - Based on detected scenarios (rushed, high pressure, struggling)
   - Falls back to context-based selection (during round → Reset)

## Background Audio Support

### iOS Configuration

Background audio mode is configured in `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Android Configuration

Android audio permissions are already configured in `AndroidManifest.xml`:
- `RECORD_AUDIO`
- `MODIFY_AUDIO_SETTINGS`

LiveKit client handles audio focus automatically.

## Session Logging

Sessions are automatically logged to Firestore with:
- `template_id`: Template used
- `intervention_type`: Type of intervention (e.g., "Reset cue")
- `duration`: Actual session duration
- `validator_status`: PASS/FAIL
- `context`: User context (during round, pre-round, etc.)
- `timestamp`: Session timestamp

Sessions are available as memory input for future AI insights.

## Integration Points

### With Existing MindCoach Widget

The voice-first widget can be integrated into the existing MindCoach flow:

```dart
// In mind_coach_widget.dart
import '/pages/coaching_modules/mind_coach_voice_integration.dart';

// Trigger voice session from button or auto-detection
await MindCoachVoiceIntegration.autoTriggerVoiceSession(
  context: context,
  userVoiceInput: userInput,
  currentMindsetRating: currentMindset,
);
```

### With Round Tracking

Set active round for context awareness:

```dart
// When round starts
MindCoachVoiceIntegration.setActiveRound(roundId);

// When round ends
MindCoachVoiceIntegration.setActiveRound(null);
```

## Backend Requirements

### LiveKit Agent Server

A backend agent server (Python/Node.js) is required to handle Gemini Live API integration:

```python
from livekit.agents import AgentSession
from livekit.plugins import google

session = AgentSession(
    llm=google.realtime.RealtimeModel(
        model="gemini-2.5-flash-native-audio-preview-12-2025",
        voice="Puck",
        temperature=0.8,
        instructions="You are FoCoCo's MindCoach AI...",
    ),
)
```

### Firebase Cloud Function

Ensure `generateLiveKitToken` function exists and properly generates tokens:

```javascript
// firebase/functions/livekit_token.js
exports.generateLiveKitToken = functions.https.onCall(async (data, context) => {
  // Generate LiveKit token with proper permissions
});
```

## Testing

### Manual Testing

1. **Voice Session Display**:
   - Verify line-by-line text appears correctly
   - Check fade animations work smoothly
   - Ensure progress ring fills as lines appear

2. **Auto-Trigger**:
   - Set context to "during round"
   - Set mindset rating to 2 or below
   - Verify session auto-triggers

3. **Session Logging**:
   - Complete a voice session
   - Verify session appears in Firestore
   - Check all required fields are present

### Integration Testing

1. **Context Detection**:
   - Test during round detection
   - Test stress indicator detection
   - Test time-based throttling

2. **Template Selection**:
   - Test scenario-based selection
   - Test mindset-based selection
   - Test context-based fallback

## Future Enhancements

1. **Voice Input Processing**:
   - Real-time transcription display
   - Intent detection from voice input
   - Dynamic content adaptation

2. **Background Audio**:
   - Handle interruptions (phone calls, notifications)
   - Resume audio after interruptions
   - Support for background playback

3. **Analytics**:
   - Track session effectiveness
   - Measure mindset improvement
   - Analyze usage patterns

## Notes

- The voice-first UI is intentionally minimal - no scrolling, no chat bubbles, no typing indicators
- Sessions auto-complete and return to previous view
- All logging happens in the background
- Form-based sessions remain available for planning/pre-round use
