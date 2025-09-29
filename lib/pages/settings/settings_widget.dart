import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/notification_settings_struct.dart';
import '/backend/schema/structs/app_preferences_struct.dart';
import '/backend/push_notifications/push_notifications_util.dart';
import '/backend/push_notifications/notification_settings_widget.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_components.dart';
import '/ai_integration/widgets/enhanced_navbar_widget.dart';
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

  // App preferences
  AppPreferencesStruct? _appPreferences;
  bool _isLoadingPreferences = true;

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

        setState(() {
          _notificationSettings = settings ?? NotificationSettingsStruct();
          _isLoadingNotifications = false;
        });
      } else {
        setState(() {
          _notificationSettings = NotificationSettingsStruct();
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading notification settings: $e');
      setState(() {
        _notificationSettings = NotificationSettingsStruct();
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
        case 'language':
          updatedPreferences = createAppPreferencesStruct(
            themeMode: _appPreferences!.themeMode,
            hapticFeedbackEnabled: _appPreferences!.hapticFeedbackEnabled,
            language: value as String,
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

    // Trigger app restart to apply theme
    if (mounted) {
      setState(() {});
      // Show restart hint
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎨 Theme updated! Restart app to see full changes'),
          duration: Duration(seconds: 3),
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

  Future<void> _launchAppStore() async {
    try {
      const String appStoreUrl =
          'https://apps.apple.com/app/fococo-golf/id123456789';
      const String playStoreUrl =
          'https://play.google.com/store/apps/details?id=com.fococo.app';

      // Use appropriate URL based on platform
      final String url = Theme.of(context).platform == TargetPlatform.iOS
          ? appStoreUrl
          : playStoreUrl;

      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('❌ Error launching app store: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Unable to open app store'),
            backgroundColor: Colors.red,
          ),
        );
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
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        drawer: loggedIn
            ? StreamBuilder<UserRecord>(
                stream: UserRecord.getDocument(
                    FirebaseFirestore.instance.doc('user/${currentUserUid}')),
                builder: (context, snapshot) {
                  final userData = snapshot.data;
                  return EnhancedFoCoCoDrawer(
                    currentUser: userData,
                    currentRoute: 'settings',
                    onNavigate: (route) => context.goNamed(route),
                  );
                },
              )
            : null,
        body: Stack(
          children: [
            // Main content
            Container(
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
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Custom App Bar
                        _buildCustomAppBar(theme),

                        // Main Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Account Settings
                                _buildAccountSection(theme),

                                const SizedBox(height: 24),

                                // Notifications
                                _buildNotificationsSection(theme),

                                const SizedBox(height: 24),

                                // Privacy & Security
                                _buildPrivacySection(theme),

                                const SizedBox(height: 24),

                                // App Preferences
                                _buildPreferencesSection(theme),

                                const SizedBox(height: 24),

                                // About & Support
                                _buildAboutSection(theme),

                                const SizedBox(height: 100), // Space for navbar
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Voice Button
            const FloatingVoiceButton(),
          ],
        ),
        bottomNavigationBar: EnhancedFoCoCoNavBar(
          currentRoute: 'settings',
          onTap: (route) {
            print('🔄 Settings page: Navigation requested to route: $route');
            context.goNamed(route);
          },
          currentUser: null,
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Menu button
          GestureDetector(
            onTap: () => scaffoldKey.currentState?.openDrawer(),
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

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Settings',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Profile button
          GestureDetector(
            onTap: () => context.goNamed('profile'),
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
                Icons.person_outline,
                color: theme.primaryText,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Account',
      subtitle: 'Manage your account settings',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingsItem(
              theme,
              Icons.edit_outlined,
              'Edit Profile',
              'Update your personal information',
              () => context.goNamed('edit_profile'),
            ),
            _buildSettingsItem(
              theme,
              Icons.security_outlined,
              'Privacy & Security',
              'Manage your privacy settings',
              () => context.goNamed('face_id_settings'),
            ),
            _buildSettingsItem(
              theme,
              Icons.payment_outlined,
              'Subscription',
              'Manage your subscription',
              () => context.goNamed('subscription_management'),
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
                'Get reminded to complete your daily mental coaching sessions',
                _notificationSettings?.dailyReminders ?? false,
                (value) => _updateNotificationSetting('dailyReminders', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.psychology_outlined,
                'AI Insights Ready',
                'Be notified when your personalized golf insights are ready',
                _notificationSettings?.insightNotifications ?? false,
                (value) =>
                    _updateNotificationSetting('insightNotifications', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.emoji_events_outlined,
                'Achievement Alerts',
                'Celebrate your progress with achievement notifications',
                _notificationSettings?.achievementAlerts ?? false,
                (value) =>
                    _updateNotificationSetting('achievementAlerts', value),
              ),
              _buildSwitchItem(
                theme,
                Icons.trending_up_outlined,
                'Weekly Progress Summary',
                'Get a weekly overview of your golf improvement journey',
                _notificationSettings?.weeklyProgress ?? false,
                (value) => _updateNotificationSetting('weeklyProgress', value),
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

  Widget _buildPrivacySection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'Privacy & Security',
      subtitle: 'Protect your data and privacy',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingsItem(
              theme,
              Icons.fingerprint_outlined,
              'Face ID / Touch ID',
              'Enable biometric authentication',
              () => context.goNamed('face_id_settings'),
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
              Icons.download_outlined,
              'Download Data',
              'Export your personal data',
              _exportUserData,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPreferencesSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'App Preferences',
      subtitle: 'Customize your app experience',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            if (_isLoadingPreferences)
              const CircularProgressIndicator()
            else ...[
              // Theme selection with three options
              _buildSettingsItem(
                theme,
                Icons.palette_outlined,
                'Theme',
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
              _buildSettingsItem(
                theme,
                Icons.language_outlined,
                'Language',
                _getLanguageDisplayName(_appPreferences?.language ?? 'en_US'),
                () => _showLanguageSelectionDialog(),
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
        return '☀️ Light Mode';
      case 'dark':
        return '🌙 Dark Mode';
      case 'system':
      default:
        return '📱 System Default';
    }
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en_US':
        return '🇺🇸 English (US)';
      case 'es_ES':
        return '🇪🇸 Spanish';
      case 'fr_FR':
        return '🇫🇷 French';
      case 'de_DE':
        return '🇩🇪 German';
      default:
        return '🇺🇸 English (US)';
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
            _buildThemeOption(
                'system', '📱 System Default', 'Follow device settings'),
            _buildThemeOption(
                'light', '☀️ Light Mode', 'Always use light theme'),
            _buildThemeOption('dark', '🌙 Dark Mode', 'Always use dark theme'),
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

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌍 Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('en_US', '🇺🇸 English (US)'),
            _buildLanguageOption('es_ES', '🇪🇸 Spanish'),
            _buildLanguageOption('fr_FR', '🇫🇷 French'),
            _buildLanguageOption('de_DE', '🇩🇪 German'),
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

  Widget _buildLanguageOption(String value, String title) {
    return ListTile(
      leading: Radio<String>(
        value: value,
        groupValue: _appPreferences?.language ?? 'en_US',
        onChanged: (newValue) {
          if (newValue != null) {
            _updateAppPreference('language', newValue);
            Navigator.of(context).pop();
            // Show restart message for language changes
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('🌍 Language updated! Restart app to apply changes'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
      title: Text(title),
      onTap: () {
        _updateAppPreference('language', value);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌍 Language updated! Restart app to apply changes'),
            duration: Duration(seconds: 3),
          ),
        );
      },
    );
  }

  Widget _buildAboutSection(FlutterFlowTheme theme) {
    return GlassDashboardCard(
      title: 'About & Support',
      subtitle: 'Get help and app information',
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            _buildSettingsItem(
              theme,
              Icons.help_outline,
              'Help & Support',
              'Get help with the app',
              () => context.goNamed('support'),
            ),
            _buildSettingsItem(
              theme,
              Icons.star_outline,
              'Rate App',
              'Rate FoCoCo on the App Store',
              _launchAppStore,
            ),
            _buildSettingsItem(
              theme,
              Icons.info_outline,
              'About FoCoCo',
              'Version 1.0.0',
              () => _showAboutDialog(),
            ),
            _buildSettingsItem(
              theme,
              Icons.logout,
              'Sign Out',
              'Sign out of your account',
              () async {
                await authManager.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              isDestructive: true,
            ),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FlutterFlowTheme.of(context).primary,
                    FlutterFlowTheme.of(context).secondary
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.golf_course,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About FoCoCo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🏌️ FoCoCo - Mental Performance for Golf',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Version 1.0.0'),
              const SizedBox(height: 16),
              const Text(
                'Transform your golf game through the power of mental performance. FoCoCo combines cutting-edge AI insights with proven sports psychology techniques.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎯 Features:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('🧠', 'AI-powered mental coaching'),
              _buildFeatureItem('📊', 'Performance analytics'),
              _buildFeatureItem('🎓', 'VARK learning adaptation'),
              _buildFeatureItem('🔒', 'Secure biometric protection'),
              _buildFeatureItem('🏆', 'Progress tracking & achievements'),
              const SizedBox(height: 16),
              const Text(
                'Built with ❤️ for golfers who want to unlock their mental edge.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '© 2024 FoCoCo Golf. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
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

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
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
}
