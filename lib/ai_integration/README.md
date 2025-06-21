# FoCoCo AI Integration Module

This module provides comprehensive OpenAI integration for the FoCoCo golf mental coaching app, enabling AI-powered insights, recommendations, and personalized content generation.

## 🎯 Features

### Core AI Services
- **Golf Performance Insights**: AI analysis of golf rounds with mental performance focus
- **Mental Coaching Recommendations**: Personalized coaching module suggestions
- **Adaptive Content Generation**: VARK-aligned learning content creation
- **Session Feedback**: AI-powered feedback for mental coaching sessions
- **Cost Tracking**: Usage analytics and budget management

### Key Capabilities
- ✅ Post-round mental performance analysis
- ✅ Long-term mindset trend analysis
- ✅ Routine effectiveness optimization
- ✅ Personalized content recommendations
- ✅ VARK learning style adaptation
- ✅ Multi-turn conversation support (Prime tier)
- ✅ Cost tracking and usage analytics
- ✅ Rate limiting and error handling

## 🚀 Quick Start

### 1. Environment Setup

Add your OpenAI API key to your environment variables:

```bash
# Add to your .env file or environment
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_ORG_ID=your_organization_id_optional
```

### 2. Initialize AI Services

```dart
import 'package:fo_co_co/ai_integration/index.dart';

// Initialize AI services in your main.dart
await FoCoCoAI.initialize();
```

### 3. Generate Golf Insights

```dart
// Generate insight for a golf round
final insight = await FoCoCoAI.generateRoundInsight(
  userId: currentUserUid,
  golfRound: golfRoundRecord,
);

// Or use the extension method
final insight = await golfRoundRecord.generateAIInsight();
```

### 4. Get Coaching Recommendations

```dart
// Get personalized coaching recommendations
final recommendations = await FoCoCoAI.getCoachingRecommendations(
  userId: currentUserUid,
);

// Or use the extension method
final recommendations = await userRecord.getCoachingRecommendations();
```

### 5. Generate Personalized Content

```dart
// Create VARK-adapted content
final content = await FoCoCoAI.createPersonalizedContent(
  userId: currentUserUid,
  contentType: 'lesson',
  topic: 'Pre-shot routine',
  context: {'difficulty': 'beginner'},
);
```

## 📖 Detailed Usage

### AI Insight Service

```dart
import 'package:fo_co_co/ai_integration/services/ai_insight_service.dart';

final insightService = AIInsightService.instance;

// Generate round insight
final insight = await insightService.generateRoundInsight(
  userId: 'user123',
  golfRound: golfRoundRecord,
  forceGenerate: false, // Skip if already generated
);

// Generate performance trend analysis
final trendInsight = await insightService.generatePerformanceInsight(
  userId: 'user123',
  roundsToAnalyze: 5,
);

// Get user's insights
final insights = await insightService.getUserInsights(
  userId: 'user123',
  limit: 10,
  category: 'mental_performance',
);

// Rate an insight
await insightService.rateInsight(
  insightId: 'insight123',
  rating: 4,
  feedback: 'Very helpful insights!',
);
```

### AI Coaching Service

```dart
import 'package:fo_co_co/ai_integration/services/ai_coaching_service.dart';

final coachingService = AICoachingService.instance;

// Generate coaching recommendations
final recommendations = await coachingService.generateCoachingRecommendations(
  userId: 'user123',
);

// Generate personalized content
final content = await coachingService.generatePersonalizedContent(
  userId: 'user123',
  contentType: 'visualization',
  topic: 'Pressure putting',
  additionalContext: {
    'skill_level': 'intermediate',
    'primary_concern': 'anxiety',
  },
);

// Generate session feedback
final feedback = await coachingService.generateSessionFeedback(
  userId: 'user123',
  session: mentalSessionRecord,
);

// Get adaptive learning path
final learningPath = await coachingService.getAdaptiveLearningPath(
  userId: 'user123',
  pathLength: 5,
);
```

### Cost Tracking

```dart
import 'package:fo_co_co/ai_integration/services/ai_cost_tracker.dart';

final costTracker = AICostTracker.instance;

// Get daily usage stats
final dailyStats = await costTracker.getDailyUsageStats('user123');
print('Daily cost: \$${dailyStats.totalCost.toStringAsFixed(2)}');
print('Requests today: ${dailyStats.totalRequests}');

// Get monthly stats
final monthlyStats = await costTracker.getMonthlyUsageStats('user123');

// Check for cost alerts
final alert = await costTracker.checkCostAlerts('user123');
if (alert != null) {
  print('⚠️ ${alert.message}');
}

// Get cost breakdown
final breakdown = await costTracker.getCostBreakdown(
  userId: 'user123',
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);
```

## 🎨 UI Components

### AI Insight Widget

```dart
import 'package:fo_co_co/ai_integration/widgets/ai_insight_widget.dart';

AIInsightWidget(
  insight: aiInsightRecord,
  showActions: true,
  onInsightRead: () {
    // Handle insight read
  },
  onInsightRated: (rating, feedback) {
    // Handle insight rating
  },
)
```

## ⚙️ Configuration

### AI Config

All AI settings are managed in `lib/ai_integration/config/ai_config.dart`:

