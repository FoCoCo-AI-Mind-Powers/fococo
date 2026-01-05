import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for visualization exercise - flowing particles
class VisualizationParticlePainter extends CustomPainter {
  final double time;
  final Color color;
  final List<Particle> particles;

  VisualizationParticlePainter({
    required this.time,
    required this.color,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      final radius = particle.size;
      
      // Create gradient effect for particles
      paint.color = color.withValues(alpha: particle.opacity);
      
      // Draw particle with glow effect
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
      
      // Draw outer glow
      paint.color = color.withValues(alpha: particle.opacity * 0.3);
      canvas.drawCircle(
        Offset(x, y),
        radius * 1.5,
        paint,
      );
    }

    // Draw flowing lines connecting particles
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < particles.length - 1; i++) {
      final p1 = particles[i];
      final p2 = particles[i + 1];
      final distance = math.sqrt(
        math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2)
      );
      
      if (distance < 0.3) {
        linePaint.color = color.withValues(alpha: (1.0 - distance * 2).clamp(0.1, 0.5));
        canvas.drawLine(
          Offset(p1.x * size.width, p1.y * size.height),
          Offset(p2.x * size.width, p2.y * size.height),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(VisualizationParticlePainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.particles != particles;
  }
}

class Particle {
  double x;
  double y;
  double size;
  double opacity;
  double speedX;
  double speedY;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speedX,
    required this.speedY,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Particle &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          size == other.size &&
          opacity == other.opacity &&
          speedX == other.speedX &&
          speedY == other.speedY;

  @override
  int get hashCode =>
      x.hashCode ^
      y.hashCode ^
      size.hashCode ^
      opacity.hashCode ^
      speedX.hashCode ^
      speedY.hashCode;
}

