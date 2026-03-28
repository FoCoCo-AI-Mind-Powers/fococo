# FoCoCo — MindCoach
## Cursor Implementation Guide
*Flutter · Confidential · v1.0*

---

> **SCOPE:** MindCoach tab — Pillar Selection screen, Pillar Detail screen, "During Round" sub-session overlay, and Session Player screen.
> Each pillar has its own accent color: **Focus = Blue**, **Confidence = Green**, **Control = Gold**.

---

## 1. Feature Overview

MindCoach is one of four tabs in FoCoCo. It helps golfers strengthen three mental pillars: Focus, Confidence, and Control. Each pillar contains audio coaching sessions organised by timing context (Before Round, During Round, After Round, Favorites).

### 1.1 Screen Hierarchy

| Screen | Route | Trigger | Notes |
|---|---|---|---|
| Pillar Selection | `/mindcoach` | MindCoach tab tap | Main entry. 3 pillar buttons. |
| Pillar Detail | `/mindcoach/pillar` | Tap a pillar button | Passes `PillarType` enum |
| "During Round" Overlay | `showModalBottomSheet` | Tap "During Round" row | Sub-session list. NOT a full route. |
| Session Player | `/mindcoach/session` | Tap any session row | Passes `SessionModel` |

---

## 2. Pillar Theme System

Every screen and widget derives its accent color from the active pillar. Define a `PillarTheme` data class and pass it down via `InheritedWidget` or provider.

### 2.1 PillarType Enum + PillarTheme

```dart
// lib/features/mind_coach/models/pillar_type.dart

enum PillarType { focus, confidence, control }

class PillarTheme {
  final PillarType type;
  final Color accentColor;
  final Color glowColor;    // same hue, lower opacity for BoxShadow
  final String label;       // "FOCUS" / "CONFIDENCE" / "CONTROL"
  final String subtitle;    // "Strengthen focus under pressure."

  const PillarTheme({
    required this.type,
    required this.accentColor,
    required this.glowColor,
    required this.label,
    required this.subtitle,
  });
}
```

```dart
// lib/features/mind_coach/constants/pillar_themes.dart

const Map<PillarType, PillarTheme> kPillarThemes = {
  PillarType.focus: PillarTheme(
    type: PillarType.focus,
    accentColor: Color(0xFF4DA6FF),   // Blue
    glowColor:   Color(0x554DA6FF),
    label:    'FOCUS',
    subtitle: 'Strengthen focus under pressure.',
  ),
  PillarType.confidence: PillarTheme(
    type: PillarType.confidence,
    accentColor: Color(0xFF66CC66),   // Green
    glowColor:   Color(0x5566CC66),
    label:    'CONFIDENCE',
    subtitle: 'Strengthen confidence under pressure.',
  ),
  PillarType.control: PillarTheme(
    type: PillarType.control,
    accentColor: Color(0xFFE8B84B),   // Gold
    glowColor:   Color(0x55E8B84B),
    label:    'CONTROL',
    subtitle: 'Strengthen control under pressure.',
  ),
};
```

---

## 3. Data Models

### 3.1 Session Timing Context

```dart
// lib/features/mind_coach/models/session_context.dart

enum SessionContext {
  beforeRound,
  duringRound,   // parent category — opens sub-session overlay
  afterRound,
  favorites,
}

enum DuringRoundContext {
  beforeShot,
  duringShot,
  afterShot,
  betweenShots,
}
```

### 3.2 SessionModel

```dart
// lib/features/mind_coach/models/session_model.dart

class SessionModel {
  final String id;
  final PillarType pillar;
  final SessionContext context;
  final DuringRoundContext? duringRoundContext; // non-null when context == duringRound
  final int durationSeconds;
  final String shortLabel;      // e.g. "Set target. Clear decision."
  final List<String> coachingLines; // shown sequentially on Session Player
  final String completionMessage;   // e.g. "You are ready."
  bool isFavorite;

  SessionModel({
    required this.id,
    required this.pillar,
    required this.context,
    this.duringRoundContext,
    required this.durationSeconds,
    required this.shortLabel,
    required this.coachingLines,
    required this.completionMessage,
    this.isFavorite = false,
  });
}
```

