import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';

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
import '/services/revenuecat_service.dart';
import '/services/units_preference_service.dart';
import '/services/ai_voice_preference_service.dart';
import '/services/app_session_prefs_service.dart';
import '/services/haptic_service.dart';
import '/services/account_deletion_service.dart';
import '/features/mindcoach_v2/services/mindcoach_replay_cache.dart';
import '/features/mindcoach_v2/services/mindcoach_session_prefetch.dart';
import '/pages/support/support_submission_widget.dart';
import '/services/support_submission_service.dart';
import '/widgets/fococo_confirm_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';

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

/// Visual treatment for [FoCoCoDrawer].
///
/// - [standard]: flat dark surface used everywhere by default — preserves the
///   existing app look.
/// - [mind]: "Mind" ecosystem shell (MindCoach / MindSession). Frosted glass
///   over an animated organic gradient with a soft clipped right edge and
///   staggered reveal on open. Designed to feel like an immersive extension
///   of the screen rather than a utility menu.
enum FoCoCoDrawerVariant { standard, mind }

/// Shared FoCoCo app drawer (menu). Use as the left drawer on main pages.
class FoCoCoDrawer extends StatefulWidget {
  final UserRecord? currentUser;
  final String currentRoute;
  final void Function(String route)? onNavigate;

  /// Which visual shell to render. Content is identical across variants.
  final FoCoCoDrawerVariant variant;

  const FoCoCoDrawer({
    super.key,
    this.currentUser,
    required this.currentRoute,
    this.onNavigate,
    this.variant = FoCoCoDrawerVariant.standard,
  });

  @override
  State<FoCoCoDrawer> createState() => _FoCoCoDrawerState();
}

