# AI Insight Widget Usage Guide

## Available Widgets

### 1. AIInsightCardWidget (Original)
The basic insight card widget without conversation features.

```dart
import 'package:fo_co_co/ai_integration/widgets/ai_insight_card_widget.dart';

AIInsightCardWidget(
  insight: insightRecord,
  onTap: () => navigateToDetails(),
  onRate: (rating, feedback) => handleRating(),
)
```

### 2. EnhancedAIInsightWidget (Full Features)
The complete insight widget with interactive chat, enhanced actions, and Firestore integration.

```dart
import 'package:fo_co_co/ai_integration/widgets/ai_insight_widget_enhanced.dart';

EnhancedAIInsightWidget(
  insight: insightRecord,
  enableConversation: true, // Enable chat functionality
  onTap: () => navigateToDetails(),
  onRate: (rating, feedback) => handleRating(),
)
```

## Migration Guide

To upgrade from the original widget to the enhanced version:

1. **Change Import**:
   ```dart
   // From:
   import 'package:fo_co_co/ai_integration/widgets/ai_insight_card_widget.dart';
   
   // To:
   import 'package:fo_co_co/ai_integration/widgets/ai_insight_widget_enhanced.dart';
   ```

2. **Update Widget Name**:
   ```dart
   // From:
   AIInsightCardWidget(...)
   
   // To:
   EnhancedAIInsightWidget(...)
   ```

3. **Optional: Enable Conversation**:
   ```dart
   EnhancedAIInsightWidget(
     insight: insightRecord,
     enableConversation: true, // Add this for chat features
     // ... other parameters
   )
   ```

## Features Comparison

| Feature | AIInsightCardWidget | EnhancedAIInsightWidget |
|---------|----------------|-------------------------|
| Basic insight display | ✅ | ✅ |
| Animations | ✅ | ✅ |
| Rating system | ✅ | ✅ |
| Interactive chat | ❌ | ✅ |
| Like/Dislike buttons | ❌ | ✅ |
| Share functionality | ❌ | ✅ |
| Copy to clipboard | ❌ | ✅ |
| Feedback system | ❌ | ✅ |
| Report functionality | ❌ | ✅ |
| Firestore integration | ❌ | ✅ |
| Rich text formatting | ❌ | ✅ |
| Table support | ❌ | ✅ |
| Markdown rendering | ❌ | ✅ |

## Dependencies

The enhanced widget requires:
```yaml
dependencies:
  flutter_markdown: ^0.7.4+1
  cloud_firestore: ^5.6.9
  font_awesome_flutter: ^10.8.0
```

## Firestore Collections Created

When using the enhanced widget, these collections will be automatically created:
- `ai_insight_conversations` - Chat history
- `ai_insight_reactions` - Like/dislike data  
- `ai_insight_feedback` - User feedback
- `ai_insight_reports` - Content reports
- `message_reactions` - Individual message reactions
- `saved_insights` - Bookmarked insights

## Performance Notes

- The enhanced widget loads chat history lazily
- Animations are optimized for smooth performance
- Firestore operations are batched and cached
- Memory management handles large conversations efficiently
