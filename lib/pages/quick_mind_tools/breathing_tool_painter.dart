import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for breathing exercise - expanding/contracting circles
class BreathingCirclePainter extends CustomPainter {
  final double breathProgress; // 0.0 to 1.0 (0 = inhale start, 1 = exhale end)
  final Color color;
  final bool isInhale; // true = inhaling, false = exhaling

  BreathingCirclePainter({
    required this.breathProgress,
    required this.color,
    required this.isInhale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.4;
    
    // Calculate current radius based on breath phase
    final radius = maxRadius * (isInhale ? breathProgress : (1.0 - breathProgress));
    
    // Draw multiple concentric circles for depth
    for (int i = 0; i < 3; i++) {
      final circleRadius = radius - (i * 20.0);
      if (circleRadius > 0) {
        final opacity = (1.0 - (i * 0.3)).clamp(0.2, 1.0);
        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        
        canvas.drawCircle(center, circleRadius, paint);
      }
    }
    
    // Draw center point
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerPaint);
  }

  @override
  bool shouldRepaint(BreathingCirclePainter oldDelegate) {
    return oldDelegate.breathProgress != breathProgress ||
        oldDelegate.color != color ||
        oldDelegate.isInhale != isInhale;
  }
}


