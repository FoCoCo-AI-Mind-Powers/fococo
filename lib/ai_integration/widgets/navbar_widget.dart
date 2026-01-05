import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/glass_design_system.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../backend/backend.dart';
import '../../auth/firebase_auth/auth_util.dart';
import '../../services/subscription_state_provider.dart';
import 'floating_audio_player.dart';

/// Enhanced Navigation Item with Performance Data
class EnhancedNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final Color? color;
  final bool hasNotification;
  final int? notificationCount;

  const EnhancedNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.color,
    this.hasNotification = false,
    this.notificationCount,
  });
}

/// Enhanced FoCoCo Navigation System - Matching the attached image design
/// Features glassmorphic design with drawer, charts, and real-time data
class EnhancedFoCoCoNavBar extends StatefulWidget {
  final String currentRoute;
  final Function(String route)? onTap;
  final bool showLabels;
  final double height;
  final EdgeInsets margin;
  final bool enableVoiceButton;
  final bool useGlassEffect;
  final VoidCallback? onVoicePressed;
  final bool showDrawer;
  final bool showMiniChart;
  final UserRecord? currentUser;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const EnhancedFoCoCoNavBar({
    Key? key,
    required this.currentRoute,
    this.onTap,
    this.showLabels = true,
    this.height = 110.0,
    this.margin = const EdgeInsets.all(0),
    this.enableVoiceButton = true,
    this.useGlassEffect = true,
    this.onVoicePressed,
    this.showDrawer = true,
    this.showMiniChart = true,
    this.currentUser,
    this.scaffoldKey,
  }) : super(key: key);

  @override
  State<EnhancedFoCoCoNavBar> createState() => _EnhancedFoCoCoNavBarState();
}

