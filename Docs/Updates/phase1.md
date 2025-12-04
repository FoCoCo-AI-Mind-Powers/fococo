3. Onboarding – First-Time User Flow (Post-Splash) 
	•	Onboarding begins after Opening enhanced 
	•	Each onboarding screen is manually advanced (tap/swipe).
	•	Show clear indication of navigation (arrows / pagination).
	•	Background across all onboarding slides:
	•	Black background.
	•	Slow moving white shooting stars.

Slide 1 – Brand Intro
	•	Logo: Pinwheel + “FoCoCo” text below.
	•	Text: “Focus. Confidence. Control.”

Slide 2 – Positioning
	•	Text: “Where Mind and Performance Meet.”

Slide 3 – Value Proposition
	•	Bulleted copy (separate lines):
	•	“Personalized Routines”
	•	“Performance Tracking”
	•	“Real Progress”

Slide 4 – CTA
	•	Text: “Ready to Unlock Your Game?”

⸻

4. Age Verification (Slide 5 + Logic)

Slide 5 – Age + Consent Inputs
	•	Title: “Let’s Personalize Your Experience”
	•	Fields:
	•	Field 1: Date of birth input (DOB).
	•	Field 2: Checkbox: “I accept the Terms and Privacy Policy”
	•	Validation:
	•	Both DOB and checkbox must be completed before proceeding.

Age Outcomes
	1.	Under 13
	•	Show message:
	•	App is for 13+.
	•	To use, a parent/legal guardian must create the account.
	•	Provide one button: “EXIT APP”.
	•	Behavior:
	•	No account creation.
	•	No data stored.
	•	Close app.
	2.	Ages 13–17
	•	Show message about needing permission.
	•	Two checkboxes:
	•	Checkbox 1:
	•	Label: “I have permission from my parent or guardian to use this app.”
	•	If checked → allow proceed to VARK Test.
	•	Checkbox 2:
	•	Label: “I do not have permission from my parent or guardian to use this app.”
	•	If checked → no access; app closes; no data stored.
	3.	Age 18+
	•	If 18 or older:
	•	Go directly to VARK Test (next section).

⸻

5. VARK Learning Style Test (Slides 6–15)

General notes:
	•	There are 7 questions total.
	•	Each question has 4 options (A–D).
	•	Each option maps to one of VARK dimensions:
	•	V = Visual
	•	A = Aural
	•	R = Read/Write
	•	K = Kinesthetic
	•	Important: Questions/answers may appear scrambled; ensure that each answer option’s mapping is correctly wired per the answer key in the document (Q1–Q7 mapping).

Slide 6 – Intro
	•	Title: “We all Learn Differently.”
	•	Body:
	•	Explain that FoCoCo adapts to the user’s learning style for a personal and focused experience.

Slide 7 – Instructions
	•	Title: “Let’s get started.”
	•	Body:
	•	“7 quick questions to discover how you learn best.”
	•	“There are no right or wrong answers.”
	•	Button: “Begin” → moves to Q1.

Slides 8–14 – Q1 to Q7
	•	For each question:
	•	Show the question text (from doc).
	•	Four answer choices (A–D).
	•	Each choice must be mapped to V/A/R/K as in the answer key.
	•	Implementation:
	•	Track counts for V, A, R, K across all answers.
	•	At the end, determine the dominant learning style (highest count).
	•	If tie logic is needed, implement your own rule or fallback (doc only specifies primary result text).

Slide 15 – Result
	•	Text:
	•	“You’re a … [ANSWER] … Learner”
	•	[ANSWER] is one of:
	•	“Visual”, “Aural”, “Read/Write”, “Kinesthetic”
	•	Provide “Continue” button → moves to Goals screen.

⸻

6. Goals – Primary Objective (Slide 16)
	•	Title: “What’s Your Main Goal?”
	•	Body: “Choose the one that matters most to you right now.”
	•	Options (single-select only):
	•	“Improve consistency”
	•	“Build confidence under pressure”
	•	“Stay calm and focused”
	•	“Play to my full potential”
	•	“Something else (add later in notes)”
	•	Validation:
	•	Only one option can be active at a time.
	•	Button: “Continue” → goes to membership plans.

⸻

7. Membership Selection (Slide 17)
	•	Title: “Choose Your Membership”
	•	Body: “Get coaching that supports your game, on and off the course.”

Three tiers, each with monthly and yearly pricing and feature set. Make the UI a card selector or segmented options; highlight the “Plus” plan as “Most Popular”.

7.1 BASE Plan
	•	Pricing:
	•	Monthly: €1.99 / month
	•	Yearly: €16.99 / year (Save 30%)
	•	Target: Players wanting structure and tracking.
	•	Features (include as bullets / list in UI):
	•	Personalized learning with VARK profile.
	•	Core mind coach training routines.
	•	Golf round logging & journaling.
	•	Mind Power Index (MPI) with progress history.
	•	“… and more!” (can be a final bullet or short label).

7.2 PLUS Plan (Most Popular)
	•	Badge: “Most Popular”.
	•	Pricing:
	•	Monthly: €6.99 / month
	•	Yearly: €49.99 / year (Save 40%).
	•	Trial:
	•	14-day Free Trial of Plus, cancel anytime.
	•	Features (Plus = Base + extra):
	•	All Base features.
	•	Advanced AI Mind Coaching.
	•	Basic FoCoMap access.
	•	Hands-free golf shot logging (“Just Talk!”).
	•	Advanced insights & training modules.

7.3 PRIME Plan
	•	Pricing:
	•	Monthly: €13.99 / month.
	•	Yearly: €99.99 / year (Save 40%).
	•	Target: Serious golfers syncing mind + game with AI feedback.
	•	Features (Prime = Plus + extra):
	•	All Plus features.
	•	Personalized AI Mind Coach with deeper insights.
	•	Full FoCoMap suite: MindMap, ShotMap, SyncMap.
	•	Advanced shot data collection.
	•	Premium Mind & Game analysis, linked together.

CTA
	•	Global button under plan selection:
	•	Label: “Choose Plan and Start”.
	•	Behavior:
	•	Proceed to subscription / purchase flow depending on app store.
	•	On success, continue to Welcome slide.

⸻

8. Welcome Confirmation (Slide 18)
	•	Title: “Let’s Get Started.”
	•	Body:
	•	Thank user for joining FoCoCo.
	•	Confirm that the experience is tailored based on:
	•	Their learning style (VARK result).
	•	Their primary goal (from Goals screen).
	•	Mention building routines, tracking performance, and unlocking potential “one round at a time.”
	•	Button:
	•	Label: “Begin My Journey”.
	•	Action: Navigate to main Home Screen of the app.

⸻

9. Core Flow Overview (for implementation)

High-level first-time user flow:
	1.	App Launch:
	•	Splash → rotating logo animation (2x rotation, black background, star field).
	•	Text: “FoCoCo – Your Mind Powers the Game”.
	2.	Onboarding Slides (1–4):
	•	Brand intro, value prop, and CTA.
	3.	Age Gate (Slide 5):
	•	DOB + terms checkbox.
	•	Age logic:
	•	< 13 → exit (no data).
	•	13–17 → consent check → either proceed or exit/no data.
	•	18+ → proceed.
	4.	VARK Test (Slides 6–15):
	•	Intro → 7 questions → compute V/A/R/K → show learner type.
	5.	Goal Selection (Slide 16):
	•	Single choice goal.
	6.	Membership Selection (Slide 17):
	•	Choose Base, Plus (default highlight), or Prime.
	•	Handle trial + purchase.
	7.	Welcome Confirmation (Slide 18):
	•	Confirm tailoring → go to main Home.