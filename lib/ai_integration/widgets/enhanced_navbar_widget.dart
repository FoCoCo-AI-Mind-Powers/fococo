import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/glass_design_system.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import '../../backend/backend.dart';
import '../../auth/firebase_auth/auth_util.dart';
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
      route: 'coaching_modules',
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
      route: 'golf_rounds',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: index < _navItems.length - 1 ? 8.0 : 0),
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
                                  ? (item.color ?? theme.primary).withValues(
                                      alpha: isGlassMode ? 0.25 : 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: isActive && isGlassMode
                                  ? Border.all(
                                      color: (item.color ?? theme.primary)
                                          .withValues(alpha: 0.5),
                                      width: 1.5,
                                    )
                                  : null,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: (item.color ?? theme.primary)
                                            .withValues(alpha: 0.3),
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
                                    ? (item.color ?? theme.primary)
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
                              ? (item.color ?? theme.primary)
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
                  // Header with user info
                  _buildDrawerHeader(theme),

                  // Performance mini chart
                  _buildPerformanceChart(theme),

                  // Navigation items
                  Expanded(
                    child: _buildDrawerItems(theme),
                  ),

                  // Footer
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // User avatar
          Container(
            width: 80,
            height: 80,
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
              borderRadius: BorderRadius.circular(40),
              child: widget.currentUser?.profileImageUrl.isNotEmpty == true
                  ? Image.network(
                      widget.currentUser!.profileImageUrl,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
            ),
          ),

          const SizedBox(height: 12),

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

          // Membership tier
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.currentUser?.currentMembershipTier.toUpperCase() ?? 'BASE',
              style: theme.labelSmall.override(
                color: theme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(FlutterFlowTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryBackground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.glassBorder.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mental Performance',
                style: theme.bodyMedium.override(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                '${widget.currentUser?.mentalPerformanceScore.toInt() ?? 76}',
                style: theme.titleMedium.override(
                  color: theme.primary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: (widget.currentUser?.mentalPerformanceScore ?? 76) / 100,
            backgroundColor: theme.alternate.withValues(alpha: 0.3),
            progressColor: theme.primary,
            barRadius: const Radius.circular(3),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems(FlutterFlowTheme theme) {
    final items = [
      DrawerItem(
        icon: Icons.dashboard_rounded,
        title: 'Dashboard',
        route: 'dashboard',
      ),
      DrawerItem(
        icon: FontAwesomeIcons.golfBallTee,
        title: 'Golf Rounds',
        route: 'golf_rounds',
      ),
      DrawerItem(
        icon: Icons.map_rounded,
        title: 'FocoMap',
        route: 'foco_map',
      ),
      DrawerItem(
        icon: Icons.psychology,
        title: 'Coaching',
        route: 'coaching_modules',
      ),
      DrawerItem(
        icon: Icons.insights,
        title: 'AI Insights',
        route: 'ai_insights',
      ),
      DrawerItem(
        icon: Icons.settings,
        title: 'Settings',
        route: 'settings',
      ),
      DrawerItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        route: 'support',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isActive = widget.currentRoute == item.route;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
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
                    : theme.primaryText.withValues(alpha: 0.8),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                height: 1.2,
              ),
            ),
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              widget.onNavigate?.call(item.route);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFooterButton(
                theme,
                Icons.logout,
                'Logout',
                () async {
                  // Handle logout
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  await authManager.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              _buildFooterButton(
                theme,
                Icons.star_outline,
                'Rate App',
                () async {
                  // Handle rating - will be implemented when app is released
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'App rating will be available when FoCoCo is released on the App Store!'),
                      backgroundColor: theme.primary,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(
    FlutterFlowTheme theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryBackground.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.primaryText.withValues(alpha: 0.7),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.labelSmall.override(
                color: theme.primaryText.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawer Item Model
class DrawerItem {
  final IconData icon;
  final String title;
  final String route;

  const DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
  });
}
