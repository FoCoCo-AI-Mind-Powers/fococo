# FoCoMap Testing & User Guide

## Overview

FoCoMap is a comprehensive GPS-based visualization tool that combines mental and technical golf performance data. This guide covers testing procedures, feature walkthrough, and implementation details.

## Features Checklist (Based on mapConcept.md)

### ✅ Core Features Implemented

#### 1. Three-Layer System
- [x] **MindMap Layer** - Mental performance visualization with color-coded markers
  - 🟢 Green: Strong mindset (Focus + Confidence + Control > 21)
  - 🟡 Yellow: Neutral mindset (15-21)
  - 🔴 Red: Struggling mindset (< 15)
- [x] **ShotMap Layer** - Technical performance with club-specific markers
  - Club icons and colors
  - Shot outcome tracking
  - Wind condition display
- [x] **SyncMap Layer** - Combined mental + technical correlation view
  - Composite markers showing both data types
  - AI-generated correlation insights

#### 2. Voice Input System
- [x] Context-aware voice processing (pre/mid/post-round)
- [x] Natural language parsing with automatic categorization
- [x] Real-time transcription display
- [x] Processing status indicators

#### 3. Real-Time Features
- [x] Live mode for Plus/Prime tiers
- [x] Real-time marker updates
- [x] Live voice logging during rounds
- [x] Instant map refresh on new data

#### 4. Interactive Elements
- [x] Tap markers for detailed popup cards
- [x] Filter system for clubs, cues, weather
- [x] Zoom from global to hole level
- [x] Map type switching (standard/satellite/hybrid)

#### 5. Data Visualization
- [x] GPS coordinate tracking
- [x] Marker clustering for performance
- [x] Color-coded mental states
- [x] Club-specific icons
- [x] Wind and condition indicators

## Test Data Generator

### Quick Start

1. **Access Test Panel**
   ```dart
   // In debug mode, look for the purple science icon FAB
   // Or programmatically:
   FoCoMapEnhancements.showTestPanel(context, onDataGenerated);
   ```

2. **Choose a Preset**
   - **Quick Test**: 3 rounds, 20 shots each (fast testing)
   - **Full Season**: 20 rounds, 50 shots each (comprehensive data)
   - **Tournament Week**: 7 rounds, 72 shots each (intensive data)
   - **Practice Rounds**: 10 rounds, 25 shots each (partial rounds)

3. **Custom Configuration**
   - Rounds: 1-30
   - Shots per round: 10-100
   - Include live round option

### Test Data Structure

#### Generated Round Data
```dart
- Course selection from 8 famous golf courses
- Realistic GPS coordinates with slight variations
- Mental state variations (green/yellow/red)
- Recovery holes
- AI summaries
- Voice transcriptions
```

#### Generated Shot Data
```dart
- Club-specific distances with realistic variability
- Shot outcomes based on mental state
- Wind conditions
- Performance ratings
- Miss patterns
- AI insights
```

### Sample Voice Inputs for Testing

#### Mental-Only Inputs
- "Feeling really confident today, my breathing routine is working perfectly"
- "Lost focus after that bad shot on 5, need to reset"
- "Mental game is strong today, trusting every shot"

#### Technical-Only Inputs
- "Driver on 10, crushed it 290 down the middle"
- "7 iron from 155, stuck it to 6 feet"
- "Pushed my driver right into the rough again"

#### Mixed Inputs
- "Driver on 5 went right because I got quick, lost my tempo"
- "Used my breathing cue before this iron shot and striped it"
- "When I trust my routine, my driver stays in play"

## User Walkthrough Features

### Interactive Tutorial
The walkthrough includes 9 animated steps:

1. **Welcome Screen** - Overview of FoCoMap capabilities
2. **Layer Introduction** - Three-layer system explanation
3. **MindMap Details** - Mental performance tracking
4. **ShotMap Details** - Technical shot analysis
5. **SyncMap Details** - Correlation insights
6. **Voice Logging** - How to use voice input
7. **Live Mode** - Real-time tracking features
8. **Interactive Analysis** - Marker interaction
9. **Get Started** - Ready to use guide

### Animation Features
- Fade-in/slide animations for smooth transitions
- Pulsing effects for emphasis
- Rotating layer icons
- Floating particles for visual appeal
- Interactive examples with real-time feedback

