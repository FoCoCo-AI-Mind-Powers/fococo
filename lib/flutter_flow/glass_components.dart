/// FoCoCo Enhanced Glass Components
/// Reusable glassmorphism widgets for consistent UI

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'flutter_flow_theme.dart';
import 'glass_design_system.dart';

/// Glass Dashboard Card with AI Integration
class GlassDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final List<Widget>? children;
  final Color? tintColor;
  final bool showAIBadge;
  final String? aiInsight;

  const GlassDashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.children,
    this.tintColor,
    this.showAIBadge = false,
    this.aiInsight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GlassDesignSystem.glass3DCard(
      onTap: onTap,
      tintColor: tintColor ?? theme.glassTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: theme.primaryBrandGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: theme.glassCardShadows,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.titleMedium.override(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (showAIBadge) _buildAIBadge(theme),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),

          // AI Insight Section
          if (aiInsight != null && aiInsight!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAIInsightSection(context, theme),
          ],

          // Additional Children
          if (children != null && children!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...children!,
          ],
        ],
      ),
    );
  }

  Widget _buildAIBadge(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: theme.aiGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.aiPrimary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.brain,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'AI',
            style: theme.labelSmall.override(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightSection(BuildContext context, FlutterFlowTheme theme) {
    return GlassDesignSystem.glassBackground(
      borderRadius: BorderRadius.circular(12),
      tintColor: theme.aiPrimary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.star,
                  size: 14,
                  color: theme.aiPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Insight',
                  style: theme.labelMedium.override(
                    color: theme.aiPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              aiInsight!,
              style: theme.bodySmall.override(
                color: theme.primaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass Performance Metric Card
class GlassPerformanceCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final IconData icon;
  final Color? color;
  final bool isPositive;
  final VoidCallback? onTap;

  const GlassPerformanceCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    required this.icon,
    this.color,
    this.isPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final effectiveColor = color ?? theme.primary;

    return GlassDesignSystem.glass3DCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? theme.success : theme.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? FontAwesomeIcons.arrowUp
                            : FontAwesomeIcons.arrowDown,
                        size: 10,
                        color: isPositive ? theme.success : theme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change!,
                        style: theme.labelSmall.override(
                          color: isPositive ? theme.success : theme.error,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.headlineMedium.override(
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass Activity Feed Item
class GlassActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timestamp;
  final Widget? leading;
  final List<Widget>? metrics;
  final VoidCallback? onTap;

  const GlassActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.leading,
    this.metrics,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GlassDesignSystem.glass3DCard(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: theme.activityGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: leading!),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.titleSmall.override(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (metrics != null && metrics!.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    children: metrics!,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timestamp,
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass Metric Badge
class GlassMetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const GlassMetricBadge({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final effectiveColor = color ?? theme.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.labelSmall.override(
              color: effectiveColor,
              fontWeight: FontWeight.w500,
              fontSize: 10,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.labelSmall.override(
              color: effectiveColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass Progress Ring
class GlassProgressRing extends StatefulWidget {
  final double progress;
  final double size;
  final Color? color;
  final String? centerText;
  final Widget? centerWidget;

  const GlassProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.color,
    this.centerText,
    this.centerWidget,
  });

  @override
  State<GlassProgressRing> createState() => _GlassProgressRingState();
}

class _GlassProgressRingState extends State<GlassProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final effectiveColor = widget.color ?? theme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveColor.withValues(alpha: 0.1),
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
          // Progress Ring
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: _progressAnimation.value,
                  color: effectiveColor,
                  strokeWidth: 4,
                ),
              );
            },
          ),
          // Center Content
          if (widget.centerWidget != null)
            widget.centerWidget!
          else if (widget.centerText != null)
            Text(
              widget.centerText!,
              style: theme.titleSmall.override(
                color: effectiveColor,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Glass Floating Action Button
class GlassFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const GlassFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bgColor = backgroundColor ?? theme.primary;
    final fgColor = foregroundColor ?? Colors.white;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor.withValues(alpha: 0.9),
                  bgColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(28),
                child: Icon(
                  icon,
                  color: fgColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass Search Bar
class GlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final Function(String)? onChanged;
  final VoidCallback? onFilterTap;

  const GlassSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GlassDesignSystem.glassBackground(
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: theme.bodyMedium.override(
                color: theme.primaryText,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: hintText ?? 'Search...',
                hintStyle: theme.bodyMedium.override(
                  color: theme.secondaryText,
                  height: 1.4,
                ),
                prefixIcon: Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: theme.secondaryText,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (onFilterTap != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FontAwesomeIcons.sliders,
                    color: theme.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FoCoCo Glass Navigation Bar Component
/// Easy-to-use wrapper for the glass navigation system
class FoCoCoGlassNavBar extends StatelessWidget {
  final String currentRoute;
  final Function(String route)? onNavigate;
  final VoidCallback? onVoicePressed;
  final bool showLabels;
  final double height;
  final EdgeInsets? margin;
  final bool enableVoiceAnimation;

  const FoCoCoGlassNavBar({
    super.key,
    required this.currentRoute,
    this.onNavigate,
    this.onVoicePressed,
    this.showLabels = false,
    this.height = 70.0,
    this.margin,
    this.enableVoiceAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassDesignSystem.focoCoGlassNavBar(
      currentRoute: currentRoute,
      onNavigate: onNavigate ?? _defaultNavigate,
      onVoicePressed: onVoicePressed ?? _defaultVoiceAction,
      showLabels: showLabels,
      height: height,
      margin: margin,
      enableVoiceAnimation: enableVoiceAnimation,
    );
  }

  void _defaultNavigate(String route) {
    // Default navigation implementation
    // This can be overridden by providing onNavigate callback
    print('Navigate to: $route');
  }

  void _defaultVoiceAction() {
    // Default voice action implementation
    // This can be overridden by providing onVoicePressed callback
    print('Voice button pressed');
  }
}

/// Navigation Helper for FoCoCo Routes
class FoCoCoNavigation {
  // Route constants
  static const String dashboard = '/dashboard';
  static const String golfRounds = '/caddy_play';
  static const String focoMap = '/foco_map';
  static const String profile = '/profile';
  static const String aiInsights = '/ai_insights';
  static const String coachingModules = '/mind_coach';
  static const String progress = '/progress';
  static const String achievements = '/achievements';
  static const String varkOnboarding = '/vark_onboarding';

  /// Navigate to a specific route with proper context
  static void navigateTo(BuildContext context, String route) {
    switch (route) {
      case dashboard:
        Navigator.pushReplacementNamed(context, '/mind_coach');
        break;
      case golfRounds:
        Navigator.pushReplacementNamed(context, '/caddy_play');
        break;
      case focoMap:
        Navigator.pushReplacementNamed(context, '/foco_map');
        break;
      case profile:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case aiInsights:
        Navigator.pushNamed(context, '/ai_insights');
        break;
      case coachingModules:
        Navigator.pushNamed(context, '/mind_coach');
        break;
      case progress:
        Navigator.pushNamed(context, '/progress');
        break;
      case achievements:
        Navigator.pushNamed(context, '/achievements');
        break;
      case varkOnboarding:
        Navigator.pushNamed(context, '/vark_onboarding');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/mind_coach');
    }
  }

  /// Get current route from context
  static String getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name ?? '/mind_coach';
  }

  /// Check if route is a main navigation route
  static bool isMainRoute(String route) {
    return [dashboard, golfRounds, focoMap, profile].contains(route);
  }
}
