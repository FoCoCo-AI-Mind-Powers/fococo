// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';

SharedPreferences? _prefs;

/// Enhanced FoCoCo Theme System
/// Strava + Calm Inspired Design with FoCoCo Brand Colors
/// Brand Colors: #fea400 (Orange), #0a3669 (Navy), #017b3d (Green)
abstract class FlutterFlowTheme {
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  /// FoCoCo is dark-only; light / system themes are not offered.
  static ThemeMode get themeMode => ThemeMode.dark;

  static void saveThemeMode(ThemeMode mode) {
    _prefs?.setBool(kThemeModeKey, true);
  }

  static FlutterFlowTheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? DarkModeTheme()
        : LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Core Colors - FoCoCo Brand Colors
  late Color primary;
  late Color secondary;
  late Color tertiary;
  late Color alternate;
  late Color primaryText;
  late Color secondaryText;
  late Color primaryBackground;
  late Color secondaryBackground;
  late Color accent1;
  late Color accent2;
  late Color accent3;
  late Color accent4;
  late Color success;
  late Color warning;
  late Color error;
  late Color info;

  // ============================================================================
  // STRAVA-INSPIRED ACTIVITY & PERFORMANCE COLORS
  // ============================================================================

  // Activity Feed Colors (Strava-inspired)
  late Color activityPrimary;
  late Color activitySecondary;
  late Color activityBackground;
  late Color activityCardBackground;
  late Color activityHighlight;
  late Color activityDivider;

  // Performance & Stats Colors (Strava-inspired)
  late Color performanceExcellent;
  late Color performanceGood;
  late Color performanceAverage;
  late Color performancePoor;
  late Color performanceNeedsWork;
  late Color performanceBackground;
  late Color performanceChartLine;
  late Color performanceChartFill;

  // Gamification & Achievements (Strava-inspired)
  late Color achievementGold;
  late Color achievementSilver;
  late Color achievementBronze;
  late Color achievementPlatinum;
  late Color streakActive;
  late Color streakInactive;
  late Color streakFire;
  late Color personalRecord;
  late Color segmentKing;
  late Color leaderboardTop;
  late Color leaderboardActive;

  // Social & Community (Strava-inspired)
  late Color socialLike;
  late Color socialComment;
  late Color socialShare;
  late Color socialFollow;
  late Color socialActivity;
  late Color socialChallenge;

  // ============================================================================
  // CALM-INSPIRED WELLNESS & MINDFULNESS COLORS
  // ============================================================================

  // Serene & Calm Colors (Calm-inspired)
  late Color calmPrimary;
  late Color calmSecondary;
  late Color calmTertiary;
  late Color calmBackground;
  late Color calmCardBackground;
  late Color calmAccent;
  late Color calmMuted;
  late Color calmHighlight;

  // Nature & Tranquility (Calm-inspired)
  late Color naturePrimary;
  late Color natureSecondary;
  late Color natureTertiary;
  late Color natureForest;
  late Color natureOcean;
  late Color natureMountain;
  late Color natureSunset;
  late Color natureSky;

  // Mindfulness & Meditation (Calm-inspired)
  late Color mindfulnessPrimary;
  late Color mindfulnessSecondary;
  late Color mindfulnessTertiary;
  late Color meditationActive;
  late Color meditationInactive;
  late Color breathingActive;
  late Color breathingInactive;
  late Color focusSession;
  late Color relaxationSession;

  // Mental Wellness Spectrum (Calm-inspired)
  late Color mentalWellness;
  late Color mentalFocus;
  late Color mentalCalm;
  late Color mentalEnergy;
  late Color mentalBalance;
  late Color mentalClarity;
  late Color mentalStrength;
  late Color mentalPeace;

  // ============================================================================
  // FOCOCO GOLF & COACHING COLORS
  // ============================================================================

  // Golf & Performance Colors (Brand-aligned)
  late Color golfPrimary;
  late Color golfSecondary;
  late Color golfTertiary;
  late Color golfCourse;
  late Color golfFairway;
  late Color golfGreen;
  late Color golfSand;
  late Color golfWater;
  late Color golfRough;

  // Coaching & Learning Colors (Brand-aligned)
  late Color coachingPrimary;
  late Color coachingSecondary;
  late Color coachingTertiary;
  late Color learningPath;
  late Color learningProgress;
  late Color skillComplete;
  late Color skillInProgress;
  late Color skillLocked;
  late Color skillMastered;

  // AI & Insights Colors (Brand-integrated)
  late Color aiPrimary;
  late Color aiSecondary;
  late Color aiTertiary;
  late Color aiAccent;
  late Color insightPositive;
  late Color insightNeutral;
  late Color insightNegative;
  late Color insightBackground;
  late Color conversationUser;
  late Color conversationAI;
  late Color conversationBackground;

  // VARK Learning Style Colors (Brand-coordinated)
  late Color varkVisual;
  late Color varkAuditory;
  late Color varkReadWrite;
  late Color varkKinesthetic;
  late Color varkMultiModal;

  // Professional & Premium Colors (Brand-enhanced)
  late Color professionalPrimary;
  late Color professionalSecondary;
  late Color professionalTertiary;
  late Color premiumGold;
  late Color premiumSilver;
  late Color premiumBronze;
  late Color subscriptionActive;
  late Color subscriptionInactive;
  late Color subscriptionPending;

  // Status & Feedback Colors (Brand-harmonized)
  late Color statusActive;
  late Color statusInactive;
  late Color statusPending;
  late Color statusComplete;
  late Color statusCancelled;
  late Color feedbackPositive;
  late Color feedbackNeutral;
  late Color feedbackNegative;
  late Color feedbackBackground;

  // ============================================================================
  // ENHANCED DESIGN TOKENS - STRAVA + CALM INSPIRED
  // ============================================================================

  // Border Radius (Strava-inspired rounded corners)
  static const double borderRadiusXS = 4.0;
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  static const double borderRadiusXXL = 32.0;
  static const double borderRadiusCard = 16.0;
  static const double borderRadiusButton = 12.0;
  static const double borderRadiusInput = 8.0;

  // Spacing (Enhanced Calm-inspired breathing room with Strava energy)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingContent = 20.0;
  static const double spacingSection = 40.0; // More generous section spacing
  static const double spacingPage = 24.0; // Consistent page margins
  static const double spacingCard = 16.0; // Standard card padding

