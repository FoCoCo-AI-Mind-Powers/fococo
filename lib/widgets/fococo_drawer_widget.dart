import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/subscription_state_provider.dart';

// ─── Spec colors ────────────────────────────────────────────────────────────
const Color _kBgColor = Color(0xFF0D0D1A);
const Color _kGold = Color(0xFFC9A84C);
const Color _kGreen = Color(0xFF4CAF82);
const Color _kPurple = Color(0xFF9B6FD4);

// ─── SharedPreferences keys ─────────────────────────────────────────────────
const String _kUnitsKey = 'fococo_units_preference';
const String _kMicrophoneKey = 'fococo_microphone_enabled';
const String _kAiResponseModeKey = 'fococo_ai_response_mode';
const String _kNotificationsKey = 'fococo_notifications_enabled';

/// Shared FoCoCo app drawer (menu). Use as the left drawer on main pages.
class FoCoCoDrawer extends StatefulWidget {
  final UserRecord? currentUser;
  final String currentRoute;
  final void Function(String route)? onNavigate;

  const FoCoCoDrawer({
    super.key,
    this.currentUser,
    required this.currentRoute,
    this.onNavigate,
  });

  @override
  State<FoCoCoDrawer> createState() => _FoCoCoDrawerState();
}

class _FoCoCoDrawerState extends State<FoCoCoDrawer> {
  String _appVersion = '';
  String _units = 'metric';
  bool _micEnabled = false;
  String _aiResponseMode = 'visual'; // visual | voice | visual_voice
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadAppVersion();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _units = prefs.getString(_kUnitsKey) ?? 'metric';
      _micEnabled = prefs.getBool(_kMicrophoneKey) ?? false;
      _aiResponseMode = prefs.getString(_kAiResponseModeKey) ?? 'visual';
      _notificationsEnabled = prefs.getBool(_kNotificationsKey) ?? false;
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = 'v${info.version}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'v1.0.0');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Derive subscription source from user record.
  String _getSubscriptionSource() {
    final user = widget.currentUser;
    if (user == null) return _platformDefault();
    if (user.appleSubscriptionId.isNotEmpty) return 'apple';
    if (user.googleSubscriptionId.isNotEmpty) return 'google';
    final sub = SubscriptionStateProvider().currentSubscription;
    if (sub != null && sub.platform.isNotEmpty) return sub.platform;
    return _platformDefault();
  }

