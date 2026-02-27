import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/glass_design_system.dart';
import '/services/subscription_state_provider.dart';

/// Drawer item model for FoCoCo drawer menu.
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

/// Shared FoCoCo app drawer (menu). Use as the left drawer on main pages.
/// App bar left action should only open this drawer on main shell pages.
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
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.glassBackground.withValues(alpha: 0.95),
                  theme.glassTint.withValues(alpha: 0.9),
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: theme.glassBorder.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildDrawerHeader(theme),
                  Expanded(child: _buildDrawerItems(theme)),
                  _buildDrawerFooter(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(FlutterFlowTheme theme) {
    final membershipTier = widget.currentUser?.currentMembershipTier ?? 'base';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo/Logo.png',
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.golf_course, color: theme.primary, size: 24),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FoCoCo',
                      style: theme.titleLarge.override(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Your Mind Powers the Game',
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        fontSize: 11,
                        height: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: widget.currentUser?.profileImageUrl.isNotEmpty == true
                      ? Image.network(
                          widget.currentUser!.profileImageUrl,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.person_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.currentUser?.displayName.isNotEmpty == true
                          ? widget.currentUser!.displayName
                          : 'Golfer',
                      style: theme.titleMedium.override(
                        color: theme.primaryText,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        membershipTier.toUpperCase(),
                        style: theme.labelSmall.override(
                          color: theme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          fontSize: 10,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUpgradeSuggestion(theme, membershipTier),
        ],
      ),
    );
  }

  Widget _buildUpgradeSuggestion(
      FlutterFlowTheme theme, String membershipTier) {
    final subscriptionProvider = SubscriptionStateProvider();
    final isWithinTrial = subscriptionProvider.isWithinTrialPeriod();
    final trialDaysRemaining = subscriptionProvider.getTrialDaysRemaining();

    String upgradeText;
    switch (membershipTier.toLowerCase()) {
      case 'base':
        upgradeText =
            'Unlock personalized coaching and your Mind Power Index (MPI)';
        break;
      case 'plus':
        upgradeText = 'Upgrade for advanced insights and full FoCoMap access';
        break;
      case 'prime':
        upgradeText = 'Fully unlocked! The connection between Mind & Game';
        break;
      default:
        upgradeText =
            'Unlock personalized coaching and your Mind Power Index (MPI)';
    }
    if (isWithinTrial && trialDaysRemaining > 0) {
      upgradeText =
          '$upgradeText ($trialDaysRemaining ${trialDaysRemaining == 1 ? 'day' : 'days'} left in trial)';
    }

    String upgradeButtonText = 'Upgrade';
    if (isWithinTrial && trialDaysRemaining > 0) {
      upgradeButtonText =
          'Upgrade ($trialDaysRemaining${trialDaysRemaining == 1 ? 'd' : 'd'} left)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              upgradeText,
              style: theme.bodySmall.override(
                color: theme.secondaryText.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (membershipTier.toLowerCase() != 'prime')
            GestureDetector(
              onTap: () async {
                try {
                  if (Navigator.of(context, rootNavigator: false).canPop()) {
                    Navigator.of(context, rootNavigator: false).pop();
                    await Future.delayed(const Duration(milliseconds: 150));
                  }
                } catch (e) {
                  debugPrint('Note: Could not close drawer: $e');
                }
                if (!context.mounted) return;
                widget.onNavigate?.call('subscription_management');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  upgradeButtonText,
                  style: theme.labelSmall.override(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems(FlutterFlowTheme theme) {
    final items = [
      FoCoCoDrawerItem(
        icon: Icons.person_outline,
        title: 'Profile',
        route: 'profile',
        subtitle:
            'Personal data, VARK results, voice mode, metric/imperial, etc.',
      ),
      FoCoCoDrawerItem(
        icon: Icons.settings_outlined,
        title: 'Settings',
        route: 'settings',
        subtitle: 'Permissions, privacy, data export/delete, accessibility',
      ),
      FoCoCoDrawerItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        route: 'support',
        subtitle: 'FAQ, Contact, Feedback',
      ),
      FoCoCoDrawerItem(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'GolfChat',
        route: 'golf_chat',
        subtitle: 'Reflect • Understand • Reset',
      ),
      FoCoCoDrawerItem(
        icon: Icons.star_outline,
        title: 'Rate App',
        route: null,
        subtitle: 'Opens App Store / Google Play',
      ),
      FoCoCoDrawerItem(
        icon: Icons.info_outline,
        title: 'About FoCoCo',
        route: null,
        subtitle: 'Brand story, Website / Web App link',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isActive = widget.currentRoute == item.route;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: isActive
                    ? theme.primary
                    : theme.primaryText.withValues(alpha: 0.7),
                size: 22,
              ),
            ),
            title: Text(
              item.title,
              style: theme.bodyMedium.override(
                color: isActive
                    ? theme.primary
                    : theme.primaryText.withValues(alpha: 0.9),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
              ),
            ),
            subtitle: item.subtitle != null
                ? Text(
                    item.subtitle!,
                    style: theme.bodySmall.override(
                      color: theme.secondaryText.withValues(alpha: 0.7),
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () {
              try {
                final scaffold = Scaffold.of(context);
                if (scaffold.isDrawerOpen) scaffold.closeDrawer();
              } catch (e) {
                try {
                  if (Navigator.of(context, rootNavigator: false).canPop()) {
                    Navigator.of(context, rootNavigator: false).pop();
                  }
                } catch (navError) {
                  debugPrint('Note: Could not close drawer: $navError');
                }
              }
              if (item.title == 'Rate App') {
                _handleRateApp(theme);
              } else if (item.title == 'About FoCoCo') {
                _handleAboutFoCoCo(theme);
              } else if (item.route != null) {
                widget.onNavigate?.call(item.route!);
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  void _handleRateApp(FlutterFlowTheme theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'App rating will be available when FoCoCo is released on the App Store!',
        ),
        backgroundColor: theme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleAboutFoCoCo(FlutterFlowTheme theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.primaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo/Logo.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.golf_course, color: theme.primary);
                },
              ),
              const SizedBox(width: 12),
              Text(
                'About FoCoCo',
                style: theme.titleLarge.override(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FoCoCo - Your Mind Powers the Game',
                  style: theme.titleMedium.override(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'FoCoCo is a comprehensive mental performance coaching platform designed specifically for golfers. We combine AI-powered insights with personalized coaching modules to help you unlock your full potential on the course.',
                  style: theme.bodyMedium.override(
                    color: theme.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('https://fococo.ai');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.language, color: theme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Visit Website',
                          style: theme.bodyMedium.override(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, color: theme.primary, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: theme.bodyMedium.override(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSignOutConfirmation(FlutterFlowTheme theme) async {
    try {
      if (Navigator.of(context, rootNavigator: false).canPop()) {
        Navigator.of(context, rootNavigator: false).pop();
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      debugPrint('Note: Could not close drawer: $e');
    }
    if (!context.mounted) return;

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
                    child: Icon(Icons.logout, color: theme.error, size: 24),
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

    if (confirmed == true && context.mounted) {
      await authManager.signOut();
      if (context.mounted) context.go('/login');
    }
  }

  Widget _buildDrawerFooter(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Divider(
            color: theme.glassBorder.withValues(alpha: 0.3),
            thickness: 1,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSignOutConfirmation(theme),
              icon: Icon(Icons.logout, color: theme.error, size: 20),
              label: Text(
                'Sign Out',
                style: theme.bodyMedium.override(
                  color: theme.error,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.error.withValues(alpha: 0.1),
                foregroundColor: theme.error,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Version: v1.0.0',
            style: theme.labelSmall.override(
              color: theme.secondaryText.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward-compatible alias for [FoCoCoDrawer]. Prefer [FoCoCoDrawer].
typedef EnhancedFoCoCoDrawer = FoCoCoDrawer;

/// Backward-compatible alias for [FoCoCoDrawerItem].
typedef DrawerItem = FoCoCoDrawerItem;
