import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '/services/cms_content_service.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  bool _isInitialized = false;

  // Default config values (will be replaced by Firebase Remote Config when available)
  final Map<String, dynamic> _defaultValues = {
    'appLiveAndroid': true,
    'appLiveiOS': true,
    'app_store_url': 'https://apps.apple.com/app/fococo',
    'play_store_url':
        'https://play.google.com/store/apps/details?id=com.fococo.app',
    'rate_app_enabled': true,
    'min_sessions_for_rating': 5,
    'force_update_android': false,
    'force_update_ios': false,
    'maintenance_mode': false,
    'maintenance_message':
        'FoCoCo is currently undergoing maintenance. Please try again later.',
  };

  /// Initialize Remote Config (temporary implementation)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await CmsContentService.instance.initialize();
      _defaultValues['maintenance_mode'] =
          CmsContentService.instance.maintenanceMode;
      _defaultValues['maintenance_message'] =
          CmsContentService.instance.maintenanceMessage;
      _isInitialized = true;
      debugPrint('✅ Remote Config initialized (CMS app_settings merged)');
    } catch (e) {
      debugPrint('❌ Remote Config initialization failed: $e');
      _isInitialized = true; // Set to true to prevent repeated attempts
    }
  }

  /// Check if app is live for current platform
  bool get isAppLive {
    if (!_isInitialized) return true; // Default to true if not initialized

    if (Platform.isAndroid) {
      return _defaultValues['appLiveAndroid'] as bool;
    } else if (Platform.isIOS) {
      return _defaultValues['appLiveiOS'] as bool;
    }
    return true;
  }

  /// Check if Android app is live
  bool get isAndroidLive => _defaultValues['appLiveAndroid'] as bool;

  /// Check if iOS app is live
  bool get isiOSLive => _defaultValues['appLiveiOS'] as bool;

  /// Check if rating is enabled
  bool get isRateAppEnabled => _defaultValues['rate_app_enabled'] as bool;

  /// Get minimum sessions required before showing rating prompt
  int get minSessionsForRating =>
      _defaultValues['min_sessions_for_rating'] as int;

  /// Check if force update is required
  bool get isForceUpdateRequired {
    if (Platform.isAndroid) {
      return _defaultValues['force_update_android'] as bool;
    } else if (Platform.isIOS) {
      return _defaultValues['force_update_ios'] as bool;
    }
    return false;
  }

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode => _defaultValues['maintenance_mode'] as bool;

  /// Get maintenance message
  String get maintenanceMessage =>
      _defaultValues['maintenance_message'] as String;

  /// Get App Store URL
  String get appStoreUrl => _defaultValues['app_store_url'] as String;

  /// Get Play Store URL
  String get playStoreUrl => _defaultValues['play_store_url'] as String;

  /// Show rate app dialog or redirect to store
  Future<void> showRateApp() async {
    if (!isRateAppEnabled || !isAppLive) return;

    try {
      String storeUrl;
      if (Platform.isAndroid) {
        storeUrl = playStoreUrl;
      } else if (Platform.isIOS) {
        storeUrl = appStoreUrl;
      } else {
        debugPrint('❌ Unsupported platform for app rating');
        return;
      }

      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ Opened app store for rating');
      } else {
        debugPrint('❌ Cannot launch app store URL: $storeUrl');
      }
    } catch (e) {
      debugPrint('❌ Error opening app store: $e');
    }
  }

  /// Get current platform store URL
  String get currentPlatformStoreUrl {
    if (Platform.isAndroid) {
      return playStoreUrl;
    } else if (Platform.isIOS) {
      return appStoreUrl;
    }
    return '';
  }

  /// Manually refresh configuration
  Future<bool> refreshConfig() async {
    if (!_isInitialized) {
      await initialize();
      return true;
    }

    // For temporary implementation, always return true
    return true;
  }

  /// Get all current config values for debugging
  Map<String, dynamic> getAllConfigValues() {
    if (!_isInitialized) return {};

    return {
      'appLiveAndroid': isAndroidLive,
      'appLiveiOS': isiOSLive,
      'app_store_url': appStoreUrl,
      'play_store_url': playStoreUrl,
      'rate_app_enabled': isRateAppEnabled,
      'min_sessions_for_rating': minSessionsForRating,
      'force_update_android': _defaultValues['force_update_android'],
      'force_update_ios': _defaultValues['force_update_ios'],
      'maintenance_mode': isMaintenanceMode,
      'maintenance_message': maintenanceMessage,
    };
  }

  /// Dispose method for cleanup
  void dispose() {
    // Remote Config doesn't require explicit disposal
    _isInitialized = false;
  }
}
