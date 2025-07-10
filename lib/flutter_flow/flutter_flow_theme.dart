// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';

SharedPreferences? _prefs;

/// Enhanced FoCoCo Theme System
/// Inspired by: Strava, Oura Ring, Headspace, Calm, Revolut, Duolingo
abstract class FlutterFlowTheme {
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

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

  // Core Colors
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
  // FOCOCO ENHANCED COLOR SYSTEM
  // ============================================================================

  // Golf & Performance Colors (Strava-inspired)
  late Color golfPrimary;
  late Color golfSecondary;
  late Color performanceGood;
  late Color performanceAverage;
  late Color performancePoor;
  late Color streakActive;
  late Color streakInactive;

  // Mental Wellness Colors (Oura Ring + Headspace inspired)
  late Color mentalWellness;
  late Color mentalFocus;
  late Color mentalCalm;
  late Color mentalEnergy;
  late Color mindfulnessPrimary;
  late Color mindfulnessSecondary;

  // Coaching & Learning Colors (Headspace + Duolingo inspired)
  late Color coachingPrimary;
  late Color coachingSecondary;
  late Color learningPath;
  late Color skillComplete;
  late Color skillInProgress;
  late Color skillLocked;
  late Color badgeGold;
  late Color badgeSilver;
  late Color badgeBronze;

  // Serene & Calm Colors (Calm-inspired)
  late Color serenePrimary;
  late Color sereneSecondary;
  late Color naturePrimary;
  late Color natureSecondary;
  late Color calmBackground;
  late Color calmAccent;

  // Professional & Premium Colors (Revolut-inspired)
  late Color professionalPrimary;
  late Color professionalSecondary;
  late Color premiumGold;
  late Color premiumSilver;
  late Color subscriptionActive;
  late Color subscriptionInactive;

  // AI & Insights Colors
  late Color aiPrimary;
  late Color aiSecondary;
  late Color aiAccent;
  late Color insightPositive;
  late Color insightNeutral;
  late Color insightNegative;
  late Color conversationUser;
  late Color conversationAI;

  // VARK Learning Style Colors
  late Color varkVisual;
  late Color varkAuditory;
  late Color varkReadWrite;
  late Color varkKinesthetic;

  // Gamification Colors
  late Color experiencePoints;
  late Color levelUp;
  late Color achievement;
  late Color leaderboard;
  late Color challenge;

  // Status & Feedback Colors
  late Color statusActive;
  late Color statusInactive;
  late Color statusPending;
  late Color statusComplete;
  late Color feedbackPositive;
  late Color feedbackNeutral;
  late Color feedbackNegative;

  // ============================================================================
  // DESIGN TOKENS
  // ============================================================================

  // Border Radius
  static const double borderRadiusXS = 4.0;
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  static const double borderRadiusXXL = 32.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationXS = 2.0;
  static const double elevationS = 4.0;
  static const double elevationM = 8.0;
  static const double elevationL = 16.0;
  static const double elevationXL = 24.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Component Sizes
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 52.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // ============================================================================
  // TYPOGRAPHY
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
  // ENHANCED GRADIENT SETS
  // ============================================================================

