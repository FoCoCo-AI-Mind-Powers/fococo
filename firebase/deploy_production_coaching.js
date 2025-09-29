#!/usr/bin/env node

/**
 * FOCOCO PRODUCTION COACHING MODULES DEPLOYMENT SCRIPT
 * 
 * This script deploys all production-ready coaching modules infrastructure:
 * 1. Deploys Firebase Functions with admin capabilities
 * 2. Updates Firestore security rules
 * 3. Imports production coaching modules
 * 4. Sets up admin user claims
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK using default credentials
try {
  admin.initializeApp({
    projectId: 'fo-co-co-89gnf5'
  });
  console.log('🔗 Firebase Admin SDK initialized successfully');
} catch (error) {
  if (error.code !== 'app/duplicate-app') {
    console.error('❌ Error initializing Firebase Admin:', error.message);
    process.exit(1);
  }
}

const db = admin.firestore();

console.log('🚀 FoCoCo Production Coaching Modules Deployment Starting...\n');

/**
 * Step 1: Deploy Firebase Functions
 */
async function deployFunctions() {
  console.log('📦 Step 1: Deploying Firebase Functions...');
  
  const { exec } = require('child_process');
  const util = require('util');
  const execPromise = util.promisify(exec);
  
  try {
    console.log('   - Installing function dependencies...');
    await execPromise('cd functions && npm install');
    
    console.log('   - Deploying coaching admin functions...');
    await execPromise('firebase deploy --only functions');
    
    console.log('   ✅ Firebase Functions deployed successfully\n');
    return true;
  } catch (error) {
    console.error('   ❌ Error deploying functions:', error.message);
    console.log('   💡 Run manually: firebase deploy --only functions\n');
    return false;
  }
}

/**
 * Step 2: Deploy Firestore Security Rules
 */
async function deploySecurityRules() {
  console.log('🛡️  Step 2: Deploying Firestore Security Rules...');
  
  const { exec } = require('child_process');
  const util = require('util');
  const execPromise = util.promisify(exec);
  
  try {
    console.log('   - Deploying updated firestore rules...');
    await execPromise('firebase deploy --only firestore:rules');
    
    console.log('   ✅ Firestore Security Rules deployed successfully');
    console.log('   📋 Rules now include coaching_modules, user_module_progress, and module_reviews\n');
    return true;
  } catch (error) {
    console.error('   ❌ Error deploying rules:', error.message);
    console.log('   💡 Run manually: firebase deploy --only firestore:rules\n');
    return false;
  }
}

/**
 * Step 3: Test Firestore connection and basic operations
 */
async function testFirestoreConnection() {
  console.log('🔍 Step 3: Testing Firestore Connection...');
  
  try {
    // Test basic read operation
    const testCollection = await db.collection('coaching_modules').limit(1).get();
    console.log('   ✅ Firestore connection successful');
    console.log(`   📊 Current coaching modules: ${testCollection.size}`);
    return true;
  } catch (error) {
    console.error('   ❌ Error connecting to Firestore:', error.message);
    console.log('   💡 Make sure you are logged in to Firebase: firebase login\n');
    return false;
  }
}

/**
 * Step 4: Import production coaching modules
 */
async function importProductionModules() {
  console.log('📚 Step 4: Importing Production Coaching Modules...');
  
  try {
    // Read the production modules JSON
    const modulesPath = path.join(__dirname, 'production_coaching_modules.json');
    
    if (!fs.existsSync(modulesPath)) {
      throw new Error('production_coaching_modules.json not found');
    }
    
    const modulesData = JSON.parse(fs.readFileSync(modulesPath, 'utf8'));
    
    console.log(`   📖 Found ${modulesData.modules.length} production modules to import`);
    
    let importCount = 0;
    let skipCount = 0;
    let errorCount = 0;
    
    for (const moduleData of modulesData.modules) {
      try {
        // Check if module already exists
        const existingModule = await db.collection('coaching_modules')
          .where('moduleId', '==', moduleData.moduleId)
          .limit(1)
          .get();
        
        if (!existingModule.empty) {
          console.log(`   ⚠️  Module already exists: ${moduleData.moduleId}`);
          skipCount++;
          continue;
        }
        
        // Add timestamps
        moduleData.createdTime = admin.firestore.Timestamp.now();
        moduleData.updatedTime = admin.firestore.Timestamp.now();
        
        // Import the module
        const docRef = await db.collection('coaching_modules').add(moduleData);
        console.log(`   ✅ Imported: ${moduleData.title} (${docRef.id})`);
        importCount++;
        
      } catch (error) {
        console.log(`   ❌ Error importing ${moduleData.moduleId}:`, error.message);
        errorCount++;
      }
    }
    
    console.log(`\n   📊 Import Summary:`);
    console.log(`   - Imported: ${importCount} modules`);
    console.log(`   - Skipped: ${skipCount} modules`);
    console.log(`   - Errors: ${errorCount} modules`);
    console.log('   ✅ Production modules import completed\n');
    
    return { importCount, skipCount, errorCount };
    
  } catch (error) {
    console.error('   ❌ Error importing modules:', error.message, '\n');
    return { importCount: 0, skipCount: 0, errorCount: 1 };
  }
}

/**
 * Step 5: Verify deployment
 */
