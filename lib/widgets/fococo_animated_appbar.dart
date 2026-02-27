import 'package:appbar_animated/appbar_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/flutter_flow/flutter_flow_theme.dart';

class FoCoCoAnimatedScaffold extends StatelessWidget {
  const FoCoCoAnimatedScaffold({
    super.key,
    required this.body,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.drawer,
    this.expandedHeight = 140.0,
    this.collapsedHeight = 60.0,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onDrawerOpen,
  });

  final Widget body;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? drawer;
  final double expandedHeight;
  final double collapsedHeight;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final VoidCallback? onDrawerOpen;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: theme.primaryBackground,
      body: ScaffoldLayoutBuilder(
        backgroundColorAppBar: ColorBuilder(
          Colors.transparent,
          theme.primaryBackground.withValues(alpha: 0.96),
        ),
        textColorAppBar: ColorBuilder(
          theme.primaryText,
          theme.primaryText,
        ),
        appBarBuilder: (context, colorAnimated) {
          return _buildAnimatedAppBar(
            context,
            theme,
            colorAnimated,
            scaffoldKey,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: expandedHeight + MediaQuery.of(context).padding.top),
              body,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAppBar(
    BuildContext context,
    FlutterFlowTheme theme,
    ColorAnimated colorAnimated,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: colorAnimated.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: collapsedHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.alternate.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              leading ??
                  _buildMenuButton(
                    theme,
                    () {
                      HapticFeedback.lightImpact();
                      if (onDrawerOpen != null) {
                        onDrawerOpen!();
                      } else {
                        scaffoldKey.currentState?.openDrawer();
                      }
                    },
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: theme.headlineMedium.copyWith(
                        color: colorAnimated.color,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Montserrat',
                      ),
                      child: Text(title),
                    ),
                    if (subtitle != null)
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(FlutterFlowTheme theme, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.glassBackground.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 24,
          color: theme.primaryText,
        ),
      ),
    );
  }
}

class FoCoCoAnimatedAppBarAction extends StatelessWidget {
  const FoCoCoAnimatedAppBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: theme.glassBackground.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                size: 24,
                color: theme.primaryText,
              ),
            ),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: badge!,
              ),
          ],
        ),
      ),
    );
  }
}

class FoCoCoSliverAnimatedScaffold extends StatelessWidget {
  const FoCoCoSliverAnimatedScaffold({
    super.key,
    required this.slivers,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.drawer,
    this.expandedHeight = 140.0,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onDrawerOpen,
    this.flexibleSpaceContent,
  });

  final List<Widget> slivers;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? drawer;
  final double expandedHeight;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final VoidCallback? onDrawerOpen;
  final Widget? flexibleSpaceContent;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: theme.primaryBackground,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeight,
            floating: false,
            pinned: true,
            backgroundColor: theme.primaryBackground,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: leading ??
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildMenuButton(
                    theme,
                    () {
                      HapticFeedback.lightImpact();
                      if (onDrawerOpen != null) {
                        onDrawerOpen!();
                      } else {
                        scaffoldKey.currentState?.openDrawer();
                      }
                    },
                  ),
                ),
            actions: actions,
            flexibleSpace: FlexibleSpaceBar(
              background: flexibleSpaceContent ??
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: theme.headlineMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  subtitle!,
                                  style: theme.bodySmall.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          ...slivers,
        ],
      ),
    );
  }

  Widget _buildMenuButton(FlutterFlowTheme theme, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.glassBackground.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.glassBorder.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 24,
          color: theme.primaryText,
        ),
      ),
    );
  }
}
