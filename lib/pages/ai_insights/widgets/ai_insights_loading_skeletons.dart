import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/glass_design_system.dart';
import 'dart:ui';

/// Loading skeleton components for AI Insights page with transparent glass styling
class AIInsightsLoadingSkeletons {
  /// Glass-styled shimmer skeleton with transparent colors
  static Widget _glassSkeleton({
    required double height,
    required double width,
    required double borderRadius,
    required FlutterFlowTheme theme,
  }) {
    return _GlassShimmerSkeleton(
      height: height,
      width: width,
      borderRadius: borderRadius,
      theme: theme,
    );
  }

  static Widget buildSmartHighlightCardSkeleton(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDesignSystem.glassBlur,
          sigmaY: GlassDesignSystem.glassBlur,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.glassBackground
                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                theme.glassTint
                    .withValues(alpha: GlassDesignSystem.glassOpacity),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder
                  .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: _glassSkeleton(
                  height: 40,
                  width: 300,
                  borderRadius: 8,
                  theme: theme,
                ),
              ),
              const SizedBox(height: 16),
              _glassSkeleton(
                height: 20,
                width: 200,
                borderRadius: 4,
                theme: theme,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: _glassSkeleton(
                  height: 16,
                  width: 280,
                  borderRadius: 4,
                  theme: theme,
                ),
              ),
              const SizedBox(height: 4),
              _glassSkeleton(
                height: 16,
                width: 150,
                borderRadius: 4,
                theme: theme,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(3, (index) {
                  return _glassSkeleton(
                    height: 36,
                    width: 80,
                    borderRadius: 12,
                    theme: theme,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildMindGameLinkTileSkeleton(FlutterFlowTheme theme) {
    return SizedBox(
      width: 320,
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassDesignSystem.glassBlur,
            sigmaY: GlassDesignSystem.glassBlur,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.glassBackground
                      .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                  theme.glassTint
                      .withValues(alpha: GlassDesignSystem.glassOpacity),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.glassBorder
                    .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _glassSkeleton(
                      height: 24,
                      width: 280,
                      borderRadius: 4,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _glassSkeleton(
                    height: 20,
                    width: 250,
                    borderRadius: 4,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _glassSkeleton(
                      height: 16,
                      width: 260,
                      borderRadius: 4,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _glassSkeleton(
                    height: 16,
                    width: 200,
                    borderRadius: 4,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(3, (index) {
                      return _glassSkeleton(
                        height: 29,
                        width: 70,
                        borderRadius: 12,
                        theme: theme,
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _glassSkeleton(
                          height: 36,
                          width: 120,
                          borderRadius: 12,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _glassSkeleton(
                          height: 36,
                          width: 120,
                          borderRadius: 12,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildPillarPulseSkeleton(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDesignSystem.glassBlur,
          sigmaY: GlassDesignSystem.glassBlur,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.glassBackground
                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                theme.glassTint
                    .withValues(alpha: GlassDesignSystem.glassOpacity),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder
                  .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
              width: 1.5,
            ),
          ),
          child: Column(
            children: List.generate(3, (index) {
              return Column(
                children: [
                  Row(
                    children: [
                      _glassSkeleton(
                        height: 20,
                        width: 100,
                        borderRadius: 4,
                        theme: theme,
                      ),
                      const SizedBox(width: 12),
                      _glassSkeleton(
                        height: 24,
                        width: 60,
                        borderRadius: 8,
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _glassSkeleton(
                    height: 14,
                    width: 200,
                    borderRadius: 4,
                    theme: theme,
                  ),
                  if (index < 2) const SizedBox(height: 16),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  static Widget buildCuesRoutinesCardSkeleton(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDesignSystem.glassBlur,
          sigmaY: GlassDesignSystem.glassBlur,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.glassBackground
                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                theme.glassTint
                    .withValues(alpha: GlassDesignSystem.glassOpacity),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder
                  .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _glassSkeleton(
                    height: 48,
                    width: 48,
                    borderRadius: 12,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _glassSkeleton(
                          height: 20,
                          width: 150,
                          borderRadius: 4,
                          theme: theme,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: _glassSkeleton(
                            height: 16,
                            width: 200,
                            borderRadius: 4,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _glassSkeleton(
                      height: 40,
                      width: 100,
                      borderRadius: 12,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _glassSkeleton(
                      height: 40,
                      width: 100,
                      borderRadius: 12,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildRecommendationCardSkeleton(FlutterFlowTheme theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDesignSystem.glassBlur,
          sigmaY: GlassDesignSystem.glassBlur,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.glassBackground
                    .withValues(alpha: GlassDesignSystem.glassOpacity + 0.1),
                theme.glassTint
                    .withValues(alpha: GlassDesignSystem.glassOpacity),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.glassBorder
                  .withValues(alpha: GlassDesignSystem.glassBorderOpacity),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _glassSkeleton(
                height: 56,
                width: 56,
                borderRadius: 16,
                theme: theme,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _glassSkeleton(
                      height: 20,
                      width: 150,
                      borderRadius: 4,
                      theme: theme,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: _glassSkeleton(
                        height: 14,
                        width: 180,
                        borderRadius: 4,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _glassSkeleton(
                      height: 14,
                      width: 200,
                      borderRadius: 4,
                      theme: theme,
                    ),
                  ],
                ),
              ),
              _glassSkeleton(
                height: 16,
                width: 16,
                borderRadius: 8,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildFullPageSkeleton(FlutterFlowTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Section 1: Smart Highlights
          _glassSkeleton(
            height: 28,
            width: 200,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 4),
          _glassSkeleton(
            height: 16,
            width: 300,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) {
            return Column(
              children: [
                buildSmartHighlightCardSkeleton(theme),
                if (index < 2) const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 32),
          // Section 2: Mind & Game Links
          _glassSkeleton(
            height: 28,
            width: 200,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 4),
          _glassSkeleton(
            height: 16,
            width: 250,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(3, (index) {
                return Row(
                  children: [
                    buildMindGameLinkTileSkeleton(theme),
                    if (index < 2) const SizedBox(width: 16),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
          // Section 3: Pillar Pulse
          _glassSkeleton(
            height: 28,
            width: 150,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 4),
          _glassSkeleton(
            height: 16,
            width: 250,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 20),
          buildPillarPulseSkeleton(theme),
          const SizedBox(height: 32),
          // Section 4: Cues & Routines
          _glassSkeleton(
            height: 28,
            width: 250,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 4),
          _glassSkeleton(
            height: 16,
            width: 200,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) {
            return Column(
              children: [
                buildCuesRoutinesCardSkeleton(theme),
                if (index < 2) const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 32),
          // Section 5: Recommendations
          _glassSkeleton(
            height: 28,
            width: 300,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 4),
          _glassSkeleton(
            height: 16,
            width: 200,
            borderRadius: 4,
            theme: theme,
          ),
          const SizedBox(height: 20),
          ...List.generate(3, (index) {
            return Column(
              children: [
                buildRecommendationCardSkeleton(theme),
                if (index < 2) const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// Custom glass shimmer skeleton widget with transparent glass colors
class _GlassShimmerSkeleton extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;
  final FlutterFlowTheme theme;

  const _GlassShimmerSkeleton({
    required this.height,
    required this.width,
    required this.borderRadius,
    required this.theme,
  });

  @override
  State<_GlassShimmerSkeleton> createState() => _GlassShimmerSkeletonState();
}

class _GlassShimmerSkeletonState extends State<_GlassShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                widget.theme.glassBackground.withValues(alpha: 0.08),
                widget.theme.glassTint.withValues(alpha: 0.18),
                widget.theme.glassBackground.withValues(alpha: 0.25),
                widget.theme.glassTint.withValues(alpha: 0.18),
                widget.theme.glassBackground.withValues(alpha: 0.08),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
            border: Border.all(
              color: widget.theme.glassBorder.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        );
      },
    );
  }
}

