/**
 * Firebase Cloud Function to Seed MindCoach Content Library and Scenario Tags
 * 
 * This function seeds:
 * - mindcoach_content_library collection from CSV
 * - mindcoach_scenario_tags collection from CSV
 * 
 * Usage:
 * 1. Deploy: firebase deploy --only functions:seedMindCoachData
 * 2. Call: https://your-project.cloudfunctions.net/seedMindCoachData
 * 3. Or run locally: node seed_mindcoach_data.js (with proper Firebase Admin setup)
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Seed Templates from authoritative JSON file
 */
async function seedTemplates() {
  try {
    const jsonPath = path.join(
      __dirname,
      '../../Docs/MindCoach/FoCoCo - B - AI Data/FoCoCo - AI Templates.json'
    );

    if (!fs.existsSync(jsonPath)) {
      throw new Error(`Templates JSON not found at: ${jsonPath}`);
    }

    const raw = fs.readFileSync(jsonPath, 'utf-8');
    const parsed = JSON.parse(raw);
    const templates = Array.isArray(parsed.templates) ? parsed.templates : [];

    console.log(`🧱 Found ${templates.length} templates`);

    const batch = db.batch();

    templates.forEach((template) => {
      const templateId = template.id;
      if (!templateId) {
        return;
      }

      const docRef = db.collection('mindcoach_templates').doc(templateId);
      const schemaVersion = parsed.schema_version || '1.0';

      batch.set(
        docRef,
        {
          id: templateId,
          schema_version: schemaVersion,
          name: template.name || '',
          primary_pillar: template.primary_pillar || '',
          allowed_routine_types: template.allowed_routine_types || [],
          allowed_cues: template.allowed_cues || [],
          delivery_lengths: template.delivery_lengths || [],
          trigger_moments: template.trigger_moments || [],
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),

          // Compatibility mirrors
          templateId,
          schemaVersion,
          primaryPillar: template.primary_pillar || '',
          allowedRoutineTypes: template.allowed_routine_types || [],
          allowedCues: template.allowed_cues || [],
          deliveryLengths: template.delivery_lengths || [],
          triggerMoments: template.trigger_moments || [],
          createdTime: admin.firestore.FieldValue.serverTimestamp(),
          updatedTime: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
        },
        { merge: true }
      );
    });

    await batch.commit();
    console.log(`✅ Imported ${templates.length} templates`);
    return { success: true, count: templates.length };
  } catch (error) {
    console.error('❌ Error seeding templates:', error);
    throw error;
  }
}

/**
 * Parse CSV line handling quoted fields
 */
function parseCsvLine(line) {
  const result = [];
  let inQuotes = false;
  let currentField = '';

  for (let i = 0; i < line.length; i++) {
    const char = line[i];

    if (char === '"') {
      inQuotes = !inQuotes;
    } else if (char === ',' && !inQuotes) {
      result.push(currentField);
      currentField = '';
    } else {
      currentField += char;
    }
  }
  result.push(currentField); // Add last field

  return result;
}

/**
 * Parse CSV content into array of objects
 */
function parseCsv(csvContent) {
  const lines = csvContent.split('\n').filter(line => line.trim().length > 0);
  if (lines.length === 0) return [];

  // Parse header
  const headers = parseCsvLine(lines[0]).map(h => h.trim());

  // Parse rows
  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const values = parseCsvLine(line);
    if (values.length < headers.length) continue;

    const row = {};
    for (let j = 0; j < headers.length && j < values.length; j++) {
      row[headers[j]] = values[j].trim();
    }
    rows.push(row);
  }

  return rows;
}

/**
 * Seed Content Library from CSV
 */
