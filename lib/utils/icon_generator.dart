import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math' as math;

/// Simple icon generator for FoCoCo
class FoCoCoIconGenerator {
  
  /// Generates a FoCoCo branded icon
  static Future<void> generateIcon() async {
    final size = 1024.0; // High resolution for better quality
    
    // Create a custom painter for the icon
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    // Background gradient
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.0,
        colors: [
          Color(0xFF0A3669), // FoCoCo primary
          Color(0xFF1E4A6B),
          Color(0xFF2D5A7B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size, size));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), backgroundPaint);
    
    // Golf ball
    final golfBallPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final golfBallCenter = Offset(size * 0.5, size * 0.5);
    final golfBallRadius = size * 0.3;
    
    canvas.drawCircle(golfBallCenter, golfBallRadius, golfBallPaint);
    
    // Golf ball dimples
    final dimplePaint = Paint()
      ..color = Color(0xFF0A3669).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 24; i++) {
      final angle = (i * 15) * (math.pi / 180);
      final dimpleRadius = golfBallRadius * 0.6;
      final dimpleX = golfBallCenter.dx + dimpleRadius * math.cos(angle);
      final dimpleY = golfBallCenter.dy + dimpleRadius * math.sin(angle);
      
      canvas.drawCircle(
        Offset(dimpleX, dimpleY),
        size * 0.015,
        dimplePaint,
      );
    }
    
    // Central "F" logo
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'F',
        style: TextStyle(
          fontSize: size * 0.2,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A3669),
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    final textOffset = Offset(
      golfBallCenter.dx - textPainter.width / 2,
      golfBallCenter.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, textOffset);
    
    // AI brain pattern overlay
    final aiPaint = Paint()
      ..color = Color(0xFF4A90E2).withValues(alpha: 0.3)
      ..strokeWidth = size * 0.008
      ..style = PaintingStyle.stroke;
    
    // Draw neural network pattern
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180);
      final innerRadius = golfBallRadius * 0.2;
      final outerRadius = golfBallRadius * 0.8;
      
      final startX = golfBallCenter.dx + innerRadius * math.cos(angle);
      final startY = golfBallCenter.dy + innerRadius * math.sin(angle);
      final endX = golfBallCenter.dx + outerRadius * math.cos(angle);
      final endY = golfBallCenter.dy + outerRadius * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        aiPaint,
      );
      
      // Draw nodes
      final nodePaint = Paint()
        ..color = Color(0xFF4A90E2).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(endX, endY),
        size * 0.008,
        nodePaint,
      );
    }
    
    // Central AI node
    final centralNodePaint = Paint()
      ..color = Color(0xFF4A90E2).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      golfBallCenter,
      size * 0.012,
      centralNodePaint,
    );
    
    // Create picture and convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    
    // Convert to bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    // Save to assets/images/
    final file = File('assets/images/fococo_icon.png');
    await file.writeAsBytes(bytes);
    
    print('✅ FoCoCo icon generated successfully: ${file.path}');
  }
}

/// Simple runner for the icon generator
void main() async {
  await FoCoCoIconGenerator.generateIcon();
} 