class _FoCoCoDrawerState extends State<FoCoCoDrawer>
    with TickerProviderStateMixin {
  // Slow-breathing background animation used only in the `mind` variant.
  // Dispose-safe: created in initState, stopped+disposed in dispose.
  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  // One-shot reveal animation that drives the staggered section entrance
  // when the mind-variant drawer opens. Cheap (no repeat, no per-frame
  // rebuild once completed).
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  String _appVersion = '';
  String _units = 'metric';
  bool _micEnabled = false;
  bool _aiVoiceEnabled = true;
  bool _notificationsEnabled = false;
  bool _gpsEnabled = false;
  UserRecord? _loadedUser;

  @override
  void initState() {
    super.initState();
    _loadedUser = widget.currentUser;
    if (_loadedUser == null && loggedIn && currentUserUid.isNotEmpty) {
      unawaited(_loadUserRecord());
    }
    _loadPreferences();
    _loadAppVersion();

    // Staggered reveal runs for both variants now — gives the standard shell
    // the same premium entrance. Ambient orbs stay mind-only.
    _revealController.forward();
    if (widget.variant == FoCoCoDrawerVariant.mind) {
      _ambientController.repeat();
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final units = await UnitsPreferenceService.load();
    final aiVoice = await AiVoicePreferenceService.isEnabled();
    final gps = await AppSessionPrefsService.isGpsEnabled();
    if (!mounted) return;
    setState(() {
      _units = units;
      _micEnabled = prefs.getBool(_kMicrophoneKey) ?? false;
      _aiVoiceEnabled = aiVoice;
      _notificationsEnabled = prefs.getBool(_kNotificationsKey) ?? false;
      _gpsEnabled = gps;
    });
  }

  Future<void> _loadUserRecord() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserUid)
          .get();
      if (!doc.exists || !mounted) return;
      setState(() {
        _loadedUser = UserRecord.fromSnapshot(doc);
      });
    } catch (e) {
      debugPrint('FoCoCoDrawer user load: $e');
    }
  }

  UserRecord? get _effectiveUser => widget.currentUser ?? _loadedUser;

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
    final user = _effectiveUser;
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
    final tier = _effectiveUser?.currentMembershipTier ?? sub.userTier;

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
    final isFounder = _effectiveUser?.snapshotData['isFounder'] == true;

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

    // Build the list of section widgets ONCE so both shells render identical
    // content. For the mind variant we wrap each with a staggered reveal.
    final sections = <Widget>[
      _buildIdentitySection(theme),
      const SizedBox(height: 28),
      _buildSection(theme, 'ACCOUNT', _buildAccountRows(theme)),
      const SizedBox(height: 28),
      _buildSection(theme, 'PREFERENCES', _buildPreferencesRows(theme)),
      const SizedBox(height: 28),
      _buildSection(theme, 'DATA & PRIVACY', _buildDataPrivacyRows(theme)),
      const SizedBox(height: 28),
      _buildSection(theme, 'SUPPORT', _buildSupportRows(theme)),
      const SizedBox(height: 28),
      _buildSection(theme, 'LEGAL', _buildLegalRows(theme)),
      const SizedBox(height: 20),
      ..._buildAboutRows(theme),
    ];

    if (widget.variant == FoCoCoDrawerVariant.mind) {
      return _buildMindShell(
        theme: theme,
        screenWidth: screenWidth,
        sections: sections,
      );
    }
    return _buildStandardShell(
      theme: theme,
      screenWidth: screenWidth,
      sections: sections,
    );
  }

  // ── Standard shell (unchanged original visual) ────────────────────────────

  Widget _buildStandardShell({
    required FlutterFlowTheme theme,
    required double screenWidth,
    required List<Widget> sections,
  }) {
    return SizedBox(
      width: screenWidth * 0.86,
      child: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: ClipPath(
          clipper: const _MindDrawerEdgeClipper(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _kBgColor,
                  Color.alphaBlend(
                    _kPurple.withValues(alpha: 0.06),
                    _kBgColor,
                  ),
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: _kGold.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildDrawerHeaderActions(theme),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        return _StaggeredReveal(
                          controller: _revealController,
                          index: index,
                          total: sections.length,
                          child: sections[index],
                        );
                      },
                    ),
                  ),
                  _StaggeredReveal(
                    controller: _revealController,
                    index: sections.length,
                    total: sections.length + 1,
                    child: _buildLogout(theme),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Close (X) button row at the top of the drawer — gives users a visible
  /// dismiss affordance instead of relying on scrim tap / swipe only.
  Widget _buildDrawerHeaderActions(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _closeDrawer,
            splashRadius: 22,
            tooltip: 'Close menu',
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mind shell (MindCoach / MindSession) ──────────────────────────────────
  //
  // Visual stack, bottom → top:
  //   1. Deep indigo/black base
  //   2. Animated organic-orb custom painter (very slow, 14s loop)
  //   3. Soft diagonal gradient overlay
  //   4. BackdropFilter blur + translucent gold border (frosted glass)
  //   5. Content — staggered fade-up per section driven by _revealController
  //   6. Clipped right edge for a soft curved drawer silhouette

  Widget _buildMindShell({
    required FlutterFlowTheme theme,
    required double screenWidth,
    required List<Widget> sections,
  }) {
    return SizedBox(
      width: screenWidth * 0.85,
      child: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: ClipPath(
          clipper: const _MindDrawerEdgeClipper(),
          child: Stack(
            children: [
              // 1-2. Base + animated organic orbs.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) => CustomPaint(
                    painter: _MindDrawerAmbientPainter(
                      progress: _ambientController.value,
                    ),
                  ),
                ),
              ),
              // 3. Diagonal gradient wash — adds depth without overpowering.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _kPurple.withValues(alpha: 0.08),
                        Colors.transparent,
                        _kGold.withValues(alpha: 0.05),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              // 4. Frosted glass. The BackdropFilter blurs whatever is painted
              // behind this drawer in the scrim — pairs with the drawer
              // scrim color to get a true glassmorphism feel.
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.025),
                      border: Border(
                        right: BorderSide(
                          color: _kGold.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 5. Content with staggered reveal.
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          return _StaggeredReveal(
                            controller: _revealController,
                            index: index,
                            total: sections.length,
                            child: sections[index],
                          );
                        },
                      ),
                    ),
                    _StaggeredReveal(
                      controller: _revealController,
                      index: sections.length,
                      total: sections.length + 1,
                      child: _buildLogout(theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Section — Identity + Status Pill ──────────────────────────────────

  Widget _buildIdentitySection(FlutterFlowTheme theme) {
    final pill = _statusPillData();
    final userName = _effectiveUser?.displayName.isNotEmpty == true
        ? _effectiveUser!.displayName
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
        if ((_effectiveUser?.email ?? currentUserEmail).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _effectiveUser?.email ?? currentUserEmail,
            style: theme.bodySmall.override(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _units == 'imperial' ? 'Units: Imperial' : 'Units: Metric',
          style: theme.labelSmall.override(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
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

  // ── ACCOUNT section ───────────────────────────────────────────────────────

  List<Widget> _buildAccountRows(FlutterFlowTheme theme) {
    return [
      _buildRow(theme, 'Profile', onTap: () {
        _closeDrawer();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) widget.onNavigate?.call('edit_profile');
        });
      }),
      _buildRow(theme, 'Manage Subscription', onTap: _handleManageSubscription),
      _buildRow(theme, 'Restore Purchases', onTap: _handleRestorePurchases),
    ];
  }

  Future<void> _handleRestorePurchases() async {
    _closeDrawer();
    try {
      final info = await RevenueCatService().restorePurchases();
      final active = info.entitlements.active.isNotEmpty;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active
                ? 'Subscription restored'
                : 'No active subscription found.',
          ),
          backgroundColor: _kGreen,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not restore purchases. Try again.'),
        ),
      );
    }
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

  List<Widget> _buildPreferencesRows(FlutterFlowTheme theme) {
    return [
      _buildRow(
        theme,
        'Units',
        trailing: _buildInlineSelector(
          theme,
          options: ['Metric', 'Imperial'],
          selected: _units == 'metric' ? 'Metric' : 'Imperial',
          onChanged: (val) async {
            final newVal =
                val.toLowerCase() == 'imperial' ? 'imperial' : 'metric';
            await UnitsPreferenceService.setUnits(newVal);
            await HapticService.light();
            if (mounted) setState(() => _units = newVal);
          },
        ),
      ),
      _buildRow(
        theme,
        'AI Voice',
        trailing: _buildToggle(
          theme,
          value: _aiVoiceEnabled,
          onChanged: (val) async {
            await AiVoicePreferenceService.setEnabled(val);
            await HapticService.light();
            if (mounted) setState(() => _aiVoiceEnabled = val);
          },
        ),
      ),
      _buildRow(
        theme,
        'Notifications',
        trailing: _buildToggle(
          theme,
          value: _notificationsEnabled,
          onChanged: (val) async {
            if (!val) {
              await openAppSettings();
            }
            setState(() => _notificationsEnabled = val);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_kNotificationsKey, val);
            await HapticService.light();
          },
        ),
      ),
      _buildRow(
        theme,
        'GPS',
        trailing: _buildToggle(
          theme,
          value: _gpsEnabled,
          onChanged: (val) async {
            if (val) {
              await Permission.locationWhenInUse.request();
            }
            await AppSessionPrefsService.setGpsEnabled(val);
            await HapticService.light();
            if (mounted) setState(() => _gpsEnabled = val);
          },
        ),
      ),
    ];
  }

  List<Widget> _buildDataPrivacyRows(FlutterFlowTheme theme) {
    return [
      _buildRow(theme, 'Download My Data', onTap: _handleDownloadData),
      _buildRow(theme, 'Delete My Account', onTap: _handleDeleteAccount),
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

  Future<void> _handleDownloadData() async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final confirmed = await showFoCoCoConfirmDialog(
      context: context,
      title: 'Download your data?',
      message:
          "We'll prepare a copy of your account and activity data and email you when it's ready.",
      confirmLabel: 'Request Data',
      icon: Icons.download_outlined,
    );
    if (confirmed != true || !mounted) return;

    final email = _effectiveUser?.email ?? currentUserEmail;
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
      const SnackBar(
        content: Text(
          "Data request received. We'll email you when your export is ready.",
        ),
        backgroundColor: _kGreen,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final confirmed = await showFoCoCoDeleteAccountDialog(context);
    if (confirmed != true || !mounted) return;

    final email = _effectiveUser?.email ?? currentUserEmail;
    await AccountDeletionService.requestDeletion(email: email);
    await AccountDeletionService.clearLocalState();
    await MindCoachReplayCache.clearAllForUser();
    MindCoachSessionPrefetch.clear();
    if (!mounted) return;
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
      _buildRow(theme, 'Email Support', onTap: () async {
        _closeDrawer();
        final url = Uri.parse(
          'mailto:support@fococo.ai?subject=FoCoCo%20Support',
        );
        if (await canLaunchUrl(url)) await launchUrl(url);
      }),
      _buildRow(theme, 'Report a Bug', onTap: () {
        _closeDrawer();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            unawaited(
              SupportSubmissionWidget.open(
                context,
                SupportSubmissionType.bug,
              ),
            );
          }
        });
      }),
      _buildRow(theme, 'Send Feedback', onTap: () {
        _closeDrawer();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            unawaited(
              SupportSubmissionWidget.open(
                context,
                SupportSubmissionType.feedback,
              ),
            );
          }
        });
      }),
      if (_isMobile)
        _buildRow(theme, 'Rate App', onTap: () async {
          _closeDrawer();
          final review = InAppReview.instance;
          if (await review.isAvailable()) {
            await review.requestReview();
          }
        }),
    ];
  }

  // ── LEGAL section ─────────────────────────────────────────────────────────

  List<Widget> _buildLegalRows(FlutterFlowTheme theme) {
    return [
      _buildRow(theme, 'Privacy Policy', onTap: () async {
        final url = Uri.parse('https://www.fococo.ai/privacy-policy');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }),
      _buildRow(theme, 'Terms of Service', onTap: () async {
        final url = Uri.parse('https://www.fococo.ai/terms');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }),
      _buildRow(theme, 'AI Disclosure', onTap: () async {
        final url = Uri.parse('https://www.fococo.ai/ai-disclosure');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }),
      _buildRow(theme, 'Non-Medical Disclaimer', onTap: () async {
        final url = Uri.parse('https://www.fococo.ai/non-medical-disclaimer');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }),
      _buildRow(theme, 'Cookie Policy', onTap: () async {
        final url = Uri.parse('https://www.fococo.ai/cookie-policy');
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
          final confirmed = await showFoCoCoConfirmDialog(
            context: context,
            title: 'Log out of FoCoCo?',
            message: 'You can sign back in anytime with your account.',
            confirmLabel: 'Log Out',
            icon: Icons.logout_rounded,
            accent: FoCoCoDialogAccent.destructive,
          );
          if (confirmed != true) return;
          await HapticService.light();
          await AppSessionPrefsService.setPostLoginTabFoCoCo();
          await MindCoachReplayCache.clearAllForUser();
          MindCoachSessionPrefetch.clear();
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

// ─── Mind-variant internals ────────────────────────────────────────────────

/// Staggered fade-up reveal for a single drawer row.
///
/// Each item picks a slice of the parent controller's 0→1 progress based on
/// its index, so earlier rows finish their entrance before later ones start.
/// Implemented as a plain [AnimatedBuilder] so it rebuilds only itself, not
/// the whole drawer.
class _StaggeredReveal extends StatelessWidget {
  const _StaggeredReveal({
    required this.controller,
    required this.index,
    required this.total,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final int total;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Each item gets a 45%-long window, offset by its index. Later items wait
    // longer before starting. Clamped so the first/last items aren't off-range.
    final windowLen = 0.45;
    final startMax = (1.0 - windowLen).clamp(0.0, 1.0);
    final start = total <= 1
        ? 0.0
        : (index / (total - 1)) * startMax;
    final end = (start + windowLen).clamp(0.0, 1.0);

    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
    );
  }
}

/// Soft curve on the drawer's right edge — avoids the hard vertical line that
/// makes the standard Material drawer feel like a utility panel. Subtle
/// enough that it reads as "premium detail" rather than decoration.
class _MindDrawerEdgeClipper extends CustomClipper<Path> {
  const _MindDrawerEdgeClipper();

  @override
  Path getClip(Size size) {
    const curveDepth = 18.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - curveDepth, 0)
      ..quadraticBezierTo(
        size.width,
        size.height * 0.15,
        size.width,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width,
        size.height * 0.85,
        size.width - curveDepth,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _MindDrawerEdgeClipper oldClipper) => false;
}

/// Animated organic-orb background for the mind drawer.
///
/// Paints 3 large, low-alpha radial gradients that drift on independent
/// phase offsets. `progress` comes from a 14s loop controller, so the motion
/// reads as a slow breath rather than animation. Frame cost is 3 `drawCircle`
/// calls with radial shaders — cheap even on iPhone 11.
class _MindDrawerAmbientPainter extends CustomPainter {
  const _MindDrawerAmbientPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill — deep, ink-indigo black so the orbs read softly.
    final base = Paint()..color = const Color(0xFF0A0A16);
    canvas.drawRect(Offset.zero & size, base);

    final orbs = <_OrbSpec>[
      _OrbSpec(
        color: _kPurple,
        baseOffset: Offset(size.width * 0.25, size.height * 0.22),
        drift: const Offset(18, 14),
        radius: size.width * 0.65,
        phase: 0.0,
        alpha: 0.28,
      ),
      _OrbSpec(
        color: _kGold,
        baseOffset: Offset(size.width * 0.85, size.height * 0.55),
        drift: const Offset(-14, 22),
        radius: size.width * 0.55,
        phase: 0.33,
        alpha: 0.18,
      ),
      _OrbSpec(
        color: _kGreen,
        baseOffset: Offset(size.width * 0.30, size.height * 0.82),
        drift: const Offset(22, -10),
        radius: size.width * 0.60,
        phase: 0.66,
        alpha: 0.12,
      ),
    ];

    for (final orb in orbs) {
      final t = (progress + orb.phase) % 1.0;
      final theta = t * 2 * math.pi;
      final center = orb.baseOffset +
          Offset(
            math.cos(theta) * orb.drift.dx,
            math.sin(theta) * orb.drift.dy,
          );
      final shader = RadialGradient(
        colors: [
          orb.color.withValues(alpha: orb.alpha),
          orb.color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: orb.radius));
      final paint = Paint()..shader = shader;
      canvas.drawCircle(center, orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MindDrawerAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _OrbSpec {
  const _OrbSpec({
    required this.color,
    required this.baseOffset,
    required this.drift,
    required this.radius,
    required this.phase,
    required this.alpha,
  });

  final Color color;
  final Offset baseOffset;
  final Offset drift;
  final double radius;
  final double phase;
  final double alpha;
}
