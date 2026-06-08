import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class StartupIsolationConfig {
  const StartupIsolationConfig._();

  static const bool enableCrashlyticsCollection = kReleaseMode;
  static const bool bypassAuthBootstrap = false;
}

class BootPhaseLogger {
  const BootPhaseLogger._();

  static bool _crashlyticsConfigured = false;

  static Future<void> configureCrashlyticsCollection() async {
    if (!_supportsCrashlytics) {
      return;
    }

    final enabled = StartupIsolationConfig.enableCrashlyticsCollection;

    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(enabled);
      _crashlyticsConfigured = enabled;

      if (!enabled) {
        return;
      }

      final info = await PackageInfo.fromPlatform();
      await setCustomKey('app_version', info.version);
      await setCustomKey('build_number', info.buildNumber);
      await setCustomKey('package_name', info.packageName);
    } catch (error) {
      _crashlyticsConfigured = false;
      if (kDebugMode) {
        print('⚠️ Crashlytics configuration failed: $error');
      }
    }
  }

  static Future<void> record(String phase) async {
    final message = '[boot_phase] $phase';
    print(message);

    if (!_canUseCrashlytics) {
      return;
    }

    try {
      await FirebaseCrashlytics.instance.setCustomKey('boot_phase', phase);
      FirebaseCrashlytics.instance.log(message);
    } catch (error) {
      if (kDebugMode) {
        print('⚠️ Boot phase Crashlytics logging failed: $error');
      }
    }
  }

  static Future<void> setCustomKey(String key, Object value) async {
    if (!_canUseCrashlytics) {
      return;
    }

    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (error) {
      if (kDebugMode) {
        print('⚠️ Crashlytics custom key update failed: $error');
      }
    }
  }

  static Future<void> setCrashlyticsUserIdentifier(String identifier) async {
    if (!_canUseCrashlytics) {
      return;
    }

    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    } catch (error) {
      if (kDebugMode) {
        print('⚠️ Crashlytics user identifier update failed: $error');
      }
    }
  }

  static bool get crashlyticsEnabled =>
      _canUseCrashlytics && StartupIsolationConfig.enableCrashlyticsCollection;

  static bool get _supportsCrashlytics => !kIsWeb && Firebase.apps.isNotEmpty;

  static bool get _canUseCrashlytics =>
      _supportsCrashlytics &&
      StartupIsolationConfig.enableCrashlyticsCollection &&
      _crashlyticsConfigured;
}