```dart
// Model selection
static const String insightModel = 'gpt-4o-mini';
static const String recommendationModel = 'gpt-4o-mini';

// Token limits
static const int maxTokensInsight = 1500;
static const int maxTokensRecommendation = 1200;

// Temperature settings
static const double temperatureInsight = 0.7;
static const double temperatureRecommendation = 0.6;

// Rate limiting
static const int maxRequestsPerUserPerDay = 50;
static const int maxRequestsPerUserPerHour = 10;

// Feature flags
static const bool enableAIInsights = true;
static const bool enableAIRecommendations = true;
```

### System Prompts

The AI uses specialized system prompts for different tasks:

- **Golf Insight System Prompt**: Expert golf mental performance coach
- **Mental Coaching System Prompt**: Certified mental performance coach
- **Personalized Content System Prompt**: Educational content creator with VARK expertise
- **Session Feedback System Prompt**: Supportive mental performance coach

## 🛡️ Error Handling

The module includes comprehensive error handling:

```dart
try {
  final insight = await FoCoCoAI.generateRoundInsight(
    userId: currentUserUid,
    golfRound: golfRound,
  );
} on AIException catch (e) {
  // Handle AI-specific errors
  print('AI Error: ${e.message} (${e.statusCode})');
  
  if (AIUtils.isRetryableError(e)) {
    // Retry logic
  }
} catch (e) {
  // Handle other errors
  final userMessage = AIUtils.getUserFriendlyErrorMessage(e);
  showErrorDialog(userMessage);
}
```

## 📊 Usage Analytics

### Daily Usage Stats

```dart
class DailyUsageStats {
  final double totalCost;
  final int totalRequests;
  final int totalTokens;
  final Map<String, int> usageTypeBreakdown;
  
  double get averageCostPerRequest;
  double get averageTokensPerRequest;
}
```

### Cost Alerts

```dart
enum CostAlertType {
  dailyCostLimit,
  dailyRequestLimit,
  monthlyCostLimit,
  monthlyRequestLimit,
  dailyCostWarning,
  monthlyCostWarning,
}
```

## 🔒 Security Features

- ✅ Server-side API calls only
- ✅ Input sanitization and validation
- ✅ Content filtering
- ✅ Rate limiting per user
- ✅ Token usage tracking
- ✅ Error handling without exposing sensitive data

## 💰 Cost Management

### Estimated Costs (GPT-4o-mini)
- Input tokens: $0.00015 per 1K tokens
- Output tokens: $0.0006 per 1K tokens
- Average insight: ~$0.001 - $0.003
- Average recommendation: ~$0.0008 - $0.002

### Budget Controls
- Daily request limits per user
- Cost tracking and alerts
- Usage analytics for optimization
- Automatic token estimation

## 🧪 Testing

```dart
// Test AI configuration
assert(AIConfig.validateConfiguration());

// Test token estimation
final tokens = AIUtils.estimateTokenCount('Your text here');
assert(tokens > 0);

// Test response validation
final isValid = AIUtils.validateAIResponse(openAIResponse);
assert(isValid);
```

## 🚨 Rate Limiting

The module includes built-in rate limiting:

- **Daily limit**: 50 requests per user
- **Hourly limit**: 10 requests per user  
- **Cooldown**: 5 seconds between requests
- **Retry logic**: Automatic retries for rate limit errors

## 📱 Integration with Existing Features

### Push Notifications

```dart
// Automatic notification when insight is ready
await PushNotificationsUtil.triggerAIInsightNotification(
  insightId: insight.reference.id,
  insightTitle: insight.insightTitle,
);
```

### User Extensions

```dart
// Extension methods for easy access
final recommendations = await userRecord.getCoachingRecommendations();
final content = await userRecord.getPersonalizedContent(
  contentType: 'lesson',
  topic: 'Focus techniques',
);
final usageStats = await userRecord.getAIUsageStats();
```

### Golf Round Extensions

```dart
// Extension methods for golf rounds
final insight = await golfRoundRecord.generateAIInsight();
```

## 🔧 Troubleshooting

### Common Issues

1. **API Key Not Set**
   ```
   Exception: OpenAI API key not configured
   ```
   Solution: Set `OPENAI_API_KEY` environment variable

2. **Rate Limit Exceeded**
   ```
   AIException: Rate limit exceeded (429)
   ```
   Solution: Wait and retry, or check daily limits

3. **Invalid Response Format**
   ```
   FormatException: Invalid JSON
   ```
   Solution: Check system prompts and model responses

### Debug Mode

Enable detailed logging in debug mode:

```dart
// In ai_config.dart
static bool get enableDetailedLogging => kDebugMode;
```

## 📚 Additional Resources

- [OpenAI API Documentation](https://platform.openai.com/docs/)
- [VARK Learning Styles](https://vark-learn.com/)
- [Golf Mental Performance Research](https://www.pga.com/mental-game)

## 🤝 Contributing

When contributing to the AI integration module:

1. Follow the existing code structure
2. Update relevant documentation
3. Add appropriate error handling
4. Include cost tracking for new features
5. Test with various user scenarios
6. Consider VARK learning style adaptations

## 📄 License

This AI integration module is part of the FoCoCo project and follows the same licensing terms. 