# FoCoMap Error Fixes

## Fixed: "Bad state: No element" Error

### Issue Description
The app was crashing when opening the filters bottom sheet with the error:
```
StateError: Bad state: No element
```

This occurred when calling `reduce()` on empty collections in the performance metrics calculations.

### Root Cause
The `reduce()` method in Dart throws an error when called on an empty iterable. This was happening in several places:
1. `_getMostUsedCue()` - When no cues were recorded
2. `_getClubPerformanceBreakdown()` - When ratings lists were empty
3. `_getBestCourseType()` - When course scores were empty
4. `_getCourseTypePerformance()` - When course scores were empty

### Fixes Applied

#### 1. `_getMostUsedCue()` (line 424)
```dart
// Added empty check
if (cueCount.isEmpty) return '';
```

#### 2. `_getClubPerformanceBreakdown()` (line 464)
```dart
// Added empty check in map function
if (ratings.isEmpty) return MapEntry(club, 0.0);
```

#### 3. `_getBestCourseType()` (line 443)
```dart
// Added empty check in forEach
if (scores.isEmpty) return;
```

#### 4. `_getCourseTypePerformance()` (line 481)
```dart
// Added empty check in map function
if (scores.isEmpty) return MapEntry(course, 0.0);
```

### Testing the Fix

1. **Hot Reload** - Press `r` in your terminal or IDE
2. **Open FoCoMap** - Navigate to the map view
3. **Test Filters** - Tap the filter button (should now work without crashing)
4. **Verify Metrics** - The performance summary should display properly with:
   - Total Rounds: 0 (or actual count)
   - Total Shots: 0 (or actual count)
   - Avg Mindset: 0.0 (or calculated value)
   - Recovery Rate: 0.0% (or calculated value)

### Prevention
These fixes ensure that:
- Empty data sets are handled gracefully
- Default values (0.0 or empty string) are returned when no data exists
- The app continues to function even with no recorded data
- Users can explore all features before logging any rounds

### Related Files
- `lib/pages/foco_map/foco_map_model.dart` - Contains all the fixed methods
- `lib/pages/foco_map/foco_map_widget.dart` - Uses the performance metrics

The app should now handle empty data sets gracefully without crashing!

