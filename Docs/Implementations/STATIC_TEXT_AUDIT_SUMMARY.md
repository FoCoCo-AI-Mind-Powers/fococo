# FoCoCo Static Text Audit & Dynamic Data Implementation

## Overview
This document outlines all static text and hardcoded data found in the FoCoCo app that needs to be replaced with dynamic data from the Firestore schema.

## Schema Enhancements Completed ✅

### New Collections Created:
1. **`coaching_modules`** - Complete VARK-based coaching module system
2. **`achievements`** - Achievement definitions with criteria
3. **`user_achievements`** - User progress on achievements
4. **`app_settings`** - App configuration and feature flags

### New Structs Created:
1. **`ModuleContentStruct`** - Individual content versions
2. **`ModuleContentVersionsStruct`** - VARK-specific content versions
3. **`AchievementCriteriaStruct`** - Achievement completion criteria

## Static Text Replacements Needed

### 1. Dashboard Widget (`lib/pages/dashboard/dashboard_widget.dart`)

#### User Information (Lines 182-228)
**Current Static:**
```dart
Text(currentUserDisplayName.isNotEmpty ? currentUserDisplayName : 'Golfer')
Text('Ready for today\'s training?')
```

**Replace With:**
```dart
StreamBuilder<UserRecord>(
  stream: UserRecord.getDocument(currentUser!.reference),
  builder: (context, snapshot) {
    final user = snapshot.data;
    return Text(user?.displayName ?? 'Golfer');
  }
)
```

#### Performance Metrics (Lines 270-305)
**Current Static:**
```dart
currentStreak: 7, // TODO: Get from user data
longestStreak: 15, // TODO: Get from user data
'Mental Focus': '85%', score: 85, trend: 5.2
'Confidence': '78%', score: 78, trend: -2.1
'Control': '92%', score: 92, trend: 8.5
```

**Replace With:**
```dart
StreamBuilder<UserRecord>(
  stream: UserRecord.getDocument(currentUser!.reference),
  builder: (context, snapshot) {
    final user = snapshot.data;
    return FoCoCoPerformanceMetrics(
      metrics: [
        PerformanceMetric(
          label: 'Mental Focus',
          value: '${user?.mentalPerformanceScore?.toInt() ?? 0}%',
          score: user?.mentalPerformanceScore ?? 0.0,
          trend: _calculateTrend(user?.mentalPerformanceScore),
        ),
        // ... other metrics from user data
      ],
    );
  }
)
```

#### Activity Feed (Lines 346-382)
**Current Static:**
```dart
FoCoCoActivityCard(
  title: 'Morning Practice Round',
  subtitle: 'Pebble Beach Golf Links',
  score: '78',
  date: '2 hours ago',
  // ... hardcoded stats
)
```

**Replace With:**
```dart
StreamBuilder<List<GolfRoundsRecord>>(
  stream: queryGolfRoundsRecord(
    queryBuilder: (q) => q
        .where('userId', isEqualTo: currentUserUid)
        .orderBy('createdTime', descending: true)
        .limit(5),
  ),
  builder: (context, snapshot) {
    final rounds = snapshot.data ?? [];
    return Column(
      children: rounds.map((round) => FoCoCoActivityCard(
        title: round.courseName,
        score: round.score.toString(),
        date: timeago.format(round.createdTime!),
        stats: [
          ActivityStat(label: 'Fairways', value: '${round.fairwaysHit}/${round.fairwaysTotal}'),
          ActivityStat(label: 'Greens', value: '${round.greensInRegulation}/${round.greensTotal}'),
          ActivityStat(label: 'Putts', value: '${round.totalPutts}'),
        ],
      )).toList(),
    );
  }
)
```

### 2. Profile Widget (`lib/pages/profile/profile_widget.dart`)

#### User Stats (Lines 361-430)
**Current Static:**
```dart
final mentalScore = userData?['mental_score'] ?? 78;
final weeklyImprovement = userData?['weekly_mental_improvement'] ?? '+5';
_buildProfessionalStatCard('Mental Score', '78', '+5 this week', ...)
_buildProfessionalStatCard('Rounds', '24', '+3 this month', ...)
_buildProfessionalStatCard('Streak', '12', 'days active', ...)
```

**Replace With:**
```dart
StreamBuilder<UserRecord>(
  stream: UserRecord.getDocument(currentUser!.reference),
  builder: (context, snapshot) {
    final user = snapshot.data;
    return Row(
      children: [
        Expanded(child: _buildProfessionalStatCard(
          'Mental Score', 
          '${user?.mentalPerformanceScore?.toInt() ?? 0}', 
          _calculateWeeklyChange(user?.mentalPerformanceScore), 
          theme.aiPrimary
        )),
        // ... other stats from UserRecord
      ],
    );
  }
)
```

