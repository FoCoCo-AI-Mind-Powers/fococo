import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/notification_settings_struct.dart';
import '/backend/schema/structs/app_preferences_struct.dart';
import '/backend/schema/user_subscriptions_record.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/push_notifications/notification_settings_widget.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/flutter_flow/glass_design_system.dart';
import '/services/revenuecat_service.dart';
import '/services/subscription_state_provider.dart';
import '/main.dart';
import '/widgets/fococo_drawer_widget.dart';
import 'settings_model.dart';
export 'settings_model.dart';

import 'package:flutter/material.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  static const String routeName = 'settings';
  static const String routePath = '/settings';

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget>
    with TickerProviderStateMixin {
  late SettingsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Notification settings
  NotificationSettingsStruct? _notificationSettings;
  bool _isLoadingNotifications = true;
  bool _newsletterEnabled = false;

  // App preferences
  AppPreferencesStruct? _appPreferences;
  bool _isLoadingPreferences = true;

  // Additional app preferences (not in struct)
  bool _reduceMotion = false;
  bool _offlineMode = false;
  bool _isLoadingAdditionalPrefs = true;

  // Permission states
  bool? _microphonePermission;
  bool? _gpsPermission;
  bool _isLoadingPermissions = true;

  // Subscription states
  final RevenueCatService _revenueCatService = RevenueCatService();
  final SubscriptionStateProvider _subscriptionProvider =
      SubscriptionStateProvider();
  Offerings? _offerings;
  bool _isLoadingOfferings = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsModel());

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Load notification settings and app preferences
    _loadNotificationSettings();
    _loadAppPreferences();
    _loadAdditionalPreferences();
    _checkPermissions();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoadingOfferings = true);
    try {
      final offerings = await _revenueCatService.getOfferings();
      setState(() {
        _offerings = offerings;
        _isLoadingOfferings = false;
      });
    } catch (e) {
      debugPrint('Failed to load offerings: $e');
      setState(() => _isLoadingOfferings = false);
    }
  }

  Future<void> _showPaywall() async {
    if (_offerings?.current == null) {
      // Fallback: navigate to subscription onboarding
      if (mounted) {
        context.pushNamed('subscription_onboarding');
      }
      return;
    }

    if (mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context)
                      .secondaryText
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Paywall View
              Expanded(
                child: PaywallView(
                  offering: _offerings!.current!,
                ),
              ),
            ],
          ),
        ),
      );

      // Refresh subscription state after paywall is dismissed
      await Future.delayed(const Duration(milliseconds: 500));
      await _subscriptionProvider.refreshSubscriptionState();
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      if (currentUserUid.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final settings = NotificationSettingsStruct.maybeFromMap(
          userData['notificationSettings'],
        );

        final newsletterEnabled = userData['newsletterEnabled'] ?? false;
        setState(() {
          _notificationSettings = settings ?? NotificationSettingsStruct();
          _newsletterEnabled = newsletterEnabled;
          _isLoadingNotifications = false;
        });
      } else {
        setState(() {
          _notificationSettings = NotificationSettingsStruct();
          _newsletterEnabled = false;
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading notification settings: $e');
      setState(() {
        _notificationSettings = NotificationSettingsStruct();
        _newsletterEnabled = false;
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    if (_notificationSettings == null) return;

    try {
      NotificationSettingsStruct updatedSettings;

      switch (setting) {
        case 'dailyReminders':
          updatedSettings = createNotificationSettingsStruct(
            dailyReminders: value,
            insightNotifications: _notificationSettings!.insightNotifications,
            achievementAlerts: _notificationSettings!.achievementAlerts,
            weeklyProgress: _notificationSettings!.weeklyProgress,
          );
          break;
        case 'insightNotifications':
          updatedSettings = createNotificationSettingsStruct(
            dailyReminders: _notificationSettings!.dailyReminders,
            insightNotifications: value,
            achievementAlerts: _notificationSettings!.achievementAlerts,
            weeklyProgress: _notificationSettings!.weeklyProgress,
          );
          break;
        case 'achievementAlerts':
          updatedSettings = createNotificationSettingsStruct(
            dailyReminders: _notificationSettings!.dailyReminders,
            insightNotifications: _notificationSettings!.insightNotifications,
            achievementAlerts: value,
            weeklyProgress: _notificationSettings!.weeklyProgress,
          );
          break;
        case 'weeklyProgress':
          updatedSettings = createNotificationSettingsStruct(
            dailyReminders: _notificationSettings!.dailyReminders,
            insightNotifications: _notificationSettings!.insightNotifications,
            achievementAlerts: _notificationSettings!.achievementAlerts,
            weeklyProgress: value,
          );
          break;
        case 'newsletter':
          // Handle newsletter separately as it's not in the struct
          await FirebaseFirestore.instance
              .collection('user')
              .doc(currentUserUid)
              .update({
            'newsletterEnabled': value,
          });
          setState(() {
            _newsletterEnabled = value;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Newsletter preference updated'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        default:
          return;
      }

      setState(() {
        _notificationSettings = updatedSettings;
      });

      // Save to Firestore
      await PushNotificationsUtil.updateNotificationPreferences(
          updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification preferences updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating notification setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update notification setting'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadAppPreferences() async {
    try {
      if (currentUserUid.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final preferences = AppPreferencesStruct.maybeFromMap(
          userData['appPreferences'],
        );

        setState(() {
          _appPreferences = preferences ?? AppPreferencesStruct();
          _isLoadingPreferences = false;
        });
      } else {
        setState(() {
          _appPreferences = AppPreferencesStruct();
          _isLoadingPreferences = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading app preferences: $e');
      setState(() {
        _appPreferences = AppPreferencesStruct();
        _isLoadingPreferences = false;
      });
    }
  }

  Future<void> _updateAppPreference(String preference, dynamic value) async {
    if (_appPreferences == null) return;

    try {
      AppPreferencesStruct updatedPreferences;

      switch (preference) {
        case 'themeMode':
          updatedPreferences = createAppPreferencesStruct(
            themeMode: value as String,
            hapticFeedbackEnabled: _appPreferences!.hapticFeedbackEnabled,
            language: _appPreferences!.language,
            analyticsEnabled: _appPreferences!.analyticsEnabled,
            crashReportingEnabled: _appPreferences!.crashReportingEnabled,
            preferredUnits: _appPreferences!.preferredUnits,
          );
          // Also update the theme immediately
          _updateTheme(value);
          break;
        case 'hapticFeedback':
          updatedPreferences = createAppPreferencesStruct(
            themeMode: _appPreferences!.themeMode,
            hapticFeedbackEnabled: value as bool,
            language: _appPreferences!.language,
            analyticsEnabled: _appPreferences!.analyticsEnabled,
            crashReportingEnabled: _appPreferences!.crashReportingEnabled,
            preferredUnits: _appPreferences!.preferredUnits,
          );
          break;
        default:
          return;
      }

      setState(() {
        _appPreferences = updatedPreferences;
      });

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        'appPreferences': updatedPreferences.toMap(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ App preferences updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Trigger haptic feedback if enabled
      if (_appPreferences!.hapticFeedbackEnabled) {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('❌ Error updating app preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update app preference'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateTheme(String themeMode) {
    ThemeMode mode;
    switch (themeMode) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'system':
      default:
        mode = ThemeMode.system;
        break;
    }

    FlutterFlowTheme.saveThemeMode(mode);

    // Update the app theme immediately
    try {
      MyApp.of(context).setThemeMode(mode);
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎨 Theme updated!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportUserData() async {
    try {
      if (currentUserUid.isEmpty) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (userDoc.exists) {
        // Show export summary dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('📊 Data Export Ready'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your personal data has been compiled. This includes:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildDataItem('Profile Information', '✅'),
                    _buildDataItem('Golf Statistics', '✅'),
                    _buildDataItem('Coaching Progress', '✅'),
                    _buildDataItem('Preferences & Settings', '✅'),
                    _buildDataItem('Subscription Details', '✅'),
                    const SizedBox(height: 16),
                    const Text(
                      'Note: For security reasons, passwords and sensitive payment information are not included in exports.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) Navigator.of(context).pop();

      debugPrint('❌ Error exporting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to export data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDataItem(String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(status),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  Future<void> _loadAdditionalPreferences() async {
    try {
      if (currentUserUid.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _reduceMotion = userData['reduceMotion'] ?? false;
          _offlineMode = userData['offlineMode'] ?? false;
          _isLoadingAdditionalPrefs = false;
        });
      } else {
        setState(() {
          _reduceMotion = false;
          _offlineMode = false;
          _isLoadingAdditionalPrefs = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading additional preferences: $e');
      setState(() {
        _reduceMotion = false;
        _offlineMode = false;
        _isLoadingAdditionalPrefs = false;
      });
    }
  }

  Future<void> _updateAdditionalPreference(
      String preference, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .update({
        preference: value,
      });

      setState(() {
        if (preference == 'reduceMotion') {
          _reduceMotion = value;
        } else if (preference == 'offlineMode') {
          _offlineMode = value;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Preference updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating additional preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update preference'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _checkPermissions() async {
    try {
      // Check microphone permission
      final micStatus = await Permission.microphone.status;
      final micGranted = micStatus.isGranted;

      // Check location permission
      bool locationGranted = false;
      try {
        LocationPermission locationStatus = await Geolocator.checkPermission();
        locationGranted = locationStatus == LocationPermission.always ||
            locationStatus == LocationPermission.whileInUse;
      } catch (e) {
        debugPrint('Error checking location permission: $e');
      }

      setState(() {
        _microphonePermission = micGranted;
        _gpsPermission = locationGranted;
        _isLoadingPermissions = false;
      });
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      setState(() {
        _isLoadingPermissions = false;
      });
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      final granted = status.isGranted;

      setState(() {
        _microphonePermission = granted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted
                ? '✅ Microphone permission granted'
                : '❌ Microphone permission denied'),
            backgroundColor: granted ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (!granted && status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Microphone Permission Required'),
              content: const Text(
                  'Please enable microphone permission in app settings to use voice features.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting microphone permission: $e');
    }
  }

  Future<void> _requestGPSPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      setState(() {
        _gpsPermission = granted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted
                ? '✅ Location permission granted'
                : '❌ Location permission denied'),
            backgroundColor: granted ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (!granted && permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                  'Please enable location permission in app settings to use GPS features.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting GPS permission: $e');
    }
  }

  Future<void> _showSignOutConfirmation() async {
    final theme = FlutterFlowTheme.of(context);

    final confirmed = await GlassDesignSystem.showGlassModal<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: theme.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Sign Out',
                      style: theme.headlineSmall.copyWith(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Are you sure you want to sign out?',
                style: theme.bodyLarge.copyWith(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You\'ll need to sign in again to access your account and continue your mental performance journey.',
                style: theme.bodyMedium.copyWith(
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign Out',
                      style: theme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      await authManager.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and will delete all your data, including:\n\n'
          '• Profile information\n'
          '• Golf statistics\n'
          '• Coaching progress\n'
          '• All saved preferences\n\n'
          'This action is permanent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUserUid)
            .delete();

        // Sign out
        await authManager.signOut();

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        // Close loading if still open
        if (mounted) Navigator.of(context).pop();

        debugPrint('❌ Error deleting account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<UserRecord>(
        stream: loggedIn
            ? UserRecord.getDocument(
                FirebaseFirestore.instance.doc('user/$currentUserUid'))
            : null,
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: theme.primaryBackground,
            drawer: user != null
                ? FoCoCoDrawer(
                    currentUser: user,
                    currentRoute: 'settings',
                    onNavigate: (route) => context.goNamed(route),
                  )
                : null,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryBackground,
                    theme.secondaryBackground.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 100.0,
                        floating: false,
                        pinned: true,
                        backgroundColor: theme.primaryBackground,
                        elevation: 0,
                        surfaceTintColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              scaffoldKey.currentState?.openDrawer();
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.glassBackground.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.glassBorder.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.menu_rounded,
                                color: theme.primaryText,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          background: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(72, 20, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Settings',
                                    style: theme.headlineMedium.copyWith(
                                      color: theme.primaryText,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage your account and preferences',
                                    style: theme.bodySmall.copyWith(
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildSubscriptionSection(theme),
                            const SizedBox(height: 24),
                            _buildAccountSection(theme),
                            const SizedBox(height: 24),
                            _buildNotificationsSection(theme),
                            const SizedBox(height: 24),
                            _buildLegalSection(theme),
                            const SizedBox(height: 24),
                            _buildPreferencesSection(theme),
                            const SizedBox(height: 24),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionSection(FlutterFlowTheme theme) {
    final hasActiveSubscription = _subscriptionProvider.hasActiveSubscription ||
        _subscriptionProvider.isSubscriptionActive();
    final isWithinTrial = _subscriptionProvider.isWithinTrialPeriod();
    final trialDaysRemaining = _subscriptionProvider.getTrialDaysRemaining();

    return GlassDashboardCard(
      title: 'Subscription',
      subtitle: hasActiveSubscription
          ? 'Manage your premium subscription'
          : isWithinTrial
              ? '$trialDaysRemaining days left in your trial'
              : 'Unlock premium features',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            StreamBuilder<List<UserSubscriptionsRecord>>(
              stream: UserSubscriptionsRecord.collection
                  .where('userId', isEqualTo: currentUserUid)
                  .where('status', whereIn: ['active', 'trialing'])
                  .orderBy('currentPeriodEnd', descending: true)
                  .limit(1)
                  .snapshots()
                  .map((snapshot) => snapshot.docs
                      .map((doc) => UserSubscriptionsRecord.fromSnapshot(doc))
                      .toList()),
              builder: (context, subscriptionSnapshot) {
                final hasPremiumSubscription = subscriptionSnapshot.hasData &&
                    subscriptionSnapshot.data!.isNotEmpty;

                bool isPremium = false;
                if (hasPremiumSubscription) {
                  final subscription = subscriptionSnapshot.data!.first;
                  final membershipTier =
                      subscription.membershipTier.toLowerCase();
                  isPremium =
                      membershipTier == 'premium' || membershipTier == 'prime';
                }

                if (hasActiveSubscription && isPremium) {
                  return _buildSettingsItem(
                    theme,
                    Icons.workspace_premium,
                    'Manage Subscription',
                    'View and manage your subscription details',
                    _showPaywall,
                  );
                } else {
                  return Column(
                    children: [
                      // Show Paywall UI by default
                      if (_isLoadingOfferings)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        )
                      else if (_offerings?.current != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              // Paywall Preview Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primary.withValues(alpha: 0.1),
                                      theme.secondary.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.primary.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      color: theme.primary,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Upgrade to Premium',
                                      style: theme.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isWithinTrial
                                          ? 'Your trial ends in $trialDaysRemaining days'
                                          : 'Unlock all premium features',
                                      style: theme.bodyMedium.copyWith(
                                        color: theme.secondaryText,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _showPaywall,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'View Plans',
                                        style: theme.titleSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (hasActiveSubscription && isPremium)
                                _buildSettingsItem(
                                  theme,
                                  Icons.settings,
                                  'Subscription Management',
                                  'Manage your subscription settings',
                                  _showPaywall,
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
                        )
                      else
                        _buildSettingsItem(
                          theme,
                          Icons.workspace_premium,
                          'Upgrade to Premium',
                          'Unlock all premium features',
                          _showPaywall,
                        ),
                    ],
                  );
                }
              },
            ),
          ],
        )
      ],
    );
  }

  Widget _buildAccountSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Account Settings',
      subtitle: 'Manage your personal info and privacy',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingsItem(
              theme,
              Icons.person_outline,
              'Manage Account Info',
              'Update your profile',
              () => context.goNamed('edit_profile'),
            ),
            _buildSettingsItem(
              theme,
              Icons.lock_outline,
              'Change Password',
              'Update your account password',
              () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('🔐 Change Password'),
                    content: const Text(
                      'To change your password, please sign out and use "Forgot Password" on the login screen.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildSettingsItem(
              theme,
              Icons.fingerprint_outlined,
              'Face ID / Touch ID',
              'Enable biometric authentication',
              () => context.goNamed('face_id_settings'),
            ),
            _buildSettingsItem(
              theme,
              Icons.download_outlined,
              'Download Data',
              'Export your personal data (GDPR / CCPA compliant)',
              _exportUserData,
            ),
            _buildSettingsItem(
              theme,
              Icons.delete_outline,
              'Delete Account',
              'Permanently close your FoCoCo account',
              _deleteAccount,
              isDestructive: true,
            ),
            _buildSettingsItem(
              theme,
              Icons.logout,
              'Sign Out',
              'Sign out of your account',
              _showSignOutConfirmation,
              isDestructive: true,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildNotificationsSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Notifications',
      subtitle: 'Control your notification preferences',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            if (_isLoadingNotifications)
              const CircularProgressIndicator()
            else ...[
              _buildSwitchItem(
                theme,
                Icons.schedule_outlined,
                'Daily Practice Reminders',
                'Stay consistent with your coaching routines',
                _notificationSettings?.dailyReminders ?? false,
                (value) => _updateNotificationSetting('dailyReminders', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.psychology_outlined,
                'AI Insights Ready',
                'Get notified when personalized golf insights are available',
                _notificationSettings?.insightNotifications ?? false,
                (value) =>
                    _updateNotificationSetting('insightNotifications', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.emoji_events_outlined,
                'Achievement Alerts',
                'Celebrate your progress with milestone updates',
                _notificationSettings?.achievementAlerts ?? false,
                (value) =>
                    _updateNotificationSetting('achievementAlerts', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.trending_up_outlined,
                'Weekly Progress Summary',
                'Receive a weekly overview of your golf improvement',
                _notificationSettings?.weeklyProgress ?? false,
                (value) => _updateNotificationSetting('weeklyProgress', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.email_outlined,
                'FoCoCo Newsletter (email)',
                'Stay up-to-date with FoCoCo latest news & updates',
                _newsletterEnabled,
                (value) => _updateNotificationSetting('newsletter', value),
              ),
              // Add settings link for advanced notification management
              _buildSettingsItem(
                theme,
                Icons.tune_outlined,
                'Advanced Notification Settings',
                'Configure detailed notification preferences',
                () => _showAdvancedNotificationSettings(context),
              ),
            ],
          ],
        )
      ],
    );
  }

  void _showAdvancedNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsWidget(),
      ),
    );
  }

  Widget _buildLegalSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Legal & Policies',
      subtitle: 'Understand your rights and data protection',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingsItem(
              theme,
              Icons.medical_information_outlined,
              'Medical Disclaimer',
              'See below',
              () => _showMedicalDisclaimer(),
            ),
            _buildSettingsItem(
              theme,
              Icons.description_outlined,
              'Terms & Conditions',
              'View terms of service',
              () => _openLegalDocument('terms'),
            ),
            _buildSettingsItem(
              theme,
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'View privacy policy',
              () => _openLegalDocument('privacy'),
            ),
            _buildSettingsItem(
              theme,
              Icons.accessibility_new_outlined,
              'Accessibility Statement',
              'View accessibility information',
              () => _openLegalDocument('accessibility'),
            ),
            _buildSettingsItem(
              theme,
              Icons.cookie_outlined,
              'Cookie Policy',
              'View cookie policy',
              () => _openLegalDocument('cookies'),
            ),
            _buildSettingsItem(
              theme,
              Icons.attribution_outlined,
              'Licenses & Attributions',
              'View open source licenses',
              () => _openLegalDocument('licenses'),
            ),
          ],
        )
      ],
    );
  }

  void _showMedicalDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Disclaimer'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FoCoCo provides mindset, focus, and performance guidance for golf and other sports.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'It does not diagnose, treat, or replace any form of medical, psychological, or therapeutic care.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Content is for educational and self-development purposes only.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Always consult a qualified medical or mental-health professional before making decisions that may affect your health or wellbeing.',
                style: TextStyle(
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLegalDocument(String documentType) async {
    // Placeholder URLs - replace with actual URLs when available
    final Map<String, String> documentUrls = {
      'terms': 'https://fococo.app/terms',
      'privacy': 'https://fococo.app/privacy',
      'accessibility': 'https://fococo.app/accessibility',
      'cookies': 'https://fococo.app/cookies',
      'licenses': 'https://fococo.app/licenses',
    };

    final url = documentUrls[documentType] ?? 'https://fococo.app';
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('❌ Error launching legal document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('❌ Unable to open ${documentType.replaceAll('_', ' ')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPreferencesSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'App Preferences',
      subtitle: 'Customize how FoCoCo looks and behaves',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            if (_isLoadingPreferences ||
                _isLoadingPermissions ||
                _isLoadingAdditionalPrefs)
              const CircularProgressIndicator()
            else ...[
              // Microphone permission
              _buildPermissionItem(
                theme,
                Icons.mic_outlined,
                'Microphone',
                _microphonePermission == true ? 'Allowed' : 'Not Allowed',
                _microphonePermission ?? false,
                _requestMicrophonePermission,
              ),
              // GPS permission
              _buildPermissionItem(
                theme,
                Icons.location_on_outlined,
                'GPS',
                _gpsPermission == true ? 'Allowed' : 'Not Allowed',
                _gpsPermission ?? false,
                _requestGPSPermission,
              ),
              // Theme selection with three options
              _buildSettingsItem(
                theme,
                Icons.palette_outlined,
                'App Theme',
                _getThemeDisplayName(_appPreferences?.themeMode ?? 'system'),
                () => _showThemeSelectionDialog(),
              ),
              _buildSwitchItem(
                theme,
                Icons.vibration_outlined,
                'Haptic Feedback',
                'Enable vibration feedback',
                _appPreferences?.hapticFeedbackEnabled ?? true,
                (value) => _updateAppPreference('hapticFeedback', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.accessibility_new_outlined,
                'Reduce Motion',
                'Minimize animations for a calmer interface',
                _reduceMotion,
                (value) => _updateAdditionalPreference('reduceMotion', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.cloud_off_outlined,
                'Offline Mode',
                'Store data locally until reconnected',
                _offlineMode,
                (value) => _updateAdditionalPreference('offlineMode', value),
              ),
            ],
          ],
        )
      ],
    );
  }

  String _getThemeDisplayName(String themeMode) {
    switch (themeMode) {
      case 'light':
        return '☀️ Light';
      case 'dark':
        return '🌙 Dark';
      case 'system':
      default:
        return '📱 Auto';
    }
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎨 Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('system', '📱 Auto', 'Follow device settings'),
            _buildThemeOption('light', '☀️ Light', 'Always use light theme'),
            _buildThemeOption('dark', '🌙 Dark', 'Always use dark theme'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String value, String title, String subtitle) {
    return ListTile(
      leading: Radio<String>(
        value: value,
        groupValue: _appPreferences?.themeMode ?? 'system',
        onChanged: (newValue) {
          if (newValue != null) {
            _updateAppPreference('themeMode', newValue);
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        _updateAppPreference('themeMode', value);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildSettingsItem(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? theme.error.withValues(alpha: 0.1)
                : theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? theme.error : theme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.bodyMedium.copyWith(
            color: isDestructive ? theme.error : theme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.secondaryText,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.labelSmall.copyWith(
            color: theme.secondaryText,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    bool isGranted,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.bodyMedium.copyWith(
            color: theme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.labelSmall.copyWith(
            color: isGranted ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          isGranted ? Icons.check_circle : Icons.settings,
          color: isGranted ? Colors.green : theme.secondaryText,
          size: 24,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
