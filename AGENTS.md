## Learned User Preferences

- Prefer the system Flutter SDK from PATH over FVM when the user asks to use the main toolchain; clear IDE pins to FVM-specific SDK paths and remove project FVM version pins when switching.
- Do not run `flutter run web` unless the user explicitly approves.
- FoCoCo main shell chrome should use the custom bottom bar and shared app bar helpers in `lib/ai_integration/widgets/navbar_widget.dart`, not `adaptive_platform_ui`, for the tab scaffold and matching visuals.
- Bottom navigation should follow the FoCoCo shell design (tab indicators, page background tint on the bar) and avoid extra bottom safe-area padding when the user wants edge-to-edge chrome.
- For screens with a bottom composer under `FoCoCoAdaptiveScaffold`, reserve space for the custom bottom bar when the keyboard is closed so the input stays above the tabs; align reserves with `kFoCoCoBottomNavStripAndTabsHeight` and `MediaQuery.viewPadding.bottom`.
- Prefer concise, production-focused responses; avoid unsolicited long summaries and generic examples unless the user asks.

## Learned Workspace Facts

- `FoCoCoAdaptiveScaffold` uses `extendBody: true` with a custom `bottomNavigationBar`, so body content draws behind the bar unless the layout reserves the bar height.
- `navbar_widget.dart` exports `buildFoCoCoAppBar`, `FoCoCoBottomNavigationBar`, and `kFoCoCoBottomNavStripAndTabsHeight` for shell layout math and consistent app bars.
- Golf Chat uses Carbon icons via `iconify_flutter` and `package:iconify_flutter/icons/carbon.dart` for several UI affordances.
