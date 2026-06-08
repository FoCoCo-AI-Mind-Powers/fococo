import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/structs/app_preferences_struct.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central haptic feedback gated on user preference.
class HapticService {
  HapticService._();

  static bool _enabledCache = true;
  static bool _loaded = false;

  static Future<void> refreshEnabled() async {
    if (!loggedIn || currentUserUid.isEmpty) {
      _enabledCache = true;
      _loaded = true;
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();
      final prefs = snap.data()?['appPreferences'];
      if (prefs is Map) {
        final struct = AppPreferencesStruct.fromMap(
          Map<String, dynamic>.from(prefs),
        );
        _enabledCache = struct.hapticFeedbackEnabled;
      }
    } catch (_) {
      _enabledCache = true;
    }
    _loaded = true;
  }

  static bool get isEnabled => _enabledCache;

  static Future<void> light() async {
    if (!_loaded) await refreshEnabled();
    if (!_enabledCache) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (!_loaded) await refreshEnabled();
    if (!_enabledCache) return;
    await HapticFeedback.mediumImpact();
  }

  static void setEnabled(bool value) {
    _enabledCache = value;
    _loaded = true;
  }
}
