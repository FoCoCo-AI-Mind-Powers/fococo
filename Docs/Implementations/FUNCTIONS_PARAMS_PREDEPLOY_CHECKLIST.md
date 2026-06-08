# Firebase Functions Params Pre-Deploy Checklist

Use this checklist before any production deployment. This project must not use `functions.config()` because Runtime Config is deprecated and will be shut down before March 2026 (per current project notice).

## 1. Required Parameter Keys

Set these values for project `fo-co-co-89gnf5` in:

- `firebase/functions/.env.fo-co-co-89gnf5`

Required keys:

- `STRIPE_SECRET_KEY`
- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`
- `CARTESIA_LINE_AGENT_ID` (Cartesia Line agent id after `cartesia deploy`)
- `CARTESIA_PRONUNCIATION_DICT_ID` (optional; sonic-3+ custom pronunciations)

> Gemini and Cartesia API keys are NOT listed here. They live in Google Cloud
> Secret Manager as `GEMINI_KEY_APP` and `CARTESIA_API`, consumed only by Cloud
> Functions via `defineSecret(...)`. Never place them in `.env.*`.

Template:

```bash
cd firebase/functions
cat > .env.fo-co-co-89gnf5 <<'EOF'
STRIPE_SECRET_KEY=sk_live_or_test_value
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret
EOF
```

## 2. Migration Safety Checks

Run from repo root:

```bash
# Must return no matches
rg -n "functions\\.config\\(" firebase/functions -g '!**/node_modules/**'

# Optional full-repo check
rg -n "functions\\.config\\(" . -g '!**/node_modules/**'
```

## 3. Compile/Load Checks

Run from repo root:

```bash
node --check firebase/functions/index.js
node --check firebase/functions/livekit_token.js
node --check firebase/functions/mindcoach_v2/generate_session_v2.js
```

Optional module load sanity:

```bash
cd firebase/functions
node -e "require('./index.js'); console.log('index.js load ok')"
node -e "require('./livekit_token.js'); console.log('livekit_token.js load ok')"
node -e "const admin=require('firebase-admin'); if(!admin.apps.length) admin.initializeApp(); require('./mindcoach_v2/generate_session_v2.js'); console.log('generate_session_v2.js load ok')"
```

## 4. MindCoach V2 Regression Checks

Run from repo root:

```bash
node firebase/functions/mindcoach_v2/template_selector_v2.spec.js
node firebase/functions/mindcoach_v2/content_selector_v2.spec.js
node firebase/functions/mindcoach_v2/runtime_validator_v2.spec.js
```

## 5. Deploy

```bash
cd firebase
firebase deploy --only functions --project fo-co-co-89gnf5
```

## 6. Post-Deploy Smoke Checks

- Verify callable functions are listed:
  - `createSubscription`
  - `confirmSubscription`
  - `cancelSubscription`
  - `reactivateSubscription`
  - `generateLiveKitToken`
  - `generateMindCoachSessionV2`
  - `completeMindCoachSessionRunV2`
  - `synthesizeSpeech`
  - `transcribeSpeech`
  - `generateGolfChatResponse`
  - `getCartesiaVoiceRuntimeConfig`
  - `mintCartesiaAccessToken`
- Execute one real call path for each:
  - LiveKit token generation.
  - MindCoach generation and completion.
  - Stripe subscription create/confirm using test values.

## 7. Legacy Runtime Config (Optional One-Time Migration)

If you still have old `functions.config()` values in Firebase, export them for reference and map to the keys above:

```bash
cd firebase
firebase functions:config:export --project fo-co-co-89gnf5
```

Do not add new `functions:config:set` usage in this project.
