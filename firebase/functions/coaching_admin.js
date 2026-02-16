const admin = require("firebase-admin");
const functions = require("firebase-functions/v1");

/**
 * FOCOCO COACHING MODULES ADMIN CONTENT MANAGEMENT SYSTEM
 * Production-ready admin functions for managing coaching content
 */

// ============================================================================
// ADMIN AUTHENTICATION & VALIDATION
// ============================================================================

/**
 * Verify if user has admin privileges
 */
function verifyAdminAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Check for admin claim (set via Firebase Admin SDK)
  if (!context.auth.token.admin && !context.auth.token.content_admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin privileges required');
  }
}

/**
 * Validate coaching module data structure
 */
function validateModuleData(data) {
  const required = ['moduleId', 'title', 'description', 'pillar', 'difficulty', 'duration'];
  const missing = required.filter(field => !data[field]);
  
  if (missing.length > 0) {
    throw new functions.https.HttpsError('invalid-argument', `Missing required fields: ${missing.join(', ')}`);
  }

  // Validate pillar values
  const validPillars = ['focus', 'confidence', 'control'];
  if (!validPillars.includes(data.pillar.toLowerCase())) {
    throw new functions.https.HttpsError('invalid-argument', 'Pillar must be: focus, confidence, or control');
  }

  // Validate difficulty values
  const validDifficulties = ['beginner', 'intermediate', 'advanced'];
  if (!validDifficulties.includes(data.difficulty.toLowerCase())) {
    throw new functions.https.HttpsError('invalid-argument', 'Difficulty must be: beginner, intermediate, or advanced');
  }

  // Validate VARK tags
  const validVarkTags = ['visual', 'aural', 'readwrite', 'kinesthetic'];
  if (data.varkTags && !Array.isArray(data.varkTags)) {
    throw new functions.https.HttpsError('invalid-argument', 'varkTags must be an array');
  }
  if (data.varkTags) {
    const invalidTags = data.varkTags.filter(tag => !validVarkTags.includes(tag.toLowerCase()));
    if (invalidTags.length > 0) {
      throw new functions.https.HttpsError('invalid-argument', `Invalid VARK tags: ${invalidTags.join(', ')}`);
    }
  }
}

// ============================================================================
// COACHING MODULE MANAGEMENT FUNCTIONS
// ============================================================================

/**
 * Create a new coaching module
 */
exports.createCoachingModule = functions.https.onCall(async (data, context) => {
  verifyAdminAuth(context);
  validateModuleData(data);

  try {
    console.log(`Creating coaching module: ${data.moduleId}`);

    // Check if module already exists
    const existingModule = await admin.firestore()
      .collection('coaching_modules')
      .where('moduleId', '==', data.moduleId)
      .limit(1)
      .get();

    if (!existingModule.empty) {
      throw new functions.https.HttpsError('already-exists', `Module with ID ${data.moduleId} already exists`);
    }

    // Prepare module data
    const moduleData = {
      moduleId: data.moduleId,
      title: data.title,
      description: data.description,
      category: data.category || 'mental_training',
      pillar: data.pillar.toLowerCase(),
      difficulty: data.difficulty.toLowerCase(),
      duration: data.duration,
      varkTags: data.varkTags || ['visual'],
      primaryVarkStyle: data.primaryVarkStyle || data.varkTags?.[0] || 'visual',
      tierRequirement: data.tierRequirement || 'FREE',
      
      // Content versions for VARK personalization
      contentVersions: data.contentVersions || {},
      
      // Learning structure
      prerequisites: data.prerequisites || [],
      learningObjectives: data.learningObjectives || [],
      tags: data.tags || [],
      
      // Media and presentation
      thumbnailUrl: data.thumbnailUrl || '',
      
      // Status and ordering
      isActive: data.isActive !== undefined ? data.isActive : true,
      order: data.order || 1,
      
      // Analytics
      completionCount: 0,
      averageRating: 0.0,
      
      // Timestamps
      createdTime: admin.firestore.Timestamp.now(),
      updatedTime: admin.firestore.Timestamp.now(),
    };

    // Create the module
    const docRef = await admin.firestore().collection('coaching_modules').add(moduleData);

    console.log(`✅ Created coaching module: ${data.moduleId} with ID: ${docRef.id}`);

    return {
      success: true,
      moduleId: data.moduleId,
      documentId: docRef.id,
      message: 'Coaching module created successfully'
    };

  } catch (error) {
    console.error('Error creating coaching module:', error);
    throw new functions.https.HttpsError('internal', `Failed to create module: ${error.message}`);
  }
});

