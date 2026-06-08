class AppFeatureFlags {
  const AppFeatureFlags._();

  /// Post-signup onboarding (brand slides, VARK, membership).
  static const bool onboardingEnabled = true;

  /// In-app VARK settings / retake UI outside onboarding.
  static const bool varkEnabled = false;
}
