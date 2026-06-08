import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';

/// Single source for metric / imperial preference (prefs + Firestore).
class UnitsPreferenceService {
  UnitsPreferenceService._();

  static const String prefsKey = 'fococo_units_preference';
  static const String metric = 'metric';
  static const String imperial = 'imperial';

  static final ValueNotifier<String> unitsNotifier =
      ValueNotifier<String>(metric);

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    var value = prefs.getString(prefsKey) ?? metric;
    if (loggedIn && currentUserUid.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUserUid)
            .get();
        final fromDoc = snap.data()?['appPreferences'];
        if (fromDoc is Map) {
          final units = fromDoc['preferredUnits'] as String?;
          if (units == metric || units == imperial) {
            value = units!;
            await prefs.setString(prefsKey, value);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('UnitsPreferenceService.load: $e');
        }
      }
    }
    unitsNotifier.value = value;
    return value;
  }

  static Future<void> setUnits(String value) async {
    final normalized =
        value.toLowerCase() == imperial ? imperial : metric;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, normalized);
    unitsNotifier.value = normalized;

    if (!loggedIn || currentUserUid.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .set({
        'appPreferences.preferredUnits': normalized,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UnitsPreferenceService.setUnits: $e');
      }
    }
  }

  /// System-context snippet for AI prompts.
  static Future<String> aiContextLine() async {
    final u = await load();
    if (u == imperial) {
      return 'User unit preference: Imperial. Use yards and Fahrenheit. '
          'Do not use metres unless the user asks.';
    }
    return 'User unit preference: Metric. Use metres and Celsius. '
        'Do not use yards unless the user asks.';
  }

  static bool get isMetric => unitsNotifier.value == metric;
}