/**
 * Update an existing coaching module
 */
exports.updateCoachingModule = functions.https.onCall(async (data, context) => {
  verifyAdminAuth(context);

  const { moduleId, updates } = data;
  if (!moduleId || !updates) {
    throw new functions.https.HttpsError('invalid-argument', 'moduleId and updates are required');
  }

  try {
    console.log(`Updating coaching module: ${moduleId}`);

    // Find the module
    const moduleQuery = await admin.firestore()
      .collection('coaching_modules')
      .where('moduleId', '==', moduleId)
      .limit(1)
      .get();

    if (moduleQuery.empty) {
      throw new functions.https.HttpsError('not-found', `Module with ID ${moduleId} not found`);
    }

    const moduleDoc = moduleQuery.docs[0];

    // Validate updates if they include core fields
    if (updates.pillar || updates.difficulty || updates.varkTags) {
      validateModuleData({ ...moduleDoc.data(), ...updates });
    }

    // Add timestamp
    updates.updatedTime = admin.firestore.Timestamp.now();

    // Update the module
    await moduleDoc.ref.update(updates);

    console.log(`✅ Updated coaching module: ${moduleId}`);

    return {
      success: true,
      moduleId: moduleId,
      message: 'Coaching module updated successfully'
    };

  } catch (error) {
    console.error('Error updating coaching module:', error);
    throw new functions.https.HttpsError('internal', `Failed to update module: ${error.message}`);
  }
});

/**
 * Delete a coaching module (deactivate)
 */
exports.deleteCoachingModule = functions.https.onCall(async (data, context) => {
  verifyAdminAuth(context);

  const { moduleId, permanentDelete = false } = data;
  if (!moduleId) {
    throw new functions.https.HttpsError('invalid-argument', 'moduleId is required');
  }

  try {
    console.log(`${permanentDelete ? 'Deleting' : 'Deactivating'} coaching module: ${moduleId}`);

    // Find the module
    const moduleQuery = await admin.firestore()
      .collection('coaching_modules')
      .where('moduleId', '==', moduleId)
      .limit(1)
      .get();

    if (moduleQuery.empty) {
      throw new functions.https.HttpsError('not-found', `Module with ID ${moduleId} not found`);
    }

    const moduleDoc = moduleQuery.docs[0];

    if (permanentDelete) {
      // Permanent deletion - only for dev/testing
      await moduleDoc.ref.delete();
      console.log(`🗑️  Permanently deleted module: ${moduleId}`);
    } else {
      // Soft delete - deactivate module
      await moduleDoc.ref.update({
        isActive: false,
        deactivatedTime: admin.firestore.Timestamp.now(),
        updatedTime: admin.firestore.Timestamp.now(),
      });
      console.log(`🔒 Deactivated module: ${moduleId}`);
    }

    return {
      success: true,
      moduleId: moduleId,
      message: `Coaching module ${permanentDelete ? 'deleted' : 'deactivated'} successfully`
    };

  } catch (error) {
    console.error('Error deleting coaching module:', error);
    throw new functions.https.HttpsError('internal', `Failed to delete module: ${error.message}`);
  }
});

/**
 * List all coaching modules with admin details
 */
