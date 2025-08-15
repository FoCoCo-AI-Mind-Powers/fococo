import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../flutter_flow/flutter_flow_theme.dart';
import 'voice_chat_button.dart';

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

/// Enhanced navigation bar with integrated AI coaching and FoCoMap access
class FoCoCoNavBar extends StatefulWidget {
  final String currentRoute;
  final Function(String route)? onTap;
  final bool showLabels;
  final double height;
  final EdgeInsets margin;
  final bool enableVoiceButton;

  const FoCoCoNavBar({
    Key? key,
    required this.currentRoute,
    this.onTap,
    this.showLabels = true,
    this.height = 85.0,
    this.margin = const EdgeInsets.only(left: 16, right: 16, bottom: 20),
    this.enableVoiceButton = true,
  }) : super(key: key);

  @override
  State<FoCoCoNavBar> createState() => _FoCoCoNavBarState();
}

class _FoCoCoNavBarState extends State<FoCoCoNavBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;

  // Navigation items for FoCoCo app
  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.today_outlined,
      activeIcon: Icons.today_rounded,
      label: 'Today',
      route: 'dashboard',
    ),
    NavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
      label: 'Performance',
      route: 'golf_rounds',
    ),
    NavigationItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology_rounded,
      label: 'Coach',
      route: 'coaching_modules',
    ),
    NavigationItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'FoCoMap',
      route: 'foco_map',
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
      duration: const Duration(milliseconds: 300),
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
      curve: Curves.easeInOutCubic,
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
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Main navigation bar
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: Container(
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryBackground.withValues(alpha: 0.95),
                      theme.secondaryBackground.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    _buildNavItem(0, theme), // Today
                    _buildNavItem(1, theme), // Performance
                    _buildNavItem(2, theme), // Coach
                    _buildNavItem(3, theme), // FoCoMap
                    _buildNavItem(4, theme), // Profile
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Voice button positioned above Today button
        if (widget.enableVoiceButton)
          Positioned(
            left: widget.margin.left + (MediaQuery.of(context).size.width - widget.margin.left - widget.margin.right) / 10 - 28,
            bottom: widget.margin.bottom + widget.height - 25,
            child: const VoiceChatButton(
              size: 56.0,
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(int index, FlutterFlowTheme theme) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primary,
                        theme.secondary,
                      ],
                    )
                  : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Transform.scale(
                scale: isActive ? _scaleAnimation.value : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        color: isActive ? Colors.white : theme.secondaryText,
                        size: isActive ? 26 : 22,
                      ),
                    ),
                    if (widget.showLabels) ...[
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.labelSmall.override(
                          fontFamily: 'Inter',
                          color: isActive ? Colors.white : theme.secondaryText,
                          fontSize: isActive ? 10 : 9,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          height: 1.0,
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

/// Alternative implementation with voice button integrated into the nav bar
class FoCoCoNavWithIntegratedVoice extends StatefulWidget {
  final String currentRoute;
  final Function(String route)? onTap;
  final bool showLabels;
  final double height;
  final EdgeInsets margin;
  final bool enableVoiceButton;

  const FoCoCoNavWithIntegratedVoice({
    Key? key,
    required this.currentRoute,
    this.onTap,
    this.showLabels = true,
    this.height = 85.0,
    this.margin = const EdgeInsets.only(left: 16, right: 16, bottom: 20),
    this.enableVoiceButton = true,
  }) : super(key: key);

  @override
  State<FoCoCoNavWithIntegratedVoice> createState() => _FoCoCoNavWithIntegratedVoiceState();
}

class _FoCoCoNavWithIntegratedVoiceState extends State<FoCoCoNavWithIntegratedVoice>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;

  // Navigation items for FoCoCo app
  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.today_outlined,
      activeIcon: Icons.today_rounded,
      label: 'Today',
      route: 'dashboard',
    ),
    NavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
      label: 'Performance',
      route: 'golf_rounds',
    ),
    NavigationItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology_rounded,
      label: 'Coach',
      route: 'coaching_modules',
    ),
    NavigationItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map_rounded,
      label: 'FoCoMap',
      route: 'foco_map',
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
      duration: const Duration(milliseconds: 300),
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
      curve: Curves.easeInOutCubic,
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
  void didUpdateWidget(FoCoCoNavWithIntegratedVoice oldWidget) {
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
    
    if (item.route != widget.currentRoute) {
      _animateToIndex(index);
      widget.onTap?.call(item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Main navigation bar
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: Container(
            height: widget.height,
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryBackground.withValues(alpha: 0.95),
                      theme.secondaryBackground.withValues(alpha: 0.95),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    _buildNavItem(0, theme), // Today
                    _buildNavItem(1, theme), // Performance
                    _buildNavItem(2, theme), // Coach
                    _buildNavItem(3, theme), // FoCoMap
                    _buildNavItem(4, theme), // Profile
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Voice button positioned above Today button
        if (widget.enableVoiceButton)
          Positioned(
            left: widget.margin.left + (MediaQuery.of(context).size.width - widget.margin.left - widget.margin.right) / 10 - 28,
            bottom: widget.margin.bottom + widget.height - 25,
            child: const VoiceChatButton(
              size: 56.0,
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(int index, FlutterFlowTheme theme) {
    final item = _navItems[index];
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primary,
                        theme.secondary,
                      ],
                    )
                  : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Transform.scale(
                scale: isActive ? _scaleAnimation.value : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        color: isActive ? Colors.white : theme.secondaryText,
                        size: isActive ? 26 : 22,
                      ),
                    ),
                    if (widget.showLabels) ...[
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.labelSmall.override(
                          fontFamily: 'Inter',
                          color: isActive ? Colors.white : theme.secondaryText,
                          fontSize: isActive ? 10 : 9,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          height: 1.0,
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

/// Compact navigation bar that provides more space for the voice button
class CompactNavWithVoice extends StatelessWidget {
  final String currentRoute;
  final Function(String route)? onTap;

  const CompactNavWithVoice({
    Key? key,
    required this.currentRoute,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Compact navigation with only essential items
        Container(
          height: 70,
          margin: const EdgeInsets.only(left: 60, right: 60, bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryBackground.withValues(alpha: 0.95),
                theme.secondaryBackground.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactNavItem(
                theme,
                Icons.today_rounded,
                'dashboard',
                'Today',
              ),
              _buildCompactNavItem(
                theme,
                Icons.trending_up_rounded,
                'golf_rounds',
                'Performance',
              ),
              _buildCompactNavItem(
                theme,
                Icons.psychology_rounded,
                'coaching_modules',
                'Coach',
              ),
              _buildCompactNavItem(
                theme,
                Icons.map_rounded,
                'foco_map',
                'FoCoMap',
              ),
            ],
          ),
        ),
        
        // Prominent voice button
        Positioned(
          bottom: 85,
          child: const EnhancedVoiceChatButton(
            size: 70.0,
            margin: EdgeInsets.zero,
          ),
        ),
      ],
    );
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
            ? theme.primary.withValues(alpha: 0.2)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? theme.primary : theme.secondaryText,
          size: 24,
        ),
      ),
    );
  }
}