  String _platformDefault() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS || Platform.isMacOS) return 'apple';
    if (Platform.isAndroid) return 'google';
    return 'web';
  }

  bool get _isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// Status pill text & color — single source of truth for pill + Membership row.
  ({String text, Color color}) _statusPillData() {
    final sub = SubscriptionStateProvider();
    final tier = widget.currentUser?.currentMembershipTier ?? sub.userTier;

    // Check trial first
    if (sub.isWithinTrialPeriod() && !sub.hasActiveSubscription) {
      final remaining = sub.getTrialDaysRemaining();
      final totalDays = SubscriptionStateProvider.trialPeriodDays;
      final dayNumber = totalDays - remaining;
      return (
        text: 'Free Trial \u00B7 Day $dayNumber of $totalDays',
        color: _kGold,
      );
    }

    // Check if Founders badge (read directly from Firestore snapshot)
    final isFounder = widget.currentUser?.snapshotData['isFounder'] == true;

    if (tier.toLowerCase() == 'prime') {
      if (isFounder) {
        return (text: 'FoCoCo Prime \u00B7 Founders', color: _kPurple);
      }
      return (text: 'FoCoCo Prime', color: _kGreen);
    }

    // Fallback for non-prime non-trial
    return (text: 'Free Trial', color: _kGold);
  }

  void _closeDrawer() {
    try {
      final scaffold = Scaffold.of(context);
      if (scaffold.isDrawerOpen) scaffold.closeDrawer();
    } catch (_) {
      try {
        if (Navigator.of(context, rootNavigator: false).canPop()) {
          Navigator.of(context, rootNavigator: false).pop();
        }
      } catch (_) {}
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.85,
      child: Drawer(
        backgroundColor: _kBgColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  children: [
                    _buildIdentitySection(theme),
                    const SizedBox(height: 36),
                    _buildSection(theme, 'MEMBERSHIP',
                        _buildMembershipRows(theme)),
                    const SizedBox(height: 36),
                    _buildSection(
                        theme, 'PROFILE', _buildProfileRows(theme)),
                    const SizedBox(height: 36),
                    _buildSection(
                        theme, 'SETTINGS', _buildSettingsRows(theme)),
                    const SizedBox(height: 36),
                    _buildSection(
                        theme, 'SUPPORT', _buildSupportRows(theme)),
                    const SizedBox(height: 36),
                    _buildSection(theme, 'LEGAL', _buildLegalRows(theme)),
                    const SizedBox(height: 36),
                    _buildSection(theme, 'ABOUT', _buildAboutRows(theme)),
                  ],
                ),
              ),
              _buildLogout(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Section — Identity + Status Pill ──────────────────────────────────

  Widget _buildIdentitySection(FlutterFlowTheme theme) {
    final pill = _statusPillData();
    final userName = widget.currentUser?.displayName.isNotEmpty == true
        ? widget.currentUser!.displayName
        : 'Golfer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo + tagline
        Row(
          children: [
            Image.asset(
              'assets/images/logo/Logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const SizedBox(width: 32, height: 32),
            ),
            const SizedBox(width: 10),
            Text(
              'Your Mind Powers the Game',
              style: theme.bodySmall.override(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // User name
        Text(
          userName,
          style: theme.titleMedium.override(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: pill.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pill.color.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            pill.text,
            style: theme.labelSmall.override(
              color: pill.color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  // ── Generic section builder ───────────────────────────────────────────────

  Widget _buildSection(
      FlutterFlowTheme theme, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.labelSmall.override(
            color: Colors.white.withValues(alpha: 0.35),
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        ...rows,
      ],
    );
  }

  // ── Row builder (text-first, no icons, thumb-friendly) ────────────────────

  Widget _buildRow(
    FlutterFlowTheme theme,
    String label, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.bodyMedium.override(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  height: 1.2,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayRow(FlutterFlowTheme theme, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: theme.bodyMedium.override(
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
              fontSize: 15,
              height: 1.2,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.bodyMedium.override(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
                fontSize: 15,
                height: 1.2,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── MEMBERSHIP section ────────────────────────────────────────────────────

  List<Widget> _buildMembershipRows(FlutterFlowTheme theme) {
    final pill = _statusPillData();

    return [
      _buildDisplayRow(theme, 'Status', pill.text),
      _buildRow(theme, 'Manage Subscription', onTap: _handleManageSubscription),
    ];
  }

  Future<void> _handleManageSubscription() async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final source = _getSubscriptionSource();
    switch (source) {
      case 'apple':
        final url = Uri.parse(
            'https://apps.apple.com/account/subscriptions');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        break;
      case 'google':
        final url = Uri.parse(
            'https://play.google.com/store/account/subscriptions');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
        break;
      case 'web':
        // Only show external billing for web subscription_source
        widget.onNavigate?.call('subscription_management');
        break;
      default:
        widget.onNavigate?.call('subscription_management');
    }
  }

  // ── PROFILE section ───────────────────────────────────────────────────────

  List<Widget> _buildProfileRows(FlutterFlowTheme theme) {
    final name = widget.currentUser?.displayName.isNotEmpty == true
        ? widget.currentUser!.displayName
        : 'Not set';
    final email = widget.currentUser?.email.isNotEmpty == true
        ? widget.currentUser!.email
        : currentUserEmail;

    return [
      _buildDisplayRow(theme, 'Name', name),
      _buildDisplayRow(theme, 'Email', email.isNotEmpty ? email : 'Not set'),
      _buildRow(
        theme,
        'Units',
        trailing: _buildInlineSelector(
          theme,
          options: ['Metric', 'Imperial'],
          selected: _units == 'metric' ? 'Metric' : 'Imperial',
          onChanged: (val) async {
            final newVal = val.toLowerCase();
            setState(() => _units = newVal);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_kUnitsKey, newVal);
          },
        ),
      ),
    ];
  }

  /// Inline selector — two pills side by side (not a dropdown).
  Widget _buildInlineSelector(
    FlutterFlowTheme theme, {
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                opt,
                style: theme.labelSmall.override(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.4),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SETTINGS section ──────────────────────────────────────────────────────

  List<Widget> _buildSettingsRows(FlutterFlowTheme theme) {
    return [
      // Voice sub-header
      _buildSubHeader(theme, 'Voice'),
      _buildRow(
        theme,
        'Microphone',
        trailing: _buildToggle(
          theme,
          value: _micEnabled,
          onChanged: (val) async {
            setState(() => _micEnabled = val);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_kMicrophoneKey, val);
          },
        ),
      ),
      _buildRow(
        theme,
        'AI Response Mode',
        trailing: _buildSegmentedControl(theme),
      ),

      const SizedBox(height: 12),
      // Notifications sub-header
      _buildSubHeader(theme, 'Notifications'),
      _buildRow(
        theme,
        'Notifications',
        trailing: _buildToggle(
          theme,
          value: _notificationsEnabled,
          onChanged: (val) async {
            setState(() => _notificationsEnabled = val);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_kNotificationsKey, val);
          },
        ),
      ),

      const SizedBox(height: 12),
      // Data & Privacy sub-header
      _buildSubHeader(theme, 'Data & Privacy'),
      _buildRow(theme, 'Download My Data', onTap: _handleDownloadData),
      _buildRow(theme, 'Delete My Account', onTap: _handleDeleteAccount),
    ];
  }

  Widget _buildSubHeader(FlutterFlowTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: theme.bodySmall.override(
          color: Colors.white.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
          fontSize: 13,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildToggle(
    FlutterFlowTheme theme, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: 28,
      width: 48,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: _kGreen.withValues(alpha: 0.5),
        activeThumbColor: _kGreen,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildSegmentedControl(FlutterFlowTheme theme) {
    final modes = {
      'visual': 'Visual',
      'voice': 'Voice',
      'visual_voice': 'Visual + Voice',
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.entries.map((entry) {
          final isSelected = _aiResponseMode == entry.key;
          return GestureDetector(
            onTap: () async {
              setState(() => _aiResponseMode = entry.key);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_kAiResponseModeKey, entry.key);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.value,
                style: theme.labelSmall.override(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.4),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10,
                  height: 1.0,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleDownloadData() async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final email = widget.currentUser?.email ?? currentUserEmail;

    // Trigger data export (fires Firestore cloud function)
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('data_export_requests').add({
          'userId': uid,
          'email': email,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }
    } catch (e) {
      debugPrint('Error requesting data export: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Your data export has been sent to $email',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _kGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    // Step 1 — native two-step alert
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Flag account for deletion in Firestore
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final email = widget.currentUser?.email ?? currentUserEmail;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('account_deletion_requests')
            .add({
          'userId': uid,
          'email': email,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }
    } catch (e) {
      debugPrint('Error flagging account deletion: $e');
    }

    if (!mounted) return;

    // Immediate logout
    final router = GoRouter.of(context);
    await authManager.signOut();
    router.go('/login');
  }

  // ── SUPPORT section ───────────────────────────────────────────────────────

  List<Widget> _buildSupportRows(FlutterFlowTheme theme) {
    return [
      _buildRow(theme, 'Help & Support', onTap: () {
        _closeDrawer();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) widget.onNavigate?.call('support');
        });
      }),
      _buildRow(theme, 'Send Feedback', onTap: () async {
        _closeDrawer();
        final url = Uri.parse('mailto:support@fococo.ai?subject=FoCoCo%20Feedback');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      }),
      // Rate App — mobile only
      if (_isMobile)
        _buildRow(theme, 'Rate App', onTap: () {
          _closeDrawer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'App rating will be available when FoCoCo is released on the App Store!',
              ),
              backgroundColor: _kGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }),
    ];
  }

  // ── LEGAL section ─────────────────────────────────────────────────────────

  List<Widget> _buildLegalRows(FlutterFlowTheme theme) {
    return [
      _buildRow(theme, 'Terms of Service', onTap: () async {
        final url = Uri.parse('https://fococo.ai/terms');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }),
      _buildRow(theme, 'Privacy Policy', onTap: () async {
        final url = Uri.parse('https://fococo.ai/privacy');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }),
    ];
  }

  // ── ABOUT section ─────────────────────────────────────────────────────────

  List<Widget> _buildAboutRows(FlutterFlowTheme theme) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          _appVersion.isNotEmpty ? _appVersion : 'v1.0.0',
          style: theme.bodyMedium.override(
            color: Colors.white.withValues(alpha: 0.4),
            fontWeight: FontWeight.w400,
            fontSize: 14,
            height: 1.2,
          ),
        ),
      ),
    ];
  }

  // ── Bottom — Logout ───────────────────────────────────────────────────────

  Widget _buildLogout(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: InkWell(
        onTap: () async {
          // LOCKED: Immediate logout, no confirmation dialog.
          final router = GoRouter.of(context);
          await authManager.signOut();
          router.go('/login');
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Log Out',
            style: theme.bodyMedium.override(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible alias for [FoCoCoDrawer]. Prefer [FoCoCoDrawer].
typedef EnhancedFoCoCoDrawer = FoCoCoDrawer;

/// Backward-compatible alias kept for any imports referencing [DrawerItem].
class FoCoCoDrawerItem {
  final IconData icon;
  final String title;
  final String? route;
  final String? subtitle;

  const FoCoCoDrawerItem({
    required this.icon,
    required this.title,
    this.route,
    this.subtitle,
  });
}

typedef DrawerItem = FoCoCoDrawerItem;
