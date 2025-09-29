# FoCoCo Coaching Modules - Production Setup Guide

## 🎯 **Overview**

This guide covers the complete production setup for FoCoCo's coaching modules system, including security, content management, and deployment.

## 📋 **Production Components**

### ✅ **What's Included**

1. **Firestore Security Rules** - Secure access control for coaching modules
2. **Admin Functions** - Complete content management system
3. **Production Modules** - 12 professional coaching modules
4. **Deployment Scripts** - Automated production setup
5. **VARK Integration** - Personalized learning content structure

---

## 🛡️ **1. Firestore Security Rules**

### **New Collections Added:**

```javascript
// Coaching Modules - Read-only for users, admin-only writes
coaching_modules/{document}
  ✅ Read: All authenticated users
  🔒 Write: Admin only (via Cloud Functions)

// User Module Progress - User-specific tracking  
user_module_progress/{document}
  ✅ Read/Write: Module owner only
  
// Module Reviews - User feedback system
module_reviews/{document}
  ✅ Read: All authenticated users
  ✅ Write: Review author only
  
// Module Analytics - Usage statistics
module_analytics/{document}
  🔒 Read/Write: Cloud Functions only
```

### **Deployment:**
```bash
cd firebase
firebase deploy --only firestore:rules
```

---

## 🔧 **2. Admin Content Management Functions**

### **Available Admin Functions:**

#### **createCoachingModule**
Create new coaching modules with full VARK content versions.

```javascript
// Example usage
const result = await functions.httpsCallable('createCoachingModule')({
  moduleId: 'custom_focus_module',
  title: 'Advanced Focus Training',
  description: 'Elite-level focus techniques for tournament play',
  pillar: 'focus',
  difficulty: 'advanced',
  duration: 25,
  varkTags: ['visual', 'kinesthetic'],
  primaryVarkStyle: 'visual',
  tierRequirement: 'PREMIUM',
  contentVersions: {
    visual: {
      contentUrl: 'gs://fococo/modules/advanced_focus_visual.mp4',
      format: 'video',
      duration: 25,
      sections: ['intro', 'techniques', 'practice']
    }
  },
  prerequisites: ['focus_fundamentals'],
  learningObjectives: [
    'Master advanced focus techniques',
    'Apply elite concentration methods'
  ],
  tags: ['advanced', 'tournament', 'elite'],
  order: 1
});
```

#### **updateCoachingModule**
Update existing modules with new content or metadata.

```javascript
const result = await functions.httpsCallable('updateCoachingModule')({
  moduleId: 'focus_fundamentals',
  updates: {
    duration: 15, // Updated duration
    averageRating: 4.7,
    contentVersions: {
      // Updated content versions
    }
  }
});
```

#### **deleteCoachingModule**
Deactivate (soft delete) or permanently delete modules.

```javascript
// Soft delete (recommended)
const result = await functions.httpsCallable('deleteCoachingModule')({
  moduleId: 'outdated_module',
  permanentDelete: false
});

// Permanent delete (use with caution)
const result = await functions.httpsCallable('deleteCoachingModule')({
  moduleId: 'test_module',
  permanentDelete: true
});
```

#### **listCoachingModules**
Get comprehensive module listings for admin purposes.

```javascript
const result = await functions.httpsCallable('listCoachingModules')({
  includeInactive: true, // Include deactivated modules
  limit: 100
});

console.log(`Found ${result.data.modules.length} modules`);
```

#### **bulkImportModules**
Import multiple modules from JSON (like our production set).

```javascript
const modulesData = [
  {
    moduleId: 'bulk_module_1',
    title: 'Bulk Imported Module',
    // ... other module fields
  }
];

const result = await functions.httpsCallable('bulkImportModules')({
  modules: modulesData,
  overwriteExisting: false
});

console.log(`Import results:`, result.data.results);
```

#### **updateModuleAnalytics**
Update completion counts and ratings.

```javascript
const result = await functions.httpsCallable('updateModuleAnalytics')({
  moduleId: 'focus_fundamentals',
  completionCount: 1250,
  averageRating: 4.6
});
```

