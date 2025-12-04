import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fo_co_co/flutter_flow/glass_design_system.dart';

import '../../flutter_flow/flutter_flow_theme.dart';

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// FoCoCo Navigation Bar - Matching the attached image design
/// Features a clean bottom navigation with proper icons and labels
class FoCoCoNavBar extends StatefulWidget {
  final String currentRoute;
  final Function(String route)? onTap;
  final bool showLabels;
  final double height;
  final EdgeInsets margin;
  final bool enableVoiceButton;
  final bool useGlassEffect;
  final VoidCallback? onVoicePressed;

  const FoCoCoNavBar({
    Key? key,
    required this.currentRoute,
    this.onTap,
    this.showLabels = true, // Enable labels to match image design
    this.height = 80.0, // Slightly taller for labels
    this.margin = const EdgeInsets.all(0), // No margin for full width
    this.enableVoiceButton = false, // Disable voice button for clean design
    this.useGlassEffect = false, // Use solid design to match image
    this.onVoicePressed,
  }) : super(key: key);

  @override
  State<FoCoCoNavBar> createState() => _FoCoCoNavBarState();
}

class _FoCoCoNavBarState extends State<FoCoCoNavBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _voicePulseController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 0;

  // Navigation items matching the image layout
  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.stacked_line_chart_outlined,
      activeIcon: Icons.stacked_line_chart,
      label: 'Statistics',
      route: 'statistics',
    ),
    NavigationItem(
      icon: Icons.laptop_outlined,
      activeIcon: Icons.laptop,
      label: 'Coaching',
      route: 'coaching_modules',
    ),
    NavigationItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: 'profile',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _voicePulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    // Start voice pulse animation
    _voicePulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(FoCoCoNavBar oldWidget) {
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
    _voicePulseController.dispose();
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

    if (item.route != widget.currentRoute) {
      _animateToIndex(index);
      widget.onTap?.call(item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: _buildModernNavBar(theme, screenWidth),
    );
  }

  /// Build modern navigation bar matching the image design
  Widget _buildModernNavBar(FlutterFlowTheme theme, double screenWidth) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.secondary, // Dark navy background
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildNavItem(index, item, theme);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavigationItem item, FlutterFlowTheme theme) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Transform.scale(
                scale: isActive ? _scaleAnimation.value : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    AnimatedSwitcher(
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
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),

                    // Label
                    if (widget.showLabels) ...[
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          fontFamily: 'Inter',
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

/// Compact version of the navbar for specific use cases
class CompactFoCoCoNavBar extends StatelessWidget {
  final String currentRoute;
  final Function(String route)? onTap;
  final bool useGlassEffect;

  const CompactFoCoCoNavBar({
    Key? key,
    required this.currentRoute,
    this.onTap,
    this.useGlassEffect = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (useGlassEffect) {
      return Container(
        height: 60,
        margin: const EdgeInsets.only(left: 40, right: 40, bottom: 20),
        child: GlassDesignSystem.glassBackground(
          borderRadius: BorderRadius.circular(30),
          tintColor: theme.glassBackground,
          child: _buildCompactNavContent(theme),
        ),
      );
    }

    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 40, right: 40, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.secondary.withValues(alpha: 0.95), // Brand navy
            theme.tertiary.withValues(alpha: 0.95), // Brand green
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _buildCompactNavContent(theme),
    );
  }

  Widget _buildCompactNavContent(FlutterFlowTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactNavItem(
          theme,
          Icons.home_rounded,
          'dashboard',
          'Home',
        ),
        _buildCompactNavItem(
          theme,
          Icons.favorite_rounded,
          'golf_rounds',
          'Favorites',
        ),
        // Center voice button
        _buildCompactVoiceButton(theme),
        _buildCompactNavItem(
          theme,
          Icons.map_rounded,
          'foco_map',
          'Map',
        ),
        _buildCompactNavItem(
          theme,
          Icons.person_rounded,
          'profile',
          'Profile',
        ),
      ],
    );
  }

  Widget _buildCompactVoiceButton(FlutterFlowTheme theme) {
    if (useGlassEffect) {
      return GlassDesignSystem.glass3DCard(
        width: 50,
        height: 50,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        tintColor: theme.primary,
        onTap: () {
          HapticFeedback.mediumImpact();
          // Add voice functionality
        },
        child: Icon(
          Icons.mic_rounded,
          color: theme.primary,
          size: 24,
        ),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primary, // Brand orange
              theme.warning, // Brand warning (same as primary)
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          Icons.mic_rounded,
          color: theme.primaryBackground, // White icon
          size: 24,
        ),
      );
    }
  }

  Widget _buildCompactNavItem(
    FlutterFlowTheme theme,
    IconData icon,
    String route,
    String tooltip,
  ) {
    final isActive = currentRoute == route;

    return GestureDetector(
      onTap: () {
        if (route != currentRoute) {
          onTap?.call(route);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? (useGlassEffect
                  ? theme.primary
                      .withValues(alpha: 0.2) // Glass mode: more subtle
                  : theme.primary.withValues(alpha: 0.3)) // Standard mode
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: useGlassEffect && isActive
              ? Border.all(
                  color: theme.primary.withValues(alpha: 0.4),
                  width: 1.0,
                )
              : null,
        ),
        child: Icon(
          icon,
          color: isActive
              ? theme.primary // Brand orange when active
              : (useGlassEffect
                  ? theme.primaryText
                      .withValues(alpha: 0.8) // Glass mode: more visible
                  : theme.primaryText.withValues(alpha: 0.7)), // Standard mode
          size: 22,
        ),
      ),
    );
  }
}