---

## 4. Screen 1 — Pillar Selection

`lib/features/mind_coach/screens/pillar_selection_screen.dart`

### 4.1 Visual Spec

| Element | Spec | Implementation Detail |
|---|---|---|
| Background | Full-screen dark textured bg | `Stack: Image.asset('assets/bg/texture_dark.png', fit: BoxFit.cover)` |
| AppBar | "MindCoach" centred. Hamburger left. | `AppBar(title: Text('MindCoach'), backgroundColor: transparent, elevation: 0)` |
| Instruction text | "Select what pillar you want to strengthen" | `Padding(top: 48), Text, size 20, white, centred` |
| FOCUS button | Full-width outlined. Blue glow border. | `PillarButton(type: PillarType.focus)` — see 4.2 |
| CONFIDENCE button | Full-width outlined. Green glow border. | `PillarButton(type: PillarType.confidence)` |
| CONTROL button | Full-width outlined. Gold glow border. | `PillarButton(type: PillarType.control)` |
| Glow lines | Subtle horizontal glow BELOW each button. | `Positioned Container` with blurred `BoxDecoration` gradient |

### 4.2 PillarButton Widget

```dart
// lib/features/mind_coach/widgets/pillar_button.dart

class PillarButton extends StatelessWidget {
  final PillarType type;
  final VoidCallback onTap;

  const PillarButton({required this.type, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = kPillarThemes[type]!;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.accentColor, width: 1.5),
              color: Colors.white.withOpacity(0.04),
              boxShadow: [
                BoxShadow(
                  color: theme.glowColor,
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              theme.label,
              style: TextStyle(
                color: theme.accentColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
        _GlowLine(color: theme.accentColor),   // horizontal glow below button
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GlowLine extends StatelessWidget {
  final Color color;
  const _GlowLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 12, spreadRadius: 2)],
      ),
    );
  }
}
```

### 4.3 Navigation

```dart
// On PillarButton tap:
Navigator.pushNamed(
  context,
  '/mindcoach/pillar',
  arguments: type,  // PillarType
);
```

---

## 5. Screen 2 — Pillar Detail

`lib/features/mind_coach/screens/pillar_detail_screen.dart`

Receives `PillarType` via route arguments. Rebuilds accent colors from `kPillarThemes`.

### 5.1 Visual Spec

| Element | Spec |
|---|---|
| App Bar | "MindCoach" centred. Hamburger left. Transparent bg. |
| Pillar title | Accent-colored. Large caps. e.g. "FOCUS". Centred. Size 36. |
| Subtitle | "Strengthen [pillar] under pressure." White. Centred. Size 16. |
| Glow line | Accent color. Below subtitle. Full-width. Blurred. |
| Session rows | 4 cards: During Round (expandable), Before Round (20s), After Round (25s), Favorites (expandable) |
| Expanded row | Chevron down icon. Subtitle text. Accent border. Accent glow line at bottom. |
| Non-expanded row | Title left + duration right. Subtitle below title. Glow line at bottom. |

### 5.2 SessionRow Widget

```dart
// lib/features/mind_coach/widgets/session_row.dart

class SessionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? durationSeconds;   // null when isExpandable
  final bool isExpandable;
  final Color accentColor;
  final VoidCallback onTap;

  const SessionRow({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.durationSeconds,
    this.isExpandable = false,
    super.key,
  });

  String get _duration =>
      durationSeconds != null ? '(${durationSeconds}s)' : '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Row(
              children: [
                if (isExpandable)
                  Icon(Icons.keyboard_arrow_down,
                      color: accentColor, size: 20),
                if (isExpandable) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: isExpandable ? accentColor : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
                if (!isExpandable)
                  Text(_duration,
                      style: TextStyle(color: accentColor, fontSize: 13)),
              ],
            ),
          ),
          _GlowLine(color: accentColor),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
```

### 5.3 PillarDetailScreen — Full Layout