#### **getModuleStatistics**
Get comprehensive statistics for admin dashboard.

```javascript
const result = await functions.httpsCallable('getModuleStatistics')({});

const stats = result.data.statistics;
console.log(`Total modules: ${stats.totalModules}`);
console.log(`Focus modules: ${stats.modulesByPillar.focus}`);
console.log(`Average rating: ${stats.averageRating}`);
```

### **Admin Authentication Setup:**

```javascript
// Set admin claims for content managers
const user = await admin.auth().getUserByEmail('admin@fococo.com');
await admin.auth().setCustomUserClaims(user.uid, {
  admin: true,
  content_admin: true
});
```

---

## 📚 **3. Production Coaching Modules**

### **Complete Module Library (12 Modules):**

#### **🎯 Focus Pillar (4 modules)**
1. **Mental Focus Fundamentals** (Beginner, 12min, FREE)
2. **Pre-Shot Routine & Focus** (Beginner, 15min, FREE) 
3. **Focus Under Pressure** (Advanced, 25min, PREMIUM)
4. **Integrated Mental Game Mastery** (Advanced, 35min, ELITE)

#### **💪 Confidence Pillar (3 modules)**
1. **Building Unshakeable Confidence** (Beginner, 14min, FREE)
2. **Shot-Specific Confidence** (Intermediate, 18min, FREE)
3. **Confidence After Setbacks** (Advanced, 22min, PREMIUM)

#### **🧘 Control Pillar (3 modules)**
1. **Emotional Control Basics** (Beginner, 16min, FREE)
2. **Managing Anger & Frustration** (Intermediate, 19min, FREE)
3. **Elite Emotional Mastery** (Advanced, 28min, PREMIUM)

### **VARK Content Structure:**

Each module includes **4 content versions**:
- **Visual**: Video demonstrations, infographics, visual cues
- **Auditory**: Audio guides, verbal instructions, sound cues  
- **Read/Write**: Articles, checklists, written exercises
- **Kinesthetic**: Interactive drills, physical practice, hands-on

### **Progressive Learning Path:**
```
Beginner Path:
Focus Fundamentals → Pre-Shot Routine → Confidence Building → Emotional Control

Intermediate Path:  
Shot-Specific Confidence → Anger Management

Advanced Path:
Pressure Focus → Comeback Confidence → Elite Emotional Mastery

Elite Path:
Integrated Mental Game Mastery
```

---

## 🚀 **4. Production Deployment**

### **Automated Deployment:**

```bash
cd firebase
node deploy_production_coaching.js
```

### **Manual Deployment Steps:**

#### **Step 1: Deploy Functions**
```bash
cd firebase/functions
npm install
cd ..
firebase deploy --only functions
```

#### **Step 2: Deploy Security Rules**
```bash
firebase deploy --only firestore:rules
```

#### **Step 3: Set Admin Claims**
```javascript
// Run in Firebase Admin SDK
const user = await admin.auth().getUserByEmail('your-admin@email.com');
await admin.auth().setCustomUserClaims(user.uid, {
  admin: true,
  content_admin: true
});
```

#### **Step 4: Import Production Modules**
```javascript
// Use the bulkImportModules function
const modulesData = require('./production_coaching_modules.json');
await functions.httpsCallable('bulkImportModules')({
  modules: modulesData.modules,
  overwriteExisting: false
});
```

---

## 📱 **5. App Integration**

### **Current Integration Status:**
✅ **Firestore Collection**: `coaching_modules`  
✅ **Real-time Queries**: Filtered by pillar, difficulty, VARK  
✅ **Security Rules**: Production-ready access control  
✅ **UI Components**: Enhanced filter dialog, pillar cards  
✅ **Development Tools**: Sample module creation (debug mode)

### **Production Data Flow:**
```
Flutter App → Firestore → coaching_modules collection
            ↓
Real-time filtered queries (VARK, pillar, difficulty)
            ↓  
Module cards with VARK-personalized content
            ↓
User progress tracking → user_module_progress collection
```

---

## 📊 **6. Content Management Workflow**

