## Learned User Preferences

- Use the Flutter SDK from PATH (system install); do not pin FVM-specific SDK paths in IDE settings.
- Do not run `flutter run web` unless the user explicitly approves.
- FoCoCo main shell chrome should use the custom bottom bar and shared app bar helpers in `lib/ai_integration/widgets/navbar_widget.dart`, not `adaptive_platform_ui`, for the tab scaffold and matching visuals.
- Bottom navigation should keep icons neutral and show selection through label/text color, not colored/glass icon containers; avoid extra bottom safe-area padding when the user wants edge-to-edge chrome.
- The FoCoCo bottom-nav tab should use the same monochrome icon style as the other tabs, not the logo/color asset.
- For screens with a bottom composer under `FoCoCoAdaptiveScaffold`, reserve space for the custom bottom bar when the keyboard is closed so the input stays above the tabs; align reserves with `kFoCoCoBottomNavStripAndTabsHeight` and `MediaQuery.viewPadding.bottom`.
- Prefer concise, production-focused responses; avoid unsolicited long summaries and generic examples unless the user asks.
- Minimum onboarding and registration age is 16+ (VARK flow still requires parental consent for ages 16–17).
- Do not commit API keys or other real secrets to the repository; use Firebase secrets/params and rotate keys if they are leaked or exposed.
- Do not add a top-right mic or Line voice coach action on the FoCoCo tab header; voice entry belongs in GolfChat and other dedicated surfaces.
- Use `showFoCoCoConfirmDialog` from `lib/widgets/fococo_confirm_dialog.dart` for destructive/account confirmations (logout, delete account, download data), not stock Material dialogs.

## Learned Workspace Facts

- `FoCoCoAdaptiveScaffold` uses `extendBody: true` with a custom `bottomNavigationBar`, so body content draws behind the bar unless the layout reserves the bar height.
- `navbar_widget.dart` exports shell helpers including `buildFoCoCoAppBar`, `FoCoCoBottomNavigationBar`, `FoCoCoInlineScreenHeader`, `FoCoCoScaffoldScope`, and `kFoCoCoBottomNavStripAndTabsHeight`.
- Among main tab roots, only FoCoCo tab mounts `FoCoCoDrawer` with `showDrawerButton: true`; GolfChat and CaddyPlay use `FoCoCoInlineScreenHeader` with back when `context.canPop()`, not a drawer.
- Golf Chat uses Carbon icons via `iconify_flutter` and `package:iconify_flutter/icons/carbon.dart` for several UI affordances.
- FoCoCo uses dark-only theming (`ThemeMode.dark`); light/system theme selection is not offered in Settings.
- On iOS and macOS, configure Firestore client settings (persistence and bounded cache) before the first Firestore read/write to reduce native Firestore/gRPC crashes during startup.
- FoCoCo tab defers Firestore/Functions on mount (cached SharedPreferences insight first, ~3s delay) to avoid iOS launch Firestore/gRPC crashes documented in `fococo_tab_widget.dart`.
- MindCoach V2 favorites intentionally avoid Firestore `orderBy` in the native query and sort by `savedAt` in Dart to avoid query-argument parser crashes.
- Splash/auth restore should wait for `StartupAuthService.bootstrap()` and read `currentUser` immediately before routing, avoiding stale startup snapshots that send signed-in users back to login.
- Post-auth onboarding/VARK/paywall routing runs via `DeferredAuthFlowGate` after the tab shell mounts (~3s deferral), not during splash.
- Cartesia voice: canonical TTS ID in `lib/ai_integration/config/cartesia_config.dart` (keep in sync with `firebase/functions/cartesia_tts.js`); GolfChat S2S uses `FoCoCoLineVoiceSheet` + deployed `cartesia_line_agent/` (Ink STT + Gemini Live text + Sonic TTS); GolfChat text chat uses `generateGolfChatResponse`.
- iOS Crashlytics deobfuscation uses `firebase/upload_flutter_ios_symbols.sh` after release builds with `--obfuscate --split-debug-info=build/symbols/ios`.
- FoCoCo tab daily insight (`getOrCreateFoCoCoDailyInsight`, `fococo_tab_v3`, `gemini-3.1-pro-preview`) must be deeply personal: exactly two short complete lines (data-grounded observation, then practical direction); ground on round summary, pillar scores, patterns, goal, active round, MindCoach/JustTalk context, and Focus/Confidence/Control trends; no generic, marketing, or incomplete copy.
- Drawer Report Bug / Send Feedback open full-page `SupportSubmissionWidget` routes (`report_bug`, `send_feedback` in `nav.dart`) and persist to Firestore `support_submissions`.
