import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '/flutter_flow/flutter_flow_theme.dart';

/// Premium Ambient Painter for immersive background effects
/// Matches quality of Calm and Strava visual experiences
class PremiumAmbientPainter extends CustomPainter {
  final double time;
  final List<Particle> particles;
  final List<Wave> waves;
  final FlutterFlowTheme theme;
  final double focusScore;
  final double calmLevel;

  PremiumAmbientPainter({
    required this.time,
    required this.particles,
    required this.waves,
    required this.theme,
    required this.focusScore,
    required this.calmLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw gradient background layers
    _drawGradientLayers(canvas, size);
    
    // Draw waves
    _drawWaves(canvas, size);
    
    // Draw particles with glow effects
    _drawParticles(canvas, size);
    
    // Draw focus/calm energy fields
    _drawEnergyFields(canvas, size);
  }

  /// Draw layered gradients for depth
  void _drawGradientLayers(Canvas canvas, Size size) {
    // Base gradient
    final baseGradient = ui.Gradient.radial(
      Offset(size.width * 0.5, size.height * 0.3),
      size.width * 0.8,
      [
        theme.mentalFocus.withValues(alpha: 0.3 * focusScore),
        theme.mentalCalm.withValues(alpha: 0.2 * calmLevel),
        Colors.transparent,
      ],
      [0.0, 0.5, 1.0],
    );

    final basePaint = Paint()
      ..shader = baseGradient
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      basePaint,
    );

    // Secondary gradient overlay
    final overlayGradient = ui.Gradient.linear(
      Offset(0, size.height * 0.2),
      Offset(size.width, size.height * 0.8),
      [
        theme.mentalStrength.withValues(alpha: 0.15),
        Colors.transparent,
      ],
    );

    final overlayPaint = Paint()
      ..shader = overlayGradient
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
    );
  }

  /// Draw animated waves
  void _drawWaves(Canvas canvas, Size size) {
    for (var wave in waves) {
      final path = Path();
      final waveHeight = size.height * 0.3 * wave.amplitude;
      final baseY = size.height * 0.7 + (wave.colorIndex * 30.0);

      path.moveTo(0, baseY);

      for (double x = 0; x < size.width; x += 2) {
        final normalizedX = x / size.width;
        final y = baseY +
            math.sin(normalizedX * math.pi * 4 + wave.phase) * waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final colors = [
        theme.mentalFocus,
        theme.mentalCalm,
        theme.mentalStrength,
      ];

      final wavePaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, baseY),
          Offset(0, baseY + waveHeight * 2),
          [
            colors[wave.colorIndex].withValues(alpha: 0.15),
            colors[wave.colorIndex].withValues(alpha: 0.05),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, wavePaint);

      // Add glow effect
      final glowPaint = Paint()
        ..color = colors[wave.colorIndex].withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawPath(path, glowPaint);
    }
  }

  /// Draw particles with advanced glow effects
  void _drawParticles(Canvas canvas, Size size) {
    final colors = [
      theme.mentalFocus,
      theme.mentalCalm,
      theme.mentalStrength,
    ];

    for (var particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      final color = colors[particle.colorIndex];

      // Outer glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: particle.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * 3,
        glowPaint,
      );

      // Middle glow
      final middlePaint = Paint()
        ..color = color.withValues(alpha: particle.opacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * 2,
        middlePaint,
      );

      // Core particle
      final corePaint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        corePaint,
      );
    }

    // Draw connections between nearby particles
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        final distance = math.sqrt(
          math.pow((p1.x - p2.x) * size.width, 2) +
              math.pow((p1.y - p2.y) * size.height, 2),
        );

        if (distance < 80) {
          final opacity = (1.0 - distance / 80).clamp(0.0, 0.3);
          final color = colors[p1.colorIndex];
          connectionPaint.color = color.withValues(alpha: opacity);
          connectionPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            connectionPaint,
          );
        }
      }
    }
  }

  /// Draw energy fields for focus and calm
  void _drawEnergyFields(Canvas canvas, Size size) {
    // Focus energy field (top area)
    if (focusScore > 0.1) {
      final focusGradient = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.2),
        size.width * 0.4 * focusScore,
        [
          theme.mentalFocus.withValues(alpha: 0.3 * focusScore),
          theme.mentalFocus.withValues(alpha: 0.1 * focusScore),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

      final focusPaint = Paint()
        ..shader = focusGradient
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.2),
        size.width * 0.4 * focusScore,
        focusPaint,
      );
    }

    // Calm energy field (bottom area)
    if (calmLevel > 0.1) {
      final calmGradient = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.8),
        size.width * 0.4 * calmLevel,
        [
          theme.mentalCalm.withValues(alpha: 0.3 * calmLevel),
          theme.mentalCalm.withValues(alpha: 0.1 * calmLevel),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

      final calmPaint = Paint()
        ..shader = calmGradient
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.8),
        size.width * 0.4 * calmLevel,
        calmPaint,
      );
    }
  }

  @override
  bool shouldRepaint(PremiumAmbientPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.particles != particles ||
        oldDelegate.waves != waves ||
        oldDelegate.focusScore != focusScore ||
        oldDelegate.calmLevel != calmLevel;
  }
}

