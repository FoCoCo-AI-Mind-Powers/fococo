import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/backend.dart';
import 'floating_audio_player.dart';

export '../../widgets/fococo_drawer_widget.dart';

/// Top dash strip + tab row height (matches [FoCoCoBottomNavigationBar]).
/// Full reserve above system UI: `kFoCoCoBottomNavStripAndTabsHeight + MediaQuery.viewPadding.bottom`.
const double kFoCoCoBottomNavStripAndTabsHeight = 82;

// ─── Nav model (replaces adaptive_platform_ui destinations) ─────────────────

/// Single tab in the FoCoCo bottom bar.
class FoCoCoNavDestination {
  const FoCoCoNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.brandLogoAsset,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  /// When set, the tab shows this asset (e.g. main mark) instead of [icon].
  final String? brandLogoAsset;
}

/// FoCoCo bottom nav — 4 tabs matching design spec.
const List<FoCoCoNavDestination> foCoCoNavDestinations = [
  FoCoCoNavDestination(
    icon: FontAwesomeIcons.clover,
    selectedIcon: FontAwesomeIcons.clover,
    label: 'FoCoCo',
    brandLogoAsset: 'assets/images/logo/Logo.png',
  ),
  FoCoCoNavDestination(
    icon: FontAwesomeIcons.flag,
    selectedIcon: FontAwesomeIcons.flag,
    label: 'CaddyPlay',
  ),
  FoCoCoNavDestination(
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    label: 'MindCoach',
  ),
  FoCoCoNavDestination(
    icon: Icons.mic_none_rounded,
    selectedIcon: Icons.mic_rounded,
    label: 'GolfChat',
  ),
];

const List<String> _foCoCoNavRoutes = [
  'fococo',
  'caddy_play',
  'mind_coach',
  'golf_chat',
];

final ValueNotifier<Map<String, String>> foCoCoNavLabelOverrides =
    ValueNotifier<Map<String, String>>(<String, String>{});

final ValueNotifier<Map<String, Color>> foCoCoNavSelectedColorOverrides =
    ValueNotifier<Map<String, Color>>(<String, Color>{});

final ValueNotifier<Color?> foCoCoNavBarBackgroundOverride =
    ValueNotifier<Color?>(null);

void setFoCoCoNavLabelOverride(String route, String? label) {
  final next = Map<String, String>.from(foCoCoNavLabelOverrides.value);
  final normalized = label?.trim();
  if (normalized == null || normalized.isEmpty) {
    next.remove(route);
  } else {
    next[route] = normalized;
  }
  if (!mapEquals(next, foCoCoNavLabelOverrides.value)) {
    foCoCoNavLabelOverrides.value = next;
  }
}

void setFoCoCoNavBarBackgroundOverride(Color? color) {
  if (foCoCoNavBarBackgroundOverride.value == color) {
    return;
  }
  foCoCoNavBarBackgroundOverride.value = color;
}

void setFoCoCoNavSelectedColorOverride(String route, Color? color) {
  final next = Map<String, Color>.from(foCoCoNavSelectedColorOverrides.value);
  if (color == null) {
    next.remove(route);
  } else {
    next[route] = color;
  }
  if (!mapEquals(next, foCoCoNavSelectedColorOverrides.value)) {
    foCoCoNavSelectedColorOverrides.value = next;
  }
}

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

// ─── App bar: white title, hairline + center glow (design spec) ─────────────

/// Thin divider with centered light flare under the title (FoCoCo tab aesthetic).
class FoCoCoAppBarGlowDivider extends StatelessWidget {
  const FoCoCoAppBarGlowDivider({
    super.key,
    this.dividerColor,
    this.glowColor,
  });