async function seedContentLibrary() {
  try {
    // Try to read from Docs folder (relative to firebase/functions)
    const csvPath = path.join(__dirname, '../../Docs/MindCoach/FoCoCo - B - AI Data/FoCoCo - AI Content Library.csv');
    
    if (!fs.existsSync(csvPath)) {
      throw new Error(`Content Library CSV not found at: ${csvPath}`);
    }

    const csvContent = fs.readFileSync(csvPath, 'utf-8');
    const entries = parseCsv(csvContent);

    console.log(`📚 Found ${entries.length} content library entries`);

    const batchSize = 500;
    let totalImported = 0;

    for (let i = 0; i < entries.length; i += batchSize) {
      const batch = db.batch();
      const batchData = entries.slice(i, i + batchSize);

      batchData.forEach(entry => {
        const contentId = entry.content_id || entry.contentId;
        if (!contentId) {
          console.warn('Skipping entry without content_id');
          return;
        }

        const docRef = db.collection('mindcoach_content_library').doc(contentId);
        
        // Convert scenario_tags from semicolon-delimited string to array
        const scenarioTags = entry.scenario_tags 
          ? entry.scenario_tags.split(';').map(tag => tag.trim()).filter(tag => tag.length > 0)
          : [];

        // Convert do_not_say_flags from comma-delimited string to array
        const doNotSayFlags = entry.do_not_say_flags
          ? entry.do_not_say_flags.split(',').map(flag => flag.trim()).filter(flag => flag.length > 0)
          : [];

        batch.set(docRef, {
          content_id: contentId,
          template_id: entry.template_id || entry.templateId || '',
          template_name: entry.template_name || entry.templateName || '',
          pillar: entry.pillar || '',
          vark_mode: entry.vark_mode || entry.varkMode || 'ReadWrite',
          level: entry.level || 'Foundation',
          length: entry.length || 'standard',
          scenario_tags: scenarioTags,
          pressure_level: entry.pressure_level || entry.pressureLevel || null,
          lie_type: entry.lie_type || entry.lieType || null,
          wind_condition: entry.wind_condition || entry.windCondition || null,
          region_variant: entry.region_variant || entry.regionVariant || null,
          script_text: entry.script_text || entry.scriptText || '',
          cta_question: entry.cta_question || entry.ctaQuestion || null,
          follow_up_prompt: entry.follow_up_prompt || entry.followUpPrompt || null,
          confidence_rating_hint: entry.confidence_rating_hint || entry.confidenceRatingHint || null,
          do_not_say_flags: doNotSayFlags,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      });

      await batch.commit();
      totalImported += batchData.length;
      console.log(`✅ Imported ${totalImported}/${entries.length} content library entries`);
    }

    return { success: true, count: totalImported };
  } catch (error) {
    console.error('❌ Error seeding content library:', error);
    throw error;
  }
}

/**
 * Seed Scenario Tags from CSV
 */
async function seedScenarioTags() {
  try {
    const csvPath = path.join(__dirname, '../../Docs/MindCoach/FoCoCo - B - AI Data/FoCoCo - AI Scenario Tags.csv');
    
    if (!fs.existsSync(csvPath)) {
      throw new Error(`Scenario Tags CSV not found at: ${csvPath}`);
    }

    const csvContent = fs.readFileSync(csvPath, 'utf-8');
    const entries = parseCsv(csvContent);

    console.log(`🏷️  Found ${entries.length} scenario tag entries`);

    const batch = db.batch();

    entries.forEach(entry => {
      const tagId = entry.scenario_tag || entry.scenarioTag || entry.tag_id || entry.tagId;
      if (!tagId) {
        console.warn('Skipping entry without scenario_tag');
        return;
      }

      const docRef = db.collection('mindcoach_scenario_tags').doc(tagId);
      
      batch.set(docRef, {
        tag_id: tagId,
        tag_name: tagId, // Use tag_id as tag_name if not provided
        scenario_tag: tagId,
        description: entry.description || '',
        detection_phrases: entry.detection_phrases 
          ? entry.detection_phrases.split(',').map(p => p.trim()).filter(p => p.length > 0)
          : [],
        template_affinity: entry.template_affinity
          ? entry.template_affinity.split(',').map(t => t.trim()).filter(t => t.length > 0)
          : [],
        context_signals: entry.context_signals
          ? entry.context_signals.split(',').map(s => s.trim()).filter(s => s.length > 0)
          : [],
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });

    await batch.commit();
    console.log(`✅ Imported ${entries.length} scenario tags`);

    return { success: true, count: entries.length };
  } catch (error) {
    console.error('❌ Error seeding scenario tags:', error);
    throw error;
  }
}

/**
 * Main Cloud Function
 */
exports.seedMindCoachData = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🌱 Starting MindCoach data seeding...');

    const results = {
      templates: null,
      contentLibrary: null,
      scenarioTags: null,
      errors: [],
    };

    // Seed Templates
    try {
      results.templates = await seedTemplates();
    } catch (error) {
      results.errors.push(`Templates: ${error.message}`);
      console.error('Templates seeding failed:', error);
    }

    // Seed Content Library
    try {
      results.contentLibrary = await seedContentLibrary();
    } catch (error) {
      results.errors.push(`Content Library: ${error.message}`);
      console.error('Content Library seeding failed:', error);
    }

    // Seed Scenario Tags
    try {
      results.scenarioTags = await seedScenarioTags();
    } catch (error) {
      results.errors.push(`Scenario Tags: ${error.message}`);
      console.error('Scenario Tags seeding failed:', error);
    }

    // Create summary document
    await db.collection('mindcoach_seeding_logs').doc().set({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      results: results,
      status: results.errors.length === 0 ? 'completed' : 'partial',
    });

    const response = {
      success: results.errors.length === 0,
      message: results.errors.length === 0 
        ? 'MindCoach data seeded successfully' 
        : 'MindCoach data seeded with errors',
      results: results,
    };

    console.log('✅ MindCoach data seeding completed');
    res.status(200).json(response);
  } catch (error) {
    console.error('❌ MindCoach data seeding failed:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Allow running as standalone script for local testing
if (require.main === module) {
  (async () => {
    try {
      console.log('🌱 Running MindCoach data seeding locally...');

      const templateResult = await seedTemplates();
      console.log('Templates:', templateResult);
      
      const contentResult = await seedContentLibrary();
      console.log('Content Library:', contentResult);
      
      const scenarioResult = await seedScenarioTags();
      console.log('Scenario Tags:', scenarioResult);
      
      console.log('✅ Seeding completed successfully!');
      process.exit(0);
    } catch (error) {
      console.error('❌ Seeding failed:', error);
      process.exit(1);
    }
  })();
}