```dart
// lib/features/mind_coach/screens/pillar_detail_screen.dart

class PillarDetailScreen extends StatelessWidget {
  final PillarType pillarType;
  const PillarDetailScreen({required this.pillarType, super.key});

  @override
  Widget build(BuildContext context) {
    final theme    = kPillarThemes[pillarType]!;
    final sessions = MindCoachRepository.getSessionsFor(pillarType);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _MindCoachAppBar(),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/bg/texture_dark.png',
              fit: BoxFit.cover)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Text(theme.label, style: TextStyle(
                      color: theme.accentColor, fontSize: 36,
                      fontWeight: FontWeight.w800, letterSpacing: 3)),
                  const SizedBox(height: 8),
                  Text(theme.subtitle, style: const TextStyle(
                      color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 12),
                  _GlowLine(color: theme.accentColor),
                  const SizedBox(height: 28),
                  // During Round — opens overlay
                  SessionRow(
                    title: 'During Round',
                    subtitle: 'Stay sharp when it matters.',
                    isExpandable: true,
                    accentColor: theme.accentColor,
                    onTap: () => _showDuringRoundOverlay(context, theme, sessions),
                  ),
                  // Before Round
                  SessionRow(
                    title: 'Before Round',
                    subtitle: sessions.beforeRound.shortLabel,
                    durationSeconds: sessions.beforeRound.durationSeconds,
                    accentColor: theme.accentColor,
                    onTap: () => _goToSession(context, sessions.beforeRound),
                  ),
                  // After Round
                  SessionRow(
                    title: 'After Round',
                    subtitle: sessions.afterRound.shortLabel,
                    durationSeconds: sessions.afterRound.durationSeconds,
                    accentColor: theme.accentColor,
                    onTap: () => _goToSession(context, sessions.afterRound),
                  ),
                  // Favorites
                  SessionRow(
                    title: 'Favorites',
                    subtitle: 'Saved for instant access.',
                    isExpandable: true,
                    accentColor: theme.accentColor,
                    onTap: () => _showFavoritesOverlay(context, theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDuringRoundOverlay(
      BuildContext ctx, PillarTheme theme, PillarSessions sessions) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DuringRoundOverlay(
        theme: theme, sessions: sessions.duringRound,
      ),
    );
  }

  void _goToSession(BuildContext ctx, SessionModel session) {
    Navigator.pushNamed(ctx, '/mindcoach/session', arguments: session);
  }
}
```

---

## 6. "During Round" Sub-Session Overlay

`lib/features/mind_coach/widgets/during_round_overlay.dart`

Shown via `showModalBottomSheet`. NOT a full-page route. Contains 4 sub-sessions + Cancel.

### 6.1 Visual Spec

| Element | Spec | Notes |
|---|---|---|
| Container | Dark bg. Border radius top: 20. Padding 24. | Decorated box over transparent modal bg |
| Header | "During Round" centred. White. Bold. Size 18. | No back arrow — Cancel button at bottom |
| Glow line | Accent color. Below header. | `_GlowLine` widget reused |
| Before Shot (10s) | Row: title + `(10 sec)` right. Subtitle below. | onTap → Session Player |
| During Shot (10s) | Same pattern. | |
| After Shot (15s) | Same pattern. | |
| Between Shots (15s) | Same pattern. | |
| Cancel | Centred `TextButton`. White. Size 16. | `Navigator.pop(context)` |

### 6.2 DuringRoundOverlay Widget

```dart
// lib/features/mind_coach/widgets/during_round_overlay.dart

class DuringRoundOverlay extends StatelessWidget {
  final PillarTheme theme;
  final List<SessionModel> sessions; // 4 during-round sessions

  const DuringRoundOverlay({
    required this.theme,
    required this.sessions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('During Round', style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _GlowLine(color: theme.accentColor),
          const SizedBox(height: 20),
          ...sessions.map((s) => SessionRow(
            title: _contextLabel(s.duringRoundContext!),
            subtitle: s.shortLabel,
            durationSeconds: s.durationSeconds,
            accentColor: theme.accentColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/mindcoach/session', arguments: s);
            },
          )),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String _contextLabel(DuringRoundContext ctx) {
    switch (ctx) {
      case DuringRoundContext.beforeShot:   return 'Before Shot';
      case DuringRoundContext.duringShot:   return 'During Shot';
      case DuringRoundContext.afterShot:    return 'After Shot';
      case DuringRoundContext.betweenShots: return 'Between Shots';
    }
  }
}
```

