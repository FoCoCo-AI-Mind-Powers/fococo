import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

class MindCoachV2Visuals {
  MindCoachV2Visuals._();

  static const Color baseBackground = Color(0xFF05070C);
  static const Color homeNavAccent = Colors.white;

  static Color accentForPillar(MindCoachV2Pillar pillar) => switch (pillar) {
        MindCoachV2Pillar.focus => const Color(0xFF2794FF),
        MindCoachV2Pillar.confidence => const Color(0xFF33D98E),
        MindCoachV2Pillar.control => const Color(0xFFF0C55D),
      };

  static Color shellBackgroundForPillar(MindCoachV2Pillar? pillar) =>
      switch (pillar) {
        MindCoachV2Pillar.focus => const Color(0xFF070C18),
        MindCoachV2Pillar.confidence => const Color(0xFF07140F),
        MindCoachV2Pillar.control => const Color(0xFF161107),
        null => const Color(0xFF100919),
      };

  static Color shadowForPillar(MindCoachV2Pillar pillar) =>
      accentForPillar(pillar).withValues(alpha: 0.74);

  static Color dimTextColor = Colors.white.withValues(alpha: 0.62);

  static String iconAssetForPillar(MindCoachV2Pillar pillar) => switch (pillar) {
        MindCoachV2Pillar.focus => 'carbon:center-square',
        MindCoachV2Pillar.confidence => 'carbon:idea',
        MindCoachV2Pillar.control => 'carbon:scale',
      };

  static const List<MindCoachV2Pillar> homePillarOrder = [
    MindCoachV2Pillar.focus,
    MindCoachV2Pillar.confidence,
    MindCoachV2Pillar.control,
  ];
}

class MindCoachV2Backdrop extends StatelessWidget {
  const MindCoachV2Backdrop({
    super.key,
    required this.child,
    this.pillar,
  });

  final Widget child;
  final MindCoachV2Pillar? pillar;

  @override
  Widget build(BuildContext context) {
    final accent = pillar == null
        ? const Color(0xFF7A54F5)
        : MindCoachV2Visuals.accentForPillar(pillar!);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: MindCoachV2Visuals.baseBackground,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MindCoachV2Visuals.shellBackgroundForPillar(pillar),
            MindCoachV2Visuals.baseBackground,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            left: -80,
            right: -80,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.9),
                  radius: 1.15,
                  colors: [
                    accent.withValues(alpha: 0.16),
                    accent.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _MindCoachNoisePainter(
                    color: accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -80,
            right: -80,
            bottom: -220,
            height: 420,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, 1.0),
                  radius: 1.2,
                  colors: [
                    accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class MindCoachGlowLine extends StatelessWidget {
  const MindCoachGlowLine({
    super.key,
    required this.color,
    this.width = 176,
  });

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withValues(alpha: 0.82),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: width * 0.78,
            height: 8,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.65),
                  blurRadius: 14,
                  spreadRadius: 0.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MindCoachGlowCard extends StatelessWidget {
  const MindCoachGlowCard({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    this.borderRadius = 18,
    this.onTap,
    this.showTopGlow = false,
  });

  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showTopGlow;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(
          color: color.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
          if (showTopGlow)
            Positioned(
              left: 14,
              right: 14,
              top: -1,
              child: MindCoachGlowLine(
                color: color,
                width: double.infinity,
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: -1,
            child: MindCoachGlowLine(
              color: color,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class MindCoachOrb extends StatefulWidget {
  const MindCoachOrb({
    super.key,
    required this.color,
    this.active = true,
  });

  final Color color;
  final bool active;

  @override
  State<MindCoachOrb> createState() => _MindCoachOrbState();
}

class _MindCoachOrbState extends State<MindCoachOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = widget.active ? 1.0 + (_controller.value * 0.06) : 1.0;
        final outerGlow = widget.active ? 34 + (_controller.value * 18) : 22.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 184,
            height: 184,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.34),
                  blurRadius: outerGlow,
                  spreadRadius: 4,
                ),
              ],
              gradient: RadialGradient(
                colors: [
                  widget.color.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.95),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.74),
                      blurRadius: 18,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MindCoachNoisePainter extends CustomPainter {
  const _MindCoachNoisePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final random = math.Random(28);
    final pointCount = (size.width * size.height / 1800).round();
    for (var i = 0; i < pointCount; i += 1) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_MindCoachNoisePainter oldDelegate) =>
      oldDelegate.color != color;
}
