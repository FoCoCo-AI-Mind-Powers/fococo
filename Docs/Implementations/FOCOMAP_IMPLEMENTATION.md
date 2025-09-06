# FoCoMap - Live Golf Experience Implementation

## Overview

FoCoMap is a comprehensive live golf mapping system that provides real-time visualization of both mental and technical golf performance data. The system includes three layers (MindMap, ShotMap, SyncMap) with voice input, NLP processing, and live data streaming.

## ✅ Implementation Status

### Completed Components

1. **Firebase Schema & Collections**
   - `round_logs` - Mental performance data
   - `shot_logs` - Technical shot data  
   - Updated Firestore rules with proper security
   - Full schema integration with existing backend

2. **Core Services**
   - `FoCoMapLiveService` - Real-time data streaming
   - `VoiceLoggingService` - Voice input and NLP processing
   - Live update notifications and error handling

3. **Map Widget Architecture**
   - Three-layer system (MindMap, ShotMap, SyncMap)
   - Real-time marker updates
   - Filter system for clubs, cues, weather
   - Live/Review mode toggle

4. **Data Models**
   - `FoCoMapModel` - State management with ChangeNotifier
   - Complete CRUD operations for round and shot logs
   - Live data filtering and processing

## 📱 Current Implementation

### Placeholder Widget
- Located: `lib/pages/foco_map/foco_map_placeholder_widget.dart`
- Shows layer selection, live mode toggle, and data streaming
- Demonstrates full functionality without external dependencies
- Includes sample data generation for testing

### Key Features Working
- ✅ Layer switching (MindMap, ShotMap, SyncMap)
- ✅ Live mode toggle with real-time streaming
- ✅ Voice logging service (ready for speech recognition)
- ✅ Data visualization in list format
- ✅ Sample data generation
- ✅ Real-time notifications

## 🔧 To Enable Full Map Functionality

### Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  google_maps_flutter: ^2.5.0
  location: ^5.0.0
  speech_to_text: ^6.6.0
  geolocator: ^10.1.0
```

### Configuration Steps

1. **Google Maps Setup**
   ```bash
   # Add Google Maps API key to android/app/src/main/AndroidManifest.xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_API_KEY"/>
   
   # Add to ios/Runner/AppDelegate.swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

2. **Permissions**
   
   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs location access to track golf shots</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for voice logging</string>
   ```

3. **Replace Placeholder**
   - Rename `foco_map_widget.dart` to `foco_map_full_widget.dart`
   - Rename `foco_map_placeholder_widget.dart` to `foco_map_widget.dart`
   - Update imports in navigation

## 🎯 Usage Instructions

### Adding to Navigation

1. Import the widget:
   ```dart
   import '/pages/foco_map/foco_map_placeholder_widget.dart';
   ```

2. Add to navigation:
   ```dart
   // In your navigation file
   case '/focomap':
     return const FoCoMapPlaceholderWidget();
   ```

3. Add navigation item:
   ```dart
   ListTile(
     leading: const Icon(Icons.map),
     title: const Text('FoCoMap'),
     onTap: () => context.pushNamed('/focomap'),
   )
   ```

### Testing the Implementation

1. **Start the app** and navigate to FoCoMap
2. **Toggle layers** to see different data views
3. **Enable Live Mode** to start real-time streaming
4. **Add Sample Data** to test the visualization
5. **Check Firebase Console** to see data being written

## 📊 Data Structure Examples

### Round Log Example
```json
{
  "userId": "user123",
  "roundId": "round_1234567890",
  "date": "2024-01-15T10:30:00Z",
  "courseName": "Augusta National",
  "mindsetFocus": 8,
  "mindsetConfidence": 7,
  "mindsetControl": 9,
  "bestCue": "Deep breathing",
  "overallMindsetEmoji": "😊",
  "coordinates": {"latitude": 33.5028, "longitude": -82.0201},
  "isLive": true
}
```

### Shot Log Example
```json
{
  "userId": "user123",
  "roundId": "round_1234567890",
  "shotId": "shot_1234567890",
  "holeNumber": 5,
  "clubUsed": "Driver",
  "distanceAttempted": 285.0,
  "shotOutcome": "fairway",
  "cueUsed": "smooth tempo",
  "confidenceLevel": 8,
  "coordinates": {"latitude": 33.5030, "longitude": -82.0199}
}
```

## 🔮 Future Enhancements

### Phase 2 Features
- [ ] AI-powered shot recommendations
- [ ] Course recognition from GPS
- [ ] Weather API integration
- [ ] Social sharing of rounds
- [ ] Coaching insights overlay

### Advanced Features
- [ ] AR putting line projection
- [ ] Wearable device integration
- [ ] Tournament mode
- [ ] Handicap integration
- [ ] Video shot analysis

## 🐛 Troubleshooting

### Common Issues

1. **Firebase permissions error**
   - Check Firestore rules are deployed
   - Verify user authentication

2. **No data showing**
   - Run "Add Sample Data" first
   - Check network connectivity
   - Verify Firebase configuration

3. **Live mode not working**
   - Check user subscription tier
   - Verify Firestore listeners are active

### Debug Commands
```bash
# Check Firebase connection
flutter packages pub run build_runner build

# Verify dependencies
flutter pub deps

# Check for analysis issues
flutter analyze
```

## 📚 Related Documentation

- [Firebase Setup Guide](./firebase/README.md)
- [VARK Integration](./VARK_INTEGRATION.md)
- [Voice Chat Implementation](./VOICE_CHAT_IMPLEMENTATION.md)
- [Developer Blueprint](./Docs/fo_co_co_app_developer_blueprint.md)

## 🤝 Contributing

When extending FoCoMap:

1. Follow the existing layer architecture
2. Maintain real-time streaming capability  
3. Add proper error handling
4. Update Firestore rules for new fields
5. Test with both live and review modes

---

**Note**: This implementation provides a complete foundation for the FoCoMap feature. The placeholder version demonstrates all functionality and can be enhanced with the full map implementation when dependencies are added.