  // Elevation (Strava-inspired depth)
  static const double elevationNone = 0.0;
  static const double elevationXS = 1.0;
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;
  static const double elevationCard = 3.0;
  static const double elevationModal = 8.0;

  // Animation Durations (Smooth micro-interactions)
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationGentle = Duration(milliseconds: 800);
  static const Duration animationCalm = Duration(milliseconds: 1200);

  // Component Sizes (Strava-inspired sizing)
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 52.0;
  static const double buttonHeightXL = 60.0;
  static const double iconSizeXS = 12.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  static const double iconSizeXXL = 64.0;

  // Activity Feed Sizes (Strava-inspired)
  static const double activityCardHeight = 120.0;
  static const double activityImageSize = 80.0;
  static const double activityStatSize = 40.0;
  static const double activityAvatarSize = 40.0;

  // Coaching Module Sizes (Calm-inspired)
  static const double moduleCardHeight = 140.0;
  static const double moduleImageHeight = 200.0;
  static const double moduleProgressHeight = 6.0;
  static const double moduleIconSize = 56.0;

  // ============================================================================
  // TYPOGRAPHY SYSTEM - STRAVA + CALM INSPIRED
  // ============================================================================

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;
  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;
  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;
  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;
  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;
  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;
  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;
  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;
  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;
  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;
  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;
  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;
  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;
  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;
  bool get displayLargeIsCustom => typography.displayLargeIsCustom;
  TextStyle get displayLarge => typography.displayLarge;
  String get displayMediumFamily => typography.displayMediumFamily;
  bool get displayMediumIsCustom => typography.displayMediumIsCustom;
  TextStyle get displayMedium => typography.displayMedium;
  String get displaySmallFamily => typography.displaySmallFamily;
  bool get displaySmallIsCustom => typography.displaySmallIsCustom;
  TextStyle get displaySmall => typography.displaySmall;
  String get headlineLargeFamily => typography.headlineLargeFamily;
  bool get headlineLargeIsCustom => typography.headlineLargeIsCustom;
  TextStyle get headlineLarge => typography.headlineLarge;
  String get headlineMediumFamily => typography.headlineMediumFamily;
  bool get headlineMediumIsCustom => typography.headlineMediumIsCustom;
  TextStyle get headlineMedium => typography.headlineMedium;
  String get headlineSmallFamily => typography.headlineSmallFamily;
  bool get headlineSmallIsCustom => typography.headlineSmallIsCustom;
  TextStyle get headlineSmall => typography.headlineSmall;
  String get titleLargeFamily => typography.titleLargeFamily;
  bool get titleLargeIsCustom => typography.titleLargeIsCustom;
  TextStyle get titleLarge => typography.titleLarge;
  String get titleMediumFamily => typography.titleMediumFamily;
  bool get titleMediumIsCustom => typography.titleMediumIsCustom;
  TextStyle get titleMedium => typography.titleMedium;
  String get titleSmallFamily => typography.titleSmallFamily;
  bool get titleSmallIsCustom => typography.titleSmallIsCustom;
  TextStyle get titleSmall => typography.titleSmall;
  String get labelLargeFamily => typography.labelLargeFamily;
  bool get labelLargeIsCustom => typography.labelLargeIsCustom;
  TextStyle get labelLarge => typography.labelLarge;
  String get labelMediumFamily => typography.labelMediumFamily;
  bool get labelMediumIsCustom => typography.labelMediumIsCustom;
  TextStyle get labelMedium => typography.labelMedium;
  String get labelSmallFamily => typography.labelSmallFamily;
  bool get labelSmallIsCustom => typography.labelSmallIsCustom;
  TextStyle get labelSmall => typography.labelSmall;
  String get bodyLargeFamily => typography.bodyLargeFamily;
  bool get bodyLargeIsCustom => typography.bodyLargeIsCustom;
  TextStyle get bodyLarge => typography.bodyLarge;
  String get bodyMediumFamily => typography.bodyMediumFamily;
  bool get bodyMediumIsCustom => typography.bodyMediumIsCustom;
  TextStyle get bodyMedium => typography.bodyMedium;
  String get bodySmallFamily => typography.bodySmallFamily;
  bool get bodySmallIsCustom => typography.bodySmallIsCustom;
  TextStyle get bodySmall => typography.bodySmall;

  Typography get typography => ThemeTypography(this);

  // ============================================================================
  // STRAVA + CALM INSPIRED GRADIENT SYSTEM
  // ============================================================================