### **For Content Teams:**

#### **Adding New Modules:**
1. **Design Module**: Define learning objectives, VARK versions
2. **Create Content**: Video, audio, article, interactive versions  
3. **Upload Media**: Firebase Storage with proper naming
4. **Create Module**: Use `createCoachingModule` admin function
5. **Test & Review**: Verify all VARK versions work properly
6. **Activate**: Set `isActive: true` to make live

#### **Updating Existing Modules:**
1. **Update Content**: Replace media files in Firebase Storage
2. **Update Metadata**: Use `updateCoachingModule` function
3. **Update Analytics**: Track completion rates and ratings

#### **Content Quality Standards:**
- **Video**: 1080p, professional golf instruction quality
- **Audio**: Clear narration, appropriate background music
- **Articles**: 500-1500 words, SEO optimized, mobile-friendly
- **Interactive**: Engaging drills, progress tracking, feedback

---

## 🔍 **7. Analytics & Monitoring**

### **Key Metrics to Track:**
- Module completion rates by pillar
- VARK preference distribution  
- User engagement by difficulty level
- Content effectiveness ratings
- Learning path progression

### **Available Analytics:**
```javascript
// Get comprehensive stats
const stats = await functions.httpsCallable('getModuleStatistics')({});

// Example response:
{
  totalModules: 12,
  modulesByPillar: { focus: 4, confidence: 3, control: 3 },
  modulesByDifficulty: { beginner: 4, intermediate: 2, advanced: 6 },
  modulesByTier: { FREE: 7, PREMIUM: 4, ELITE: 1 },
  totalCompletions: 15420,
  averageRating: 4.6,
  topModules: [...]
}
```

---

## 🛠️ **8. Maintenance & Updates**

### **Regular Maintenance Tasks:**
- **Weekly**: Update module analytics and completion rates
- **Monthly**: Review user feedback and module ratings  
- **Quarterly**: Add new modules based on user needs
- **Yearly**: Refresh content and update VARK distributions

### **Content Updates:**
```javascript
// Update module content
await functions.httpsCallable('updateCoachingModule')({
  moduleId: 'focus_fundamentals',
  updates: {
    contentVersions: {
      visual: {
        contentUrl: 'gs://fococo/modules/focus_fundamentals_v2.mp4',
        // ... updated content
      }
    }
  }
});
```

---

## 🚨 **9. Troubleshooting**

### **Common Issues:**

#### **"Permission denied" errors**
- Check admin claims are set correctly
- Verify security rules are deployed
- Confirm user authentication status

#### **Modules not appearing in app**
- Check `isActive: true` on modules
- Verify security rules allow read access
- Test Firestore queries in Firebase console

#### **Content not loading**
- Verify Firebase Storage URLs are correct
- Check file permissions in Storage
- Test media URLs in browser

### **Debug Commands:**
```bash
# Check deployed functions
firebase functions:list

# Test security rules
firebase firestore:rules

# View logs
firebase functions:log --only createCoachingModule
```

---

## 🎯 **10. Next Steps**

### **Immediate (Week 1):**
- [ ] Deploy production security rules
- [ ] Set up admin user claims  
- [ ] Import production coaching modules
- [ ] Test module access in app

### **Short Term (Month 1):**
- [ ] Upload professional video/audio content
- [ ] Set up Firebase Storage organization
- [ ] Create content admin dashboard
- [ ] Configure user progress tracking

### **Long Term (Quarter 1):**
- [ ] Add more advanced modules
- [ ] Implement AI-powered content recommendations
- [ ] Create personalized learning paths
- [ ] Set up comprehensive analytics dashboard

---

## 📞 **Support**

For issues with the coaching modules system:

1. **Check the Firebase Console** for errors and logs
2. **Review security rules** in Firestore Rules tab  
3. **Test functions** using Firebase Functions logs
4. **Verify data structure** matches schema requirements

**Admin Functions Reference**: All functions require admin privileges and return standardized responses with success/error status and detailed messages.

---

**🎉 Your FoCoCo app now has a complete, professional coaching modules system ready for production use!**

