import 'package:shared_preferences/shared_preferences.dart';

/// Local session flags (post-login tab, GPS toggle, etc.).
class AppSessionPrefsService {
  AppSessionPrefsService._();

  static const String postLoginTabKey = 'fococo_post_login_tab';
  static const String gpsEnabledKey = 'fococo_gps_enabled';

  static Future<void> setPostLoginTabFoCoCo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(postLoginTabKey, 'fococo');
  }

  static Future<String> postLoginTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(postLoginTabKey) ?? 'fococo';
  }

  static Future<bool> isGpsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(gpsEnabledKey) ?? false;
  }

  static Future<void> setGpsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(gpsEnabledKey, enabled);
  }
}