exports.listCoachingModules = functions.https.onCall(async (data, context) => {
  verifyAdminAuth(context);

  const { includeInactive = false, limit = 50 } = data;

  try {
    let query = admin.firestore().collection('coaching_modules');

    if (!includeInactive) {
      query = query.where('isActive', '==', true);
    }

    query = query.orderBy('pillar').orderBy('order').limit(limit);

    const snapshot = await query.get();
    const modules = [];

    snapshot.forEach(doc => {
      modules.push({
        documentId: doc.id,
        ...doc.data(),
        createdTime: doc.data().createdTime?.toDate()?.toISOString(),
        updatedTime: doc.data().updatedTime?.toDate()?.toISOString(),
      });
    });

    console.log(`📋 Retrieved ${modules.length} coaching modules`);

    return {
      success: true,
      modules: modules,
      count: modules.length
    };

  } catch (error) {
    console.error('Error listing coaching modules:', error);
    throw new functions.https.HttpsError('internal', `Failed to list modules: ${error.message}`);
  }
});

/**
 * Bulk import coaching modules from JSON
 */
exports.bulkImportModules = functions.https.onCall(async (data, context) => {
  verifyAdminAuth(context);

  const { modules, overwriteExisting = false } = data;
  
  if (!modules || !Array.isArray(modules)) {
    throw new functions.https.HttpsError('invalid-argument', 'modules array is required');
  }

  try {
    console.log(`🚀 Bulk importing ${modules.length} coaching modules`);

    const results = {
      success: 0,
      failed: 0,
      skipped: 0,
      errors: []
    };

    const batch = admin.firestore().batch();
    let batchOperations = 0;

    for (const moduleData of modules) {
      try {
        validateModuleData(moduleData);

        // Check if module exists
        const existingModule = await admin.firestore()
          .collection('coaching_modules')
          .where('moduleId', '==', moduleData.moduleId)
          .limit(1)
          .get();

        if (!existingModule.empty && !overwriteExisting) {
          results.skipped++;
          continue;
        }

        // Prepare full module data
        const fullModuleData = {
          moduleId: moduleData.moduleId,
          title: moduleData.title,
          description: moduleData.description,
          category: moduleData.category || 'mental_training',
          pillar: moduleData.pillar.toLowerCase(),
          difficulty: moduleData.difficulty.toLowerCase(),
          duration: moduleData.duration,
          varkTags: moduleData.varkTags || ['visual'],
          primaryVarkStyle: moduleData.primaryVarkStyle || moduleData.varkTags?.[0] || 'visual',
          tierRequirement: moduleData.tierRequirement || 'FREE',
          contentVersions: moduleData.contentVersions || {},
          prerequisites: moduleData.prerequisites || [],
          learningObjectives: moduleData.learningObjectives || [],
          tags: moduleData.tags || [],
          thumbnailUrl: moduleData.thumbnailUrl || '',
          isActive: moduleData.isActive !== undefined ? moduleData.isActive : true,
          order: moduleData.order || 1,
          completionCount: moduleData.completionCount || 0,
          averageRating: moduleData.averageRating || 0.0,
          createdTime: admin.firestore.Timestamp.now(),
          updatedTime: admin.firestore.Timestamp.now(),
        };

        if (!existingModule.empty && overwriteExisting) {
          // Update existing
          batch.update(existingModule.docs[0].ref, fullModuleData);
        } else {
          // Create new
          const newDocRef = admin.firestore().collection('coaching_modules').doc();
          batch.set(newDocRef, fullModuleData);
        }

        batchOperations++;
        results.success++;

        // Commit batch if reaching limit (Firestore limit is 500)
        if (batchOperations >= 450) {
          await batch.commit();
          batchOperations = 0;
        }

      } catch (error) {
        results.failed++;
        results.errors.push({
          moduleId: moduleData.moduleId || 'unknown',
          error: error.message
        });
      }
    }

    // Commit final batch
    if (batchOperations > 0) {
      await batch.commit();
    }

    console.log(`✅ Bulk import completed: ${results.success} success, ${results.failed} failed, ${results.skipped} skipped`);

    return {
      success: true,
      results: results,
      message: `Bulk import completed: ${results.success} modules processed`
    };

  } catch (error) {
    console.error('Error in bulk import:', error);
    throw new functions.https.HttpsError('internal', `Failed to bulk import: ${error.message}`);
  }
});

