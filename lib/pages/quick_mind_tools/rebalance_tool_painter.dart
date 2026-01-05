import 'package:flutter/material.dart';

/// Custom painter for rebalance exercise - balanced elements
class RebalanceBalancePainter extends CustomPainter {
  final double balanceProgress;
  final Color color;
  final List<BalanceElement> elements;

  RebalanceBalancePainter({
    required this.balanceProgress,
    required this.color,
    required this.elements,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw center balance point
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerPaint);

    // Draw balance line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(center.dx - size.width * 0.3, center.dy),
      Offset(center.dx + size.width * 0.3, center.dy),
      linePaint,
    );

    // Draw balance elements
    for (final element in elements) {
      final x = center.dx + element.x * size.width * 0.25;
      final y = center.dy + element.y * size.height * 0.25;
      
      final elementPaint = Paint()
        ..color = color.withValues(alpha: element.opacity)
        ..style = PaintingStyle.fill;
      
      // Draw element as circle
      canvas.drawCircle(
        Offset(x, y),
        element.size,
        elementPaint,
      );
      
      // Draw connection line to center
      final connectionPaint = Paint()
        ..color = color.withValues(alpha: element.opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawLine(center, Offset(x, y), connectionPaint);
    }
  }

  @override
  bool shouldRepaint(RebalanceBalancePainter oldDelegate) {
    return oldDelegate.balanceProgress != balanceProgress ||
        oldDelegate.elements != elements;
  }
}

class BalanceElement {
  double x; // -1.0 to 1.0 (relative to center)
  double y; // -1.0 to 1.0 (relative to center)
  double size;
  double opacity;

  BalanceElement({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceElement &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          size == other.size &&
          opacity == other.opacity;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ size.hashCode ^ opacity.hashCode;
}

