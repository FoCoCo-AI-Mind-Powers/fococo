import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/notification_settings_struct.dart';
import '/backend/schema/structs/app_preferences_struct.dart';
import '/backend/schema/user_subscriptions_record.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/push_notifications/notification_settings_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/services/ai_voice_preference_service.dart';
import '/services/account_deletion_service.dart';
import '/services/app_session_prefs_service.dart';
import '/services/cms_content_service.dart';
import '/services/haptic_service.dart';
import '/services/revenuecat_service.dart';
import '/services/subscription_state_provider.dart';
import '/services/units_preference_service.dart';
import '/main.dart';
import '/widgets/fococo_confirm_dialog.dart';
import '/widgets/fococo_drawer_widget.dart';
import 'settings_model.dart';
export 'settings_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _aiVoiceEnabled = true;
  String _unitsPreference = UnitsPreferenceService.metric;
  bool _notificationsMasterEnabled = false;
  bool _gpsAppEnabled = false;

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
  bool? _hasProAccess;

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
    _loadUnitsAndVoicePrefs();
    _checkPermissions();
    _loadOfferings();
    _loadProAccess();
  }

  Future<void> _loadProAccess() async {
    try {
      final hasAccess = await _revenueCatService.hasProAccess();
      if (mounted) setState(() => _hasProAccess = hasAccess);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load pro access: $e');
      if (mounted) setState(() => _hasProAccess = false);
    }
  }

  Future<void> _openNativeManageSubscriptions() async {
    await _revenueCatService.openManageSubscriptions();
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
    FlutterFlowTheme.saveThemeMode(ThemeMode.dark);
    try {
      MyApp.of(context).setThemeMode(ThemeMode.dark);
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _exportUserData() async {
    if (currentUserUid.isEmpty) return;

    final confirmed = await showFoCoCoConfirmDialog(
      context: context,
      title: 'Download your data?',
      message:
          "We'll prepare a copy of your account and activity data and email you when it's ready.",
      confirmLabel: 'Request Data',
      icon: Icons.download_outlined,
    );
    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('data_export_requests').add({
        'userId': currentUserUid,
        'email': currentUserEmail,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Error requesting data export: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request data export: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Data request received. We'll email you when your export is ready.",
          ),
        ),
      );
    }
  }

  Future<void> _loadUnitsAndVoicePrefs() async {
    try {
      final units = await UnitsPreferenceService.load();
      final voiceOn = await AiVoicePreferenceService.isEnabled();
      final gpsOn = await AppSessionPrefsService.isGpsEnabled();
      final prefs = await SharedPreferences.getInstance();
      final notificationsOn =
          prefs.getBool('fococo_notifications_enabled') ?? false;
      if (mounted) {
        setState(() {
          _unitsPreference = units;
          _aiVoiceEnabled = voiceOn;
          _gpsAppEnabled = gpsOn;
          _notificationsMasterEnabled = notificationsOn;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading units/voice prefs: $e');
    }
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
          final openSettings = await showFoCoCoConfirmDialog(
            context: context,
            title: 'Microphone access needed',
            message:
                'Enable microphone permission in Settings to use voice features.',
            confirmLabel: 'Open Settings',
            cancelLabel: 'Not now',
            icon: Icons.mic_off_outlined,
          );
          if (openSettings) {
            await openAppSettings();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting microphone permission: $e');
    }
  }

  Future<void> _showSignOutConfirmation() async {
    final confirmed = await showFoCoCoConfirmDialog(
      context: context,
      title: 'Sign out?',
      message:
          'Are you sure you want to sign out? '
          'You\'ll need to sign in again to access your account.',
      confirmLabel: 'Sign Out',
      icon: Icons.logout_rounded,
      accent: FoCoCoDialogAccent.destructive,
    );

    if (confirmed && mounted) {
      await HapticService.light();
      await AppSessionPrefsService.setPostLoginTabFoCoCo();
      await authManager.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showFoCoCoDeleteAccountDialog(context);

    final email = currentUserEmail;
    await AccountDeletionService.requestDeletion(email: email);
    await AccountDeletionService.clearLocalState();
    if (!mounted) return;
    final router = GoRouter.of(context);
    await authManager.signOut();
    router.go('/login');
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
            drawer: null,
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
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: theme.primaryText,
                            size: 20,
                          ),
                          onPressed: () => context.pop(),
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

    if (_hasProAccess == true) {
      return GlassDashboardCard(
        title: 'Subscription',
        subtitle: 'FoCoCo Prime membership',
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              Text(
                "You're on FoCoCo Prime",
                style: theme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Manage billing, renewal, or cancellation in your app store account.',
                style: theme.bodyMedium.copyWith(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                theme,
                Icons.workspace_premium,
                'Manage Subscription',
                'Open your app store subscription settings',
                _openNativeManageSubscriptions,
              ),
            ],
          ),
        ],
      );
    }

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
                    _openNativeManageSubscriptions,
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
                showFoCoCoAlertDialog(
                  context: context,
                  title: 'Change password',
                  message:
                      'To change your password, sign out and use Forgot Password on the login screen.',
                  icon: Icons.lock_outline_rounded,
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
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'How we collect and protect your data',
              () => _openLegalDocument('privacy'),
            ),
            _buildSettingsItem(
              theme,
              Icons.description_outlined,
              'Terms',
              'Terms of service for using FoCoCo',
              () => _openLegalDocument('terms'),
            ),
            _buildSettingsItem(
              theme,
              Icons.smart_toy_outlined,
              'AI Disclosure',
              'You are interacting with an AI system',
              () => _openLegalDocument('ai'),
            ),
            _buildSettingsItem(
              theme,
              Icons.shield_outlined,
              'Data Security',
              'How your data is stored and secured',
              () => _openLegalDocument('data_security'),
            ),
            _buildSettingsItem(
              theme,
              Icons.medical_information_outlined,
              'Non-Medical Disclaimer',
              'FoCoCo is not a medical or therapy product',
              () => _openLegalDocument('non_medical'),
            ),
            _buildSettingsItem(
              theme,
              Icons.cookie_outlined,
              'Cookie Policy',
              'How we use cookies and similar technologies',
              () => _openLegalDocument('cookie'),
            ),
            _buildSettingsItem(
              theme,
              Icons.delete_forever_outlined,
              'Account Deletion',
              'Permanently delete your account and data',
              () => _deleteAccount(),
            ),
            _buildSettingsItem(
              theme,
              Icons.attribution_outlined,
              'Licenses & Attributions',
              'Open source licenses',
              () => _openLegalDocument('licenses'),
            ),
          ],
        )
      ],
    );
  }

  Future<void> _openLegalDocument(String documentType) async {
    final url = CmsContentService.instance.legalUrl(documentType);
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

  Future<void> _showUnitsPicker(FlutterFlowTheme theme) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.primaryBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Metric (metres)'),
              onTap: () => Navigator.pop(
                context,
                UnitsPreferenceService.metric,
              ),
            ),
            ListTile(
              title: const Text('Imperial (yards)'),
              onTap: () => Navigator.pop(
                context,
                UnitsPreferenceService.imperial,
              ),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) {
      return;
    }
    await UnitsPreferenceService.setUnits(choice);
    await HapticService.light();
    setState(() => _unitsPreference = choice);
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
              _buildSwitchItem(
                theme,
                Icons.notifications_outlined,
                'Notifications',
                _notificationsMasterEnabled ? 'On' : 'Off',
                _notificationsMasterEnabled,
                (value) async {
                  if (!value) {
                    await openAppSettings();
                  }
                  setState(() => _notificationsMasterEnabled = value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('fococo_notifications_enabled', value);
                  await HapticService.light();
                },
              ),
              _buildSwitchItem(
                theme,
                Icons.location_on_outlined,
                'GPS',
                _gpsAppEnabled ? 'On' : 'Off',
                _gpsAppEnabled,
                (value) async {
                  if (value) {
                    await Permission.locationWhenInUse.request();
                  }
                  await AppSessionPrefsService.setGpsEnabled(value);
                  await HapticService.light();
                  setState(() => _gpsAppEnabled = value);
                },
              ),
              _buildSettingsItem(
                theme,
                Icons.palette_outlined,
                'App Theme',
                'Dark (FoCoCo default)',
                null,
                showTrailing: false,
              ),
              _buildSettingsItem(
                theme,
                Icons.straighten_outlined,
                'Units',
                _unitsPreference == UnitsPreferenceService.imperial
                    ? 'Imperial (yards)'
                    : 'Metric (metres)',
                () => _showUnitsPicker(theme),
              ),
              _buildSwitchItem(
                theme,
                Icons.record_voice_over_outlined,
                'AI Voice',
                _aiVoiceEnabled ? 'On' : 'Off',
                _aiVoiceEnabled,
                (value) async {
                  setState(() => _aiVoiceEnabled = value);
                  await AiVoicePreferenceService.setEnabled(value);
                  await HapticService.light();
                },
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

  Widget _buildSettingsItem(
    FlutterFlowTheme theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap, {
    bool isDestructive = false,
    bool showTrailing = true,
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
        trailing: showTrailing
            ? Icon(
                Icons.arrow_forward_ios,
                color: theme.secondaryText,
                size: 16,
              )
            : null,
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
