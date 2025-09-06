import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Comprehensive biometric authentication service for FoCoCo
/// Handles Face ID, Touch ID, fingerprint, and PIN authentication
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Shared preferences keys
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricTypeKey = 'biometric_type';
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _subscriptionProtectionKey =
      'subscription_protection_enabled';
  static const String _paymentProtectionKey = 'payment_protection_enabled';

  /// Check if biometric authentication is available on device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Get primary biometric type name for display
  Future<String> getPrimaryBiometricName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) return 'Biometric Authentication';

    if (Platform.isIOS) {
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Touch ID';
      }
    } else if (Platform.isAndroid) {
      if (biometrics.contains(BiometricType.face)) {
        return 'Face Unlock';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      }
    }

    return 'Biometric Authentication';
  }

  /// Authenticate user with biometrics
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication is not available on this device',
          errorType: BiometricAuthError.notAvailable,
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          const IOSAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Settings',
            goToSettingsDescription:
                'Please set up your biometric authentication in Settings.',
            lockOut:
                'Biometric authentication is disabled. Please lock and unlock your screen to enable it.',
          ),
          const AndroidAuthMessages(
            cancelButton: 'Cancel',
            goToSettingsButton: 'Settings',
            goToSettingsDescription:
                'Please set up your biometric authentication in Settings.',
            biometricHint: 'Verify your identity',
            biometricNotRecognized: 'Biometric not recognized. Try again.',
            biometricRequiredTitle: 'Biometric Authentication Required',
            biometricSuccess: 'Biometric authentication successful',
            deviceCredentialsRequiredTitle: 'Device Credentials Required',
            deviceCredentialsSetupDescription:
                'Please set up device credentials in Settings.',
            signInTitle: 'Sign in to FoCoCo',
          ),
        ],
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
        ),
      );

      return BiometricAuthResult(
        success: didAuthenticate,
        error: didAuthenticate ? null : 'Authentication failed',
        errorType:
            didAuthenticate ? null : BiometricAuthError.authenticationFailed,
      );
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        error: 'Unexpected error: $e',
        errorType: BiometricAuthError.unknown,
      );
    }
  }

  /// Handle platform-specific exceptions
  BiometricAuthResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication is not available',
          errorType: BiometricAuthError.notAvailable,
        );
      case 'NotEnrolled':
        return BiometricAuthResult(
          success: false,
          error: 'No biometric credentials are enrolled',
          errorType: BiometricAuthError.notEnrolled,
        );
      case 'LockedOut':
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication is temporarily locked',
          errorType: BiometricAuthError.lockedOut,
        );
      case 'PermanentlyLockedOut':
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication is permanently locked',
          errorType: BiometricAuthError.permanentlyLockedOut,
        );
      case 'UserCancel':
        return BiometricAuthResult(
          success: false,
          error: 'User cancelled authentication',
          errorType: BiometricAuthError.userCancel,
        );
      case 'UserFallback':
        return BiometricAuthResult(
          success: false,
          error: 'User chose fallback authentication',
          errorType: BiometricAuthError.userFallback,
        );
      default:
        return BiometricAuthResult(
          success: false,
          error: 'Authentication error: ${e.message}',
          errorType: BiometricAuthError.unknown,
        );
    }
  }

  // Settings Management

  /// Check if biometric authentication is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);

    if (enabled) {
      // Store the primary biometric type
      final biometricName = await getPrimaryBiometricName();
      await prefs.setString(_biometricTypeKey, biometricName);
    }
  }

  /// Get stored biometric type name
  Future<String> getStoredBiometricType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricTypeKey) ?? 'Biometric Authentication';
  }

  /// Check if app lock is enabled
  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  /// Enable or disable app lock
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
  }

  /// Check if subscription management protection is enabled
  Future<bool> isSubscriptionProtectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_subscriptionProtectionKey) ?? false;
  }

  /// Enable or disable subscription protection
  Future<void> setSubscriptionProtectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionProtectionKey, enabled);
  }

  /// Check if payment protection is enabled
  Future<bool> isPaymentProtectionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paymentProtectionKey) ??
        true; // Default to true for security
  }

  /// Enable or disable payment protection
  Future<void> setPaymentProtectionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_paymentProtectionKey, enabled);
  }

  // Convenience Methods

  /// Authenticate for app access
  Future<BiometricAuthResult> authenticateForAppAccess() async {
    final isEnabled = await isAppLockEnabled();
    if (!isEnabled) {
      return BiometricAuthResult(success: true);
    }

    return await authenticate(
      reason: 'Unlock FoCoCo to access your mental coaching',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }

  /// Authenticate for subscription management
  Future<BiometricAuthResult> authenticateForSubscription() async {
    final isEnabled = await isSubscriptionProtectionEnabled();
    if (!isEnabled) {
      return BiometricAuthResult(success: true);
    }

    return await authenticate(
      reason: 'Verify your identity to manage your subscription',
      useErrorDialogs: true,
    );
  }

  /// Authenticate for payment operations
  Future<BiometricAuthResult> authenticateForPayment() async {
    final isEnabled = await isPaymentProtectionEnabled();
    if (!isEnabled) {
      return BiometricAuthResult(success: true);
    }

    return await authenticate(
      reason: 'Verify your identity to complete payment',
      useErrorDialogs: true,
    );
  }

  /// Reset all biometric settings
  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricEnabledKey);
    await prefs.remove(_biometricTypeKey);
    await prefs.remove(_appLockEnabledKey);
    await prefs.remove(_subscriptionProtectionKey);
    await prefs.remove(_paymentProtectionKey);
  }

  /// Authenticate with biometrics for login
  Future<String?> authenticateForLogin() async {
    try {
      // Check if biometric is enabled
      final bool isEnabled = await isBiometricEnabled();
      if (!isEnabled) return null;

      // Get the stored email (we'll use a simple approach for now)
      final prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('biometric_user_email');
      if (email == null) return null;

      // Authenticate
      final result = await authenticate(
        reason: 'Sign in to FoCoCo with biometric authentication',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      if (!result.success) return null;

      return email;
    } catch (e) {
      debugPrint('Error authenticating for login: $e');
      return null;
    }
  }

  /// Get biometric status info for display
  Future<Map<String, dynamic>> getBiometricStatus() async {
    final bool isAvailable = await isBiometricAvailable();
    final bool isEnabled = await isBiometricEnabled();
    final String biometricName = await getPrimaryBiometricName();
    final List<BiometricType> availableTypes = await getAvailableBiometrics();

    return {
      'isAvailable': isAvailable,
      'isEnabled': isEnabled,
      'biometricName': biometricName,
      'availableTypes': availableTypes.map((type) => type.name).toList(),
      'hasFingerprint': availableTypes.contains(BiometricType.fingerprint),
      'hasFace': availableTypes.contains(BiometricType.face),
      'hasIris': availableTypes.contains(BiometricType.iris),
    };
  }

  /// Enable biometric authentication for a user
  Future<bool> enableBiometricAuth(String userEmail) async {
    try {
      // First authenticate to confirm user identity
      final result = await authenticate(
        reason: 'Verify your identity to enable biometric authentication',
        useErrorDialogs: true,
      );

      if (!result.success) return false;

      // Save biometric settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      await prefs.setString('biometric_user_email', userEmail);

      return true;
    } catch (e) {
      debugPrint('Error enabling biometric auth: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<bool> disableBiometricAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      await prefs.remove('biometric_user_email');
      return true;
    } catch (e) {
      debugPrint('Error disabling biometric auth: $e');
      return false;
    }
  }

  /// Get the email associated with biometric authentication
  Future<String?> getBiometricUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('biometric_user_email');
    } catch (e) {
      debugPrint('Error getting biometric user email: $e');
      return null;
    }
  }
}

