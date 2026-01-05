# FoCoCo MindCoach AI Sessions — Full Implementation Guide (Cursor)

> Goal: Integrate MindCoach AI so the app can **generate**, **validate**, **store**, and **retrieve** “AI sessions” reliably, using the FoCoCo docs as the single source of truth.

---

## 0) Important — Sources Availability

Some previously uploaded files have expired in this chat environment and can’t be opened right now.  
To fully “check other sources” and re-derive exact constraints from your PDFs, re-upload:
- FoCoCo - AI Templates.pdf
- FoCoCo - AI Runtime.pdf
- FoCoCo - AI Role.pdf
- FoCoCo - AI Specification.pdf
- FoCoCo - AI Authority & Content Governance.pdf

Until you re-upload, this guide implements the same architecture already described: **fixed templates**, **JSON-only output**, **runtime validator**, **logs**, and **retrieval feed**.

---

## 1) Step-by-step Plan (Implementation Order)

### Step 1 — Define Source of Truth & Data Boundaries
1. Templates are authoritative data (“containers”). AI cannot invent containers.
2. Sessions are user-specific outputs (history feed).
3. Validator is mandatory between AI output and persistence.
4. Validator logs are mandatory for governance + debugging.

Deliverable:
- Firestore collections + schema (Step 2)
- Validator module (Step 5)
- Generation endpoint (Step 6)
- Retrieval queries + UI (Step 7)

---

## 2) Firestore Data Model

### 2.1 Collection: `mindcoach_templates` (authoritative dataset)
**Doc ID**: `template_id` (e.g., `MC_T02_PRE_SHOT_FOCUS`)