async function verifyDeployment() {
  console.log('✅ Step 5: Verifying Deployment...');
  
  try {
    // Check coaching modules collection
    const modulesSnapshot = await db.collection('coaching_modules').get();
    
    if (modulesSnapshot.empty) {
      console.log('   ⚠️  No coaching modules found');
      return false;
    }
    
    console.log(`   ✅ Found ${modulesSnapshot.size} coaching modules`);
    
    // Display module statistics by pillar
    const stats = { focus: 0, confidence: 0, control: 0, other: 0 };
    const difficulties = { beginner: 0, intermediate: 0, advanced: 0 };
    const tiers = { FREE: 0, PREMIUM: 0, ELITE: 0 };
    
    modulesSnapshot.forEach(doc => {
      const data = doc.data();
      
      // Count by pillar
      if (stats.hasOwnProperty(data.pillar)) {
        stats[data.pillar]++;
      } else {
        stats.other++;
      }
      
      // Count by difficulty
      if (difficulties.hasOwnProperty(data.difficulty)) {
        difficulties[data.difficulty]++;
      }
      
      // Count by tier
      if (tiers.hasOwnProperty(data.tierRequirement)) {
        tiers[data.tierRequirement]++;
      }
    });
    
    console.log('   📈 Modules by Pillar:');
    console.log(`      - Focus: ${stats.focus} modules`);
    console.log(`      - Confidence: ${stats.confidence} modules`);
    console.log(`      - Control: ${stats.control} modules`);
    
    console.log('   📊 Modules by Difficulty:');
    console.log(`      - Beginner: ${difficulties.beginner} modules`);
    console.log(`      - Intermediate: ${difficulties.intermediate} modules`);
    console.log(`      - Advanced: ${difficulties.advanced} modules`);
    
    console.log('   💎 Modules by Tier:');
    console.log(`      - FREE: ${tiers.FREE} modules`);
    console.log(`      - PREMIUM: ${tiers.PREMIUM} modules`);
    console.log(`      - ELITE: ${tiers.ELITE} modules`);
    
    console.log('\n   ✅ Deployment verification completed successfully');
    return true;
    
  } catch (error) {
    console.error('   ❌ Error verifying deployment:', error.message);
    return false;
  }
}

/**
 * Main deployment function
 */
async function deployProduction() {
  console.log('🎯 FOCOCO COACHING MODULES - PRODUCTION DEPLOYMENT');
  console.log('================================================\n');
  
  let deploymentSteps = {
    functions: false,
    rules: false,
    connection: false,
    modules: false,
    verification: false
  };
  
  try {
    // Step 1: Test Firestore connection first
    deploymentSteps.connection = await testFirestoreConnection();
    
    if (!deploymentSteps.connection) {
      throw new Error('Cannot proceed without Firestore connection');
    }
    
    // Step 2: Deploy Functions (optional, can fail and continue)
    deploymentSteps.functions = await deployFunctions();
    
    // Step 3: Deploy Security Rules (optional, can fail and continue)
    deploymentSteps.rules = await deploySecurityRules();
    
    // Step 4: Import Production Modules (core requirement)
    const importResults = await importProductionModules();
    deploymentSteps.modules = importResults.importCount > 0;
    
    // Step 5: Verify Deployment
    deploymentSteps.verification = await verifyDeployment();
    
    // Final Report
    console.log('\n🎉 PRODUCTION DEPLOYMENT REPORT');
    console.log('==============================');
    console.log('');
    
    if (deploymentSteps.connection) {
      console.log('✅ Firestore Connection: SUCCESS');
    } else {
      console.log('❌ Firestore Connection: FAILED');
    }
    
    if (deploymentSteps.functions) {
      console.log('✅ Firebase Functions: DEPLOYED');
    } else {
      console.log('⚠️  Firebase Functions: NOT DEPLOYED (run manually if needed)');
    }
    
    if (deploymentSteps.rules) {
      console.log('✅ Security Rules: DEPLOYED');
    } else {
      console.log('⚠️  Security Rules: NOT DEPLOYED (run manually if needed)');
    }
    
    if (deploymentSteps.modules) {
      console.log('✅ Coaching Modules: IMPORTED');
    } else {
      console.log('❌ Coaching Modules: IMPORT FAILED');
    }
    
    if (deploymentSteps.verification) {
      console.log('✅ Verification: PASSED');
    } else {
      console.log('❌ Verification: FAILED');
    }
    
    console.log('');
    
    if (deploymentSteps.modules && deploymentSteps.verification) {
      console.log('🎉 CORE DEPLOYMENT SUCCESSFUL!');
      console.log('📱 Your FoCoCo app can now access coaching modules!');
      console.log('');
      console.log('🚀 Next Steps:');
      console.log('   1. Test coaching modules in your Flutter app');
      console.log('   2. Upload content to Firebase Storage');
      console.log('   3. Configure admin user claims');
      if (!deploymentSteps.functions) {
        console.log('   4. Deploy functions: firebase deploy --only functions');
      }
      if (!deploymentSteps.rules) {
        console.log('   5. Deploy rules: firebase deploy --only firestore:rules');
      }
    } else {
      console.log('⚠️  PARTIAL DEPLOYMENT');
      console.log('Some components may need manual deployment.');
    }
    
  } catch (error) {
    console.error('\n❌ DEPLOYMENT FAILED:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Make sure you are logged in: firebase login');
    console.log('   2. Check project selection: firebase use fo-co-co-89gnf5');
    console.log('   3. Verify your Firebase permissions');
    console.log('   4. Run individual steps manually if needed');
  }
}

// Run deployment if script is called directly
if (require.main === module) {
  deployProduction().then(() => {
    console.log('\n🏁 Deployment script completed.');
    process.exit(0);
  }).catch((error) => {
    console.error('\n💥 Fatal error:', error.message);
    process.exit(1);
  });
}

module.exports = { deployProduction };