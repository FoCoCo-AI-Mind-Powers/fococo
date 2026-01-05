import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for reset exercise - calming waves/ripples
class ResetWavePainter extends CustomPainter {
  final double wavePhase;
  final Color color;
  final int waveCount;

  ResetWavePainter({
    required this.wavePhase,
    required this.color,
    this.waveCount = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2)
    );

    for (int i = 0; i < waveCount; i++) {
      final waveOffset = (wavePhase + i * 0.2) % 1.0;
      final radius = maxRadius * waveOffset;
      final opacity = (1.0 - waveOffset).clamp(0.2, 0.8);
      
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, paint);
    }

    // Draw center calming point
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerPaint);
  }

  @override
  bool shouldRepaint(ResetWavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase || oldDelegate.color != color;
  }
}


