# MindCoach Session Model Update & Firestore Integration - Implementation Summary

## ✅ Completed Implementation

### 1. Core Models Created
- **`MindCoachSession`** - Comprehensive session model matching documentation structure
- **`BreathingSession`** - Extends MindCoachSession for breathing exercises
- **`ContentLibraryEntry`** - Model for content library entries
- **`ScenarioTag`** - Model for scenario detection tags

**Location**: `lib/ai_integration/models/mind_coach_models.dart`

### 2. Services Implemented

#### MindCoach Session Service
- CRUD operations for Firestore
- Pagination support
- Success signal calculation
- Real-time streaming

**Location**: `lib/ai_integration/services/mind_coach_session_service.dart`

#### Content Library Selector Service
- Loads from Firestore (primary) or CSV assets (fallback)
- Implements deterministic selection algorithm
- Handles relaxation fallback logic

**Location**: `lib/ai_integration/services/mind_coach_content_selector.dart`

#### Scenario Detection Service
- Detects scenarios from user messages, context, and performance data
- Loads scenario tags from Firestore or CSV assets

**Location**: `lib/ai_integration/services/mind_coach_scenario_detector.dart`

#### Migration Service
- Migrates existing sessions to new structure
- Converts mindset ratings from String to int
- Batch migration with progress tracking

**Location**: `lib/ai_integration/services/mind_coach_migration_service.dart`

#### Migration Helper
- UI helper for running migrations
- Command-line style migration utility

**Location**: `lib/ai_integration/services/mind_coach_migration_helper.dart`

### 3. Firestore Schema Updates

#### Updated Record Schema
- Added new fields: `contentId`, `scenarioTag`, `varkMode`, `level`, `length`, `sessionType`, `userResponse`
- Updated `mindsetBefore`/`mindsetAfter` to support both int and String (for migration compatibility)

**Location**: `lib/backend/schema/mindcoach_sessions_record.dart`

#### Firestore Indexes
- Added index: `userId + templateId + timestamp`
- Added index: `userId + sessionType + timestamp`

**Location**: `firebase/firestore.indexes.json`

#### Security Rules
- Added rules for `mindcoach_content_library` collection
- Read access for authenticated users, admin-only writes

**Location**: `firebase/firestore.rules`

### 4. Data Seeding Script

Created Cloud Function to seed:
- Content Library from CSV
- Scenario Tags from CSV

**Location**: `firebase/functions/seed_mindcoach_data.js`

**Usage**:
```bash
# Deploy function
firebase deploy --only functions:seedMindCoachData

# Call function
# Via HTTP: https://your-project.cloudfunctions.net/seedMindCoachData
# Or run locally: node firebase/functions/seed_mindcoach_data.js
```

### 5. UI Integration

Updated `mind_coach_widget.dart` to:
- Import new services
- Use new session service for streaming
- Added `createMindCoachSession()` method that integrates:
  - Scenario detection
  - Content selection
  - VARK preference detection
  - Session creation

**Location**: `lib/pages/coaching_modules/mind_coach_widget.dart`

## 📋 Next Steps

### Immediate Actions Required

1. **Seed Firestore Collections**
   ```bash
   # Deploy the seeding function
   firebase deploy --only functions:seedMindCoachData
   
   # Call the function to seed data
   # Or run locally if you have Firebase Admin SDK configured
   ```

2. **Run Migration for Existing Sessions**
   ```dart
   // In your app, call:
   await MindCoachMigrationHelper.migrateCurrentUser(context);
   
   // Or for all users (admin):
   await MindCoachMigrationHelper.migrateAllUsersWithProgress(context);
   ```

3. **Update UI to Use New Session Creation**
   - Replace any direct Firestore writes with `createMindCoachSession()`
   - Update session display to show new fields (contentId, scenarioTag, varkMode, etc.)

4. **Add Breathing Exercise Integration**
   - Integrate breathing exercises as optional session type
   - Use `BreathingSession` model for breathing-specific sessions

### Testing Checklist

- [ ] Content library loads from Firestore
- [ ] Scenario detection works correctly
- [ ] Content selection algorithm returns correct content
- [ ] Session creation saves all fields correctly
- [ ] Session retrieval works with pagination
- [ ] Migration script completes successfully
- [ ] UI displays sessions with new fields
- [ ] Breathing sessions can be created

## 🔧 Configuration Notes

### CSV File Locations
The seeding script expects CSV files at:
- `Docs/MindCoach/FoCoCo - B - AI Data/FoCoCo - AI Content Library.csv`
- `Docs/MindCoach/FoCoCo - B - AI Data/FoCoCo - AI Scenario Tags.csv`

### Firestore Collections
The services will use these collections:
- `mindcoach_sessions` - User session records
- `mindcoach_content_library` - Content library entries
- `mindcoach_scenario_tags` - Scenario detection tags
- `mindcoach_templates` - Template definitions (if needed)

### Asset Loading (Fallback)
If Firestore collections are empty, services will attempt to load from:
- `assets/csvs/mindcoach_content_library.csv`
- `assets/csvs/mindcoach_scenario_tags.csv`

**Note**: These asset files need to be added to `pubspec.yaml` if using asset fallback.

## 📚 Key Features

1. **Content Selection Algorithm**
   - Filters by template_id (required)
   - Prioritizes scenario tags
   - Filters by VARK mode, level, and length
   - Relaxation fallback logic

2. **Scenario Detection**
   - Text-based detection from user messages
   - Context-based detection (pressure, pace, weather)
   - Performance-based detection (recent shots, mindset)

3. **Session Management**
   - Comprehensive session model with all required fields
   - Support for both coaching and breathing sessions
   - Success signal calculation
   - Real-time streaming support

## 🎯 Architecture

```
User Request
    ↓
MindCoach Widget
    ↓
Scenario Detector → Detect scenarios
    ↓
Content Selector → Select content from library
    ↓
Session Service → Create session
    ↓
Firestore → Store session
```

All services are singleton instances for efficient resource management and caching.