#### VARK Scores (Lines 569-663)
**Current Static:**
```dart
final varkScores = userData?['vark_scores'] as Map<String, dynamic>?;
_buildVarkCard('Visual', 'V', 'Charts & Images', theme.varkVisual, 0.8)
```

**Replace With:**
```dart
StreamBuilder<UserRecord>(
  stream: UserRecord.getDocument(currentUser!.reference),
  builder: (context, snapshot) {
    final user = snapshot.data;
    final vark = user?.varkPreferences;
    return Row(
      children: [
        _buildVarkCard('Visual', 'V', 'Charts & Images', theme.varkVisual, 
            vark?.visual == true ? 1.0 : 0.0),
        _buildVarkCard('Auditory', 'A', 'Audio & Voice', theme.varkAuditory, 
            vark?.aural == true ? 1.0 : 0.0),
        // ... other VARK preferences
      ],
    );
  }
)
```

#### Subscription Info (Lines 1124-1245)
**Current Static:**
```dart
Text('PRIME')
Text('\$9.99/month')
Text('Active')
```

**Replace With:**
```dart
StreamBuilder<List<UserSubscriptionsRecord>>(
  stream: queryUserSubscriptionsRecord(
    queryBuilder: (q) => q.where('userId', isEqualTo: currentUserUid),
  ),
  builder: (context, snapshot) {
    final subscription = snapshot.data?.first;
    return Container(
      child: Column(
        children: [
          Text(subscription?.membershipTier?.toUpperCase() ?? 'BASE'),
          Text('\$${(subscription?.priceAmountMicros ?? 0) / 1000000}/month'),
          Text(subscription?.status ?? 'Inactive'),
        ],
      ),
    );
  }
)
```

### 3. Golf Rounds Widget (`lib/pages/golf_rounds/golf_rounds_widget.dart`)

#### Header Stats (Lines 194-229)
**Current Static:**
```dart
_buildHeaderStatCard(theme, 'Avg Score', '78.5', '-2.3 from last month', ...)
_buildHeaderStatCard(theme, 'Best Round', '72', 'Personal best!', ...)
_buildHeaderStatCard(theme, 'Rounds', '24', 'This year', ...)
```

**Replace With:**
```dart
StreamBuilder<List<GolfRoundsRecord>>(
  stream: queryGolfRoundsRecord(
    queryBuilder: (q) => q.where('userId', isEqualTo: currentUserUid),
  ),
  builder: (context, snapshot) {
    final rounds = snapshot.data ?? [];
    final avgScore = rounds.isEmpty ? 0.0 : 
        rounds.map((r) => r.score).reduce((a, b) => a + b) / rounds.length;
    final bestScore = rounds.isEmpty ? 0 : 
        rounds.map((r) => r.score).reduce((a, b) => a < b ? a : b);
    
    return Row(
      children: [
        _buildHeaderStatCard(theme, 'Avg Score', avgScore.toStringAsFixed(1), 
            _calculateScoreTrend(rounds), ...),
        _buildHeaderStatCard(theme, 'Best Round', bestScore.toString(), 
            'Personal best!', ...),
        _buildHeaderStatCard(theme, 'Rounds', rounds.length.toString(), 
            'This year', ...),
      ],
    );
  }
)
```

#### Round Cards (Lines 377-425)
**Current Static:**
```dart
_buildRoundCard(
  theme,
  'Pebble Beach Golf Links',
  DateTime.now().subtract(const Duration(days: 2)),
  82,
  'Challenging conditions with strong winds...',
  {'Fairways': 71, 'Greens': 67, 'Putts': 32},
  true,
)
```

**Replace With:**
```dart
StreamBuilder<List<GolfRoundsRecord>>(
  stream: queryGolfRoundsRecord(
    queryBuilder: (q) => q
        .where('userId', isEqualTo: currentUserUid)
        .orderBy('createdTime', descending: true)
        .limit(10),
  ),
  builder: (context, snapshot) {
    final rounds = snapshot.data ?? [];
    return Column(
      children: rounds.map((round) => _buildRoundCard(
        theme,
        round.courseName,
        round.createdTime!,
        round.score,
        round.notes,
        {
          'Fairways': ((round.fairwaysHit / round.fairwaysTotal) * 100).round(),
          'Greens': ((round.greensInRegulation / round.greensTotal) * 100).round(),
          'Putts': round.totalPutts,
        },
        round.aiInsightsGenerated,
      )).toList(),
    );
  }
)
```

