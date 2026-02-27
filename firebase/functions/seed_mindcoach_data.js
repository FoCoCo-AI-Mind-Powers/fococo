/**
 * Firebase Cloud Function to seed MindCoach authoritative datasets.
 *
 * Supports:
 * - idempotent upsert seeding
 * - dry-run validation
 * - optional reseed prune for stale docs
 * - post-seed integrity report
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const fs = require('fs');

const {
  TEMPLATE_IDS,
  CONTENT_LIBRARY_EXPECTED_ROWS,
  TEMPLATES_JSON_PATH,
  CONTENT_LIBRARY_CSV_PATH,
  SCENARIO_TAGS_CSV_PATH,
} = require('./mindcoach_v2/contracts_v2');
const {
  parseCsvFile,
  validateContentLibraryIntegrity,
} = require('./mindcoach_v2/csv_utils_v2');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const EXPECTED_CONTENT_ROWS = CONTENT_LIBRARY_EXPECTED_ROWS;

function parseBool(value, fallback = false) {
  if (value == null) return fallback;
  const normalized = String(value).trim().toLowerCase();
  if (['1', 'true', 'yes', 'y', 'on'].includes(normalized)) return true;
  if (['0', 'false', 'no', 'n', 'off'].includes(normalized)) return false;
  return fallback;
}

function toStringOrNull(value) {
  const normalized = value == null ? '' : String(value).trim();
  return normalized.length ? normalized : null;
}

function splitList(value, delimiter) {
  return String(value || '')
    .split(delimiter)
    .map((item) => item.trim())
    .filter(Boolean);
}

function loadTemplatesFromJson() {
  if (!fs.existsSync(TEMPLATES_JSON_PATH)) {
    throw new Error(`Templates JSON not found at: ${TEMPLATES_JSON_PATH}`);
  }

  const raw = fs.readFileSync(TEMPLATES_JSON_PATH, 'utf8');
  const parsed = JSON.parse(raw);
  const templates = Array.isArray(parsed.templates) ? parsed.templates : [];

  return {
    schemaVersion: String(parsed.schema_version || '1.0'),
    templates,
  };
}

function loadContentEntriesFromCsv() {
  if (!fs.existsSync(CONTENT_LIBRARY_CSV_PATH)) {
    throw new Error(`Content CSV not found at: ${CONTENT_LIBRARY_CSV_PATH}`);
  }

  const entries = parseCsvFile(CONTENT_LIBRARY_CSV_PATH).map((entry) => {
    const contentId = String(entry.content_id || entry.contentId || '').trim();
    if (!contentId) {
      return null;
    }

    return {
      content_id: contentId,
      template_id: String(entry.template_id || entry.templateId || '').trim(),
      template_name: String(entry.template_name || entry.templateName || '').trim(),
      pillar: String(entry.pillar || '').trim(),
      vark_mode: String(entry.vark_mode || entry.varkMode || 'ReadWrite').trim(),
      level: String(entry.level || 'Foundation').trim(),
      length: String(entry.length || 'standard').trim(),
      scenario_tags: splitList(entry.scenario_tags, ';'),
      pressure_level: toStringOrNull(entry.pressure_level || entry.pressureLevel),
      lie_type: toStringOrNull(entry.lie_type || entry.lieType),
      wind_condition: toStringOrNull(entry.wind_condition || entry.windCondition),
      region_variant: toStringOrNull(entry.region_variant || entry.regionVariant),
      script_text: String(entry.script_text || entry.scriptText || '').trim(),
      cta_question: toStringOrNull(entry.cta_question || entry.ctaQuestion),
      follow_up_prompt: toStringOrNull(entry.follow_up_prompt || entry.followUpPrompt),
      confidence_rating_hint: toStringOrNull(
        entry.confidence_rating_hint || entry.confidenceRatingHint,
      ),
      do_not_say_flags: splitList(entry.do_not_say_flags, ','),
    };
  }).filter(Boolean);

  const validation = validateContentLibraryIntegrity(entries, {
    templateIds: TEMPLATE_IDS,
    expectedRows: EXPECTED_CONTENT_ROWS,
  });

  return { entries, validation };
}

function loadScenarioEntriesFromCsv() {
  if (!fs.existsSync(SCENARIO_TAGS_CSV_PATH)) {
    throw new Error(`Scenario CSV not found at: ${SCENARIO_TAGS_CSV_PATH}`);
  }

  return parseCsvFile(SCENARIO_TAGS_CSV_PATH)
    .map((entry) => {
      const tagId = String(
        entry.scenario_tag || entry.scenarioTag || entry.tag_id || entry.tagId || '',
      ).trim();
      if (!tagId) {
        return null;
      }

      return {
        tag_id: tagId,
        tag_name: String(entry.tag_name || tagId).trim(),
        scenario_tag: tagId,
        description: String(entry.description || '').trim(),
        detection_phrases: splitList(entry.detection_phrases, ','),
        template_affinity: splitList(entry.template_affinity, ','),
        context_signals: splitList(entry.context_signals, ','),
      };
    })
    .filter(Boolean);
}

async function pruneCollection({ collectionName, keepIds }) {
  const existing = await db.collection(collectionName).get();
  if (existing.empty) {
    return { deleted: 0 };
  }

  const keep = new Set(keepIds || []);
  const staleIds = existing.docs
    .map((doc) => doc.id)
    .filter((id) => !keep.has(id));

  let deleted = 0;
  const batchSize = 400;
  for (let i = 0; i < staleIds.length; i += batchSize) {
    const batch = db.batch();
    const chunk = staleIds.slice(i, i + batchSize);
    for (const id of chunk) {
      batch.delete(db.collection(collectionName).doc(id));
    }
    await batch.commit();
    deleted += chunk.length;
  }

  return { deleted };
}

async function upsertTemplates({ templates, schemaVersion, dryRun, pruneExtras }) {
  if (dryRun) {
    return {
      success: true,
      count: templates.length,
      dryRun: true,
      pruned: 0,
    };
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  for (const template of templates) {
    const templateId = String(template.id || '').trim();
    if (!templateId) continue;

    batch.set(
      db.collection('mindcoach_templates').doc(templateId),
      {
        id: templateId,
        schema_version: schemaVersion,
        name: template.name || '',
        primary_pillar: template.primary_pillar || '',
        allowed_routine_types: template.allowed_routine_types || [],
        allowed_cues: template.allowed_cues || [],
        delivery_lengths: template.delivery_lengths || [],
        trigger_moments: template.trigger_moments || [],
        created_at: now,
        updated_at: now,
        templateId,
        schemaVersion,
        primaryPillar: template.primary_pillar || '',
        allowedRoutineTypes: template.allowed_routine_types || [],
        allowedCues: template.allowed_cues || [],
        deliveryLengths: template.delivery_lengths || [],
        triggerMoments: template.trigger_moments || [],
        createdTime: now,
        updatedTime: now,
        isActive: true,
      },
      { merge: true },
    );
  }

  await batch.commit();

  let pruned = 0;
  if (pruneExtras) {
    const keepIds = templates.map((template) => String(template.id || '').trim()).filter(Boolean);
    const pruneResult = await pruneCollection({
      collectionName: 'mindcoach_templates',
      keepIds,
    });
    pruned = pruneResult.deleted;
  }

  return {
    success: true,
    count: templates.length,
    dryRun: false,
    pruned,
  };
}

async function upsertContentLibrary({ entries, dryRun, pruneExtras }) {
  if (dryRun) {
    return {
      success: true,
      count: entries.length,
      dryRun: true,
      pruned: 0,
    };
  }

  const batchSize = 400;
  const now = admin.firestore.FieldValue.serverTimestamp();
  let imported = 0;

  for (let i = 0; i < entries.length; i += batchSize) {
    const batch = db.batch();
    const chunk = entries.slice(i, i + batchSize);

    for (const entry of chunk) {
      batch.set(
        db.collection('mindcoach_content_library').doc(entry.content_id),
        {
          ...entry,
          created_at: now,
          updated_at: now,
        },
        { merge: true },
      );
    }

    await batch.commit();
    imported += chunk.length;
  }

  let pruned = 0;
  if (pruneExtras) {
    const keepIds = entries.map((entry) => entry.content_id);
    const pruneResult = await pruneCollection({
      collectionName: 'mindcoach_content_library',
      keepIds,
    });
    pruned = pruneResult.deleted;
  }

  return {
    success: true,
    count: imported,
    dryRun: false,
    pruned,
  };
}

async function upsertScenarioTags({ entries, dryRun, pruneExtras }) {
  if (dryRun) {
    return {
      success: true,
      count: entries.length,
      dryRun: true,
      pruned: 0,
    };
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  for (const entry of entries) {
    batch.set(
      db.collection('mindcoach_scenario_tags').doc(entry.tag_id),
      {
        ...entry,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
  }

  await batch.commit();

  let pruned = 0;
  if (pruneExtras) {
    const keepIds = entries.map((entry) => entry.tag_id);
    const pruneResult = await pruneCollection({
      collectionName: 'mindcoach_scenario_tags',
      keepIds,
    });
    pruned = pruneResult.deleted;
  }

  return {
    success: true,
    count: entries.length,
    dryRun: false,
    pruned,
  };
}

async function validateFirestoreState() {
  const templateSnap = await db.collection('mindcoach_templates').get();
  const contentSnap = await db.collection('mindcoach_content_library').get();
  const scenarioSnap = await db.collection('mindcoach_scenario_tags').get();

  const templateIdsInStore = new Set(templateSnap.docs.map((doc) => doc.id));
  const missingTemplates = TEMPLATE_IDS.filter((id) => !templateIdsInStore.has(id));

  const contentEntries = contentSnap.docs.map((doc) => ({
    content_id: doc.id,
    ...doc.data(),
  }));
  const contentValidation = validateContentLibraryIntegrity(contentEntries, {
    templateIds: TEMPLATE_IDS,
    expectedRows: EXPECTED_CONTENT_ROWS,
  });

  const ok = missingTemplates.length === 0 && contentValidation.ok && scenarioSnap.size > 0;

  return {
    ok,
    templates: {
      count: templateSnap.size,
      missingTemplates,
    },
    content: {
      count: contentSnap.size,
      validation: contentValidation,
    },
    scenarios: {
      count: scenarioSnap.size,
    },
  };
}

async function executeSeed(options = {}) {
  const dryRun = !!options.dryRun;
  const reseed = !!options.reseed;
  const pruneExtras = dryRun ? false : !!options.pruneExtras;

  const { schemaVersion, templates } = loadTemplatesFromJson();
  const { entries: contentEntries, validation: contentSourceValidation } = loadContentEntriesFromCsv();
  const scenarioEntries = loadScenarioEntriesFromCsv();

  const sourceValidation = {
    templates: {
      expected: TEMPLATE_IDS.length,
      found: templates.length,
      missing: TEMPLATE_IDS.filter(
        (templateId) => !templates.some((template) => String(template.id || '').trim() === templateId),
      ),
    },
    content: contentSourceValidation,
    scenarios: {
      count: scenarioEntries.length,
    },
  };

  if (!contentSourceValidation.ok) {
    throw new Error(
      `Content CSV integrity failed: ${contentSourceValidation.errors.join(', ')}`,
    );
  }
  if (sourceValidation.templates.missing.length > 0) {
    throw new Error(
      `Templates JSON missing required template IDs: ${sourceValidation.templates.missing.join(', ')}`,
    );
  }

  const shouldPrune = reseed || pruneExtras;
  const results = {
    mode: dryRun ? 'dry_run' : reseed ? 'reseed' : 'upsert',
    options: {
      dryRun,
      reseed,
      pruneExtras: shouldPrune,
    },
    sourceValidation,
    templates: await upsertTemplates({
      templates,
      schemaVersion,
      dryRun,
      pruneExtras: shouldPrune,
    }),
    contentLibrary: await upsertContentLibrary({
      entries: contentEntries,
      dryRun,
      pruneExtras: shouldPrune,
    }),
    scenarioTags: await upsertScenarioTags({
      entries: scenarioEntries,
      dryRun,
      pruneExtras: shouldPrune,
    }),
  };

  results.postValidation = await validateFirestoreState();
  results.success = dryRun ? true : results.postValidation.ok;

  return results;
}

exports.seedMindCoachData = functions.https.onRequest(async (req, res) => {
  try {
    const dryRun = parseBool(req.query.dryRun ?? req.body?.dryRun, false);
    const reseed = parseBool(req.query.reseed ?? req.body?.reseed, false);
    const pruneExtras = parseBool(req.query.pruneExtras ?? req.body?.pruneExtras, false);

    const results = await executeSeed({
      dryRun,
      reseed,
      pruneExtras,
    });

    await db.collection('mindcoach_seeding_logs').doc().set({
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: results.success ? 'completed' : 'failed_validation',
      results,
    });

    res.status(results.success ? 200 : 409).json({
      success: results.success,
      message: results.success
        ? dryRun
          ? 'MindCoach dry-run completed successfully.'
          : 'MindCoach seeding completed successfully.'
        : 'MindCoach seeding completed but post-validation failed.',
      results,
    });
  } catch (error) {
    console.error('seedMindCoachData failed:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

if (require.main === module) {
  (async () => {
    try {
      const dryRun = parseBool(process.env.DRY_RUN, false);
      const reseed = parseBool(process.env.RESEED, true);
      const pruneExtras = parseBool(process.env.PRUNE_EXTRAS, false);

      const results = await executeSeed({ dryRun, reseed, pruneExtras });
      console.log(JSON.stringify(results, null, 2));
      process.exit(results.success ? 0 : 2);
    } catch (error) {
      console.error(error);
      process.exit(1);
    }
  })();
}

module.exports.executeSeed = executeSeed;