  // Activity Performance Gradients (Strava-inspired)
  LinearGradient get activityGradient => LinearGradient(
        colors: [activityPrimary, activitySecondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get performanceGradient => LinearGradient(
        colors: [performanceExcellent, performanceGood, performanceAverage],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.5, 1.0],
      );

  LinearGradient get achievementGradient => LinearGradient(
        colors: [achievementGold, achievementSilver, achievementBronze],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  // Calm & Mindfulness Gradients (Calm-inspired)
  LinearGradient get calmGradient => LinearGradient(
        colors: [calmPrimary, calmSecondary, calmTertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  LinearGradient get mindfulnessGradient => LinearGradient(
        colors: [mindfulnessPrimary, mindfulnessSecondary, mindfulnessTertiary],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.5, 1.0],
      );

  LinearGradient get natureGradient => LinearGradient(
        colors: [naturePrimary, natureSecondary, natureTertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  // Primary Brand Gradients (FoCoCo Brand)
  LinearGradient get primaryBrandGradient => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryBrandGradient => LinearGradient(
        colors: [secondary, tertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get tertiaryBrandGradient => LinearGradient(
        colors: [tertiary, primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get fullBrandGradient => LinearGradient(
        colors: [primary, secondary, tertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  // Golf & Coaching Gradients
  LinearGradient get golfGradient => LinearGradient(
        colors: [golfPrimary, golfSecondary, golfTertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  LinearGradient get coachingGradient => LinearGradient(
        colors: [coachingPrimary, coachingSecondary, coachingTertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  // AI & Insights Gradients
  LinearGradient get aiGradient => LinearGradient(
        colors: [aiPrimary, aiSecondary, aiTertiary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  // Animated Background Gradient
  LinearGradient get animatedBackgroundGradient => LinearGradient(
        colors: [
          primaryBackground.withValues(alpha: 0.95),
          secondaryBackground.withValues(alpha: 0.98),
          primaryBackground.withValues(alpha: 0.95),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      );

  // ============================================================================
  // STRAVA + CALM INSPIRED SHADOWS
  // ============================================================================

  // Activity Card Shadow (Strava-inspired)
  BoxShadow get activityCardShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 8.0,
        offset: const Offset(0, 2),
      );

  // Coaching Module Shadow (Calm-inspired)
  BoxShadow get coachingModuleShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12.0,
        offset: const Offset(0, 4),
      );

  // Performance Card Shadow (Strava-inspired)
  BoxShadow get performanceCardShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 10.0,
        offset: const Offset(0, 3),
      );

  // Floating Action Button Shadow (Enhanced)
  BoxShadow get fabShadow => BoxShadow(
        color: primary.withValues(alpha: 0.3),
        blurRadius: 16.0,
        offset: const Offset(0, 6),
      );

  // Modal Shadow (Calm-inspired)
  BoxShadow get modalShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 20.0,
        offset: const Offset(0, 8),
      );

  // ============================================================================
  // GLASSMORPHISM DESIGN SYSTEM COLORS & EFFECTS
  // ============================================================================

  // Glass Material Colors
  late Color glassBackground;
  late Color glassTint;
  late Color glassBorder;
  late Color glassHighlight;
  late Color glassShadow;

  // 3D Card Effects
  late Color card3DLight;
  late Color card3DShadow;
  late Color card3DHighlight;
  late Color cardHoverTint;
  late Color cardPressTint;

  // Enhanced Glassmorphism Gradients
  LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          glassTint.withValues(alpha: 0.25),
          glassTint.withValues(alpha: 0.10),
          glassTint.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  LinearGradient get glass3DGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          card3DLight.withValues(alpha: 0.3),
          glassTint.withValues(alpha: 0.15),
          card3DShadow.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  LinearGradient get glassCardGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glassTint.withValues(alpha: 0.2),
          glassTint.withValues(alpha: 0.1),
          glassTint.withValues(alpha: 0.05),
        ],
        stops: const [0.0, 0.6, 1.0],
      );

  // Glass Navigation Gradient
  LinearGradient get glassNavGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryBackground.withValues(alpha: 0.9),
          primaryBackground.withValues(alpha: 0.7),
          primaryBackground.withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  // Enhanced Glass Shadows for 3D Effect
  List<BoxShadow> get glass3DShadows => [
        // Main shadow
        BoxShadow(
          color: glassShadow.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        // Highlight shadow (top-left)
        BoxShadow(
          color: glassHighlight.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(-2, -2),
          spreadRadius: 0,
        ),
        // Depth shadow (bottom-right)
        BoxShadow(
          color: glassShadow.withValues(alpha: 0.1),
          blurRadius: 15,
          offset: const Offset(4, 4),
          spreadRadius: 0,
        ),
      ];

  List<BoxShadow> get glassCardShadows => [
        BoxShadow(
          color: glassShadow.withValues(alpha: 0.15),
          blurRadius: 15,
          offset: const Offset(0, 5),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: glassHighlight.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(-1, -1),
          spreadRadius: 0,
        ),
      ];

  List<BoxShadow> get glassHoverShadows => [
        BoxShadow(
          color: glassShadow.withValues(alpha: 0.25),
          blurRadius: 25,
          offset: const Offset(0, 12),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: primary.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get color based on performance score (0-100)
  Color getPerformanceColor(double score) {
    if (score >= 90) return performanceExcellent;
    if (score >= 80) return performanceGood;
    if (score >= 70) return performanceAverage;
    if (score >= 60) return performancePoor;
    return performanceNeedsWork;
  }

  /// Get achievement color based on tier
  Color getAchievementColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return achievementPlatinum;
      case 'gold':
        return achievementGold;
      case 'silver':
        return achievementSilver;
      case 'bronze':
        return achievementBronze;
      default:
        return achievementBronze;
    }
  }

  /// Get VARK learning style color
  Color getVarkColor(String style) {
    switch (style.toLowerCase()) {
      case 'visual':
        return varkVisual;
      case 'auditory':
      case 'aural':
        return varkAuditory;
      case 'readwrite':
      case 'read/write':
        return varkReadWrite;
      case 'kinesthetic':
        return varkKinesthetic;
      default:
        return varkMultiModal;
    }
  }

  /// Get mindfulness session color
  Color getMindfulnessColor(String sessionType) {
    switch (sessionType.toLowerCase()) {
      case 'meditation':
        return meditationActive;
      case 'breathing':
        return breathingActive;
      case 'focus':
        return focusSession;
      case 'relaxation':
        return relaxationSession;
      default:
        return mindfulnessPrimary;
    }
  }

  /// Get coaching module color based on progress
  Color getCoachingProgressColor(double progress) {
    if (progress >= 1.0) return skillComplete;
    if (progress >= 0.8) return skillMastered;
    if (progress > 0.0) return skillInProgress;
    return skillLocked;
  }

  /// Get subscription tier color
  Color getSubscriptionColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'prime':
        return premiumGold;
      case 'plus':
        return premiumSilver;
      case 'base':
        return premiumBronze;
      default:
        return subscriptionInactive;
    }
  }
}

/// Enhanced Light Mode Theme - FoCoCo Brand Colors with Strava + Calm Inspiration
class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Core Colors - FoCoCo Brand Colors (Light Mode) - Enhanced for Calm × Strava
  late Color primary = const Color(0xFFFEA400); // #fea400 - Orange/Gold
  late Color secondary = const Color(0xFF0A3669); // #0a3669 - Navy Blue
  late Color tertiary = const Color(0xFF017B3D); // #017b3d - Forest Green
  late Color alternate =
      const Color(0xFFF1F5F9); // Softer neutral for calm aesthetic
  late Color primaryText =
      const Color(0xFF0F172A); // Deeper contrast for better readability
  late Color secondaryText =
      const Color(0xFF475569); // Improved contrast while maintaining harmony
  late Color primaryBackground = const Color(0xFFFFFFFF);
  late Color secondaryBackground =
      const Color(0xFFFAFBFC); // Warmer, more inviting background
  late Color accent1 = const Color(0x4CFEA400);
  late Color accent2 = const Color(0x4C0A3669);
  late Color accent3 = const Color(0x4C017B3D);
  late Color accent4 = const Color(0xB2E5E7EB);
  late Color success = const Color(0xFF017B3D); // Brand green
  late Color warning = const Color(0xFFFEA400); // Brand orange
  late Color error = const Color(0xFFDC2626);
  late Color info = const Color(0xFF0A3669); // Brand blue

  // ============================================================================
  // STRAVA-INSPIRED ACTIVITY & PERFORMANCE COLORS (Light Mode)
  // ============================================================================

  // Activity Feed Colors (Strava-inspired Light)
  late Color activityPrimary = const Color(0xFFFEA400); // Brand orange
  late Color activitySecondary = const Color(0xFF0A3669); // Brand navy
  late Color activityBackground = const Color(0xFFFFFBF5); // Light orange tint
  late Color activityCardBackground = const Color(0xFFFFFFFF);
  late Color activityHighlight = const Color(0xFFFEA400); // Brand orange
  late Color activityDivider = const Color(0xFFE5E7EB);

  // Performance & Stats Colors (Strava-inspired Light)
  late Color performanceExcellent = const Color(0xFF017B3D); // Brand green
  late Color performanceGood = const Color(0xFF059669); // Lighter green
  late Color performanceAverage = const Color(0xFFFEA400); // Brand orange
  late Color performancePoor = const Color(0xFFEA580C); // Orange-red
  late Color performanceNeedsWork = const Color(0xFFDC2626); // Red
  late Color performanceBackground = const Color(0xFFF9FAFB);
  late Color performanceChartLine = const Color(0xFFFEA400); // Brand orange
  late Color performanceChartFill =
      const Color(0x4CFEA400); // Transparent orange

  // Gamification & Achievements (Strava-inspired Light)
  late Color achievementGold = const Color(0xFFFEA400); // Brand orange
  late Color achievementSilver = const Color(0xFF9CA3AF);
  late Color achievementBronze = const Color(0xFFCD7F32);
  late Color achievementPlatinum = const Color(0xFF6366F1);
  late Color streakActive = const Color(0xFFFEA400); // Brand orange
  late Color streakInactive = const Color(0xFF9CA3AF);
  late Color streakFire = const Color(0xFFEA580C); // Fire orange
  late Color personalRecord = const Color(0xFF017B3D); // Brand green
  late Color segmentKing = const Color(0xFF0A3669); // Brand navy
  late Color leaderboardTop = const Color(0xFFFEA400); // Brand orange
  late Color leaderboardActive = const Color(0xFF017B3D); // Brand green

  // Social & Community (Strava-inspired Light)
  late Color socialLike = const Color(0xFFEF4444); // Red heart
  late Color socialComment = const Color(0xFF0A3669); // Brand navy
  late Color socialShare = const Color(0xFF017B3D); // Brand green
  late Color socialFollow = const Color(0xFFFEA400); // Brand orange
  late Color socialActivity = const Color(0xFF6366F1); // Purple
  late Color socialChallenge = const Color(0xFFEA580C); // Challenge orange

  // ============================================================================
  // CALM-INSPIRED WELLNESS & MINDFULNESS COLORS (Light Mode)
  // ============================================================================

  // Serene & Calm Colors (Calm-inspired Light)
  late Color calmPrimary = const Color(0xFF0369A1); // Calm blue
  late Color calmSecondary = const Color(0xFF0891B2); // Cyan
  late Color calmTertiary = const Color(0xFF0D9488); // Teal
  late Color calmBackground = const Color(0xFFF0F9FF); // Light blue tint
  late Color calmCardBackground = const Color(0xFFFFFFFF);
  late Color calmAccent = const Color(0xFFE0F2FE); // Light blue
  late Color calmMuted = const Color(0xFF94A3B8); // Muted blue-gray
  late Color calmHighlight = const Color(0xFF0369A1); // Calm blue

  // Nature & Tranquility (Calm-inspired Light)
  late Color naturePrimary = const Color(0xFF017B3D); // Brand green
  late Color natureSecondary = const Color(0xFF059669); // Forest green
  late Color natureTertiary = const Color(0xFF10B981); // Emerald
  late Color natureForest = const Color(0xFF065F46); // Dark forest
  late Color natureOcean = const Color(0xFF0369A1); // Ocean blue
  late Color natureMountain = const Color(0xFF6B7280); // Mountain gray
  late Color natureSunset = const Color(0xFFFEA400); // Brand orange
  late Color natureSky = const Color(0xFF0EA5E9); // Sky blue

  // Mindfulness & Meditation (Calm-inspired Light)
  late Color mindfulnessPrimary = const Color(0xFF0369A1); // Calm blue
  late Color mindfulnessSecondary = const Color(0xFF0891B2); // Cyan
  late Color mindfulnessTertiary = const Color(0xFF0D9488); // Teal
  late Color meditationActive = const Color(0xFF7C3AED); // Meditation purple
  late Color meditationInactive = const Color(0xFFA78BFA); // Light purple
  late Color breathingActive = const Color(0xFF0D9488); // Breathing teal
  late Color breathingInactive = const Color(0xFF5EEAD4); // Light teal
  late Color focusSession = const Color(0xFF0369A1); // Focus blue
  late Color relaxationSession = const Color(0xFF059669); // Relaxation green

  // Mental Wellness Spectrum (Calm-inspired Light)
  late Color mentalWellness = const Color(0xFF0369A1); // Wellness blue
  late Color mentalFocus = const Color(0xFF0A3669); // Brand navy
  late Color mentalCalm = const Color(0xFF0D9488); // Calm teal
  late Color mentalEnergy = const Color(0xFFFEA400); // Brand orange
  late Color mentalBalance = const Color(0xFF059669); // Balance green
  late Color mentalClarity = const Color(0xFF0891B2); // Clarity cyan
  late Color mentalStrength = const Color(0xFF017B3D); // Brand green
  late Color mentalPeace = const Color(0xFF5EEAD4); // Peace light teal

  // ============================================================================
  // FOCOCO GOLF & COACHING COLORS (Light Mode)
  // ============================================================================

  // Golf & Performance Colors (Brand-aligned Light)
  late Color golfPrimary = const Color(0xFF017B3D); // Brand green
  late Color golfSecondary = const Color(0xFF059669); // Forest green
  late Color golfTertiary = const Color(0xFF10B981); // Emerald
  late Color golfCourse = const Color(0xFF065F46); // Course green
  late Color golfFairway = const Color(0xFF10B981); // Fairway green
  late Color golfGreen = const Color(0xFF017B3D); // Brand green
  late Color golfSand = const Color(0xFFF59E0B); // Sand bunker
  late Color golfWater = const Color(0xFF0369A1); // Water hazard
  late Color golfRough = const Color(0xFF374151); // Rough gray

  // Coaching & Learning Colors (Brand-aligned Light)
  late Color coachingPrimary = const Color(0xFF0A3669); // Brand navy
  late Color coachingSecondary = const Color(0xFF1E40AF); // Lighter navy
  late Color coachingTertiary = const Color(0xFF3B82F6); // Blue
  late Color learningPath = const Color(0xFF0A3669); // Brand navy
  late Color learningProgress = const Color(0xFFFEA400); // Brand orange
  late Color skillComplete = const Color(0xFF017B3D); // Brand green
  late Color skillInProgress = const Color(0xFFFEA400); // Brand orange
  late Color skillLocked = const Color(0xFF9CA3AF); // Locked gray
  late Color skillMastered = const Color(0xFF0A3669); // Brand navy

  // AI & Insights Colors (Brand-integrated Light)
  late Color aiPrimary = const Color(0xFF0A3669); // Brand navy
  late Color aiSecondary = const Color(0xFF1E40AF); // Lighter navy
  late Color aiTertiary = const Color(0xFF3B82F6); // Blue
  late Color aiAccent = const Color(0xFF6366F1); // Purple accent
  late Color insightPositive = const Color(0xFF017B3D); // Brand green
  late Color insightNeutral = const Color(0xFF0A3669); // Brand navy
  late Color insightNegative = const Color(0xFFDC2626); // Red
  late Color insightBackground = const Color(0xFFF0F9FF); // Light blue
  late Color conversationUser = const Color(0xFF0A3669); // Brand navy
  late Color conversationAI = const Color(0xFF1E40AF); // Lighter navy
  late Color conversationBackground = const Color(0xFFF8FAFC);

  // VARK Learning Style Colors (Brand-coordinated Light)
  late Color varkVisual = const Color(0xFFEC4899); // Visual pink
  late Color varkAuditory = const Color(0xFF0A3669); // Brand navy
  late Color varkReadWrite = const Color(0xFF017B3D); // Brand green
  late Color varkKinesthetic = const Color(0xFFFEA400); // Brand orange
  late Color varkMultiModal = const Color(0xFF6366F1); // Multi-modal purple

  // Professional & Premium Colors (Brand-enhanced Light)
  late Color professionalPrimary = const Color(0xFF111827);
  late Color professionalSecondary = const Color(0xFF1F2937);
  late Color professionalTertiary = const Color(0xFF374151);
  late Color premiumGold = const Color(0xFFFEA400); // Brand orange
  late Color premiumSilver = const Color(0xFF9CA3AF);
  late Color premiumBronze = const Color(0xFFCD7F32);
  late Color subscriptionActive = const Color(0xFF017B3D); // Brand green
  late Color subscriptionInactive = const Color(0xFF9CA3AF);
  late Color subscriptionPending = const Color(0xFFFEA400); // Brand orange

  // Status & Feedback Colors (Brand-harmonized Light)
  late Color statusActive = const Color(0xFF017B3D); // Brand green
  late Color statusInactive = const Color(0xFF9CA3AF);
  late Color statusPending = const Color(0xFFFEA400); // Brand orange
  late Color statusComplete = const Color(0xFF017B3D); // Brand green
  late Color statusCancelled = const Color(0xFFDC2626); // Red
  late Color feedbackPositive = const Color(0xFF017B3D); // Brand green
  late Color feedbackNeutral = const Color(0xFF6B7280);
  late Color feedbackNegative = const Color(0xFFDC2626); // Red
  late Color feedbackBackground = const Color(0xFFF9FAFB);

  // Glassmorphism Colors (Light Mode)
  late Color glassBackground = const Color(0xFFFFFFFF); // Pure white base
  late Color glassTint = const Color(0xFFFFFFFF); // White tint
  late Color glassBorder = const Color(0xFFE5E7EB); // Light border
  late Color glassHighlight = const Color(0xFFFFFFFF); // White highlight
  late Color glassShadow = const Color(0xFF000000); // Black shadow

  // 3D Card Effects (Light Mode)
  late Color card3DLight = const Color(0xFFFFFFFF); // Highlight
  late Color card3DShadow = const Color(0xFF64748B); // Depth shadow
  late Color card3DHighlight = const Color(0xFFFEA400); // Brand highlight
  late Color cardHoverTint = const Color(0xFFFEA400); // Hover tint
  late Color cardPressTint = const Color(0xFF0A3669); // Press tint
}

/// Enhanced Dark Mode Theme - FoCoCo Brand Colors with Strava + Calm Inspiration
class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Core Colors - FoCoCo Brand Colors (Dark Mode)
  late Color primary = const Color(0xFFFEA400); // #fea400 - Orange/Gold
  late Color secondary = const Color(0xFF1E40AF); // Lighter version of #0a3669
  late Color tertiary = const Color(0xFF22C55E); // Lighter version of #017b3d
  late Color alternate = const Color(0xFF374151);
  late Color primaryText = const Color(0xFFFFFFFF); // White for contrast
  late Color secondaryText =
      const Color(0xFF94A3B8); // Brand-tinted light gray for better harmony
  late Color primaryBackground = const Color(0xFF111827);
  late Color secondaryBackground = const Color(0xFF1F2937);
  late Color accent1 = const Color(0x4CFEA400);
  late Color accent2 = const Color(0x4C1E40AF);
  late Color accent3 = const Color(0x4C22C55E);
  late Color accent4 = const Color(0xB2374151);
  late Color success = const Color(0xFF22C55E); // Lighter brand green
  late Color warning = const Color(0xFFFEA400); // Brand orange
  late Color error = const Color(0xFFEF4444);
  late Color info = const Color(0xFF1E40AF); // Lighter brand blue

  // ============================================================================
  // STRAVA-INSPIRED ACTIVITY & PERFORMANCE COLORS (Dark Mode)
  // ============================================================================

  // Activity Feed Colors (Strava-inspired Dark)
  late Color activityPrimary = const Color(0xFFFEA400); // Brand orange
  late Color activitySecondary = const Color(0xFF1E40AF); // Lighter navy
  late Color activityBackground = const Color(0xFF1F2937); // Dark background
  late Color activityCardBackground = const Color(0xFF374151);
  late Color activityHighlight = const Color(0xFFFEA400); // Brand orange
  late Color activityDivider = const Color(0xFF4B5563);

  // Performance & Stats Colors (Strava-inspired Dark)
  late Color performanceExcellent = const Color(0xFF22C55E); // Lighter green
  late Color performanceGood = const Color(0xFF10B981); // Emerald
  late Color performanceAverage = const Color(0xFFFEA400); // Brand orange
  late Color performancePoor = const Color(0xFFF59E0B); // Amber
  late Color performanceNeedsWork = const Color(0xFFEF4444); // Red
  late Color performanceBackground = const Color(0xFF1F2937);
  late Color performanceChartLine = const Color(0xFFFEA400); // Brand orange
  late Color performanceChartFill =
      const Color(0x4CFEA400); // Transparent orange

  // Gamification & Achievements (Strava-inspired Dark)
  late Color achievementGold = const Color(0xFFFEA400); // Brand orange
  late Color achievementSilver = const Color(0xFFC0C0C0); // Silver
  late Color achievementBronze = const Color(0xFFCD7F32); // Bronze
  late Color achievementPlatinum = const Color(0xFF8B5CF6); // Purple
  late Color streakActive = const Color(0xFFFEA400); // Brand orange
  late Color streakInactive = const Color(0xFF6B7280); // Gray
  late Color streakFire = const Color(0xFFF59E0B); // Fire orange
  late Color personalRecord = const Color(0xFF22C55E); // Lighter green
  late Color segmentKing = const Color(0xFF1E40AF); // Lighter navy
  late Color leaderboardTop = const Color(0xFFFEA400); // Brand orange
  late Color leaderboardActive = const Color(0xFF22C55E); // Lighter green

  // Social & Community (Strava-inspired Dark)
  late Color socialLike = const Color(0xFFF87171); // Light red
  late Color socialComment = const Color(0xFF1E40AF); // Lighter navy
  late Color socialShare = const Color(0xFF22C55E); // Lighter green
  late Color socialFollow = const Color(0xFFFEA400); // Brand orange
  late Color socialActivity = const Color(0xFF8B5CF6); // Purple
  late Color socialChallenge = const Color(0xFFF59E0B); // Challenge orange

  // ============================================================================
  // CALM-INSPIRED WELLNESS & MINDFULNESS COLORS (Dark Mode)
  // ============================================================================

  // Serene & Calm Colors (Calm-inspired Dark)
  late Color calmPrimary = const Color(0xFF0EA5E9); // Light blue
  late Color calmSecondary = const Color(0xFF06B6D4); // Cyan
  late Color calmTertiary = const Color(0xFF14B8A6); // Teal
  late Color calmBackground = const Color(0xFF1E293B); // Dark blue tint
  late Color calmCardBackground = const Color(0xFF334155);
  late Color calmAccent = const Color(0xFF475569); // Blue-gray
  late Color calmMuted = const Color(0xFF64748B); // Muted blue-gray
  late Color calmHighlight = const Color(0xFF0EA5E9); // Light blue

  // Nature & Tranquility (Calm-inspired Dark)
  late Color naturePrimary = const Color(0xFF22C55E); // Lighter green
  late Color natureSecondary = const Color(0xFF10B981); // Emerald
  late Color natureTertiary = const Color(0xFF059669); // Forest green
  late Color natureForest = const Color(0xFF047857); // Dark forest
  late Color natureOcean = const Color(0xFF0EA5E9); // Ocean blue
  late Color natureMountain = const Color(0xFF6B7280); // Mountain gray
  late Color natureSunset = const Color(0xFFFEA400); // Brand orange
  late Color natureSky = const Color(0xFF0EA5E9); // Sky blue

  // Mindfulness & Meditation (Calm-inspired Dark)
  late Color mindfulnessPrimary = const Color(0xFF0EA5E9); // Light blue
  late Color mindfulnessSecondary = const Color(0xFF06B6D4); // Cyan
  late Color mindfulnessTertiary = const Color(0xFF14B8A6); // Teal
  late Color meditationActive = const Color(0xFF8B5CF6); // Purple
  late Color meditationInactive = const Color(0xFFA78BFA); // Light purple
  late Color breathingActive = const Color(0xFF14B8A6); // Teal
  late Color breathingInactive = const Color(0xFF5EEAD4); // Light teal
  late Color focusSession = const Color(0xFF0EA5E9); // Blue
  late Color relaxationSession = const Color(0xFF10B981); // Green

  // Mental Wellness Spectrum (Calm-inspired Dark)
  late Color mentalWellness = const Color(0xFF0EA5E9); // Wellness blue
  late Color mentalFocus = const Color(0xFF1E40AF); // Lighter navy
  late Color mentalCalm = const Color(0xFF14B8A6); // Teal
  late Color mentalEnergy = const Color(0xFFFEA400); // Brand orange
  late Color mentalBalance = const Color(0xFF10B981); // Balance green
  late Color mentalClarity = const Color(0xFF06B6D4); // Clarity cyan
  late Color mentalStrength = const Color(0xFF22C55E); // Lighter green
  late Color mentalPeace = const Color(0xFF5EEAD4); // Peace light teal

  // ============================================================================
  // MISSING PROPERTIES FOR BACKWARD COMPATIBILITY
  // ============================================================================

  // Shadow Properties
  BoxShadow get shadowL => BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      );

  // Badge Colors
  Color get badgeGold => const Color(0xFFFFD700);
  Color get badgeSilver => const Color(0xFFC0C0C0);
  Color get badgeBronze => const Color(0xFFCD7F32);

  // Professional Gradient
  LinearGradient get professionalGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary,
          secondary,
        ],
      );

  // ============================================================================
  // FOCOCO GOLF & COACHING COLORS (Dark Mode)
  // ============================================================================

  // Golf & Performance Colors (Brand-aligned Dark)
  late Color golfPrimary = const Color(0xFF22C55E); // Lighter green
  late Color golfSecondary = const Color(0xFF10B981); // Emerald
  late Color golfTertiary = const Color(0xFF059669); // Forest green
  late Color golfCourse = const Color(0xFF047857); // Dark course
  late Color golfFairway = const Color(0xFF10B981); // Fairway green
  late Color golfGreen = const Color(0xFF22C55E); // Lighter green
  late Color golfSand = const Color(0xFFF59E0B); // Sand bunker
  late Color golfWater = const Color(0xFF0EA5E9); // Water hazard
  late Color golfRough = const Color(0xFF6B7280); // Rough gray

  // Coaching & Learning Colors (Brand-aligned Dark)
  late Color coachingPrimary = const Color(0xFF1E40AF); // Lighter navy
  late Color coachingSecondary = const Color(0xFF3B82F6); // Blue
  late Color coachingTertiary = const Color(0xFF60A5FA); // Light blue
  late Color learningPath = const Color(0xFF1E40AF); // Lighter navy
  late Color learningProgress = const Color(0xFFFEA400); // Brand orange
  late Color skillComplete = const Color(0xFF22C55E); // Lighter green
  late Color skillInProgress = const Color(0xFFFEA400); // Brand orange
  late Color skillLocked = const Color(0xFF6B7280); // Locked gray
  late Color skillMastered = const Color(0xFF1E40AF); // Lighter navy

  // AI & Insights Colors (Brand-integrated Dark)
  late Color aiPrimary = const Color(0xFF1E40AF); // Lighter navy
  late Color aiSecondary = const Color(0xFF3B82F6); // Blue
  late Color aiTertiary = const Color(0xFF60A5FA); // Light blue
  late Color aiAccent = const Color(0xFF8B5CF6); // Purple accent
  late Color insightPositive = const Color(0xFF22C55E); // Lighter green
  late Color insightNeutral = const Color(0xFF1E40AF); // Lighter navy
  late Color insightNegative = const Color(0xFFEF4444); // Red
  late Color insightBackground = const Color(0xFF1E293B); // Dark blue
  late Color conversationUser = const Color(0xFF1E40AF); // Lighter navy
  late Color conversationAI = const Color(0xFF3B82F6); // Blue
  late Color conversationBackground = const Color(0xFF1F2937);

  // VARK Learning Style Colors (Brand-coordinated Dark)
  late Color varkVisual = const Color(0xFFF472B6); // Light pink
  late Color varkAuditory = const Color(0xFF1E40AF); // Lighter navy
  late Color varkReadWrite = const Color(0xFF22C55E); // Lighter green
  late Color varkKinesthetic = const Color(0xFFFEA400); // Brand orange
  late Color varkMultiModal = const Color(0xFF8B5CF6); // Multi-modal purple

  // Professional & Premium Colors (Brand-enhanced Dark)
  late Color professionalPrimary = const Color(0xFF111827);
  late Color professionalSecondary = const Color(0xFF1F2937);
  late Color professionalTertiary = const Color(0xFF374151);
  late Color premiumGold = const Color(0xFFFEA400); // Brand orange
  late Color premiumSilver = const Color(0xFFC0C0C0);
  late Color premiumBronze = const Color(0xFFCD7F32);
  late Color subscriptionActive = const Color(0xFF22C55E); // Lighter green
  late Color subscriptionInactive = const Color(0xFF6B7280);
  late Color subscriptionPending = const Color(0xFFFEA400); // Brand orange

  // Status & Feedback Colors (Brand-harmonized Dark)
  late Color statusActive = const Color(0xFF22C55E); // Lighter green
  late Color statusInactive = const Color(0xFF6B7280);
  late Color statusPending = const Color(0xFFFEA400); // Brand orange
  late Color statusComplete = const Color(0xFF22C55E); // Lighter green
  late Color statusCancelled = const Color(0xFFEF4444); // Red
  late Color feedbackPositive = const Color(0xFF22C55E); // Lighter green
  late Color feedbackNeutral = const Color(0xFF9CA3AF);
  late Color feedbackNegative = const Color(0xFFEF4444); // Red
  late Color feedbackBackground = const Color(0xFF1F2937);

  // Glassmorphism Colors (Dark Mode)
  late Color glassBackground = const Color(0xFF111827); // Dark base
  late Color glassTint = const Color(0xFF1F2937); // Dark tint
  late Color glassBorder = const Color(0xFF374151); // Dark border
  late Color glassHighlight = const Color(0xFF4B5563); // Light highlight
  late Color glassShadow = const Color(0xFF000000); // Black shadow

  // 3D Card Effects (Dark Mode)
  late Color card3DLight = const Color(0xFF4B5563); // Light highlight
  late Color card3DShadow = const Color(0xFF000000); // Deep shadow
  late Color card3DHighlight = const Color(0xFFFEA400); // Brand highlight
  late Color cardHoverTint = const Color(0xFFFEA400); // Hover tint
  late Color cardPressTint = const Color(0xFF1E40AF); // Press tint
}

/// Enhanced Typography System
abstract class Typography {
  String get displayLargeFamily;
  bool get displayLargeIsCustom;
  TextStyle get displayLarge;
  String get displayMediumFamily;
  bool get displayMediumIsCustom;
  TextStyle get displayMedium;
  String get displaySmallFamily;
  bool get displaySmallIsCustom;
  TextStyle get displaySmall;
  String get headlineLargeFamily;
  bool get headlineLargeIsCustom;
  TextStyle get headlineLarge;
  String get headlineMediumFamily;
  bool get headlineMediumIsCustom;
  TextStyle get headlineMedium;
  String get headlineSmallFamily;
  bool get headlineSmallIsCustom;
  TextStyle get headlineSmall;
  String get titleLargeFamily;
  bool get titleLargeIsCustom;
  TextStyle get titleLarge;
  String get titleMediumFamily;
  bool get titleMediumIsCustom;
  TextStyle get titleMedium;
  String get titleSmallFamily;
  bool get titleSmallIsCustom;
  TextStyle get titleSmall;
  String get labelLargeFamily;
  bool get labelLargeIsCustom;
  TextStyle get labelLarge;
  String get labelMediumFamily;
  bool get labelMediumIsCustom;
  TextStyle get labelMedium;
  String get labelSmallFamily;
  bool get labelSmallIsCustom;
  TextStyle get labelSmall;
  String get bodyLargeFamily;
  bool get bodyLargeIsCustom;
  TextStyle get bodyLarge;
  String get bodyMediumFamily;
  bool get bodyMediumIsCustom;
  TextStyle get bodyMedium;
  String get bodySmallFamily;
  bool get bodySmallIsCustom;
  TextStyle get bodySmall;
}

/// Enhanced Theme Typography
class ThemeTypography extends Typography {
  ThemeTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'Montserrat';
  bool get displayLargeIsCustom => false;
  TextStyle get displayLarge => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 64.0,
        letterSpacing: -0.02,
      );
  String get displayMediumFamily => 'Montserrat';
  bool get displayMediumIsCustom => false;
  TextStyle get displayMedium => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 44.0,
        letterSpacing: -0.02,
      );
  String get displaySmallFamily => 'Montserrat';
  bool get displaySmallIsCustom => false;
  TextStyle get displaySmall => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 36.0,
        letterSpacing: -0.02,
      );
  String get headlineLargeFamily => 'Montserrat';
  bool get headlineLargeIsCustom => false;
  TextStyle get headlineLarge => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 32.0,
        letterSpacing: -0.01,
      );
  String get headlineMediumFamily => 'Montserrat';
  bool get headlineMediumIsCustom => false;
  TextStyle get headlineMedium => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 28.0,
        letterSpacing: -0.01,
      );
  String get headlineSmallFamily => 'Montserrat';
  bool get headlineSmallIsCustom => false;
  TextStyle get headlineSmall => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 24.0,
        letterSpacing: -0.01,
      );
  String get titleLargeFamily => 'Montserrat';
  bool get titleLargeIsCustom => false;
  TextStyle get titleLarge => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
        letterSpacing: -0.005,
      );
  String get titleMediumFamily => 'Montserrat';
  bool get titleMediumIsCustom => false;
  TextStyle get titleMedium => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 18.0,
        letterSpacing: -0.005,
      );
  String get titleSmallFamily => 'Montserrat';
  bool get titleSmallIsCustom => false;
  TextStyle get titleSmall => GoogleFonts.montserrat(
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
        letterSpacing: -0.005,
      );
  String get labelLargeFamily => 'Inter';
  bool get labelLargeIsCustom => false;
  TextStyle get labelLarge => GoogleFonts.inter(
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
        letterSpacing: 0.01,
      );
  String get labelMediumFamily => 'Inter';
  bool get labelMediumIsCustom => false;
  TextStyle get labelMedium => GoogleFonts.inter(
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        letterSpacing: 0.01,
      );
  String get labelSmallFamily => 'Inter';
  bool get labelSmallIsCustom => false;
  TextStyle get labelSmall => GoogleFonts.inter(
        color: theme.secondaryText,
        fontWeight: FontWeight.w500,
        fontSize: 12.0,
        letterSpacing: 0.01,
      );
  String get bodyLargeFamily => 'Inter';
  bool get bodyLargeIsCustom => false;
  TextStyle get bodyLarge => GoogleFonts.inter(
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        letterSpacing: 0.005,
        height: 1.5,
      );
  String get bodyMediumFamily => 'Inter';
  bool get bodyMediumIsCustom => false;
  TextStyle get bodyMedium => GoogleFonts.inter(
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
        letterSpacing: 0.005,
        height: 1.5,
      );
  String get bodySmallFamily => 'Inter';
  bool get bodySmallIsCustom => false;
  TextStyle get bodySmall => GoogleFonts.inter(
        color: theme.primaryText,
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
        letterSpacing: 0.005,
        height: 1.5,
      );
}