---

## 7. Session Player Screen

`lib/features/mind_coach/screens/session_screen.dart`

Full-screen player. Shows coaching lines sequentially. Ends in "Session complete." state with Play Again, Back to [Pillar], Add to Favorites.

### 7.1 Visual Spec

| Element | Spec | Detail |
|---|---|---|
| AppBar | "[Context] · [duration] sec" centred. Back arrow left. Sound icon right. | e.g. "Before Round · 20 sec" |
| Pillar title | Accent color. Large. Centred. | "FOCUS" / "CONFIDENCE" / "CONTROL" |
| Glow line | Accent color below title. | `_GlowLine` |
| Coaching lines | Fade in sequentially. White. Bold for first line. | `AnimatedSwitcher` |
| Completion heading | "You are ready." — White bold. Size 22. | Shown after last line + timer |
| "Session complete." | Smaller. `white60`. Below completion heading. | Shown simultaneously |
| Glow line | Accent. Below completion area. | |
| Play Again btn | Full-width outlined. Accent border + text. | Replays from start |
| Back to [Pillar] btn | Full-width outlined. Accent border + text. | `Navigator.pop` |
| Add to favorites | Star icon + text. Centred. Below buttons. | Toggles `SessionModel.isFavorite` |

### 7.2 State Machine

