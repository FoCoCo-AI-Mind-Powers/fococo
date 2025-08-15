FoCoCo App Concept

Overview

FoCoCo.ai – Focus. Confidence. Control. Mobile app empowering everyday golfers with mental performance coaching and data-driven insights.

Core Principles
	•	Scalability: Support 10K+ active users with cost-effective Firebase architecture.
	•	Performance: Native-like responsiveness via FlutterFlow.
	•	Security: Firebase Auth, granular Firestore rules, server-side IAP validation.
	•	Modularity: Clear separation of UI, business logic, and backend services.
	•	Extensibility: Flexible structure for future features and custom code.
	•	User-Centric: VARK-based personalization for content delivery.

User Roles
	•	BASE: Basic coaching modules, stat logging, AI insights (limited).
	•	PLUS: All BASE + advanced modules, trend graphs, deeper AI analysis.
	•	PRIME: All PLUS + premium content, unlimited AI insights, token system.

Technology Stack
	•	Frontend: FlutterFlow (Dart).
	•	Backend: Firebase (Auth, Firestore, Cloud Functions, Storage).
	•	AI: OpenAI API via Cloud Functions.
	•	IAP: Apple StoreKit & Google Play Billing.
	•	CI/CD: FlutterFlow builds, Firebase CLI deploys, optional Fastlane.

Navigation Structure
	•	Bottom Bar: Home, Log Round (FAB), Coach, Performance.
	•	Drawer: Profile, Settings, FAQ, Support, Privacy & Terms.
	•	Stack Nav: Push/pop detailed screens (auth flows, module detail).

Key User Flows
	1.	Onboarding & Auth
	•	Splash → Onboarding Carousel → Email/Google/Apple Sign-in → Profile Setup (handicap, VARK quiz) → Subscription Prompt.
	2.	Subscription Management
	•	Pricing screen → Native purchase → Cloud Function receipt validation → Success/Failure screen → Manage Subscription.
	3.	Golf Round Logging
	•	NewRound screen (stats + journal) → Save to Firestore → Trigger generateAIInsights → Round History → Round Detail with AI insights.
	4.	Mental Coaching
	•	Coach tab → VARK & tier filter → Module Detail (video/audio/text) → Mark complete → Journaling.
	5.	AI Insights
	•	Insights list → Detail view → Link to round/session.
	6.	Performance Analytics
	•	Charts: Handicap trend, stat averages, coaching streaks on Performance tab.
	7.	Profile & Settings
	•	Profile screen (VARK, photo, name) → Settings (notifications, GDPR tools, feedback).

UI Components
	•	CustomTextField, CustomButton, DataCard, ChartWidget, LoadingSpinner, AlertDialog
	•	VideoPlayer, AudioPlayer, ProgressBar, JournalEntryDisplay

Data Model Summary
	•	users: profile, VARK prefs, tier, subscription IDs, tokens.
	•	user_subscriptions: platform, status, period dates.
	•	golf_rounds: date, course, stats, notes, AI flag.
	•	mental_sessions: moduleId, completion, journal.
	•	coaching_modules: VARK tags, tier targets, content sections.
	•	ai_insights: source ref, content, recs, cost.
	•	app_settings: feature flags.

Integrations
	•	IAP: Server-side receipt verification (Apple/Google) via Cloud Functions.
	•	AI: OpenAI calls with prompt engineering, cost tracking.
	•	Push Notifications: FCM for insights & reminders.
	•	Analytics: Firebase Analytics for key events.

Future Enhancements
	•	GDPR/CCPA data export & deletion flows.
	•	Offline support (Firestore persistence & sync queue).
	•	Admin dashboard for user & content management.
	•	AI token pack purchase & feedback loop.
	•	Gamification: Mind Index, badges, goals & streaks.