/// Breathing Ring Painter - Interactive breathing visualization
/// Matches Calm app quality
class BreathingRingPainter extends CustomPainter {
  final double scale; // 0.4 to 1.0
  final Color color;
  final FlutterFlowTheme theme;

  BreathingRingPainter({
    required this.scale,
    required this.color,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.4;
    final currentRadius = maxRadius * scale;

    // Outer glow rings (multiple layers for depth)
    for (int i = 3; i > 0; i--) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.2 / i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 - (i * 2)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          10.0 + (i * 5),
        );

      canvas.drawCircle(
        center,
        currentRadius + (i * 10),
        glowPaint,
      );
    }

    // Main breathing ring
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, currentRadius, mainPaint);

    // Inner accent ring
    final accentPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(
      center,
      currentRadius * 0.85,
      accentPaint,
    );

    // Core center point
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, corePaint);

    // Pulsing center glow
    final centerGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 20, centerGlowPaint);
  }

  @override
  bool shouldRepaint(BreathingRingPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.color != color;
  }
}

/// Focus Meter Painter - Visual progress indicator
/// Matches Strava quality metrics display
class FocusMeterPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final FlutterFlowTheme theme;

  FocusMeterPainter({
    required this.progress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 8.0;
    final barHeight = size.height - (padding * 2);
    final barWidth = size.width - (padding * 2);
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padding,
        padding,
        barWidth,
        barHeight,
      ),
      Radius.circular(barHeight / 2),
    );

    // Background
    final backgroundPaint = Paint()
      ..color = theme.glassBackground.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(barRect, backgroundPaint);

    // Progress bar with gradient
    final progressWidth = barWidth * progress;
    if (progressWidth > 0) {
      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          padding,
          padding,
          progressWidth,
          barHeight,
        ),
        Radius.circular(barHeight / 2),
      );

      final gradient = ui.Gradient.linear(
        Offset(padding, padding),
        Offset(padding + progressWidth, padding),
        [
          theme.mentalFocus,
          theme.mentalFocus.withValues(alpha: 0.8),
        ],
      );

      final progressPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;

      canvas.drawRRect(progressRect, progressPaint);

      // Glow effect
      final glowPaint = Paint()
        ..color = theme.mentalFocus.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(progressRect, glowPaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(barRect, borderPaint);
  }

  @override
  bool shouldRepaint(FocusMeterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Calm Level Painter - Horizontal progress bar
class CalmLevelPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final FlutterFlowTheme theme;

  CalmLevelPainter({
    required this.progress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 2.0;
    final barHeight = size.height - (padding * 2);
    final barWidth = size.width - (padding * 2);
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        padding,
        padding,
        barWidth,
        barHeight,
      ),
      Radius.circular(barHeight / 2),
    );

    // Background
    final backgroundPaint = Paint()
      ..color = theme.glassBackground.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(barRect, backgroundPaint);

    // Progress with gradient
    final progressWidth = barWidth * progress;
    if (progressWidth > 0) {
      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          padding,
          padding,
          progressWidth,
          barHeight,
        ),
        Radius.circular(barHeight / 2),
      );

      final gradient = ui.Gradient.linear(
        Offset(padding, padding),
        Offset(padding + progressWidth, padding),
        [
          theme.mentalCalm,
          theme.mentalCalm.withValues(alpha: 0.7),
        ],
      );

      final progressPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;

      canvas.drawRRect(progressRect, progressPaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(barRect, borderPaint);
  }

  @override
  bool shouldRepaint(CalmLevelPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Particle class (moved from widget file for painter access)
class Particle {
  double x;
  double y;
  double size;
  double opacity;
  double speedX;
  double speedY;
  int colorIndex;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
    required this.colorIndex,
  });
}

/// Wave class (moved from widget file for painter access)
class Wave {
  double phase;
  double amplitude;
  double speed;
  int colorIndex;

  Wave({
    required this.phase,
    required this.amplitude,
    required this.speed,
    required this.colorIndex,
  });
}