```dart
enum _PlayerState { playing, complete }

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin {
  _PlayerState _state = _PlayerState.playing;
  int _lineIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  void _startPlayback() {
    setState(() {
      _state = _PlayerState.playing;
      _lineIndex = 0;
    });
    final session   = widget.session;
    final msPerLine = (session.durationSeconds * 1000) ~/ session.coachingLines.length;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: msPerLine), (t) {
      if (_lineIndex < session.coachingLines.length - 1) {
        setState(() => _lineIndex++);
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _state = _PlayerState.complete);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

### 7.3 Session Screen Build

```dart
  @override
  Widget build(BuildContext context) {
    final session    = widget.session;
    final theme      = kPillarThemes[session.pillar]!;
    final isComplete = _state == _PlayerState.complete;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        title: Text('${_contextName(session.context)} · ${session.durationSeconds} sec',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up, color: theme.accentColor),
            onPressed: () { /* toggle audio */ },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Text(theme.label, style: TextStyle(
                color: theme.accentColor, fontSize: 32,
                fontWeight: FontWeight.w800, letterSpacing: 3)),
            const SizedBox(height: 8),
            _GlowLine(color: theme.accentColor),
            const Spacer(),
            if (!isComplete)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  session.coachingLines[_lineIndex],
                  key: ValueKey(_lineIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _lineIndex == 0 ? 22 : 18,
                    fontWeight: _lineIndex == 0
                        ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            if (isComplete) ...[
              Text(session.completionMessage, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Session complete.', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 16)),
            ],
            const Spacer(),
            _GlowLine(color: theme.accentColor),
            const SizedBox(height: 24),
            if (isComplete) ...[
              _OutlineBtn(label: 'Play Again',
                  color: theme.accentColor, onTap: _startPlayback),
              const SizedBox(height: 12),
              _OutlineBtn(
                  label: 'Back to ${theme.label[0]}${theme.label.substring(1).toLowerCase()}',
                  color: theme.accentColor,
                  onTap: () => Navigator.pop(context)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _toggleFavorite,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      session.isFavorite ? Icons.star : Icons.star_border,
                      color: Colors.white60, size: 18),
                    const SizedBox(width: 6),
                    const Text('Add to favorites',
                        style: TextStyle(color: Colors.white60, fontSize: 15)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
```

---

## 8. MindCoachRepository — Static Seed Data

`lib/features/mind_coach/data/mind_coach_repository.dart`

For the deterministic content-selection system (480+ scripts), wire this to Firestore. For prototyping, seed locally.

```dart
class MindCoachRepository {
  static PillarSessions getSessionsFor(PillarType type) {
    switch (type) {
      case PillarType.focus:      return _focusSessions();
      case PillarType.confidence: return _confidenceSessions();
      case PillarType.control:    return _controlSessions();
    }
  }

  static PillarSessions _focusSessions() => PillarSessions(
    beforeRound: SessionModel(
      id: 'focus_before_round_001',
      pillar: PillarType.focus,
      context: SessionContext.beforeRound,
      durationSeconds: 20,
      shortLabel: 'Slow it down. Center yourself.',
      coachingLines: [
        'Stand tall and settle your weight.',
        'Let your arms hang loose.',
        'Take a deep breath in.',
      ],
      completionMessage: 'You are ready.',
    ),
    // afterRound, duringRound[] defined similarly ...
  );
}

class PillarSessions {
  final SessionModel beforeRound;
  final SessionModel afterRound;
  final List<SessionModel> duringRound; // 4 entries
  const PillarSessions({
    required this.beforeRound,
    required this.afterRound,
    required this.duringRound,
  });
}
```

---

## 9. Routing

```dart
// lib/app/app_router.dart  (inside onGenerateRoute)

case '/mindcoach':
  return MaterialPageRoute(
    builder: (_) => const PillarSelectionScreen());

case '/mindcoach/pillar':
  final type = settings.arguments as PillarType;
  return MaterialPageRoute(
    builder: (_) => PillarDetailScreen(pillarType: type));

case '/mindcoach/session':
  final session = settings.arguments as SessionModel;
  return MaterialPageRoute(
    builder: (_) => SessionScreen(session: session));
```

---

## 10. Folder Structure

```
lib/
  features/
    mind_coach/
      constants/
        pillar_themes.dart              // kPillarThemes map
      data/
        mind_coach_repository.dart      // static seed + Firestore hook
      models/
        pillar_type.dart                // PillarType enum + PillarTheme
        session_context.dart            // SessionContext + DuringRoundContext enums
        session_model.dart              // SessionModel
        pillar_sessions.dart            // PillarSessions grouped model
      screens/
        pillar_selection_screen.dart
        pillar_detail_screen.dart
        session_screen.dart
      widgets/
        pillar_button.dart
        session_row.dart
        during_round_overlay.dart
        _glow_line.dart                 // shared glow line widget
        _outline_btn.dart               // shared outline button
```

---

## 11. Cursor Instructions — Build Order

> Open Cursor with the full FoCoCo project in context. Paste the relevant section with `@codebase` active.

### Step-by-Step Build Order

| Step | Cursor Prompt Target | Files |
|---|---|---|
| 1 | Create `PillarType` enum and `PillarTheme` constants (§2) | `pillar_type.dart` · `pillar_themes.dart` |
| 2 | Create `SessionContext`, `DuringRoundContext`, `SessionModel` (§3) | `session_context.dart` · `session_model.dart` |
| 3 | Create `PillarButton` + `_GlowLine` widgets (§4) | `pillar_button.dart` · `_glow_line.dart` |
| 4 | Create `PillarSelectionScreen` (§4) | `pillar_selection_screen.dart` |
| 5 | Create `SessionRow` widget (§5) | `session_row.dart` |
| 6 | Create `PillarDetailScreen` (§5) | `pillar_detail_screen.dart` |
| 7 | Create `DuringRoundOverlay` modal (§6) | `during_round_overlay.dart` |
| 8 | Create `SessionScreen` with state machine (§7) | `session_screen.dart` |
| 9 | Wire `MindCoachRepository` with seed data (§8) | `mind_coach_repository.dart` |
| 10 | Add routes to `AppRouter` (§9) | `app_router.dart` |

### Key Cursor Context Tags

```
// Include in every prompt:
@pillar_type.dart
@pillar_themes.dart
@mind_coach_repository.dart
// + the file you're actively building

// Example prompt:
// "Using @pillar_themes.dart and @session_model.dart,
//  build PillarDetailScreen as described in the implementation guide.
//  Match the dark textured background, accent glow lines per pillar,
//  and 4-section layout with SessionRow widgets."
```