  LinearGradient get golfGradient => LinearGradient(
    colors: [golfPrimary, golfSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get mentalWellnessGradient => LinearGradient(
    colors: [mentalWellness, mentalFocus],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get coachingGradient => LinearGradient(
    colors: [coachingPrimary, coachingSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get sereneGradient => LinearGradient(
    colors: [serenePrimary, sereneSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get professionalGradient => LinearGradient(
    colors: [professionalPrimary, professionalSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get aiGradient => LinearGradient(
    colors: [aiPrimary, aiSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // SHADOW PRESETS
  // ============================================================================

  List<BoxShadow> get shadowXS => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  List<BoxShadow> get shadowS => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  List<BoxShadow> get shadowM => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  List<BoxShadow> get shadowL => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Enhanced Light Mode Theme
class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Core Colors
  late Color primary = const Color(0xFF0B4D2C);
  late Color secondary = const Color(0xFF2E8B57);
  late Color tertiary = const Color(0xFF6B46C1);
  late Color alternate = const Color(0xFFE0E3E7);
  late Color primaryText = const Color(0xFF1A1A1A);
  late Color secondaryText = const Color(0xFF6B7280);
  late Color primaryBackground = const Color(0xFFFFFFFF);
  late Color secondaryBackground = const Color(0xFFF8FAFC);
  late Color accent1 = const Color(0x4C0B4D2C);
  late Color accent2 = const Color(0x4C2E8B57);
  late Color accent3 = const Color(0x4C6B46C1);
  late Color accent4 = const Color(0xCCFFFFFF);
  late Color success = const Color(0xFF10B981);
  late Color warning = const Color(0xFFF59E0B);
  late Color error = const Color(0xFFEF4444);
  late Color info = const Color(0xFF3B82F6);

  // Golf & Performance Colors (Strava-inspired)
  late Color golfPrimary = const Color(0xFF0B4D2C);
  late Color golfSecondary = const Color(0xFF2E8B57);
  late Color performanceGood = const Color(0xFF10B981);
  late Color performanceAverage = const Color(0xFFF59E0B);
  late Color performancePoor = const Color(0xFFEF4444);
  late Color streakActive = const Color(0xFFFF6B35);
  late Color streakInactive = const Color(0xFF9CA3AF);

  // Mental Wellness Colors (Oura Ring + Headspace inspired)
  late Color mentalWellness = const Color(0xFF8B5CF6);
  late Color mentalFocus = const Color(0xFF6366F1);
  late Color mentalCalm = const Color(0xFF06B6D4);
  late Color mentalEnergy = const Color(0xFFF59E0B);
  late Color mindfulnessPrimary = const Color(0xFF7C3AED);
  late Color mindfulnessSecondary = const Color(0xFFA855F7);

  // Coaching & Learning Colors (Headspace + Duolingo inspired)
  late Color coachingPrimary = const Color(0xFF6B46C1);
  late Color coachingSecondary = const Color(0xFF8B5CF6);
  late Color learningPath = const Color(0xFF3B82F6);
  late Color skillComplete = const Color(0xFF10B981);
  late Color skillInProgress = const Color(0xFFF59E0B);
  late Color skillLocked = const Color(0xFF9CA3AF);
  late Color badgeGold = const Color(0xFFFFD700);
  late Color badgeSilver = const Color(0xFFC0C0C0);
  late Color badgeBronze = const Color(0xFFCD7F32);

  // Serene & Calm Colors (Calm-inspired)
  late Color serenePrimary = const Color(0xFF0EA5E9);
  late Color sereneSecondary = const Color(0xFF06B6D4);
  late Color naturePrimary = const Color(0xFF10B981);
  late Color natureSecondary = const Color(0xFF22C55E);
  late Color calmBackground = const Color(0xFFF0F9FF);
  late Color calmAccent = const Color(0xFFE0F2FE);

  // Professional & Premium Colors (Revolut-inspired)
  late Color professionalPrimary = const Color(0xFF1F2937);
  late Color professionalSecondary = const Color(0xFF374151);
  late Color premiumGold = const Color(0xFFFFD700);
  late Color premiumSilver = const Color(0xFFC0C0C0);
  late Color subscriptionActive = const Color(0xFF10B981);
  late Color subscriptionInactive = const Color(0xFF9CA3AF);

  // AI & Insights Colors
  late Color aiPrimary = const Color(0xFF6366F1);
  late Color aiSecondary = const Color(0xFF8B5CF6);
  late Color aiAccent = const Color(0xFFE0E7FF);
  late Color insightPositive = const Color(0xFF10B981);
  late Color insightNeutral = const Color(0xFF3B82F6);
  late Color insightNegative = const Color(0xFFEF4444);
  late Color conversationUser = const Color(0xFF3B82F6);
  late Color conversationAI = const Color(0xFF6366F1);

  // VARK Learning Style Colors
  late Color varkVisual = const Color(0xFFEC4899);
  late Color varkAuditory = const Color(0xFF8B5CF6);
  late Color varkReadWrite = const Color(0xFF10B981);
  late Color varkKinesthetic = const Color(0xFFF59E0B);

  // Gamification Colors
  late Color experiencePoints = const Color(0xFF8B5CF6);
  late Color levelUp = const Color(0xFFFFD700);
  late Color achievement = const Color(0xFFFF6B35);
  late Color leaderboard = const Color(0xFF3B82F6);
  late Color challenge = const Color(0xFFEF4444);

  // Status & Feedback Colors
  late Color statusActive = const Color(0xFF10B981);
  late Color statusInactive = const Color(0xFF9CA3AF);
  late Color statusPending = const Color(0xFFF59E0B);
  late Color statusComplete = const Color(0xFF10B981);
  late Color feedbackPositive = const Color(0xFF10B981);
  late Color feedbackNeutral = const Color(0xFF6B7280);
  late Color feedbackNegative = const Color(0xFFEF4444);
}

/// Enhanced Dark Mode Theme
class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;
  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;
  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  // Core Colors
  late Color primary = const Color(0xFF22C55E);
  late Color secondary = const Color(0xFF16A34A);
  late Color tertiary = const Color(0xFF8B5CF6);
  late Color alternate = const Color(0xFF374151);
  late Color primaryText = const Color(0xFFFFFFFF);
  late Color secondaryText = const Color(0xFF9CA3AF);
  late Color primaryBackground = const Color(0xFF111827);
  late Color secondaryBackground = const Color(0xFF1F2937);
  late Color accent1 = const Color(0x4C22C55E);
  late Color accent2 = const Color(0x4C16A34A);
  late Color accent3 = const Color(0x4C8B5CF6);
  late Color accent4 = const Color(0xB2374151);
  late Color success = const Color(0xFF10B981);
  late Color warning = const Color(0xFFF59E0B);
  late Color error = const Color(0xFFEF4444);
  late Color info = const Color(0xFF3B82F6);

  // Golf & Performance Colors (Strava-inspired)
  late Color golfPrimary = const Color(0xFF22C55E);
  late Color golfSecondary = const Color(0xFF16A34A);
  late Color performanceGood = const Color(0xFF10B981);
  late Color performanceAverage = const Color(0xFFF59E0B);
  late Color performancePoor = const Color(0xFFEF4444);
  late Color streakActive = const Color(0xFFFF6B35);
  late Color streakInactive = const Color(0xFF6B7280);

  // Mental Wellness Colors (Oura Ring + Headspace inspired)
  late Color mentalWellness = const Color(0xFF8B5CF6);
  late Color mentalFocus = const Color(0xFF6366F1);
  late Color mentalCalm = const Color(0xFF06B6D4);
  late Color mentalEnergy = const Color(0xFFF59E0B);
  late Color mindfulnessPrimary = const Color(0xFF7C3AED);
  late Color mindfulnessSecondary = const Color(0xFFA855F7);

  // Coaching & Learning Colors (Headspace + Duolingo inspired)
  late Color coachingPrimary = const Color(0xFF8B5CF6);
  late Color coachingSecondary = const Color(0xFFA855F7);
  late Color learningPath = const Color(0xFF3B82F6);
  late Color skillComplete = const Color(0xFF10B981);
  late Color skillInProgress = const Color(0xFFF59E0B);
  late Color skillLocked = const Color(0xFF6B7280);
  late Color badgeGold = const Color(0xFFFFD700);
  late Color badgeSilver = const Color(0xFFC0C0C0);
  late Color badgeBronze = const Color(0xFFCD7F32);

  // Serene & Calm Colors (Calm-inspired)
  late Color serenePrimary = const Color(0xFF0EA5E9);
  late Color sereneSecondary = const Color(0xFF06B6D4);
  late Color naturePrimary = const Color(0xFF10B981);
  late Color natureSecondary = const Color(0xFF22C55E);
  late Color calmBackground = const Color(0xFF1E293B);
  late Color calmAccent = const Color(0xFF334155);

  // Professional & Premium Colors (Revolut-inspired)
  late Color professionalPrimary = const Color(0xFF111827);
  late Color professionalSecondary = const Color(0xFF1F2937);
  late Color premiumGold = const Color(0xFFFFD700);
  late Color premiumSilver = const Color(0xFFC0C0C0);
  late Color subscriptionActive = const Color(0xFF10B981);
  late Color subscriptionInactive = const Color(0xFF6B7280);

  // AI & Insights Colors
  late Color aiPrimary = const Color(0xFF6366F1);
  late Color aiSecondary = const Color(0xFF8B5CF6);
  late Color aiAccent = const Color(0xFF312E81);
  late Color insightPositive = const Color(0xFF10B981);
  late Color insightNeutral = const Color(0xFF3B82F6);
  late Color insightNegative = const Color(0xFFEF4444);
  late Color conversationUser = const Color(0xFF3B82F6);
  late Color conversationAI = const Color(0xFF6366F1);

  // VARK Learning Style Colors
  late Color varkVisual = const Color(0xFFEC4899);
  late Color varkAuditory = const Color(0xFF8B5CF6);
  late Color varkReadWrite = const Color(0xFF10B981);
  late Color varkKinesthetic = const Color(0xFFF59E0B);

  // Gamification Colors
  late Color experiencePoints = const Color(0xFF8B5CF6);
  late Color levelUp = const Color(0xFFFFD700);
  late Color achievement = const Color(0xFFFF6B35);
  late Color leaderboard = const Color(0xFF3B82F6);
  late Color challenge = const Color(0xFFEF4444);

  // Status & Feedback Colors
  late Color statusActive = const Color(0xFF10B981);
  late Color statusInactive = const Color(0xFF6B7280);
  late Color statusPending = const Color(0xFFF59E0B);
  late Color statusComplete = const Color(0xFF10B981);
  late Color feedbackPositive = const Color(0xFF10B981);
  late Color feedbackNeutral = const Color(0xFF9CA3AF);
  late Color feedbackNegative = const Color(0xFFEF4444);
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
    double? lineHeight,
    List<Shadow>? shadows,
    String? package,
    required double height,
  }) {
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
            height: lineHeight,
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
            height: lineHeight,
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