  final Color? dividerColor;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              color: dividerColor ?? Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Center(
            child: Container(
              height: 10,
              width: 140,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomCenter,
                  radius: 1.2,
                  colors: [
                    (glowColor ?? Colors.white).withValues(alpha: 0.45),
                    (glowColor ?? Colors.white).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Material [AppBar] with FoCoCo hairline + glow; use everywhere for consistency.
PreferredSizeWidget buildFoCoCoAppBar(
  BuildContext context, {
  required Widget title,
  Widget? leading,
  List<Widget>? actions,
  Color? backgroundColor,
  Color? foregroundColor,
  bool centerTitle = true,
  bool automaticallyImplyLeading = true,
  bool showGlowDivider = true,
  Color? dividerColor,
  Color? glowColor,
}) {
  final theme = FlutterFlowTheme.of(context);
  final resolvedForeground = foregroundColor ?? theme.primaryText;
  return AppBar(
    backgroundColor: backgroundColor ?? theme.primaryBackground,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: centerTitle,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    actions: actions,
    iconTheme: IconThemeData(color: resolvedForeground),
    actionsIconTheme: IconThemeData(color: resolvedForeground),
    title: title,
    bottom: showGlowDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(10),
            child: FoCoCoAppBarGlowDivider(
              dividerColor: dividerColor,
              glowColor: glowColor,
            ),
          )
        : null,
  );
}

// ─── Bottom bar: page tint, inactive top dashes, active icon spotlight ───────

/// Thin separator + small blurred dashes above **inactive** tabs only.
class _NavInactiveTopDashes extends StatelessWidget {
  const _NavInactiveTopDashes({
    required this.itemCount,
    required this.selectedIndex,
  });

  final int itemCount;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final segment = itemCount > 0 ? w / itemCount : w;
        return SizedBox(
          height: 10,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              for (var i = 0; i < itemCount; i++)
                if (i != selectedIndex)
                  Positioned(
                    left: segment * i + segment / 2 - 14,
                    width: 28,
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.55),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.85),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom bottom navigation: [barBackgroundColor] should match each page
/// [Scaffold.backgroundColor] / body fill. Flush to screen bottom (no SafeArea).
class FoCoCoBottomNavigationBar extends StatelessWidget {
  const FoCoCoBottomNavigationBar({
    super.key,
    required this.currentRoute,
    required this.onTap,
    this.showLabels = true,
    this.barBackgroundColor,
  });

  final String currentRoute;
  final void Function(String route) onTap;
  final bool showLabels;

  /// When null, uses [FlutterFlowTheme.primaryBackground].
  final Color? barBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ValueListenableBuilder<Color?>(
      valueListenable: foCoCoNavBarBackgroundOverride,
      builder: (context, overrideBackground, _) {
        return ValueListenableBuilder<Map<String, String>>(
          valueListenable: foCoCoNavLabelOverrides,
          builder: (context, overrides, __) {
            return ValueListenableBuilder<Map<String, Color>>(
              valueListenable: foCoCoNavSelectedColorOverrides,
              builder: (context, selectedOverrides, ___) {
                final bg = barBackgroundColor ??
                    overrideBackground ??
                    theme.primaryBackground;
                final selectedIndex = foCoCoNavIndexFromRoute(currentRoute);
                final selectedColor = selectedOverrides[currentRoute] ??
                    _accentForRoute(currentRoute);
                const unselectedColor = Color(0xFFB0B0B0);
                final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

                return Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NavInactiveTopDashes(
                          itemCount: foCoCoNavDestinations.length,
                          selectedIndex: selectedIndex,
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: bottomInset),
                          child: SizedBox(
                            height: 72,
                            child: Row(
                              children: List.generate(
                                foCoCoNavDestinations.length,
                                (i) {
                                  final d = foCoCoNavDestinations[i];
                                  final route = foCoCoNavRouteFromIndex(i);
                                  final isSelected = i == selectedIndex;
                                  return Expanded(
                                    child: _FoCoCoNavTile(
                                      icon: _iconData(
                                        isSelected
                                            ? (d.selectedIcon ?? d.icon)
                                            : d.icon,
                                      ),
                                      brandLogoAsset: d.brandLogoAsset,
                                      label: showLabels
                                          ? (overrides[route] ?? d.label)
                                          : null,
                                      isSelected: isSelected,
                                      selectedColor: selectedColor,
                                      unselectedColor: unselectedColor,
                                      onTap: () {
                                        if (!isSelected) {
                                          HapticFeedback.lightImpact();
                                          onTap(route);
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  static IconData _iconData(dynamic icon) =>
      icon is IconData ? icon : Icons.circle;

  /// Per-tab accent colour shown on the active icon.
  static Color _accentForRoute(String route) => switch (route) {
        'fococo' => const Color(0xFFFEA400), // Gold — FoCoCo brand
        'caddy_play' => const Color(0xFF66BB6A), // CaddyPlay green
        'mind_coach' => const Color(0xFFFEA400), // Orange — theme.primary
        'golf_chat' => const Color(0xFF1E7FC4), // Blue — readable on dark bg
        _ => Colors.white,
      };
}

/// Builds the FoCoCo bottom bar for [Scaffold.bottomNavigationBar].
Widget buildFoCoCoBottomNavBar({
  required BuildContext context,
  required String currentRoute,
  required void Function(String route) onTap,
  bool showLabels = true,
  Color? barBackgroundColor,
}) {
  return FoCoCoBottomNavigationBar(
    currentRoute: currentRoute,
    onTap: onTap,
    showLabels: showLabels,
    barBackgroundColor: barBackgroundColor,
  );
}

class _FoCoCoNavTile extends StatefulWidget {
  const _FoCoCoNavTile({
    required this.icon,
    this.brandLogoAsset,
    this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final String? brandLogoAsset;
  final String? label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  State<_FoCoCoNavTile> createState() => _FoCoCoNavTileState();
}

class _FoCoCoNavBrandMark extends StatefulWidget {
  const _FoCoCoNavBrandMark({
    required this.assetPath,
    required this.size,
    required this.isSelected,
  });

  final String assetPath;
  final double size;
  final bool isSelected;

  @override
  State<_FoCoCoNavBrandMark> createState() => _FoCoCoNavBrandMarkState();
}

class _FoCoCoNavBrandMarkState extends State<_FoCoCoNavBrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant _FoCoCoNavBrandMark oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotation.value * 2 * math.pi,
          child: child,
        );
      },
      child: Opacity(
        opacity: 1.0,
        child: Image.asset(
          widget.assetPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Icon(
            FontAwesomeIcons.clover,
            color: Colors.white70,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}

class _FoCoCoNavTileState extends State<_FoCoCoNavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.unselectedColor;
    final labelColor =
        widget.isSelected ? widget.selectedColor : widget.unselectedColor;
    final iconSize = widget.isSelected ? 25.0 : 23.0;
    final useBrand = widget.brandLogoAsset != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, bottom: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 34,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: iconSize),
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          builder: (context, size, _) => useBrand
                              ? _FoCoCoNavBrandMark(
                                  assetPath: widget.brandLogoAsset!,
                                  size: size,
                                  isSelected: widget.isSelected,
                                )
                              : Icon(
                                  widget.icon,
                                  color: iconColor,
                                  size: size,
                                ),
                        ),
                      ),
                      if (widget.label != null) ...[
                        const SizedBox(height: 2),
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: MediaQuery.textScalerOf(context).clamp(
                              maxScaleFactor: 1.15,
                            ),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 10,
                              height: 1.1,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                            child: Text(
                              widget.label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Exposes drawer control to inline headers when [FoCoCoAdaptiveScaffold.hideAppBar]
/// is true.
class FoCoCoScaffoldScope extends InheritedWidget {
  const FoCoCoScaffoldScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback? openDrawer;

  static FoCoCoScaffoldScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FoCoCoScaffoldScope>();
  }

  @override
  bool updateShouldNotify(FoCoCoScaffoldScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}

/// MindCoach-style inline header: optional drawer/back row + centered title/subtitle.
class FoCoCoInlineScreenHeader extends StatelessWidget {
  const FoCoCoInlineScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.subtitleColor,
    this.leading,
    this.actions,
    this.showDrawerButton = false,
    this.compactTitle = false,
    this.topInset = 0,
    this.horizontalPadding = 16,
  });

  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showDrawerButton;
  final bool compactTitle;
  final double topInset;
  final double horizontalPadding;

  static const double _sideSlotWidth = 48;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final resolvedTitleColor = titleColor ?? Colors.white;
    final resolvedSubtitleColor =
        subtitleColor ?? Colors.white.withValues(alpha: 0.62);
    final scope = FoCoCoScaffoldScope.maybeOf(context);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showDrawerButton && scope?.openDrawer != null) {
      leadingWidget = IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: _sideSlotWidth,
          minHeight: 44,
        ),
        icon: Icon(Icons.menu_rounded, color: theme.primaryText),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: scope!.openDrawer,
      );
    }

    final actionWidgets = actions ?? const <Widget>[];
    final trailingSlotWidth = actionWidgets.isEmpty
        ? _sideSlotWidth
        : _sideSlotWidth * actionWidgets.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topInset + 4,
        horizontalPadding,
        subtitle == null ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _sideSlotWidth,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leadingWidget ?? const SizedBox.shrink(),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compactTitle ? theme.titleLarge : theme.headlineSmall)
                      .copyWith(
                    color: resolvedTitleColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              SizedBox(
                width: trailingSlotWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: actionWidgets.isEmpty
                      ? const SizedBox.shrink()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actionWidgets,
                        ),
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.titleMedium.copyWith(
                color: resolvedSubtitleColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Main shell: Material [Scaffold], custom app bar + bottom bar (no adaptive UI).
class FoCoCoAdaptiveScaffold extends StatefulWidget {
  const FoCoCoAdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    required this.onTap,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.drawer,
    this.enableVoiceButton = true,
    this.hideAppBar = false,
    this.backgroundColor,
    this.showBottomNav = true,
    this.appBarForegroundColor,
    this.showAppBarGlowDivider = true,
  });

  final Widget body;
  final String currentRoute;
  final void Function(String route) onTap;
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? drawer;
  final bool enableVoiceButton;

  /// When true, no app bar is shown (e.g. when using a custom header in body).
  final bool hideAppBar;

  /// Same as the page body fill — drives [Scaffold.backgroundColor] and bottom bar.
  final Color? backgroundColor;

  /// When false, the bottom navigation bar is omitted (used inside StatefulShellRoute
  /// where the shell provides its own nav bar).
  final bool showBottomNav;

  final Color? appBarForegroundColor;
  final bool showAppBarGlowDivider;

  @override
  State<FoCoCoAdaptiveScaffold> createState() => _FoCoCoAdaptiveScaffoldState();
}

class _FoCoCoAdaptiveScaffoldState extends State<FoCoCoAdaptiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final pageBg = widget.backgroundColor ?? theme.primaryBackground;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final viewBottom = MediaQuery.viewPaddingOf(context).bottom;
    final hideVoiceForRoute = widget.currentRoute == 'golf_chat';
    final showVoiceButton =
        widget.enableVoiceButton && !keyboardOpen && !hideVoiceForRoute;

    Widget body = widget.body;
    if (showVoiceButton) {
      // Match [FoCoCoBottomNavigationBar] total: strip+tabs + viewPadding.bottom.
      final overlayBottom = viewBottom + kFoCoCoBottomNavStripAndTabsHeight;
      body = Stack(
        children: [
          body,
          Positioned(
            left: 0,
            right: 0,
            bottom: overlayBottom,
            child: const Center(child: FloatingAudioPlayer()),
          ),
        ],
      );
    }

    Widget? leading = widget.leading;
    if (!widget.hideAppBar && widget.drawer != null && leading == null) {
      leading = IconButton(
        icon: Icon(Icons.menu_rounded, color: theme.primaryText),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      );
    }

    final showAppBar = !widget.hideAppBar &&
        (widget.title != null ||
            widget.titleWidget != null ||
            leading != null ||
            (widget.actions != null && widget.actions!.isNotEmpty));

    PreferredSizeWidget? appBar;
    if (showAppBar && (widget.title != null || widget.titleWidget != null)) {
      appBar = buildFoCoCoAppBar(
        context,
        title: widget.titleWidget ??
            Text(
              widget.title!,
              style: theme.titleLarge.copyWith(
                color: widget.appBarForegroundColor ?? theme.primaryText,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.6,
              ),
            ),
        leading: leading,
        actions: widget.actions,
        automaticallyImplyLeading: leading != null || widget.drawer != null,
        foregroundColor: widget.appBarForegroundColor,
        showGlowDivider: widget.showAppBarGlowDivider,
      );
    } else if (showAppBar) {
      appBar = buildFoCoCoAppBar(
        context,
        title: const SizedBox.shrink(),
        leading: leading,
        actions: widget.actions,
        automaticallyImplyLeading: leading != null || widget.drawer != null,
        foregroundColor: widget.appBarForegroundColor,
        showGlowDivider: widget.showAppBarGlowDivider,
      );
    }

    body = FoCoCoScaffoldScope(
      openDrawer: widget.drawer == null
          ? null
          : () => _scaffoldKey.currentState?.openDrawer(),
      child: body,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: pageBg,
      drawer: widget.drawer,
      // Always allow the user to swipe in from the left edge to reveal the
      // FoCoCo drawer, even when nested scrollables compete with the gesture.
      drawerEnableOpenDragGesture: widget.drawer != null,
      drawerEdgeDragWidth:
          widget.drawer != null ? _kFoCoCoDrawerEdgeDragWidth : null,
      appBar: appBar,
      extendBody: true,
      body: body,
      bottomNavigationBar: widget.showBottomNav
          ? buildFoCoCoBottomNavBar(
              context: context,
              currentRoute: widget.currentRoute,
              onTap: widget.onTap,
              barBackgroundColor: pageBg,
            )
          : null,
    );
  }
}

/// Width of the left-edge zone that opens the FoCoCo drawer on swipe. Wider
/// than Material's default (~20pt) so the gesture wins against horizontal
/// PageViews and chart panners on the home/coaching pages.
const double _kFoCoCoDrawerEdgeDragWidth = 28.0;

/// Legacy bottom bar for [Scaffold.bottomNavigationBar].
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
    this.barBackgroundColor,
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

  /// Match host [Scaffold.backgroundColor] / page body.
  final Color? barBackgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget nav = buildFoCoCoBottomNavBar(
      context: context,
      currentRoute: currentRoute,
      onTap: onTap ?? (_) {},
      showLabels: showLabels,
      barBackgroundColor: barBackgroundColor,
    );
    if (height != null) {
      nav = SizedBox(height: height, child: nav);
    }
    nav = Container(margin: margin, child: nav);

    if (!useGlassEffect) {
      return nav;
    }
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        nav,
        Positioned(
          top: -45,
          child: enableVoiceButton
              ? const FloatingAudioPlayer()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