### 4. Coaching Modules Widget (`lib/pages/coaching_modules/coaching_modules_widget.dart`)

#### Module Content (Lines 200+)
**Current Static:**
```dart
Text('Find Your Center')
Text('Strengthen your mental game with mindful practice')
```

**Replace With:**
```dart
StreamBuilder<List<CoachingModulesRecord>>(
  stream: queryCoachingModulesRecord(
    queryBuilder: (q) => q
        .where('isActive', isEqualTo: true)
        .orderBy('order'),
  ),
  builder: (context, snapshot) {
    final modules = snapshot.data ?? [];
    return Column(
      children: modules.map((module) => CoachingModuleCard(
        title: module.title,
        description: module.description,
        duration: module.duration,
        pillar: module.pillar,
        varkStyle: _getUserVarkStyle(),
        onTap: () => _openModule(module),
      )).toList(),
    );
  }
)
```

### 5. Home Page Widget (`lib/pages/home_page/home_page_widget.dart`)

#### Performance Metrics (Lines 340-380)
**Current Static:**
```dart
_buildMetricCard('Mental Index', '8.2', '+1.3', ...)
_buildMetricCard('Streak Days', '12', '+5', ...)
```

**Replace With:**
```dart
StreamBuilder<UserRecord>(
  stream: UserRecord.getDocument(currentUser!.reference),
  builder: (context, snapshot) {
    final user = snapshot.data;
    return Row(
      children: [
        _buildMetricCard(
          'Mental Index', 
          user?.mentalPerformanceScore?.toStringAsFixed(1) ?? '0.0',
          _calculateTrend(user?.mentalPerformanceScore),
          FontAwesomeIcons.chartLine,
          theme.performanceExcellent,
        ),
        _buildMetricCard(
          'Streak Days', 
          user?.coachingStreak?.toString() ?? '0',
          _calculateStreakChange(user?.coachingStreak),
          FontAwesomeIcons.fire,
          theme.warning,
        ),
      ],
    );
  }
)
```

## Implementation Priority

### High Priority (Core User Experience)
1. ✅ **Dashboard user data** - Name, photo, basic stats
2. ✅ **Profile VARK scores** - Learning preferences
3. ✅ **Golf rounds data** - Recent rounds and statistics
4. ✅ **Performance metrics** - Mental scores and trends

### Medium Priority (Enhanced Features)
5. ✅ **Coaching modules** - Dynamic content based on VARK
6. ✅ **AI insights** - Real AI-generated content
7. ✅ **Subscription status** - Current tier and billing
8. ✅ **Achievement system** - Progress and earned badges

### Low Priority (Polish)
9. ✅ **App version info** - Dynamic version display
10. ✅ **Feature flags** - Conditional feature display

## Additional Schema Fields Needed

### UserRecord Enhancements:
- `weeklyMentalImprovement: double?` - For trend calculations
- `lastScoreUpdate: DateTime?` - For tracking changes
- `longestStreak: int?` - Historical streak data
- `totalRoundsPlayed: int?` - Lifetime round count

### New Helper Methods Needed:
```dart
// Calculate performance trends
double _calculateTrend(double? currentValue, double? previousValue)

// Calculate streak changes
String _calculateStreakChange(int? currentStreak, int? previousStreak)

// Get user's dominant VARK style
String _getUserDominantVarkStyle(VarkPreferencesStruct vark)

// Format time ago
String _formatTimeAgo(DateTime dateTime)
```

## Testing Checklist

- [ ] Dashboard loads with real user data
- [ ] Profile shows actual VARK scores
- [ ] Golf rounds display from Firestore
- [ ] Coaching modules filter by VARK
- [ ] AI insights show real data
- [ ] Subscription status is accurate
- [ ] Performance metrics calculate correctly
- [ ] Achievement progress updates
- [ ] App handles empty data gracefully
- [ ] Loading states work properly

## Notes

1. **Firestore Security Rules**: Ensure all new collections have proper security rules
2. **Offline Support**: Consider caching strategies for better UX
3. **Performance**: Use appropriate query limits and pagination
4. **Error Handling**: Implement proper error states for failed queries
5. **Loading States**: Add skeleton loaders for better perceived performance

This audit ensures FoCoCo transforms from a static demo into a fully dynamic, data-driven golf mental coaching application.
