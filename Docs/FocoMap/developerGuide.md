# FoCoMap – Developer Implementation Checklist

## 1. Core Setup

- [ ] **Create Firebase Collections**
  - [ ] `RoundLog` (mental + technical summary fields)
  - [ ] `ShotLog` (per-shot technical details)
  - [ ] `AIInsights` (AI patterns & coaching overlays)

- [ ] **Indexing & Queries**
  - [ ] Create composite indexes for `roundID + date`, `userID + date`, and GPS-based queries.
  - [ ] Enable GeoPoint querying for map pin rendering.

- [ ] **Map Integration**
  - [ ] Integrate Google Maps widget in FlutterFlow with zoom (world → hole level).
  - [ ] Enable marker clustering when zoomed out.
  - [ ] Add custom pin icons for:
    - Mindset (Green, Yellow, Red)
    - Club types (Driver, Irons, Wedges, Putter)
    - Combined mindset + club overlay

---

## 2. Voice Input & NLP

- [ ] **Floating FAB Microphone**
  - [ ] Global FAB accessible from all screens.
  - [ ] Context-aware state:
    - Active round → Expect golf context
    - Off-course → Expect journaling/training context

- [ ] **Voice-to-Text Processing**
  - [ ] Integrate with Google ML Kit or OpenAI Whisper API.
  - [ ] Send transcription to NLP service (Gemini/OpenAI).

- [ ] **NLP Parsing Logic**
  - [ ] Detect and extract **mental fields** → Save to `RoundLog`.
  - [ ] Detect and extract **technical fields** → Save to `ShotLog`.
  - [ ] Mixed input → Split and save to both.
  - [ ] Auto-tag entries with:
    - userID
    - date
    - roundID (if active)
    - coordinates (if GPS enabled)

---

## 3. Map Layers

### MindMap
- [ ] Fetch data from `RoundLog`.
- [ ] Color pins based on mindset rating.
- [ ] Popup card fields:
  - Course name
  - Avg mindset emoji
  - Best cue
  - Recovery highlights
  - Last played date

### ShotMap
- [ ] Fetch data from `ShotLog`.
- [ ] Pin icons by club type.
- [ ] Shape/color intensity based on performance/miss pattern.
- [ ] Popup card fields:
  - Course + hole
  - Club used
  - Wind condition
  - Cue usage
  - Shot trend
  - AI tip

### SyncMap
- [ ] Join `RoundLog` + `ShotLog` by `roundID`.
- [ ] Combined pins (mindset color + club overlay).
- [ ] Popup card fields:
  - Mental rating
  - Technical result
  - Cue correlation
  - AI insight

---

## 4. Filters & Toggles

- [ ] **Global Filters** (apply to all layers):
  - Club
  - Cue Used
  - Weather Conditions
  - Recovery Zones
  - Course Type

- [ ] **Layer-Specific Toggles**:
  - MindMap → Show Recovery Zones
  - ShotMap → Show Shot Shape / Miss Pattern
  - SyncMap → Show Cue + Club Correlation

- [ ] Persist filter state between sessions.

---

## 5. Live Mode & Review Mode

- [ ] **Live Mode** (Plus & Prime tiers only)
  - Voice logs appear on map in real-time (no full refresh).
  - Auto-fetch new entries via Firestore snapshots.

- [ ] **Review Mode**
  - Fetch past rounds from Performance Tab.
  - Render markers with correct icons and GPS data.

---

## 6. Deep Dive Cards

- [ ] On marker tap → Show summary card:
  - Mindset logs (Focus, Confidence, Control)
  - Technical logs (clubs, outcomes, conditions)
  - AI patterns/trends
  - Action buttons:
    - “View full round in MindTrack”
    - “Download club performance report” (PDF/CSV)

---

## 7. UI & UX Requirements

- [ ] Persistent layer selector (MindMap / ShotMap / SyncMap).
- [ ] Marker clustering at high zoom levels.
- [ ] Mini FoCoMap preview in Performance Tab cards.
- [ ] Pulse animation on last 5 rounds’ pins.
- [ ] “Replay last round” action to view route, cues, and key shots.

---

## 8. AIInsights Overlay

- [ ] Pull `AIInsights` for patterns (e.g., “Confidence dips in headwind”).
- [ ] Render overlay lines or shapes (mapOverlayCoordinates).
- [ ] Link insights to relevant clubs/cues.

---

## 9. Tier-Based Access Control

- [ ] Hide certain layers for non-Prime users:
  - Junior: No map access.
  - Base: MindMap only (manual entries).
  - Plus: MindMap + Live mode.
  - Prime: All layers + full technical data.

---

## 10. Testing & QA

- [ ] Test voice parsing with mixed inputs.
- [ ] Verify GPS tagging accuracy.
- [ ] Check AI suggestions relevance.
- [ ] Test all filters & toggles across layers.
- [ ] Validate data sync speed in Live Mode.

---

## 11. Deployment Notes

- [ ] Secure API keys (Maps, NLP).
- [ ] Optimize Firestore reads with field masks.
- [ ] Ensure offline caching for recent map data.