/// Enhanced Text Style Extensions
extension TextStyleHelper on TextStyle {
  TextStyle override({
    TextStyle? font,
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = false,
    TextDecoration? decoration,
    Color? decorationColor,
    double? lineHeight,
    /// Same as [lineHeight] — sets [TextStyle.height] (line-height multiplier).
    double? height,
    List<Shadow>? shadows,
    String? package,
  }) {
    final lineHeightValue = lineHeight ?? height;
    if (useGoogleFonts && fontFamily != null) {
      font = GoogleFonts.getFont(fontFamily,
          fontWeight: fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? this.fontStyle);
    }

    return font != null
        ? font.copyWith(
            color: color ?? this.color,
            fontSize: fontSize ?? this.fontSize,
            letterSpacing: letterSpacing ?? this.letterSpacing,
            fontWeight: fontWeight ?? this.fontWeight,
            fontStyle: fontStyle ?? this.fontStyle,
            decoration: decoration,
            decorationColor: decorationColor,
            height: lineHeightValue,
            shadows: shadows,
          )
        : copyWith(
            fontFamily: fontFamily,
            package: package,
            color: color,
            fontSize: fontSize,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            decorationColor: decorationColor,
            height: lineHeightValue,
            shadows: shadows,
          );
  }
}

/// FoCoCo-specific UI Helper Extensions
extension FoCoCoThemeExtensions on FlutterFlowTheme {
  /// Get color based on performance score
  Color getPerformanceColor(double score) {
    if (score >= 0.8) return performanceGood;
    if (score >= 0.6) return performanceAverage;
    return performancePoor;
  }

  /// Get VARK learning style color
  Color getVarkColor(String varkStyle) {
    switch (varkStyle.toLowerCase()) {
      case 'visual':
        return varkVisual;
      case 'auditory':
        return varkAuditory;
      case 'readwrite':
      case 'read-write':
        return varkReadWrite;
      case 'kinesthetic':
        return varkKinesthetic;
      default:
        return primaryText;
    }
  }

  /// Get subscription tier color
  Color getSubscriptionTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
      case 'prime':
        return premiumGold;
      case 'plus':
        return premiumSilver;
      case 'base':
      default:
        return secondaryText;
    }
  }

  /// Get AI insight sentiment color
  Color getInsightSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return insightPositive;
      case 'negative':
        return insightNegative;
      case 'neutral':
      default:
        return insightNeutral;
    }
  }
}