class _EnhancedFoCoCoNavBarState extends State<EnhancedFoCoCoNavBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 0;

  // Enhanced navigation items matching the image design
  final List<EnhancedNavigationItem> _navItems = [
    EnhancedNavigationItem(
      icon: Icons.access_time_outlined,
      activeIcon: Icons.access_time_rounded,
      label: 'Today',
      route: 'dashboard',
      color: const Color(0xFF0A3669), // Brand navy
    ),
    EnhancedNavigationItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'MindCoach',
      route: 'mind_coach',
      color: const Color(0xFF017B3D), // Brand green
    ),
    EnhancedNavigationItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'Insights',
      route: 'ai_insights',
      color: const Color(0xFF7C3AED), // Purple - mindfulness/meditation color
    ),
    EnhancedNavigationItem(
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on_rounded,
      label: 'FoCoMap',
      route: 'foco_map',
      color: const Color(0xFFFEA400), // Brand orange
    ),
    EnhancedNavigationItem(
      icon: FontAwesomeIcons.flag,
      activeIcon: FontAwesomeIcons.flag,
      label: 'GolfSync',
      route: 'golf_sync',
      color: const Color(0xFF0EA5E9), // Calm blue - different from navy
    ),
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Set initial index based on current route
    _currentIndex = _getIndexFromRoute(widget.currentRoute);

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void didUpdateWidget(EnhancedFoCoCoNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      final newIndex = _getIndexFromRoute(widget.currentRoute);
      if (newIndex != _currentIndex) {
        _animateToIndex(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  int _getIndexFromRoute(String route) {
    final index = _navItems.indexWhere((item) => item.route == route);
    return index >= 0 ? index : 0;
  }

  /// Get adjusted color based on theme brightness
  /// Makes dark blue lighter in dark mode for better visibility
  Color _getAdjustedColor(Color originalColor, FlutterFlowTheme theme) {
    // Check if it's the navy blue color (0xFF0A3669) and we're in dark mode
    if (originalColor.value == 0xFF0A3669) {
      final brightness = Theme.of(context).brightness;
      if (brightness == Brightness.dark) {
        // Use a lighter blue for dark mode (0xFF1E5A9E - lighter navy)
        return const Color(0xFF1E5A9E);
      }
    }
    return originalColor;
  }

  void _animateToIndex(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      _scaleController.reset();
      _scaleController.forward();

      HapticFeedback.lightImpact();
    }
  }

  void _onItemTapped(int index) {
    final item = _navItems[index];

    print('🔄 Enhanced NavBar: Tapping ${item.label} (route: ${item.route})');
    print('🔄 Current route: ${widget.currentRoute}');
    print('🔄 Current index: $_currentIndex, Tapped index: $index');

    if (item.route != widget.currentRoute) {
      _animateToIndex(index);
      print('🔄 Calling onTap with route: ${item.route}');
      widget.onTap?.call(item.route);
    } else {
      print('🔄 Same route, not navigating');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    print('🔄 Enhanced NavBar Build: Current route: ${widget.currentRoute}');
    print('🔄 Enhanced NavBar Build: Current index: $_currentIndex');
    print('🔄 Enhanced NavBar Build: Glass effect: ${widget.useGlassEffect}');
    print('🔄 Enhanced NavBar Build: Height: ${widget.height}');

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: widget.useGlassEffect
          ? _buildGlassNavBar(theme, screenWidth)
          : _buildStandardNavBar(theme, screenWidth),
    );
  }

  /// Build glassmorphic navigation bar
  Widget _buildGlassNavBar(FlutterFlowTheme theme, double screenWidth) {
    return Container(
      height: widget.height,
      margin: widget.margin,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassDesignSystem.glassBlur,
            sigmaY: GlassDesignSystem.glassBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.glassBackground
                      .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                  theme.glassTint
                      .withValues(alpha: GlassDesignSystem.glassOpacity),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: theme.glassBorder.withValues(
                      alpha: GlassDesignSystem.glassBorderOpacity + 0.1),
                  width: 1.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, -8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: _buildNavBarContent(theme, screenWidth, true),
          ),
        ),
      ),
    );
  }

  /// Build standard navigation bar
  Widget _buildStandardNavBar(FlutterFlowTheme theme, double screenWidth) {
    return Container(
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primaryBackground,
            theme.secondaryBackground,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: theme.alternate,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _buildNavBarContent(theme, screenWidth, false),
    );
  }

  /// Build the navigation bar content
  Widget _buildNavBarContent(
      FlutterFlowTheme theme, double screenWidth, bool isGlassMode) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Navigation items - centered
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: _navItems.asMap().entries.map((entry) {
                return _buildNavItem(entry.key, theme, isGlassMode);
              }).toList(),
            ),
          ),
        ),

        // Floating Audio Player - centered above nav items (overlay)
        Positioned(
          top: -45,
          child: const FloatingAudioPlayer(),
        ),
      ],
    );
  }

  /// Build individual navigation item
  Widget _buildNavItem(int index, FlutterFlowTheme theme, bool isGlassMode) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;
    // Get adjusted color for dark mode (lighter blue)
    final itemColor = item.color != null
        ? _getAdjustedColor(item.color!, theme)
        : theme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: index < _navItems.length - 1 ? 6.0 : 0),
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Container(
              height: widget.height - 32,
              child: Transform.scale(
                scale: isActive ? _scaleAnimation.value : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon container with notification badge
                    Flexible(
                      child: Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? itemColor.withValues(
                                      alpha: isGlassMode ? 0.25 : 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: isActive && isGlassMode
                                  ? Border.all(
                                      color: itemColor.withValues(alpha: 0.5),
                                      width: 1.5,
                                    )
                                  : null,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: itemColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                key: ValueKey('${item.route}_${isActive}'),
                                color: isActive
                                    ? itemColor
                                    : theme.primaryText.withValues(alpha: 0.7),
                                size: isActive ? 32 : 28,
                              ),
                            ),
                          ),

                          // Notification badge
                          if (item.hasNotification && !isActive)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: theme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.primaryBackground,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.error.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Label
                    if (widget.showLabels) ...[
                      const SizedBox(height: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.labelMedium.override(
                          fontFamily: 'Inter',
                          color: isActive
                              ? itemColor
                              : theme.primaryText.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w600,
                          height: 1.1,
                          letterSpacing: isActive ? 0.2 : 0.1,
                        ),
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Enhanced Drawer Widget matching the image design
class EnhancedFoCoCoDrawer extends StatefulWidget {
  final UserRecord? currentUser;
  final String currentRoute;
  final Function(String route)? onNavigate;

  const EnhancedFoCoCoDrawer({
    Key? key,
    this.currentUser,
    required this.currentRoute,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<EnhancedFoCoCoDrawer> createState() => _EnhancedFoCoCoDrawerState();
}

class _EnhancedFoCoCoDrawerState extends State<EnhancedFoCoCoDrawer> {
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
                  // TOP AREA: Brand + User Info
                  _buildDrawerHeader(theme),

                  // MIDDLE AREA: Navigation items
                  Expanded(
                    child: _buildDrawerItems(theme),
                  ),

                  // BOTTOM AREA: Sign Out + Version
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
          // Section 1: FoCoCo Brand Logo + Name + Tagline
          Row(
            children: [
              // Logo
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
                    child: Icon(
                      Icons.golf_course,
                      color: theme.primary,
                      size: 24,
                    ),
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

          // Section 2: User avatar/photo and display name
          Row(
            children: [
              // User avatar
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
                      : Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name
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
                    // Membership tier badge
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

          // Upgrade suggestion based on membership tier
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

    // Add trial days info if in trial
    if (isWithinTrial && trialDaysRemaining > 0) {
      upgradeText = '$upgradeText ($trialDaysRemaining ${trialDaysRemaining == 1 ? 'day' : 'days'} left in trial)';
    }

    String upgradeButtonText = 'Upgrade';
    if (isWithinTrial && trialDaysRemaining > 0) {
      upgradeButtonText = 'Upgrade ($trialDaysRemaining${trialDaysRemaining == 1 ? 'd' : 'd'} left)';
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
      DrawerItem(
        icon: Icons.person_outline,
        title: 'Profile',
        route: 'profile',
        subtitle:
            'Personal data, VARK results, voice mode, metric/imperial, etc.',
      ),
      DrawerItem(
        icon: Icons.settings_outlined,
        title: 'Settings',
        route: 'settings',
        subtitle: 'Permissions, privacy, data export/delete, accessibility',
      ),
      DrawerItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        route: 'support',
        subtitle: 'FAQ, Contact, Feedback',
      ),
      DrawerItem(
        icon: Icons.star_outline,
        title: 'Rate App',
        route: null, // Special handling
        subtitle: 'Opens App Store / Google Play',
      ),
      DrawerItem(
        icon: Icons.info_outline,
        title: 'About FoCoCo',
        route: null, // Special handling
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
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              // Special handling for Rate App and About
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
    // Platform-specific app store URLs
    // This will be implemented when the app is published
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'App rating will be available when FoCoCo is released on the App Store!',
        ),
        backgroundColor: theme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleAboutFoCoCo(FlutterFlowTheme theme) async {
    // Show about dialog or navigate to about page
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
                    final url = Uri.parse('https://fococo.app');
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
                        Icon(
                          Icons.language,
                          color: theme.primary,
                          size: 20,
                        ),
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
                        Icon(
                          Icons.arrow_forward_ios,
                          color: theme.primary,
                          size: 16,
                        ),
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
    // Close drawer first if it's open (safely)
    try {
      if (Navigator.of(context, rootNavigator: false).canPop()) {
        Navigator.of(context, rootNavigator: false).pop();
        // Wait a bit for drawer to close
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      // Ignore errors when closing drawer
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

    if (confirmed == true && context.mounted) {
      await authManager.signOut();
      if (context.mounted) {
        context.go('/login');
      }
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
          // Sign Out button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSignOutConfirmation(theme),
              icon: Icon(
                Icons.logout,
                color: theme.error,
                size: 20,
              ),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
          // Version
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

/// Drawer Item Model
class DrawerItem {
  final IconData icon;
  final String title;
  final String? route;
  final String? subtitle;

  const DrawerItem({
    required this.icon,
    required this.title,
    this.route,
    this.subtitle,
  });
}
