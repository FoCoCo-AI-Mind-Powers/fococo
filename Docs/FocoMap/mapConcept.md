# FoCoMap – Full Concept (v1.9.0)

**Project:** App1 – GOLF  
**Prepared by:** Dirk J. Delfortrie  
**Shared with:** Imad Bouirmane  
**Date:** Aug 5–6, 2025  
**Brand:** FoCoCo.ai — Focus. Confidence. Control.

---

## 1. Overview

FoCoMap is a **dual-purpose, GPS-based interactive map** that visualizes both **mental** and **technical** golf performance data.  
It consists of three primary layers:

1. **MindMap** – Mental performance visualization.
2. **ShotMap** – Technical/club performance visualization.
3. **SyncMap** – Combined mental + technical correlation view.

Base map: Google Maps (or equivalent), zoomable from **global** to **hole level**.  
Data: Voice-logged → NLP processed → Stored in **Firebase**.

---

## 2. Map Layers

### 2.1 MindMap – Mental Performance Layer
**Purpose:** Show mindset quality, cue usage, and recovery patterns.  
**Display:**
- Pins per course with **color codes**:  
  - 🟩 Green = Strong mindset (Focus, Confidence, Control)  
  - 🟨 Yellow = Neutral mindset  
  - 🟥 Red = Struggle round / loss of control
- **Tap pin → Popup card** with:
  - Course name
  - Avg mindset emoji
  - Best cue used
  - Recovery highlight
  - Last played date

---

### 2.2 ShotMap – Technical Performance Layer
**Purpose:** Display club usage, shot outcomes, and environmental conditions.  
**Display:**
- Pins with club icons.
- Color intensity/shape = performance or miss tendency.
- Hole-level zoom: Shot clusters.
- **Tap pin → Popup card** with:
  - Course + hole number
  - Club used
  - Wind condition
  - Cue usage
  - Shot trend (e.g., “3 misses short right”)
  - AI tip (e.g., “Try breath cue + 6i next time”)

---

### 2.3 SyncMap – Combined Layer
**Purpose:** Correlate mental & technical data for deeper coaching insights.  
**Display:**
- Pins with **mindset color + club icon overlay**.
- **Tap pin → Popup** with:
  - Mental rating
  - Technical result
  - Cue correlation
  - AI insight (e.g., “Confidence dips with Driver into headwind — 80% miss right”)

---

## 3. Voice Input & NLP Flow

### 3.1 Microphone Access
Floating FAB (🎤), context-aware:
- **Pre-round:** Intention, cue choice, mental prep.
- **Mid-round:** Hole-by-hole or shot-by-shot logging.
- **Post-round:** Summary.
- **Off-course:** Journaling/training notes.

---

### 3.2 Voice Input Examples
- **Mental-only:** “Felt calm on front nine, lost focus on 12, recovered with breathing.”
- **Technical-only:** “7 iron from 150 into headwind, missed short right.”
- **Mixed:** “Driver on hole 5, felt tense, pushed right, recovered with self-talk.”

---

### 3.3 NLP Parsing Logic
- **Mental → RoundLog:**  
  - Mindset state (Focus, Confidence, Control)  
  - Cue usage  
  - Recovery points
- **Technical → ShotLog:**  
  - Club used, distance, wind, shot shape/outcome

---

### 3.4 Data Save Rules
- Mental-only → RoundLog
- Technical-only → ShotLog
- Mixed → Both
- All tagged with: userID, date, roundID, coordinates

---

### 3.5 Confirmation & Feedback
- Visual ✅ + short animation
- Optional voice read-back
- Quick tap to confirm/edit

---

## 4. Filters & Toggles

**Global Filters:** Club, Cue Used, Weather, Recovery Zones, Course Type.  
**Layer Toggles:**
- MindMap → Recovery Zones
- ShotMap → Shot Shape / Miss Pattern
- SyncMap → Cue + Club Correlation

---

## 5. Deep Dive on Tap
- Full mental + technical logs
- AI-generated trends
- Actions: View in MindTrack / Download club report

---

## 6. Starting State & UX Goals
- Default zoom: Current location or most-played course
- Last 5 rounds pulse
- “Replay last round” quick action
- **UX Aim:** Fast, visual, pattern-driven insights

---

## 7. Developer / Tier Logic

### 7.1 Tier Access
| Feature                  | Junior | Base | Plus | Prime |
|--------------------------|--------|------|------|-------|
| Review Past Rounds       | ❌     | ✅   | ✅   | ✅   |
| Live Map Updates         | ❌     | ❌   | ✅   | ✅   |
| Technical Data Layer     | ❌     | ❌   | ❌   | ✅   |
| Combined SyncMap Layer   | ❌     | ❌   | ❌   | ✅   |
| GPS Mapping              | ❌     | ✅*  | ✅   | ✅   |

---

### 7.2 Layer Logic
- **MindMap:** Mental data only.
- **ShotMap:** Technical data only.
- **SyncMap:** Merge by GPS + time.

---

## 8. Firebase Data Structure

### 8.1 RoundLog
- userID, roundID, date, courseName, courseType, coordinates
- mindsetFocus / Confidence / Control
- bestCue, recoveryHoles, overallMindsetEmoji
- technicalSummary, aiRoundSummary

### 8.2 ShotLog
- userID, roundID, holeNumber, clubUsed
- distanceAttempted, shotShape, shotOutcome
- cueUsed, confidenceLevel, windCondition
- coordinates, aiShotInsight

### 8.3 AIInsights
- userID, roundID, insightType, title, description
- relatedClub, relatedCue, mapOverlayCoordinates

---

## 9. Developer Key Points
- Real-time map updates (Plus/Prime)
- Marker clustering on zoomed-out views
- Persistent layer toggle
- Integration with Performance Tab
- Mini FoCoMap previews in round cards
- Live vs Review mode handling