/// Result of biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final String? error;
  final BiometricAuthError? errorType;

  BiometricAuthResult({
    required this.success,
    this.error,
    this.errorType,
  });

  @override
  String toString() {
    return 'BiometricAuthResult(success: $success, error: $error, errorType: $errorType)';
  }
}

/// Types of biometric authentication errors
enum BiometricAuthError {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  userFallback,
  authenticationFailed,
  unknown,
}

/// Extension to get user-friendly error messages
extension BiometricAuthErrorExtension on BiometricAuthError {
  String get message {
    switch (this) {
      case BiometricAuthError.notAvailable:
        return 'Biometric authentication is not available on this device';
      case BiometricAuthError.notEnrolled:
        return 'No biometric credentials are set up. Please set up Face ID, Touch ID, or fingerprint in your device settings';
      case BiometricAuthError.lockedOut:
        return 'Biometric authentication is temporarily locked due to too many failed attempts';
      case BiometricAuthError.permanentlyLockedOut:
        return 'Biometric authentication is permanently locked. Please use your device passcode';
      case BiometricAuthError.userCancel:
        return 'Authentication was cancelled';
      case BiometricAuthError.userFallback:
        return 'User chose to use device passcode instead';
      case BiometricAuthError.authenticationFailed:
        return 'Authentication failed. Please try again';
      case BiometricAuthError.unknown:
        return 'An unknown error occurred during authentication';
    }
  }

  bool get isRecoverable {
    switch (this) {
      case BiometricAuthError.authenticationFailed:
      case BiometricAuthError.userCancel:
      case BiometricAuthError.userFallback:
        return true;
      case BiometricAuthError.notAvailable:
      case BiometricAuthError.notEnrolled:
      case BiometricAuthError.lockedOut:
      case BiometricAuthError.permanentlyLockedOut:
      case BiometricAuthError.unknown:
        return false;
    }
  }
}
