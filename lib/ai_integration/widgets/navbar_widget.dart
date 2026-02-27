import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '/adaptive_ui/adaptive_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/glass_design_system.dart';
import '/backend/backend.dart';
import 'floating_audio_player.dart';

export '../../widgets/fococo_drawer_widget.dart';

/// FoCoCo bottom nav destinations – same icons and titles for AdaptiveScaffold.
final List<AdaptiveNavigationDestination> foCoCoNavDestinations = [
  const AdaptiveNavigationDestination(
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    label: 'MindCoach',
  ),
  const AdaptiveNavigationDestination(
    icon: FontAwesomeIcons.flag,
    selectedIcon: FontAwesomeIcons.flag,
    label: 'CaddyPlay',
  ),
  const AdaptiveNavigationDestination(
    icon: Icons.chat_bubble_outline_rounded,
    selectedIcon: Icons.chat_bubble_rounded,
    label: 'GolfChat',
  ),
];

const List<String> _foCoCoNavRoutes = ['mind_coach', 'caddy_play', 'golf_chat'];

int foCoCoNavIndexFromRoute(String route) {
  final i = _foCoCoNavRoutes.indexWhere((r) => r == route);
  return i >= 0 ? i : 0;
}

String foCoCoNavRouteFromIndex(int index) {
  if (index >= 0 && index < _foCoCoNavRoutes.length) {
    return _foCoCoNavRoutes[index];
  }
  return _foCoCoNavRoutes.first;
}

/// Builds [AdaptiveBottomNavigationBar] for FoCoCo with theme colors.
AdaptiveBottomNavigationBar buildFoCoCoBottomNavBar({
  required BuildContext context,
  required String currentRoute,
  required void Function(String route) onTap,
  bool useNativeBottomBar = true,
}) {
  final theme = FlutterFlowTheme.of(context);
  final selectedIndex = foCoCoNavIndexFromRoute(currentRoute);
  return AdaptiveBottomNavigationBar(
    items: foCoCoNavDestinations,
    selectedIndex: selectedIndex,
    onTap: (index) {
      final route = foCoCoNavRouteFromIndex(index);
      if (route != currentRoute) {
        onTap(route);
      }
    },
    useNativeBottomBar: useNativeBottomBar,
    selectedItemColor: theme.primary,
    unselectedItemColor: theme.secondaryText.withValues(alpha: 0.7),
  );
}

/// Scaffold that uses [AdaptiveScaffold] with FoCoCo bottom bar directly.
/// Same icons and titles; supports app bar, drawer, and optional floating audio.
class FoCoCoAdaptiveScaffold extends StatefulWidget {
  const FoCoCoAdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    required this.onTap,
    this.title,
    this.leading,
    this.actions,
    this.drawer,
    this.enableVoiceButton = true,
    this.useNativeBottomBar = true,
    this.useNativeToolbar = false,
    this.hideAppBar = false,
  });

  final Widget body;
  final String currentRoute;
  final void Function(String route) onTap;
  final String? title;
  final Widget? leading;
  final List<AdaptiveAppBarAction>? actions;
  final Widget? drawer;
  final bool enableVoiceButton;
  final bool useNativeBottomBar;
  final bool useNativeToolbar;

  /// When true, no app bar is shown (e.g. when using a custom header in body).
  final bool hideAppBar;

  @override
  State<FoCoCoAdaptiveScaffold> createState() => _FoCoCoAdaptiveScaffoldState();
}

class _FoCoCoAdaptiveScaffoldState extends State<FoCoCoAdaptiveScaffold> {
  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hasDrawer = widget.drawer != null;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final hideVoiceForRoute = widget.currentRoute == 'golf_chat';
    final showVoiceButton =
        widget.enableVoiceButton && !keyboardOpen && !hideVoiceForRoute;

    Widget body = widget.body;
    if (hasDrawer) {
      body = Scaffold(
        key: _drawerKey,
        drawer: widget.drawer,
        body: body,
      );
    }
    if (showVoiceButton) {
      final overlayBottom =
          safeBottomInset + (widget.useNativeBottomBar ? 76 : 84);
      body = Stack(
        children: [
          body,
          Positioned(
            left: 0,
            right: 0,
            bottom: overlayBottom,
            child: Center(child: const FloatingAudioPlayer()),
          ),
        ],
      );
    }

    Widget? leading = widget.leading;
    if (!widget.hideAppBar && hasDrawer && leading == null) {
      leading = IconButton(
        icon: Icon(Icons.menu_rounded, color: theme.primaryText),
        onPressed: () => _drawerKey.currentState?.openDrawer(),
      );
    }

    final showAppBar = !widget.hideAppBar &&
        (widget.title != null ||
            leading != null ||
            (widget.actions != null && widget.actions!.isNotEmpty));

