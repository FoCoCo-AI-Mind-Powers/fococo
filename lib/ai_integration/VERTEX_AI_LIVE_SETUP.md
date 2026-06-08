# Vertex AI Gemini Live Integration Guide

## Overview

FoCoCo now supports **Vertex AI Gemini Live** for real-time speech-to-speech conversation using the `gemini-live-2.5-flash-preview-native-audio-09-2025` model.

## Features

- ✅ Real-time speech-to-text via Gemini Live
- ✅ AI text responses from Gemini Live
- ✅ High-quality text-to-speech via Cartesia
- ✅ Low-latency voice interaction
- ✅ VARK learning style adaptation
- ✅ Toggle between text and voice modes
- ✅ Automatic fallback to text mode if voice fails

## Architecture

```
User Speech → Gemini Live (STT + AI) → Text Response → Cartesia TTS → Audio Output
```

**Note**: Gemini Live handles speech recognition and AI processing, while Cartesia handles voice synthesis for the responses.

## Setup

### 1. Configure Google Cloud Project

You need a Google Cloud Project with Vertex AI API enabled:

```bash
# Set your Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT=your-project-id

# Or use dart-define when running Flutter
flutter run --dart-define=GOOGLE_CLOUD_PROJECT=your-project-id
```

### 2. Authentication Options

#### Option A: Firebase AI Logic (required going forward)
Gemini is resolved server-side. The Flutter client authenticates via
**Firebase App Check**, and the Cloud Functions runtime reads the key from
**Secret Manager** (`GEMINI_KEY_APP`). No raw key is shipped to the client
and no `--dart-define=GEMINI_API_KEY` is used anymore.

#### Option B: Application Default Credentials (Recommended for production)
```bash
# Authenticate with gcloud
gcloud auth application-default login

# Set project
gcloud config set project your-project-id
```

### 3. Enable Vertex AI API

```bash
gcloud services enable aiplatform.googleapis.com
```

## Usage

### In Voice Chat Modal

1. **Open Voice Chat**: Tap the floating voice button in the navbar
2. **Enable Voice Mode**: Toggle the "Live" switch in the header
3. **Start Speaking**: Tap the microphone button to start speech-to-speech conversation

### Programmatic Usage

```dart
import 'package:fococo/ai_integration/services/vertex_ai_gemini_live_service.dart';

final service = VertexAIGeminiLiveService();

// Initialize
await service.initialize(
  projectId: 'your-project-id',
  location: 'global', // or 'us-central1', etc.
  varkPreferences: varkPrefs,
);

// Connect
await service.connect();

// Start listening
await service.startListening();

// Listen to responses
service.responseStream.listen((response) {
  print('AI Response: ${response.text}');
  // Play audio: response.audioData
});

// Stop listening
await service.stopListening();

// Disconnect
await service.disconnect();
```

## Model Details

- **Model ID**: `gemini-live-2.5-flash-preview-native-audio-09-2025`
- **Endpoint**: Vertex AI WebSocket API
- **Audio Format**: 
  - Input: 16kHz, 16-bit PCM, mono (for speech recognition)
- **Response Modalities**: TEXT (Cartesia handles TTS)
- **TTS Provider**: Cartesia (sonic-2 model with Pro voice clone)


## Configuration

### Environment Variables

```bash
# Required
GOOGLE_CLOUD_PROJECT=your-project-id

# Gemini key is NOT a client env-var. Stored in Secret Manager as
# `GEMINI_KEY_APP` and consumed by Cloud Functions only.

# Optional (default: 'global')
GOOGLE_CLOUD_LOCATION=global
```

### Code Configuration

The service can be configured in `voice_chat_modal.dart`:

```dart
await _vertexAILiveService.initialize(
  projectId: 'your-project-id', // Optional, uses env var if not provided
  location: 'global', // Optional, defaults to 'global'
  accessToken: null, // Optional, uses ADC or API key if not provided
  varkPreferences: _varkPrefs, // Optional, for personalized coaching
);
```

## Troubleshooting

### Connection Issues

1. **Check Project ID**: Ensure `GOOGLE_CLOUD_PROJECT` is set correctly
2. **Verify API Access**: Make sure Vertex AI API is enabled
3. **Check Authentication**: Verify API key or ADC credentials

### Audio Issues

1. **Microphone Permission**: Ensure microphone permission is granted
2. **Audio Format**: Verify audio is being captured at 16kHz, 16-bit PCM
3. **Network**: Check network connection for WebSocket stability

### Error Messages

- `Google Cloud Project ID not configured`: Set `GOOGLE_CLOUD_PROJECT`
- `No authentication method available`: Configure API key or ADC
- `Microphone permission not granted`: Grant microphone permission in app settings

## Differences from Google AI Studio API

| Feature | Vertex AI | Google AI Studio |
|---------|----------|------------------|
| Endpoint | `{location}-aiplatform.googleapis.com` | `generativelanguage.googleapis.com` |
| Authentication | ADC or API Key | API Key only |
| Model Format | `projects/{project}/locations/{location}/publishers/google/models/{model}` | `models/{model}` |
| Requires Project | Yes | No |

## References

- [Vertex AI Live API Documentation](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/live-api/get-started-websocket)
- [Gemini Live API Guide](https://ai.google.dev/gemini-api/docs/live)
- [Vertex AI Authentication](https://cloud.google.com/docs/authentication)

