## Learned User Preferences

- Use the Flutter SDK from PATH (system install); do not pin FVM-specific SDK paths in IDE settings.
- Do not run `flutter run web` unless the user explicitly approves.
- FoCoCo main shell chrome should use the custom bottom bar and shared app bar helpers in `lib/ai_integration/widgets/navbar_widget.dart`, not `adaptive_platform_ui`, for the tab scaffold and matching visuals.
- Bottom navigation should follow the FoCoCo shell design (tab indicators, page background tint on the bar) and avoid extra bottom safe-area padding when the user wants edge-to-edge chrome.
- For screens with a bottom composer under `FoCoCoAdaptiveScaffold`, reserve space for the custom bottom bar when the keyboard is closed so the input stays above the tabs; align reserves with `kFoCoCoBottomNavStripAndTabsHeight` and `MediaQuery.viewPadding.bottom`.
- Prefer concise, production-focused responses; avoid unsolicited long summaries and generic examples unless the user asks.
- Minimum onboarding and registration age is 16+ (VARK flow still requires parental consent for ages 16–17).
- Do not commit API keys or other real secrets to the repository; use Firebase secrets/params and rotate keys if they are leaked or exposed.

## Learned Workspace Facts

- `FoCoCoAdaptiveScaffold` uses `extendBody: true` with a custom `bottomNavigationBar`, so body content draws behind the bar unless the layout reserves the bar height.
- `navbar_widget.dart` exports `buildFoCoCoAppBar`, `FoCoCoBottomNavigationBar`, and `kFoCoCoBottomNavStripAndTabsHeight` for shell layout math and consistent app bars.
- Golf Chat uses Carbon icons via `iconify_flutter` and `package:iconify_flutter/icons/carbon.dart` for several UI affordances.
- FoCoCo uses dark-only theming (`ThemeMode.dark`); light/system theme selection is not offered in Settings.
- On iOS and macOS, configure Firestore client settings (persistence and bounded cache) before the first Firestore read/write to reduce native Firestore/gRPC crashes during startup.