## Implementation Integration

### 1. Add Dependencies
```yaml
dependencies:
  shared_preferences: ^2.0.0  # For walkthrough state
  # ... other existing dependencies
```

### 2. Import Enhanced Features
```dart
import 'foco_map_walkthrough.dart';
import 'foco_map_test_panel.dart';
import 'focomap_test_data_generator.dart';
```

### 3. Initialize Walkthrough (in initState)
```dart
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FoCoMapEnhancements.checkAndShowWalkthrough(context);
  });
}
```

### 4. Add Test Panel Button (Debug Mode)
```dart
if (kDebugMode)
  Positioned(
    bottom: 180,
    right: 20,
    child: FloatingActionButton(
      onPressed: () {
        FoCoMapEnhancements.showTestPanel(context, () {
          _loadMapData(); // Refresh after generating data
        });
      },
      backgroundColor: Colors.purple,
      child: const Icon(Icons.science),
    ),
  ),
```

### 5. Add Help Button
```dart
GestureDetector(
  onTap: () {
    FoCoMapEnhancements.showWalkthroughManually(context);
  },
  child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
  ),
),
```

## Testing Scenarios

### Scenario 1: First-Time User
1. Launch FoCoMap
2. Walkthrough automatically appears
3. Complete all 9 steps
4. Generate quick test data (3 rounds)
5. Explore all three layers
6. Test voice input

### Scenario 2: Mental Performance Testing
1. Generate test data with varying mental states
2. Switch to MindMap layer
3. Observe color-coded markers
4. Tap markers to view mental scores
5. Check recovery hole highlights

### Scenario 3: Technical Analysis Testing
1. Switch to ShotMap layer
2. Filter by specific clubs
3. Check shot outcome patterns
4. Verify distance calculations
5. Review AI shot insights

### Scenario 4: Correlation Testing
1. Switch to SyncMap layer
2. Look for patterns between mental state and shot outcomes
3. Verify AI correlation insights
4. Test different filter combinations

### Scenario 5: Live Mode Testing
1. Generate data with live round enabled
2. Enable live mode (Plus/Prime tier)
3. Test voice input during "live" round
4. Verify real-time marker updates
5. Check live status indicators

## Tier-Based Feature Matrix

| Feature | Junior | Base | Plus | Prime |
|---------|--------|------|------|-------|
| View Past Rounds | ❌ | ✅ | ✅ | ✅ |
| MindMap Layer | ❌ | ✅ | ✅ | ✅ |
| ShotMap Layer | ❌ | ❌ | ❌ | ✅ |
| SyncMap Layer | ❌ | ❌ | ❌ | ✅ |
| Voice Input | ❌ | ✅* | ✅ | ✅ |
| Live Mode | ❌ | ❌ | ✅ | ✅ |
| GPS Tracking | ❌ | ✅* | ✅ | ✅ |
| AI Insights | ❌ | Basic | Advanced | Premium |

*Limited functionality

## Troubleshooting

### Common Issues

1. **No markers appearing**
   - Check authentication status
   - Verify Firestore permissions
   - Generate test data first

2. **Voice input not working**
   - Check microphone permissions
   - Verify speech-to-text API configuration
   - Test with sample phrases

3. **Live mode not activating**
   - Verify user tier (Plus/Prime required)
   - Check GPS permissions
   - Ensure internet connectivity

4. **Map not loading**
   - Verify Google Maps API key
   - Check platform-specific configurations
   - Test internet connection

## Performance Optimization

1. **Marker Clustering**
   - Automatically groups markers when zoomed out
   - Expands on zoom for detail

2. **Data Loading**
   - Progressive loading based on zoom level
   - Local caching for frequently accessed data
   - Pagination for large datasets

3. **Memory Management**
   - Marker recycling for large datasets
   - Efficient image loading
   - Background processing for voice

## Next Steps

1. Test all features with generated data
2. Verify tier-based access controls
3. Test voice input accuracy
4. Validate GPS coordinate accuracy
5. Check performance with large datasets
6. Test across different devices/platforms

## Support

For issues or questions:
1. Check the walkthrough guide
2. Review test data generation logs
3. Verify Firebase configuration
4. Check platform-specific settings