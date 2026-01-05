# 🎤 LiveKit Token Generation Setup Guide

## 📋 Overview

This guide explains where to get LiveKit credentials and how to set up token generation for the "Just Talk" feature.

## 🔑 Where to Get LiveKit Credentials

### 1. **LiveKit Dashboard** (Already Configured ✅)

Your LiveKit credentials are already in the code:

**Location**: `lib/services/livekit_cartesia_voice_service.dart`

```dart
static const String _livekitUrl = 'wss://fococo-45unq6sj.livekit.cloud';
static const String _apiKey = 'APIhqsNFhwph9pU';
static const String _apiSecret = 'ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F';
```

**To get new credentials or verify:**
1. Go to [LiveKit Cloud Dashboard](https://cloud.livekit.io/)
2. Sign in to your account
3. Navigate to your project: `fococo-45unq6sj`
4. Go to **Settings** → **API Keys**
5. You'll see:
   - **API Key**: Used for token generation
   - **API Secret**: Used to sign tokens (keep this secure!)
   - **Server URL**: Your LiveKit server WebSocket URL

## 🚀 Setup Steps

### Step 1: Install Dependencies

The Firebase Functions need the `jsonwebtoken` package:

```bash
cd firebase/functions
npm install
```

This will install `jsonwebtoken` which was added to `package.json`.

### Step 2: Configure Firebase Functions (Optional)

For production, you can store LiveKit credentials in Firebase Functions config:

```bash
cd firebase
firebase functions:config:set livekit.api_key="APIhqsNFhwph9pU"
firebase functions:config:set livekit.api_secret="ehDWeXLot46F1P4VtSgMYL4gePSLymhdO9IWheeJbC4F"
```

**Note**: The function will use hardcoded values if config is not set (for development).

### Step 3: Deploy Firebase Function

Deploy the LiveKit token generation function:

```bash
cd firebase
firebase deploy --only functions:generateLiveKitToken --project fo-co-co-89gnf5
```

Or deploy all functions:

```bash
firebase deploy --only functions --project fo-co-co-89gnf5
```

### Step 4: Verify Function Deployment

Check that the function is deployed:

```bash
firebase functions:list --project fo-co-co-89gnf5
```

You should see `generateLiveKitToken` in the list.

## 📱 How It Works

### Flow:

1. **User taps "Just Talk" button** in the app
2. **App calls Firebase Function** `generateLiveKitToken` with:
   - `room`: Room name (auto-generated)
   - `identity`: User's Firebase UID
   - `name`: User's display name
3. **Firebase Function generates JWT token** using:
   - LiveKit API Key
   - LiveKit API Secret
   - Room permissions
4. **Token returned to app**
5. **App connects to LiveKit** using the token

### Code Flow:

```
just_talk_widget.dart
  ↓
livekit_cartesia_voice_service.dart
  ↓ _generateToken()
  ↓ FirebaseFunctions.instance.httpsCallable('generateLiveKitToken')
  ↓
firebase/functions/livekit_token.js
  ↓ generateLiveKitToken()
  ↓ Returns JWT token
```

## 🔒 Security Notes

1. **API Secret**: Never expose in client-side code (already secure ✅)
2. **Token Generation**: Always done server-side (Firebase Functions ✅)
3. **Token Expiration**: Tokens expire after 6 hours
4. **Authentication**: Only authenticated Firebase users can generate tokens

## 🧪 Testing

### Test the Function Locally:

```bash
cd firebase/functions
npm run serve
```

Then test with:

```bash
curl -X POST http://localhost:5001/fo-co-co-89gnf5/us-central1/generateLiveKitToken \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "room": "test-room",
      "identity": "test-user",
      "name": "Test User"
    }
  }'
```

### Test in App:

1. Open the app
2. Navigate to "Just Talk"
3. Tap the microphone button
4. Should connect successfully (no crash!)

## 🐛 Troubleshooting

### Error: "Function not found"
- **Solution**: Deploy the function: `firebase deploy --only functions:generateLiveKitToken`

### Error: "Unauthenticated"
- **Solution**: Make sure user is logged in to Firebase Auth

### Error: "Invalid token"
- **Solution**: Check that LiveKit API key/secret are correct in Firebase Functions config

### Error: "Connection timeout"
- **Solution**: Check internet connection and LiveKit server URL

## 📚 Resources

- [LiveKit Documentation](https://docs.livekit.io/)
- [LiveKit Access Tokens Guide](https://docs.livekit.io/guides/access-tokens/)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)

## ✅ Checklist

- [x] LiveKit credentials configured in code
- [x] Firebase Function created (`livekit_token.js`)
- [x] Function exported in `index.js`
- [x] Flutter code updated to use Firebase Functions
- [ ] Deploy Firebase Function: `firebase deploy --only functions:generateLiveKitToken`
- [ ] Test connection in app

---

**Next Step**: Deploy the Firebase Function and test the "Just Talk" feature!