Required fields:
```json
{
  "schema_version": "v1",
  "template_id": "MC_T02_PRE_SHOT_FOCUS",
  "name": "Pre-Shot Focus",
  "allowed_routine_types": ["📐 Pre-Shot"],
  "allowed_cues": ["🎯 Visualization", "🗣 Trigger Word", "💬 Self-Talk"],
  "delivery_lengths": ["micro_10s", "standard_30s", "deep_60s"],
  "primary_pillar": "Focus",
  "trigger_moments": ["Standing over the ball", "Decision moment"]
}
Notes:

Seed exactly the fixed template set you use (8 templates).

Keep everything needed for validation inside this doc (allowed lists, schema version).

2.2 Collection: mindcoach_sessions (retrievable history)
Each AI delivery becomes a session record.

Recommended fields:

json
Copy code
{
  "user_id": "uid",
  "timestamp": 1734739200000,

  "template_id": "MC_T02_PRE_SHOT_FOCUS",
  "routine_type": "📐 Pre-Shot",
  "cue_used": "🗣 Trigger Word",
  "delivery_length": "micro_10s",

  "coaching_text": "string",
  "follow_up_question": null,

  "mindset_before": "😐 Neutral",
  "mindset_after": "😌 Calm & In Control",

  "context": {
    "course_id": "course_abc",
    "round_id": "round_123",
    "pressure_level": "medium",
    "pace_flag": "slow_play"
  },

  "success_signal_flags": {
    "user_marked_helpful": false,
    "user_completed": true
  }
}
2.3 Collection: ai_validator_logs (audit + governance)
Write one log per generation attempt.

json
Copy code
{
  "timestamp": 1734739200000,
  "user_id": "uid",

  "template_id_requested": "MC_T02_PRE_SHOT_FOCUS",
  "template_id_returned": "MC_T02_PRE_SHOT_FOCUS",

  "validator_status": "PASS",
  "failed_rules": [],
  "replacements": {},

  "model_version": "gpt-5.2-thinking",
  "prompt_version": "mindcoach_system_v1",
  "content_flags": []
}
3) Indexes
Create composite index for session feed:

Collection: mindcoach_sessions

Fields: user_id ASC, timestamp DESC

4) API Boundary (Recommended)
Do not generate sessions directly from client.
Use a backend endpoint:

Ensures validator always runs

Enforces governance rules

Prevents template spoofing / bypass

Backend options:

Cloud Run (recommended)

Firebase Functions (2nd)

Your existing backend stack (Node / Python / Java)

5) Runtime Validator (Mandatory)
5.1 AI Output Must Be JSON Only
AI must return JSON with required keys:

json
Copy code
{
  "template_id": "MC_T02_PRE_SHOT_FOCUS",
  "routine_type": "📐 Pre-Shot",
  "recommended_cue": "🗣 Trigger Word",
  "delivery_length": "micro_10s",
  "coaching_text": "string",
  "follow_up_question": "string|null"
}
5.2 Validation Rules (Hard Rules)
Given:

aiJson (parsed JSON from model)

templateDoc (from mindcoach_templates for selected template_id)

Rules:

template_id must exist in templates

If missing/invalid: fallback to safe template

routine_type must be in allowed_routine_types

Else replace with first allowed

recommended_cue must be in allowed_cues

Else replace with first allowed

delivery_length must be in delivery_lengths

Else replace with standard_30s if allowed, else first allowed

coaching_text must be non-empty and within max length (per length bucket)

Suggested limits:

micro_10s: <= 400 chars

standard_30s: <= 900 chars

deep_60s: <= 1600 chars

If too long: truncate safely or regenerate (prefer truncate + log)

5.3 Guardrails (Hard Fail → Fallback)
Block/replace when:

medical/therapeutic/diagnostic framing

“guarantee / will fix / cure / promise” language

new templates/cues/routines invented

unsafe or disallowed content

Action:

Set validator_status = "FALLBACK"

Store a safe fallback session text

Log replacements + flags

6) Generation Endpoint (Backend)
6.1 Endpoint Spec
POST /mindcoach/generate

Request:

json
Copy code
{
  "user_id": "uid",
  "context": {
    "moment": "standing_over_ball",
    "pressure_level": "medium",
    "pace_flag": "slow_play",
    "round_id": "round_123",
    "course_id": "course_abc",
    "mindset_before": "😐 Neutral",
    "last_template_id": "MC_T03_BETWEEN_SHOTS_RESET"
  },
  "preferred_delivery_length": "micro_10s"
}
Response (session doc):

json
Copy code
{
  "session_id": "firestore_doc_id",
  "session": { "...mindcoach_sessions doc..." }
}
6.2 Backend Flow (Strict)
Load all templates (or fetch by chosen template_id).

Choose template_id using deterministic mapping (not AI).

Build system prompt enforcing:

Only allowed values

JSON-only output

Call model.

Parse JSON (if fail: fallback).

Validate and correct.

Write:

mindcoach_sessions

ai_validator_logs

Return session.

7) Retrieval (App)
7.1 Sessions Feed Query
Firestore query:

mindcoach_sessions

where user_id == currentUid

orderBy timestamp desc

limit 20

Pagination:

startAfter(lastDoc) for next page

7.2 Session Detail
Either render from list data

Or fetch by doc id if you keep list minimal

7.3 Templates Cache
Fetch all mindcoach_templates once at startup

Cache locally; refresh on schema_version change

8) Security Rules (Minimum)
8.1 Sessions
Read: only owner

Write: backend only (recommended)

8.2 Templates
Read: authenticated users

Write: admin only

8.3 Validator Logs
Read: admin only

Write: backend only

9) “Other Sources” to Check (Step-by-step)
Step 9.1 Identify Your Sources
You likely have at least:

Firestore (templates + sessions)

OpenAI (generation)

App telemetry/analytics (optional)

In-app rounds/scores database (context input)

Local cache (offline feed)

Step 9.2 Validation Against Sources
For each source:

Define authoritative fields

Define sync strategy

Define failure modes + fallback

Checklist:

Templates only come from mindcoach_templates

Sessions only come from mindcoach_sessions

Any AI output not validated is never stored

Step 9.3 Source Compatibility Matrix
Create a small internal doc with:

Field name → source of truth → stored in → used by

Example:

allowed_cues → templates → mindcoach_templates → validator

coaching_text → AI → mindcoach_sessions → history feed

pressure_level → app context → mindcoach_sessions.context → future personalization

10) Cursor Task List (Copy into Cursor)
Task A — Seed Templates
Create mindcoach_templates

Seed 8 templates with:

allowed routine types

allowed cues

allowed lengths

schema_version

Task B — Build Validator Module
validateMindcoachResponse(aiJson, templateDoc)

returns {validated, log}

Task C — Backend Endpoint
POST /mindcoach/generate

deterministic template selection

call model (JSON-only)

validate → persist → return

Task D — Retrieval UI
Sessions list with pagination

Session detail view

Task E — Security Rules + Indexes
Firestore rules

composite index

11) What You Re-upload, I Will Do Next (No Guessing)
After you re-upload the PDFs, I will:

Extract exact:

template IDs/names

allowed routine types/cues/lengths

validator constraints + prohibited content terms

Output:

final seeded template JSON for all 8 templates

final validator ruleset exactly matching your docs

final system prompt text blocks exactly matching your “AI Role” 

----

# Fococo MindCoach Complete Implementation Guide

Project Structure
fococo/
├── backend/
│   ├── database/
│   │   ├── schemas/
│   │   ├── migrations/
│   │   └── seed-data/
│   │       ├── templates.json
│   │       ├── content-library.csv
│   │       └── scenario-tags.csv
│   ├── api/
│   │   ├── endpoints/
│   │   ├── validators/
│   │   └── middleware/
│   ├── ai/
│   │   ├── content-selector/
│   │   ├── scenario-detector/
│   │   └── prompts/
│   └── services/
│       ├── session-logger/
│       └── analytics/
├── frontend/
│   ├── components/
│   ├── screens/
│   └── utils/
└── shared/
    ├── types/
    ├── constants/
    └── validators/
1. Complete Database Schema
typescript// CORE COLLECTIONS

// mindcoach_templates (LOCKED - v1)
interface MindCoachTemplate {
  id: string; // MC_T01-T08
  name: string;
  when_to_use: string[];
  primary_pillar: 'FOCUS' | 'CONFIDENCE' | 'CONTROL' | 'ALL';
  secondary_pillars: string[];
  allowed_routine_types: string[];
  allowed_cues: string[];
  user_outcome_goal: string;
  delivery_lengths: string[];
  vark_supported: string[];
  progression_levels: string[];
  insight_hooks: {
    loggable_fields: string[];
    success_signals: string[];
  };
  ai_variation_zones: {
    allowed: string[];
    forbidden: string[];
  };
}

// mindcoach_content_library (VERSIONED)
interface ContentLibraryEntry {
  content_id: string; // CL001-CL480+
  template_id: string;
  vark_mode: 'Visual' | 'Aural' | 'ReadWrite' | 'Kinesthetic';
  level: 'Foundation' | 'Build' | 'Compete' | 'Maintain';
  length: 'micro' | 'standard' | 'deep';
  scenario_tags: string; // semicolon-delimited
  coaching_script: string;
  follow_up_question?: string;
  tone: 'calm' | 'directive' | 'reassuring';
  youth_variant?: string;
}

// mindcoach_scenario_tags
interface ScenarioTag {
  tag_id: string; // ST01-ST30+
  tag_name: string;
  detection_phrases: string[]; // trigger words
  template_affinity: string[]; // which templates commonly use
  context_signals: string[];
}

// mindcoach_sessions
interface MindCoachSession {
  session_id: string;
  user_id: string;
  timestamp: Date;
  template_id: string;
  content_id: string; // from content library
  scenario_tag?: string;
  vark_mode: string;
  level: string;
  length: string;
  cue_used: string;
  routine_type: string;
  mindset_before: 1 | 2 | 3 | 4 | 5;
  mindset_after?: 1 | 2 | 3 | 4 | 5;
  context: {
    pressure_level?: 'low' | 'medium' | 'high';
    pace_flag?: boolean;
    location?: string;
    weather?: string;
    playing_partners?: number;
  };
  coaching_text_delivered: string;
  follow_up_question?: string;
  user_response?: string;
  success_signals: Record<string, boolean>;
}

// ai_validator_logs
interface ValidatorLog {
  log_id: string;
  timestamp: Date;
  user_id: string;
  content_id_selected: string;
  template_id: string;
  validator_status: 'PASS' | 'FAIL_CORRECTED' | 'FAIL_FALLBACK';
  failed_rules: string[];
  replacements: Record<string, any>;
  selection_path: {
    initial_filters: Record<string, any>;
    relaxation_steps?: string[];
    final_selection: string;
  };
  content_flags: string[];
}
2. Content Selection Engine
typescript// backend/ai/content-selector/index.ts
import { parse } from 'csv-parse/sync';
import fs from 'fs';

interface SelectionCriteria {
  template_id: string;
  vark_mode?: 'Visual' | 'Aural' | 'ReadWrite' | 'Kinesthetic';
  level?: 'Foundation' | 'Build' | 'Compete' | 'Maintain';
  length?: 'micro' | 'standard' | 'deep';
  scenario_tags?: string[];
  user_age?: number;
}

export class ContentSelector {
  private contentLibrary: ContentLibraryEntry[];
  
  constructor() {
    const csvContent = fs.readFileSync('./seed-data/content-library.csv', 'utf-8');
    this.contentLibrary = parse(csvContent, {
      columns: true,
      skip_empty_lines: true
    });
  }
  
  selectContent(criteria: SelectionCriteria): ContentLibraryEntry {
    let candidates = [...this.contentLibrary];
    const selectionPath = {
      initial_count: candidates.length,
      steps: []
    };
    
    // Step 1: Filter by template_id (required)
    candidates = candidates.filter(c => c.template_id === criteria.template_id);
    selectionPath.steps.push(`template_id: ${candidates.length} matches`);
    
    // Step 2: Prioritize scenario tags if provided
    if (criteria.scenario_tags?.length) {
      const taggedCandidates = candidates.filter(c => 
        criteria.scenario_tags.some(tag => 
          c.scenario_tags?.split(';').includes(tag)
        )
      );
      if (taggedCandidates.length > 0) {
        candidates = taggedCandidates;
        selectionPath.steps.push(`scenario_tags: ${candidates.length} matches`);
      }
    }
    
    // Step 3: Filter by VARK mode
    const varkMode = criteria.vark_mode || 'ReadWrite';
    const varkCandidates = candidates.filter(c => c.vark_mode === varkMode);
    if (varkCandidates.length > 0) {
      candidates = varkCandidates;
      selectionPath.steps.push(`vark_mode: ${candidates.length} matches`);
    }
    
    // Step 4: Filter by level
    const level = criteria.level || 'Foundation';
    const levelCandidates = candidates.filter(c => c.level === level);
    if (levelCandidates.length > 0) {
      candidates = levelCandidates;
      selectionPath.steps.push(`level: ${candidates.length} matches`);
    }
    
    // Step 5: Filter by length
    const length = criteria.length || 'standard';
    const lengthCandidates = candidates.filter(c => c.length === length);
    if (lengthCandidates.length > 0) {
      candidates = lengthCandidates;
      selectionPath.steps.push(`length: ${candidates.length} matches`);
    }
    
    // Step 6: Select lowest content_id for stability
    if (candidates.length === 0) {
      // Fallback to safe default
      candidates = this.contentLibrary.filter(
        c => c.template_id === 'MC_T02_PRE_SHOT_FOCUS' && 
             c.vark_mode === 'ReadWrite' && 
             c.level === 'Foundation' && 
             c.length === 'standard'
      );
    }
    
    candidates.sort((a, b) => a.content_id.localeCompare(b.content_id));
    
    // Youth variant for users under 18
    let selected = candidates[0];
    if (criteria.user_age && criteria.user_age < 18 && selected.youth_variant) {
      selected = { ...selected, coaching_script: selected.youth_variant };
    }
    
    return selected;
  }
}
3. Scenario Detection System
typescript// backend/ai/scenario-detector/index.ts
export class ScenarioDetector {
  private scenarioTags: ScenarioTag[];
  
  constructor() {
    this.loadScenarioTags();
  }
  
  private loadScenarioTags() {
    const csvContent = fs.readFileSync('./seed-data/scenario-tags.csv', 'utf-8');
    this.scenarioTags = parse(csvContent, {
      columns: true,
      skip_empty_lines: true
    });
  }
  
  detectScenarios(input: {
    user_message?: string;
    context?: any;
    recent_shots?: any[];
    mindset_rating?: number;
  }): string[] {
    const detectedTags: string[] = [];
    
    // Text-based detection
    if (input.user_message) {
      const lowerMessage = input.user_message.toLowerCase();
      
      this.scenarioTags.forEach(tag => {
        const matched = tag.detection_phrases.some(phrase => 
          lowerMessage.includes(phrase.toLowerCase())
        );
        if (matched) {
          detectedTags.push(tag.tag_name);
        }
      });
    }
    
    // Context-based detection
    if (input.context?.pressure_level === 'high') {
      detectedTags.push('high_pressure');
    }
    
    if (input.mindset_rating && input.mindset_rating <= 2) {
      detectedTags.push('struggling');
    }
    
    // Recent performance detection
    if (input.recent_shots?.length >= 3) {
      const lastThree = input.recent_shots.slice(-3);
      const allBad = lastThree.every(s => s.result === 'poor');
      if (allBad) {
        detectedTags.push('spiral');
      }
    }
    
    return [...new Set(detectedTags)];
  }
}
4. Complete Validator with Content Library
typescript// backend/api/validators/mindcoach-validator.ts
export class MindCoachValidator {
  private templates = MINDCOACH_TEMPLATES_V1.templates;
  private contentSelector: ContentSelector;
  private forbiddenTerms = [
    'diagnose', 'diagnosis', 'treat', 'treatment', 'therapy',
    'therapist', 'counseling', 'clinical', 'disorder', 'condition',
    'depression', 'anxiety disorder', 'ADHD', 'OCD', 'medical',
    'psychiatric', 'psychological', 'will fix', 'guaranteed', 'cure'
  ];
  
  constructor() {
    this.contentSelector = new ContentSelector();
  }
  
  async validateAndSelect(request: {
    user_id: string;
    template_id: string;
    context: any;
    scenario_tags?: string[];
    user_preferences?: {
      vark_mode?: string;
      level?: string;
    };
  }): Promise<ValidationResult> {
    const log: ValidatorLog = {
      log_id: generateId(),
      timestamp: new Date(),
      user_id: request.user_id,
      content_id_selected: null,
      template_id: request.template_id,
      validator_status: 'PASS',
      failed_rules: [],
      replacements: {},
      selection_path: null,
      content_flags: []
    };
    
    // Validate template exists
    const template = this.templates.find(t => t.id === request.template_id);
    if (!template) {
      log.failed_rules.push('invalid_template_id');
      request.template_id = 'MC_T02_PRE_SHOT_FOCUS';
      log.validator_status = 'FAIL_CORRECTED';
    }
    
    // Select content from library
    const content = this.contentSelector.selectContent({
      template_id: request.template_id,
      vark_mode: request.user_preferences?.vark_mode,
      level: request.user_preferences?.level,
      length: this.determineLength(request.context),
      scenario_tags: request.scenario_tags,
      user_age: request.context.user_age
    });
    
    log.content_id_selected = content.content_id;
    
    // Validate content for forbidden terms
    const textToCheck = content.coaching_script.toLowerCase();
    const foundTerms = this.forbiddenTerms.filter(term => 
      textToCheck.includes(term)
    );
    
    if (foundTerms.length > 0) {
      log.content_flags = foundTerms;
      log.validator_status = 'FAIL_FALLBACK';
      // Use fallback content
      content.coaching_script = this.getFallbackContent(request.template_id);
    }
    
    await this.saveLog(log);
    
    return {
      content,
      log,
      template
    };
  }
  
  private determineLength(context: any): 'micro' | 'standard' | 'deep' {
    if (context.location === 'during_round') {
      return context.pace_flag ? 'micro' : 'standard';
    }
    if (context.location === 'post_round') {
      return 'deep';
    }
    return 'standard';
  }
  
  private getFallbackContent(templateId: string): string {
    const fallbacks = {
      'MC_T02_PRE_SHOT_FOCUS': "One breath. Pick one target. Commit to one swing. Then go.",
      'MC_T05_MISTAKE_RECOVERY': "Reset. The last shot is done. Your job now is one clear decision for the next one.",
      'MC_T01_PRE_ROUND_CLARITY': "Take three deep breaths. Pick one simple goal for today. Trust your preparation."
    };
    return fallbacks[templateId] || fallbacks['MC_T02_PRE_SHOT_FOCUS'];
  }
}
5. API Implementation
typescript// backend/api/endpoints/mindcoach.ts
import express from 'express';

const router = express.Router();

// Main coaching endpoint
router.post('/generate', async (req, res) => {
  const { user_id, context } = req.body;
  
  // Step 1: Detect scenarios
  const scenarioDetector = new ScenarioDetector();
  const scenarios = scenarioDetector.detectScenarios({
    user_message: context.user_message,
    context,
    recent_shots: context.recent_shots,
    mindset_rating: context.mindset_rating
  });
  
  // Step 2: Determine template
  const templateSelector = new TemplateSelector();
  const template_id = templateSelector.selectTemplate({
    location: context.location,
    scenarios,
    last_template_used: context.last_template_used,
    user_state: context.mindset_rating
  });
  
  // Step 3: Get user preferences
  const userPrefs = await getUserPreferences(user_id);
  
  // Step 4: Validate and select content
  const validator = new MindCoachValidator();
  const result = await validator.validateAndSelect({
    user_id,
    template_id,
    context,
    scenario_tags: scenarios,
    user_preferences: userPrefs
  });
  
  // Step 5: Personalize if needed
  const personalized = personalizeContent(result.content, {
    user_name: userPrefs.name,
    last_cue: context.last_cue_used
  });
  
  res.json({
    session: {
      template_id: result.template.id,
      content_id: result.content.content_id,
      coaching_text: personalized.coaching_script,
      follow_up_question: personalized.follow_up_question,
      recommended_cue: result.template.allowed_cues[0],
      routine_type: result.template.allowed_routine_types[0],
      vark_mode: result.content.vark_mode,
      level: result.content.level,
      length: result.content.length,
      scenario_tags: scenarios
    },
    metadata: {
      template_name: result.template.name,
      primary_pillar: result.template.primary_pillar,
      validation_status: result.log.validator_status
    }
  });
});

// Session logging
router.post('/session', async (req, res) => {
  const session = req.body;
  
  // Add server timestamp
  session.timestamp = new Date();
  session.session_id = generateId();
  
  // Calculate success signals
  session.success_signals = calculateSuccessSignals(session);
  
  // Save to Firestore
  await db.collection('mindcoach_sessions').doc(session.session_id).set(session);
  
  // Update user analytics
  await updateUserAnalytics(session.user_id, session);
  
  res.json({ session_id: session.session_id });
});

// Get templates (read-only)
router.get('/templates', async (req, res) => {
  res.json(MINDCOACH_TEMPLATES_V1);
});

// Get user history
router.get('/history/:userId', async (req, res) => {
  const sessions = await db.collection('mindcoach_sessions')
    .where('user_id', '==', req.params.userId)
    .orderBy('timestamp', 'desc')
    .limit(50)
    .get();
  
  res.json(sessions.docs.map(doc => doc.data()));
});
6. Frontend Implementation
tsx// frontend/components/MindCoachInterface.tsx
import React, { useState, useEffect } from 'react';

interface MindCoachInterfaceProps {
  userId: string;
  location: 'pre_round' | 'during_round' | 'post_round';
}

export const MindCoachInterface: React.FC<MindCoachInterfaceProps> = ({ 
  userId, 
  location 
}) => {
  const [currentSession, setCurrentSession] = useState(null);
  const [mindsetBefore, setMindsetBefore] = useState(3);
  const [mindsetAfter, setMindsetAfter] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  
  const requestCoaching = async (additionalContext = {}) => {
    setIsLoading(true);
    
    const context = {
      location,
      mindset_rating: mindsetBefore,
      ...additionalContext,
      user_message: additionalContext.message,
      last_template_used: localStorage.getItem('last_template'),
      last_cue_used: localStorage.getItem('last_cue')
    };
    
    const response = await fetch('/api/mindcoach/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: userId, context })
    });
    
    const session = await response.json();
    setCurrentSession(session);
    setIsLoading(false);
    
    // Store for next request
    localStorage.setItem('last_template', session.session.template_id);
    localStorage.setItem('last_cue', session.session.recommended_cue);
  };
  
  const completeSession = async () => {
    if (!currentSession || !mindsetAfter) return;
    
    await fetch('/api/mindcoach/session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...currentSession.session,
        user_id: userId,
        mindset_before: mindsetBefore,
        mindset_after: mindsetAfter,
        context: { location }
      })
    });
    
    setCurrentSession(null);
    setMindsetAfter(null);
  };
  
  return (
    <View style={styles.container}>
      {!currentSession ? (
        <MindsetSelector 
          value={mindsetBefore}
          onChange={setMindsetBefore}
          onConfirm={() => requestCoaching()}
        />
      ) : (
        <CoachingDisplay
          session={currentSession}
          onComplete={(rating) => {
            setMindsetAfter(rating);
            completeSession();
          }}
        />
      )}
    </View>
  );
};
7. Data Seeding Scripts
typescript// backend/database/seed-data/seed.ts
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { parse } from 'csv-parse/sync';
import fs from 'fs';

const seedDatabase = async () => {
  const db = getFirestore();
  
  // 1. Seed Templates (LOCKED)
  const templates = JSON.parse(
    fs.readFileSync('./FoCoCo_-_AI_Templates.json', 'utf-8')
  );
  
  for (const template of templates.templates) {
    await db.collection('mindcoach_templates')
      .doc(template.id)
      .set({
        ...template,
        schema_version: templates.schema_version,
        locked: true,
        created_at: new Date()
      });
  }
  
  // 2. Seed Content Library
  const contentCsv = fs.readFileSync('./FoCoCo_-_AI_Content_Library.csv', 'utf-8');
  const contentEntries = parse(contentCsv, {
    columns: true,
    skip_empty_lines: true
  });
  
  for (const entry of contentEntries) {
    await db.collection('mindcoach_content_library')
      .doc(entry.content_id)
      .set({
        ...entry,
        scenario_tags: entry.scenario_tags?.split(';') || [],
        created_at: new Date()
      });
  }
  
  // 3. Seed Scenario Tags
  const scenarioCsv = fs.readFileSync('./FoCoCo_-_AI_Scenario_Tags.csv', 'utf-8');
  const scenarioTags = parse(scenarioCsv, {
    columns: true,
    skip_empty_lines: true
  });
  
  for (const tag of scenarioTags) {
    await db.collection('mindcoach_scenario_tags')
      .doc(tag.tag_id)
      .set({
        ...tag,
        detection_phrases: tag.detection_phrases?.split(';') || [],
        template_affinity: tag.template_affinity?.split(';') || [],
        created_at: new Date()
      });
  }
  
  console.log('Database seeded successfully');
};

seedDatabase().catch(console.error);
8. Security Rules
javascript// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Templates and content library are read-only
    match /mindcoach_templates/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    match /mindcoach_content_library/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    match /mindcoach_scenario_tags/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    // Sessions are user-specific
    match /mindcoach_sessions/{session} {
      allow read: if request.auth.uid == resource.data.user_id;
      allow create: if request.auth.uid == request.resource.data.user_id;
      allow update: if false;
      allow delete: if false;
    }
    
    // Validator logs are admin-only
    match /ai_validator_logs/{log} {
      allow read: if request.auth.token.admin == true;
      allow write: if false;
    }
  }
}
9. Analytics Service
typescript// backend/services/analytics/index.ts
export class MindCoachAnalytics {
  async calculateSuccessSignals(session: MindCoachSession): Record<string, boolean> {
    const signals = {};
    
    // Mindset improvement
    if (session.mindset_after && session.mindset_before) {
      signals.mindset_improved = session.mindset_after > session.mindset_before;
      signals.mindset_stable = session.mindset_after >= 3;
    }
    
    // Completion
    signals.session_completed = !!session.mindset_after;
    
    // Template-specific signals
    const template = await this.getTemplate(session.template_id);
    template.insight_hooks.success_signals.forEach(signal => {
      if (signal === 'mindset_improves_or_stabilizes') {
        signals[signal] = signals.mindset_improved || signals.mindset_stable;
      }
      // Add other signal calculations
    });
    
    return signals;
  }
  
  async getUserInsights(userId: string): Promise<UserInsights> {
    const sessions = await this.getUserSessions(userId);
    
    return {
      most_used_template: this.getMostUsedTemplate(sessions),
      most_effective_cue: this.getMostEffectiveCue(sessions),
      average_mindset_improvement: this.calculateAverageImprovement(sessions),
      pressure_performance: this.analyzePressurePerformance(sessions),
      progression_level: this.determineProgressionLevel(sessions),
      recommended_focus: this.getRecommendedFocus(sessions)
    };
  }
}
10. Testing Suite
typescript// tests/integration/mindcoach.test.ts
describe('MindCoach Integration Tests', () => {
  let validator: MindCoachValidator;
  let selector: ContentSelector;
  let detector: ScenarioDetector;
  
  beforeEach(() => {
    validator = new MindCoachValidator();
    selector = new ContentSelector();
    detector = new ScenarioDetector();
  });
  
  test('full flow: high pressure pre-shot', async () => {
    // Detect scenario
    const scenarios = detector.detectScenarios({
      user_message: "Big putt to win",
      context: { pressure_level: 'high' }
    });
    expect(scenarios).toContain('high_pressure');
    
    // Select content
    const content = selector.selectContent({
      template_id: 'MC_T06_PRESSURE_MOMENTS',
      scenario_tags: scenarios,
      vark_mode: 'Visual',
      level: 'Compete',
      length: 'micro'
    });
    expect(content).toBeDefined();
    expect(content.template_id).toBe('MC_T06_PRESSURE_MOMENTS');
    
    // Validate
    const result = await validator.validateAndSelect({
      user_id: 'test_user',
      template_id: 'MC_T06_PRESSURE_MOMENTS',
      context: { pressure_level: 'high' },
      scenario_tags: scenarios
    });
    expect(result.log.validator_status).toBe('PASS');
  });
  
  test('content library coverage', () => {
    const templates = MINDCOACH_TEMPLATES_V1.templates;
    
    templates.forEach(template => {
      template.vark_supported.forEach(vark => {
        template.progression_levels.forEach(level => {
          template.delivery_lengths.forEach(length => {
            const content = selector.selectContent({
              template_id: template.id,
              vark_mode: vark,
              level,
              length: length.split('_')[0] // micro/standard/deep
            });
            expect(content).toBeDefined();
          });
        });
      });
    });
  });
});
11. Deployment Checklist
markdown## Pre-Deployment
- [ ] Firebase project initialized
- [ ] Environment variables configured
- [ ] Security rules tested

## Data Setup
- [ ] Templates JSON uploaded (8 templates)
- [ ] Content library CSV processed (480+ entries)
- [ ] Scenario tags CSV loaded (30+ tags)
- [ ] All collections indexed

## Validation
- [ ] Validator catches forbidden terms
- [ ] Content selector returns valid content for all combinations
- [ ] Scenario detector identifies correct tags
- [ ] Fallback responses work

## Testing
- [ ] All 8 templates tested
- [ ] All VARK modes tested
- [ ] All progression levels tested
- [ ] Youth variants work for under-18
- [ ] Session logging works
- [ ] Analytics calculate correctly

## Monitoring
- [ ] Validator logs being created
- [ ] Session success signals tracked
- [ ] Error rates acceptable
- [ ] Response times under 500ms
Critical Implementation Rules

NEVER modify templates - They are the locked spine
ALWAYS select from content library - No AI generation
Deterministic selection - Same inputs = same content
Log everything - Every selection, validation, and session
No medical language - Instant fallback if detected
Youth safety - Use youth variants for under-18
Version everything - Templates, content, and prompts
Validate continuously - Every request goes through validator

This is the complete FoCoCo MindCoach implementation with all components integrated.

---

# FoCoCo Firebase/Google Cloud Architecture
Architecture Overview
Frontend (cached) → Firebase Hosting
    ↓
Firestore (static data cached locally)
    ↓
Cloud Functions (only for logging/validation)
    ↓
BigQuery (analytics)
1. Firebase Project Setup
bash# Initialize
firebase init
# Select: Firestore, Functions, Hosting

# Deploy structure
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions
firebase deploy --only hosting
2. Firestore Structure (Optimized for Caching)
typescript// Static Collections (Cache Forever)
/config/v1/templates/{templateId}
/config/v1/content_library/{contentId}  
/config/v1/scenario_tags/{tagId}

// User Collections (Dynamic)
/users/{userId}/sessions/{sessionId}
/users/{userId}/preferences
3. Frontend Cache Implementation
typescript// frontend/services/cache-manager.ts
import { enableIndexedDbPersistence, enableNetwork, disableNetwork } from 'firebase/firestore';

class CacheManager {
  private staticDataVersion = 'v1';
  private db: Firestore;
  
  async initializeCache() {
    // Enable offline persistence
    await enableIndexedDbPersistence(this.db);
    
    // Cache all static data on first load
    await this.cacheStaticData();
  }
  
  private async cacheStaticData() {
    const cached = localStorage.getItem('static_data_version');
    if (cached === this.staticDataVersion) return;
    
    // One-time fetch of all static data
    const batch = await Promise.all([
      getDocs(collection(db, 'config/v1/templates')),
      getDocs(collection(db, 'config/v1/content_library')),
      getDocs(collection(db, 'config/v1/scenario_tags'))
    ]);
    
    localStorage.setItem('static_data_version', this.staticDataVersion);
  }
  
  // Content selection runs entirely client-side
  selectContent(criteria: SelectionCriteria): Content {
    const cachedLibrary = this.getCachedCollection('content_library');
    return this.runSelectionAlgorithm(cachedLibrary, criteria);
  }
}
4. Cloud Functions (Minimal)
typescript// functions/src/index.ts
import * as functions from 'firebase-functions';
import { BigQuery } from '@google-cloud/bigquery';

// Only for logging (write-only)
export const logSession = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated');
  
  // Validate session data
  const validated = validateSession(data);
  
  // Write to Firestore
  await admin.firestore()
    .collection(`users/${uid}/sessions`)
    .add({
      ...validated,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  
  // Stream to BigQuery for analytics
  const bigquery = new BigQuery();
  await bigquery
    .dataset('fococo_analytics')
    .table('sessions')
    .insert([validated]);
    
  return { success: true };
});

// Scheduled function for analytics
export const calculateInsights = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const bigquery = new BigQuery();
    
    // Run aggregation queries
    const query = `
      SELECT user_id, 
             AVG(mindset_after - mindset_before) as avg_improvement,
             COUNT(*) as session_count
      FROM fococo_analytics.sessions
      WHERE DATE(timestamp) = CURRENT_DATE()
      GROUP BY user_id
    `;
    
    const [rows] = await bigquery.query(query);
    
    // Write insights back to Firestore
    for (const row of rows) {
      await admin.firestore()
        .doc(`users/${row.user_id}/insights/daily`)
        .set(row, { merge: true });
    }
  });
5. Frontend-Only Execution
typescript// frontend/services/mindcoach-service.ts
export class MindCoachService {
  private cache: CacheManager;
  private templates: Map<string, Template>;
  private contentLibrary: Map<string, Content>;
  
  constructor() {
    this.loadStaticData();
  }
  
  // All selection logic runs client-side
  async generateCoaching(context: Context): CoachingSession {
    // 1. Detect scenarios (client-side)
    const scenarios = this.detectScenarios(context);
    
    // 2. Select template (client-side)
    const template = this.selectTemplate(context, scenarios);
    
    // 3. Select content (client-side)
    const content = this.selectContent({
      template_id: template.id,
      scenarios,
      ...context
    });
    
    // 4. Personalize (client-side)
    const personalized = this.personalize(content, context);
    
    // 5. Return session (no server call)
    return {
      template,
      content: personalized,
      timestamp: new Date()
    };
  }
  
  // Only server call is for logging
  async logSession(session: Session) {
    const logFunction = httpsCallable(functions, 'logSession');
    await logFunction(session);
  }
}
6. Deployment Configuration
json// firebase.json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs18",
    "minInstances": 0,
    "maxInstances": 10
  },
  "hosting": {
    "public": "dist",
    "rewrites": [{
      "source": "**",
      "destination": "/index.html"
    }],
    "headers": [{
      "source": "**/*.@(js|css)",
      "headers": [{
        "key": "Cache-Control",
        "value": "public, max-age=31536000"
      }]
    }]
  }
}
7. Security Rules (Simplified)
javascript// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Static data - public read
    match /config/{version}/{collection}/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    // User data - owner only
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
8. Cost Optimization
typescript// Cache strategy for minimal reads
const CACHE_CONFIG = {
  // Static data - cache forever
  templates: { source: 'cache' },
  content_library: { source: 'cache' },
  scenario_tags: { source: 'cache' },
  
  // User data - server then cache
  sessions: { source: 'default' },
  preferences: { source: 'default' }
};

// Batch operations
async function batchFetch() {
  const batch = writeBatch(db);
  // Add all operations
  await batch.commit(); // Single write
}
9. BigQuery Schema
sql-- Create dataset
CREATE SCHEMA fococo_analytics;

-- Sessions table
CREATE TABLE fococo_analytics.sessions (
  session_id STRING,
  user_id STRING,
  template_id STRING,
  content_id STRING,
  mindset_before INT64,
  mindset_after INT64,
  timestamp TIMESTAMP,
  context STRUCT
    pressure_level STRING,
    location STRING
  >
);

-- Materialized view for performance
CREATE MATERIALIZED VIEW fococo_analytics.user_insights AS
SELECT 
  user_id,
  AVG(mindset_after - mindset_before) as avg_improvement,
  COUNT(*) as total_sessions,
  ARRAY_AGG(STRUCT(template_id, COUNT(*)) ORDER BY COUNT(*) DESC LIMIT 3) as top_templates
FROM fococo_analytics.sessions
GROUP BY user_id;
10. Implementation Steps
bash# 1. Setup project
gcloud projects create fococo-prod
firebase use fococo-prod

# 2. Enable APIs
gcloud services enable firestore.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable bigquery.googleapis.com

# 3. Deploy static data
npm run seed:firestore

# 4. Deploy functions (minimal)
cd functions && npm run deploy

# 5. Build and deploy frontend
npm run build
firebase deploy --only hosting
Key Architecture Decisions

Static Data Cached Forever: Templates, content library, scenario tags never change after deploy
Client-Side Logic: All selection/validation runs in browser
Server for Logging Only: Cloud Functions only for writes and analytics
BigQuery for Analytics: Separate analytical queries from operational database
Firestore Offline: Built-in offline support for seamless experience

Cost Estimates (10K users)

Firestore reads: ~$0 (all cached)
Firestore writes: ~$50/month (sessions only)
Cloud Functions: ~$5/month (minimal invocations)
BigQuery: ~$10/month (analytics)
Total: ~$65/month

This architecture maximizes frontend caching, minimizes server calls, and keeps costs extremely low while maintaining full functionality.