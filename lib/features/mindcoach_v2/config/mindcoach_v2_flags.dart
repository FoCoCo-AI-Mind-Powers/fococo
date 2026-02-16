import 'package:flutter/foundation.dart';

class MindCoachV2Flags {
  MindCoachV2Flags._();

  /// Default ON as required by rebuild strategy.
  static const bool mindCoachV2Enabled =
      bool.fromEnvironment('MINDCOACH_V2_ENABLED', defaultValue: true);

  /// Legacy route remains hidden in production.
  static bool get allowLegacyRoute => kDebugMode;
}
