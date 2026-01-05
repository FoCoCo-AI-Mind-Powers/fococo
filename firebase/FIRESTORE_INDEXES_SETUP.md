# Firestore Indexes Setup for AI Insights Page

## Required Indexes

The AI Insights page requires the following Firestore composite indexes to function properly. These indexes enable efficient querying of user data with date range filters.

### Indexes Already Defined

The indexes are defined in `firebase/firestore.indexes.json`. You need to deploy them to Firebase.

## Deployment Instructions

### Option 1: Deploy via Firebase CLI (Recommended)

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy indexes
firebase deploy --only firestore:indexes
```

### Option 2: Deploy via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes** tab
4. Click **Create Index**
5. For each index below, create it manually:

#### Index 1: ai_insights - userId + createdTime
- **Collection ID**: `ai_insights`
- **Fields to index**:
  - `userId` (Ascending)
  - `createdTime` (Descending)
- **Query scope**: Collection

#### Index 2: golf_rounds - userId + date
- **Collection ID**: `golf_rounds`
- **Fields to index**:
  - `userId` (Ascending)
  - `date` (Descending)
- **Query scope**: Collection

#### Index 3: golf_rounds - userId + courseName + date
- **Collection ID**: `golf_rounds`
- **Fields to index**:
  - `userId` (Ascending)
  - `courseName` (Ascending)
  - `date` (Descending)
- **Query scope**: Collection

#### Index 4: round_logs - userId + date
- **Collection ID**: `round_logs`
- **Fields to index**:
  - `userId` (Ascending)
  - `date` (Descending)
- **Query scope**: Collection

#### Index 5: mental_sessions - userId + dateCompleted
- **Collection ID**: `mental_sessions`
- **Fields to index**:
  - `userId` (Ascending)
  - `dateCompleted` (Descending)
- **Query scope**: Collection

## Verification

After deploying, you can verify the indexes are building by:

1. Checking the Firebase Console → Firestore → Indexes tab
2. Indexes will show as "Building" initially, then "Enabled" when ready
3. The AI Insights page will work once indexes are enabled

## Troubleshooting

If you see errors like "The query requires an index", Firebase will provide a link to create the missing index automatically. Click the link and it will pre-populate the index creation form.

## Notes

- Index creation can take several minutes for large collections
- Queries will fail until indexes are fully built
- The app will show loading states while indexes are building

