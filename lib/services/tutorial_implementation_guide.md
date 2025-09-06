# FoCoCo Tutorial Implementation Guide

## Overview
This guide documents the comprehensive tutorial system implemented across all FoCoCo app pages using the `tutorial_coach_mark` package.

## Core Tutorial Service

### AppTutorialService (`lib/services/app_tutorial_service.dart`)
The main service that provides tutorial functionality for all pages:

```dart
// Key features:
- Centralized tutorial management
- Persistent tutorial completion tracking  
- Consistent UI/UX across all tutorials
- Page-specific tutorial methods
- Quick tooltip functionality
```

## Implementation Pattern

### 1. Import the Service
```dart
import '/services/app_tutorial_service.dart';
```

### 2. Add to State Class
```dart
class _PageWidgetState extends State<PageWidget> {
  final AppTutorialService _tutorialService = AppTutorialService();
  
  // Tutorial target keys
  final GlobalKey _key1 = GlobalKey();
  final GlobalKey _key2 = GlobalKey();
  // ... more keys
}
```

### 3. Initialize in initState
```dart
@override
void initState() {
  super.initState();
  // ... other initialization
  _checkAndShowTutorial();
}

Future<void> _checkAndShowTutorial() async {
  await Future.delayed(const Duration(milliseconds: 1500));
  
  if (!mounted) return;
  
  _tutorialService.startPageTutorial(
    context,
    key1: _key1,
    key2: _key2,
    // ... more keys
  );
}
```

### 4. Add Keys to Widgets
```dart
Widget build(BuildContext context) {
  return Container(
    key: _tutorialKey,
    child: YourWidget(),
  );
}
```

## Implemented Pages

### 1. Dashboard (`glass_dashboard_widget.dart`)
- **Tutorial Keys**: pillarCardsKey, quickActionsKey, statsKey, aiCoachKey, recentActivityKey
- **Focus**: Overview of mental performance pillars and quick access features

### 2. Golf Rounds (`golf_rounds_widget.dart`)
- **Tutorial Keys**: roundsListKey, addRoundKey, filterKey, statsKey
- **Focus**: How to log rounds and view performance statistics

### 3. AI Insights (`claude_style_ai_insights_widget.dart`)
- **Tutorial Keys**: chatAreaKey, suggestionsKey, voiceInputKey, insightTypesKey
- **Focus**: Interacting with the AI coach for personalized insights

### 4. Coaching Modules (`coaching_modules_widget.dart`)
- **Tutorial Keys**: modulesGridKey, filterPillarsKey, progressTrackerKey, varkIndicatorKey
- **Focus**: Exploring VARK-adapted coaching content

### 5. Progress (Pending)
- **Tutorial Keys**: chartsKey, metricsKey, milestonesKey, exportKey
- **Focus**: Understanding performance trends and achievements

### 6. Profile (Pending)
- **Tutorial Keys**: profileInfoKey, settingsKey, subscriptionKey, varkKey
- **Focus**: Managing profile and preferences

### 7. VARK Onboarding (Pending)
- **Tutorial Keys**: questionKey, optionsKey, progressKey
- **Focus**: Understanding the learning style assessment

## Tutorial Content Structure

Each tutorial card includes:
- **Icon**: Visual indicator for the feature
- **Title**: Clear, engaging heading
- **Description**: Concise explanation of functionality
- **Action Buttons**: Next/Skip options
- **Color Theme**: Consistent with app design

## Best Practices

### 1. Timing
- Show tutorials after animations complete (1-1.5s delay)
- Don't interrupt user actions

### 2. Persistence
- Track completion using SharedPreferences
- Allow users to replay tutorials from settings

### 3. Content
- Keep descriptions concise (2-3 sentences)
- Use action-oriented language
- Highlight key benefits

### 4. Visual Design
- Use glassmorphic design consistent with app
- Ensure high contrast for readability
- Add subtle animations for engagement

## Testing Tutorials

### Reset All Tutorials
```dart
// For testing - add to settings or debug menu
await _tutorialService.resetAllTutorials();
```

### Check Tutorial Status
```dart
final hasCompleted = await _tutorialService.hasCompletedTutorial(tutorialKey);
```

## Common Issues & Solutions

### Issue: Tutorial not showing
- Check if key is properly attached to widget
- Verify delay is sufficient for UI to render
- Ensure mounted check before showing

### Issue: Tutorial shows repeatedly
- Verify completion is being saved
- Check SharedPreferences persistence

### Issue: Wrong element highlighted
- Ensure GlobalKey is unique
- Verify key is on the correct widget

## Future Enhancements

1. **Interactive Tutorials**: Step-by-step guided actions
2. **Video Tutorials**: Embedded video guides
3. **Contextual Help**: Show tutorials based on user behavior
4. **Accessibility**: Voice-over support for tutorials
5. **Analytics**: Track tutorial engagement and completion rates

## Maintenance

- Review tutorials after major UI changes
- Update content based on user feedback
- Add tutorials for new features
- Keep tutorial content in sync with actual functionality