    return AdaptiveScaffold(
      appBar: showAppBar
          ? AdaptiveAppBar(
              title: widget.title,
              leading: leading,
              actions: widget.actions,
              useNativeToolbar: widget.useNativeToolbar,
            )
          : null,
      body: body,
      bottomNavigationBar: buildFoCoCoBottomNavBar(
        context: context,
        currentRoute: widget.currentRoute,
        onTap: widget.onTap,
        useNativeBottomBar: widget.useNativeBottomBar,
      ),
    );
  }
}

/// Legacy bottom bar for [Scaffold.bottomNavigationBar]. Prefer [FoCoCoAdaptiveScaffold].
class EnhancedFoCoCoNavBar extends StatelessWidget {
  const EnhancedFoCoCoNavBar({
    super.key,
    required this.currentRoute,
    this.onTap,
    this.showLabels = true,
    this.height,
    this.margin = const EdgeInsets.all(0),
    this.enableVoiceButton = true,
    this.useGlassEffect = true,
    this.onVoicePressed,
    this.showDrawer = true,
    this.showMiniChart = true,
    this.currentUser,
    this.scaffoldKey,
  });

  final String currentRoute;
  final void Function(String route)? onTap;
  final bool showLabels;
  final double? height;
  final EdgeInsets margin;
  final bool enableVoiceButton;
  final bool useGlassEffect;
  final VoidCallback? onVoicePressed;
  final bool showDrawer;
  final bool showMiniChart;
  final UserRecord? currentUser;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final selectedIndex = foCoCoNavIndexFromRoute(currentRoute);
    final selectedColor = theme.primary;
    final unselectedColor = theme.secondaryText.withValues(alpha: 0.7);
    final isIOS = !kIsWeb && Platform.isIOS;

    Widget bar = isIOS
        ? _buildCupertinoBar(
            context, theme, selectedIndex, selectedColor, unselectedColor)
        : _buildMaterialBar(
            context, theme, selectedIndex, selectedColor, unselectedColor);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        if (useGlassEffect) _wrapWithGlass(theme, bar) else bar,
        Positioned(
          top: -45,
          child: enableVoiceButton
              ? const FloatingAudioPlayer()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _wrapWithGlass(FlutterFlowTheme theme, Widget child) {
    return Container(
      height: height ?? 80,
      margin: margin,
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
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoBar(
    BuildContext context,
    FlutterFlowTheme theme,
    int selectedIndex,
    Color selectedColor,
    Color unselectedColor,
  ) {
    return Container(
      height: height ?? 80,
      margin: useGlassEffect ? EdgeInsets.zero : margin,
      color: useGlassEffect ? Colors.transparent : theme.primaryBackground,
      child: SafeArea(
        top: false,
        child: CupertinoTabBar(
          backgroundColor:
              useGlassEffect ? Colors.transparent : theme.primaryBackground,
          activeColor: selectedColor,
          inactiveColor: unselectedColor,
          iconSize: 28,
          currentIndex: selectedIndex,
          onTap: (i) {
            if (onTap != null && i != selectedIndex) {
              HapticFeedback.lightImpact();
              onTap!(foCoCoNavRouteFromIndex(i));
            }
          },
          items: foCoCoNavDestinations
              .map(
                (d) => BottomNavigationBarItem(
                  icon: Icon(_iconData(d.icon), color: unselectedColor),
                  activeIcon: Icon(_iconData(d.selectedIcon ?? d.icon),
                      color: selectedColor),
                  label: showLabels ? d.label : null,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMaterialBar(
    BuildContext context,
    FlutterFlowTheme theme,
    int selectedIndex,
    Color selectedColor,
    Color unselectedColor,
  ) {
    return Container(
      height: height ?? 80,
      margin: useGlassEffect ? EdgeInsets.zero : margin,
      decoration: useGlassEffect
          ? null
          : BoxDecoration(
              color: theme.primaryBackground,
              border: Border(
                top: BorderSide(color: theme.alternate.withValues(alpha: 0.3)),
              ),
            ),
      child: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            height: 80,
            indicatorColor: selectedColor.withValues(alpha: 0.2),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: selectedColor, size: 28);
              }
              return IconThemeData(color: unselectedColor, size: 26);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.labelMedium.copyWith(
                  color: selectedColor,
                  fontWeight: FontWeight.w600,
                );
              }
              return theme.labelMedium.copyWith(color: unselectedColor);
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) {
            if (onTap != null && i != selectedIndex) {
              HapticFeedback.lightImpact();
              onTap!(foCoCoNavRouteFromIndex(i));
            }
          },
          backgroundColor:
              useGlassEffect ? Colors.transparent : theme.primaryBackground,
          elevation: 0,
          height: 80,
          destinations: foCoCoNavDestinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(_iconData(d.icon)),
                  selectedIcon: Icon(_iconData(d.selectedIcon ?? d.icon)),
                  label: showLabels ? d.label : '',
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static IconData _iconData(dynamic icon) =>
      icon is IconData ? icon : Icons.circle;
}
