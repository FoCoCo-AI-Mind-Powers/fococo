## Learned User Preferences

- Use the Flutter SDK from PATH (system install); do not pin FVM-specific SDK paths in IDE settings.
- Do not run `flutter run web` unless the user explicitly approves.
- FoCoCo main shell chrome should use the custom bottom bar and shared app bar helpers in `lib/ai_integration/widgets/navbar_widget.dart`, not `adaptive_platform_ui`, for the tab scaffold and matching visuals.
- Bottom navigation: selected tab uses per-route accent on icon and label (FoCoCo/MindCoach gold, GolfChat blue, CaddyPlay green); unselected tabs stay neutral; FoCoCo tab uses monochrome icon not logo/color brand asset; avoid extra bottom safe-area padding for edge-to-edge chrome.
- GolfChat AI replies must render in full with no artificial truncation or character limits in generation or UI.
- For screens with a bottom composer under `FoCoCoAdaptiveScaffold`, reserve space for the custom bottom bar when the keyboard is closed so the input stays above the tabs; align reserves with `kFoCoCoBottomNavStripAndTabsHeight` and `MediaQuery.viewPadding.bottom`.
- Prefer concise, production-focused responses; avoid unsolicited long summaries and generic examples unless the user asks.
- Minimum onboarding and registration age is 16+ (VARK flow still requires parental consent for ages 16–17).
- Do not commit API keys or other real secrets to the repository; use Firebase secrets/params and rotate keys if they are leaked or exposed.
- Do not add a top-right mic or Line voice coach action on the FoCoCo tab header; GolfChat voice entry uses `Carbon.phone_voice` (speech icon), not a microphone icon.
- Cartesia TTS across MindCoach, GolfChat, and FoCoCo tab should prefer low-latency streaming/WebSocket generation over slow callable round-trips where supported.
- Use `showFoCoCoConfirmDialog` from `lib/widgets/fococo_confirm_dialog.dart` for destructive/account confirmations (logout, delete account, download data), not stock Material dialogs.

## Learned Workspace Facts

- `FoCoCoAdaptiveScaffold` uses `extendBody: true` with a custom `bottomNavigationBar` (body draws behind the bar unless layout reserves height); `navbar_widget.dart` exports `buildFoCoCoAppBar`, `FoCoCoBottomNavigationBar`, `FoCoCoInlineScreenHeader`, `FoCoCoScaffoldScope`, and `kFoCoCoBottomNavStripAndTabsHeight`.
- Among main tab roots, only FoCoCo tab mounts `FoCoCoDrawer` with `showDrawerButton: true`; GolfChat and CaddyPlay use `FoCoCoInlineScreenHeader` with back when `context.canPop()`, not a drawer.
- Golf Chat uses Carbon icons via `iconify_flutter` and `package:iconify_flutter/icons/carbon.dart` for several UI affordances.
- FoCoCo uses dark-only theming (`ThemeMode.dark`); light/system theme selection is not offered in Settings.
- On iOS/macOS, configure Firestore client settings before the first read/write; FoCoCo tab defers Firestore/Functions on mount (cached SharedPreferences insight first, ~3s delay) to reduce launch Firestore/gRPC crashes.
- MindCoach V2: favorites sort by `savedAt` in Dart (no Firestore `orderBy`); all session starts use `runMindCoachSessionPrep`; no resume-session banner on home.
- Splash/auth restore waits for `StartupAuthService.bootstrap()` and reads `currentUser` before routing; post-auth onboarding/VARK/paywall runs via `DeferredAuthFlowGate` after the tab shell mounts (~3s deferral), not during splash.
- Cartesia voice: production `voice_id` from Secret Manager `CARTESIA_VOICE_ID` via `cartesia_voice_config.js`/`getCartesiaVoiceRuntimeConfig` (keep `cartesia_config.dart` in sync with `cartesia_tts.js`); `mintCartesiaAccessToken` sends `grants: { agent: true }` (agent id in WebSocket URL); GolfChat S2S is inline full-screen voice (blue glass, no sheet) via `cartesia_line_agent/` with legacy fallback; GolfChat text uses `generateGolfChatResponse`.
- Favorites page (`FavoritesPageWidget`, route `favorites`) opens from FoCoCo tab top-right; MindSessions and saved GolfChat tabs; MindCoach replays use `mindcoach_favorite_launcher.dart`.
- iOS Crashlytics deobfuscation uses `firebase/upload_flutter_ios_symbols.sh` after release builds with `--obfuscate --split-debug-info=build/symbols/ios`.
- FoCoCo tab daily insight (`getOrCreateFoCoCoDailyInsight`, `fococo_tab_v3`, `gemini-3.1-pro-preview`) must be deeply personal: exactly two short complete lines (data-grounded observation, then practical direction); ground on round summary, pillar scores, patterns, goal, active round, MindCoach/JustTalk context, and Focus/Confidence/Control trends; no generic, marketing, or incomplete copy.
- Drawer Report Bug / Send Feedback open full-page `SupportSubmissionWidget` routes (`report_bug`, `send_feedback` in `nav.dart`) and persist to Firestore `support_submissions`.
