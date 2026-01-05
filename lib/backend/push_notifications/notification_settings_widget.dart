import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/structs/notification_settings_struct.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';
import '/flutter_flow/glass_components.dart';
import 'push_notifications_util.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  static String routeName = 'notification_settings';
  static String routePath = '/notification-settings';

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget>
    with TickerProviderStateMixin {
  NotificationSettingsStruct? _currentSettings;
  bool _isLoading = true;
  bool _isSaving = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

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

    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
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
          _currentSettings = settings ?? NotificationSettingsStruct();
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentSettings = NotificationSettingsStruct();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading notification settings: $e');
      }
      setState(() {
        _currentSettings = NotificationSettingsStruct();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_currentSettings == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await PushNotificationsUtil.updateNotificationPreferences(
          _currentSettings!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Notification preferences updated successfully!'),
            backgroundColor: FlutterFlowTheme.of(context).success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving notification settings: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ Failed to update notification preferences. Please try again.'),
            backgroundColor: FlutterFlowTheme.of(context).error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _updateSetting(String setting, bool value) {
    if (_currentSettings == null) return;

    setState(() {
      switch (setting) {
        case 'dailyReminders':
          _currentSettings = createNotificationSettingsStruct(
            dailyReminders: value,
            insightNotifications: _currentSettings!.insightNotifications,
            achievementAlerts: _currentSettings!.achievementAlerts,
            weeklyProgress: _currentSettings!.weeklyProgress,
          );
          break;
        case 'insightNotifications':
          _currentSettings = createNotificationSettingsStruct(
            dailyReminders: _currentSettings!.dailyReminders,
            insightNotifications: value,
            achievementAlerts: _currentSettings!.achievementAlerts,
            weeklyProgress: _currentSettings!.weeklyProgress,
          );
          break;
        case 'achievementAlerts':
          _currentSettings = createNotificationSettingsStruct(
            dailyReminders: _currentSettings!.dailyReminders,
            insightNotifications: _currentSettings!.insightNotifications,
            achievementAlerts: value,
            weeklyProgress: _currentSettings!.weeklyProgress,
          );
          break;
        case 'weeklyProgress':
          _currentSettings = createNotificationSettingsStruct(
            dailyReminders: _currentSettings!.dailyReminders,
            insightNotifications: _currentSettings!.insightNotifications,
            achievementAlerts: _currentSettings!.achievementAlerts,
            weeklyProgress: value,
          );
          break;
      }
    });
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
                          child: _isLoading
                              ? _buildLoadingState(theme)
                              : _buildNotificationSettings(theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.goNamed('settings');
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.glassBackground.withValues(alpha: 0.3),
                        theme.glassTint.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.glassBorder.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: theme.primaryText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'Notification Settings',
              style: theme.headlineSmall.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Save button
          GestureDetector(
            onTap: _isSaving ? null : _saveSettings,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: _isSaving
                        ? LinearGradient(
                            colors: [
                              theme.glassBackground.withValues(alpha: 0.3),
                              theme.glassTint.withValues(alpha: 0.2),
                            ],
                          )
                        : theme.primaryBrandGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSaving
                          ? theme.glassBorder.withValues(alpha: 0.4)
                          : theme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save',
                          style: theme.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading notification settings...',
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          GlassDashboardCard(
            title: 'Manage Your Notifications',
            subtitle:
                'Choose which notifications you\'d like to receive to optimize your golf mental training journey',
            icon: Icon(
              FontAwesomeIcons.bell,
              color: theme.primary,
              size: 24,
            ),
            children: [
              const SizedBox(height: 20),
            ],
          ),

          const SizedBox(height: 20),

          // Notification Options
          GlassDashboardCard(
            title: 'Notification Preferences',
            subtitle: 'Control what notifications you receive',
            children: [
              const SizedBox(height: 16),

              // Daily Practice Reminders
              _buildNotificationSwitch(
                theme: theme,
                icon: Icons.schedule,
                title: 'Daily Practice Reminders',
                subtitle:
                    'Get reminded to complete your daily mental coaching sessions',
                value: _currentSettings?.dailyReminders ?? false,
                onChanged: (value) => _updateSetting('dailyReminders', value),
              ),

              const SizedBox(height: 12),

              // AI Insights Ready
              _buildNotificationSwitch(
                theme: theme,
                icon: FontAwesomeIcons.brain,
                title: 'AI Insights Ready',
                subtitle:
                    'Be notified when your personalized golf insights are ready',
                value: _currentSettings?.insightNotifications ?? false,
                onChanged: (value) =>
                    _updateSetting('insightNotifications', value),
              ),

              const SizedBox(height: 12),

              // Achievement Alerts
              _buildNotificationSwitch(
                theme: theme,
                icon: FontAwesomeIcons.trophy,
                title: 'Achievement Alerts',
                subtitle:
                    'Celebrate your progress with achievement notifications',
                value: _currentSettings?.achievementAlerts ?? false,
                onChanged: (value) =>
                    _updateSetting('achievementAlerts', value),
              ),

              const SizedBox(height: 12),

              // Weekly Progress Summary
              _buildNotificationSwitch(
                theme: theme,
                icon: FontAwesomeIcons.chartLine,
                title: 'Weekly Progress Summary',
                subtitle:
                    'Get a weekly overview of your golf improvement journey',
                value: _currentSettings?.weeklyProgress ?? false,
                onChanged: (value) => _updateSetting('weeklyProgress', value),
              ),
            ],
          ),

          // Test notification button (only in debug mode)
          if (kDebugMode) ...[
            const SizedBox(height: 20),
            GlassDashboardCard(
              title: 'Testing',
              subtitle: 'Developer tools',
              children: [
                const SizedBox(height: 16),
                GlassDesignSystem.glassButton(
                  text: '🧪 Send Test Notification',
                  onPressed: () async {
                    await PushNotificationsUtil.sendTestNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🧪 Test notification sent!'),
                          backgroundColor: theme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icons.bug_report,
                  theme: theme,
                  color: theme.secondaryText,
                ),
              ],
            ),
          ],

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required FlutterFlowTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.glassTint.withValues(alpha: 0.1),
            theme.glassTint.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.titleSmall.copyWith(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.bodySmall.copyWith(
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primary,
            activeTrackColor: theme.primary.withValues(alpha: 0.3),
            inactiveThumbColor: theme.secondaryText,
            inactiveTrackColor: theme.secondaryText.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
