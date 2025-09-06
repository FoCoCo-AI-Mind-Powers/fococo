import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
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
            _buildSwitchItem(
              theme,
              Icons.notifications_outlined,
              'Push Notifications',
              'Receive notifications on your device',
              true,
              (value) {
                // TODO: Implement notification toggle
              },
            ),
            _buildSwitchItem(
              theme,
              Icons.email_outlined,
              'Email Updates',
              'Receive updates via email',
              false,
              (value) {
                // TODO: Implement email toggle
              },
            ),
            _buildSwitchItem(
              theme,
              Icons.golf_course_outlined,
              'Round Reminders',
              'Get reminders for your golf rounds',
              true,
              (value) {
                // TODO: Implement reminder toggle
              },
            ),
          ],
        )
      ],
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
                // TODO: Implement password change
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password change coming soon!'),
                    backgroundColor: theme.primary,
                  ),
                );
              },
            ),
            _buildSettingsItem(
              theme,
              Icons.download_outlined,
              'Download Data',
              'Export your personal data',
              () {
                // TODO: Implement data export
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data export coming soon!'),
                    backgroundColor: theme.primary,
                  ),
                );
              },
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
            _buildSwitchItem(
              theme,
              Icons.dark_mode_outlined,
              'Dark Mode',
              'Use dark theme',
              false,
              (value) {
                // TODO: Implement theme toggle
              },
            ),
            _buildSwitchItem(
              theme,
              Icons.vibration_outlined,
              'Haptic Feedback',
              'Enable vibration feedback',
              true,
              (value) {
                // TODO: Implement haptic toggle
              },
            ),
            _buildSettingsItem(
              theme,
              Icons.language_outlined,
              'Language',
              'English (US)',
              () {
                // TODO: Implement language selection
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language selection coming soon!'),
                    backgroundColor: theme.primary,
                  ),
                );
              },
            ),
          ],
        )
      ],
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
              () {
                // TODO: Implement app rating
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('App rating coming soon!'),
                    backgroundColor: theme.primary,
                  ),
                );
              },
            ),
            _buildSettingsItem(
              theme,
              Icons.info_outline,
              'About FoCoCo',
              'Version 1.0.0',
              () {
                // TODO: Show about dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('About FoCoCo'),
                    content: Text(
                        'FoCoCo - Mental Performance for Golf\nVersion 1.0.0\n\nBuilt with ❤️ for golfers'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
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