// ============================================================================
// CONTENT ANALYTICS & MANAGEMENT
// ============================================================================

/**
 * Update module analytics (completion count, ratings)
 */
exports.updateModuleAnalytics = functions.https.onCall(async (data, context) => {
  verifyAdminAuth(context);

  const { moduleId, completionCount, averageRating } = data;
  
  if (!moduleId) {
    throw new functions.https.HttpsError('invalid-argument', 'moduleId is required');
  }

  try {
    const moduleQuery = await admin.firestore()
      .collection('coaching_modules')
      .where('moduleId', '==', moduleId)
      .limit(1)
      .get();

    if (moduleQuery.empty) {
      throw new functions.https.HttpsError('not-found', `Module with ID ${moduleId} not found`);
    }

    const updates = {
      updatedTime: admin.firestore.Timestamp.now(),
    };

    if (completionCount !== undefined) {
      updates.completionCount = completionCount;
    }

    if (averageRating !== undefined) {
      updates.averageRating = averageRating;
    }

    await moduleQuery.docs[0].ref.update(updates);

    console.log(`📊 Updated analytics for module: ${moduleId}`);

    return {
      success: true,
      moduleId: moduleId,
      message: 'Module analytics updated successfully'
    };

  } catch (error) {
    console.error('Error updating module analytics:', error);
    throw new functions.https.HttpsError('internal', `Failed to update analytics: ${error.message}`);
  }
});

/**
 * Get coaching modules usage statistics
 */
exports.getModuleStatistics = functions.https.onCall(async (data, context) => {
  verifyAdminAuth(context);

  try {
    const modulesSnapshot = await admin.firestore()
      .collection('coaching_modules')
      .where('isActive', '==', true)
      .get();

    const stats = {
      totalModules: 0,
      modulesByPillar: { focus: 0, confidence: 0, control: 0 },
      modulesByDifficulty: { beginner: 0, intermediate: 0, advanced: 0 },
      modulesByTier: { FREE: 0, PREMIUM: 0, ELITE: 0 },
      totalCompletions: 0,
      averageRating: 0,
      topModules: [],
    };

    const modules = [];

    modulesSnapshot.forEach(doc => {
      const data = doc.data();
      modules.push(data);
      
      stats.totalModules++;
      stats.modulesByPillar[data.pillar] = (stats.modulesByPillar[data.pillar] || 0) + 1;
      stats.modulesByDifficulty[data.difficulty] = (stats.modulesByDifficulty[data.difficulty] || 0) + 1;
      stats.modulesByTier[data.tierRequirement] = (stats.modulesByTier[data.tierRequirement] || 0) + 1;
      stats.totalCompletions += data.completionCount || 0;
    });

    // Calculate overall average rating
    const ratingsSum = modules.reduce((sum, module) => sum + (module.averageRating || 0), 0);
    stats.averageRating = stats.totalModules > 0 ? (ratingsSum / stats.totalModules) : 0;

    // Get top 5 modules by completion count
    stats.topModules = modules
      .sort((a, b) => (b.completionCount || 0) - (a.completionCount || 0))
      .slice(0, 5)
      .map(module => ({
        moduleId: module.moduleId,
        title: module.title,
        completionCount: module.completionCount || 0,
        averageRating: module.averageRating || 0,
      }));

    console.log(`📈 Generated statistics for ${stats.totalModules} modules`);

    return {
      success: true,
      statistics: stats
    };

  } catch (error) {
    console.error('Error generating statistics:', error);
    throw new functions.https.HttpsError('internal', `Failed to generate statistics: ${error.message}`);
  }
});

