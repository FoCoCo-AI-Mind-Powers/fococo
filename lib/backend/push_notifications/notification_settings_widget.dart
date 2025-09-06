import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fo_co_co/backend/schema/structs/notification_settings_struct.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'push_notifications_util.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  NotificationSettingsStruct? _currentSettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Notification preferences updated successfully!'),
          backgroundColor: FlutterFlowTheme.of(context).success,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving notification settings: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '❌ Failed to update notification preferences. Please try again.'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notification Settings'),
          backgroundColor: FlutterFlowTheme.of(context).primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: FlutterFlowTheme.of(context).primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔔 Manage Your Notifications',
              style: FlutterFlowTheme.of(context).headlineSmall.override(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose which notifications you\'d like to receive to optimize your golf mental training journey.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    height: 1.0,
                  ),
            ),
            SizedBox(height: 24),

            // Daily Reminders
            _buildNotificationTile(
              icon: Icons.schedule,
              title: 'Daily Practice Reminders',
              subtitle:
                  'Get reminded to complete your daily mental coaching sessions',
              value: _currentSettings?.dailyReminders ?? false,
              onChanged: (value) => _updateSetting('dailyReminders', value),
            ),

            SizedBox(height: 16),

            // AI Insights
            _buildNotificationTile(
              icon: Icons.psychology,
              title: 'AI Insights Ready',
              subtitle:
                  'Be notified when your personalized golf insights are ready',
              value: _currentSettings?.insightNotifications ?? false,
              onChanged: (value) =>
                  _updateSetting('insightNotifications', value),
            ),

            SizedBox(height: 16),

            // Achievement Alerts
            _buildNotificationTile(
              icon: Icons.emoji_events,
              title: 'Achievement Alerts',
              subtitle:
                  'Celebrate your progress with achievement notifications',
              value: _currentSettings?.achievementAlerts ?? false,
              onChanged: (value) => _updateSetting('achievementAlerts', value),
            ),

            SizedBox(height: 16),

            // Weekly Progress
            _buildNotificationTile(
              icon: Icons.trending_up,
              title: 'Weekly Progress Summary',
              subtitle:
                  'Get a weekly overview of your golf improvement journey',
              value: _currentSettings?.weeklyProgress ?? false,
              onChanged: (value) => _updateSetting('weeklyProgress', value),
            ),

            SizedBox(height: 32),

            // Test notification button (only in debug mode)
            if (kDebugMode) ...[
              Divider(),
              SizedBox(height: 16),
              FFButtonWidget(
                onPressed: () async {
                  await PushNotificationsUtil.sendTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🧪 Test notification sent!'),
                      backgroundColor: FlutterFlowTheme.of(context).success,
                    ),
                  );
                },
                text: '🧪 Send Test Notification',
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 50,
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                  iconPadding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: FlutterFlowTheme.of(context).primaryText,
                        height: 1.0,
                      ),
                  elevation: 0,
                  borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: FlutterFlowTheme.of(context).primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: FlutterFlowTheme.of(context).bodyLarge.override(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                fontFamily: 'Inter',
                color: FlutterFlowTheme.of(context).secondaryText,
                height: 1.0,
              ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: FlutterFlowTheme.of(context).primary,
          activeTrackColor:
              FlutterFlowTheme.of(context).primary.withValues(alpha: 0.3),
          inactiveThumbColor: FlutterFlowTheme.of(context).alternate,
          inactiveTrackColor:
              FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.3),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
