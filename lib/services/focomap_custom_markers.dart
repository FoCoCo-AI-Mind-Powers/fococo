import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show BitmapDescriptor;
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/schema/golf_rounds_record.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/scorecard_record.dart';
import '/backend/schema/shot_logs_record.dart';

/// Custom marker types for different golf data
enum MarkerType {
  golfRound,
  roundLog,
  scorecard,
  shotLog,
  cluster,
  hotspot,
  trajectory,
  liveLocation,
}

/// Service for creating custom markers with unique designs
class FoCoMapCustomMarkers {
  static final Map<String, ui.Image> _imageCache = {};
  static final Map<String, BitmapDescriptor> _markerCache = {};

  /// Initialize marker assets
  static Future<void> initialize() async {
    // Pre-load marker images if needed
    await _preloadMarkerAssets();
  }

  /// Create custom marker for golf round data
  static Future<BitmapDescriptor> createGolfRoundMarker({
    required GolfRoundsRecord round,
    bool isSelected = false,
  }) async {
    final cacheKey =
        'golf_round_${round.score}_${round.scoreToPar}_$isSelected';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = isSelected ? 120.0 : 80.0;

    // Background circle with gradient
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size / 2, size / 2),
          size / 2,
          [
            _getScoreColor(round.scoreToPar),
            _getScoreColor(round.scoreToPar).withValues(alpha: 0.6),
          ],
          [0.0, 1.0],
        ),
    );

    // White inner circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 8, innerPaint);

    // Score text
    final scorePainter = TextPainter(
      text: TextSpan(
        text: '${round.score}',
        style: TextStyle(
          color: _getScoreColor(round.scoreToPar),
          fontSize: isSelected ? 28 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(
      canvas,
      Offset(
        size / 2 - scorePainter.width / 2,
        size / 2 - scorePainter.height / 2 - 10,
      ),
    );

    // Score to par
    final parText = round.scoreToPar > 0
        ? '+${round.scoreToPar}'
        : round.scoreToPar == 0
            ? 'E'
            : '${round.scoreToPar}';
    final parPainter = TextPainter(
      text: TextSpan(
        text: parText,
        style: TextStyle(
          color: Colors.black87,
          fontSize: isSelected ? 16 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    parPainter.layout();
    parPainter.paint(
      canvas,
      Offset(
        size / 2 - parPainter.width / 2,
        size / 2 + 5,
      ),
    );

    // Course abbreviation
    if (isSelected && round.courseName.isNotEmpty) {
      final coursePainter = TextPainter(
        text: TextSpan(
          text: _abbreviateCourseName(round.courseName),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      coursePainter.layout();
      coursePainter.paint(
        canvas,
        Offset(
          size / 2 - coursePainter.width / 2,
          size - 20,
        ),
      );
    }

    // Selection ring
    if (isSelected) {
      final ringPaint = Paint()
        ..color = _getScoreColor(round.scoreToPar)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2 + 4, ringPaint);
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  /// Create custom marker for round log (mental data)
  static Future<BitmapDescriptor> createRoundLogMarker({
    required RoundLogsRecord round,
    bool isSelected = false,
  }) async {
    final cacheKey =
        'round_log_${round.mindsetColor}_${round.overallMindsetEmoji}_$isSelected';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = isSelected ? 100.0 : 70.0;

    // Hexagon shape for mental data
    final path = _createHexagonPath(size);

    // Background with mindset color
    final bgPaint = Paint()
      ..color = _getMindsetColor(round.mindsetColor)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // White inner hexagon
    final innerPath = _createHexagonPath(size - 10);
    final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawPath(innerPath, innerPaint);

    // Emoji
    final emojiPainter = TextPainter(
      text: TextSpan(
        text: round.overallMindsetEmoji,
        style: TextStyle(fontSize: isSelected ? 32 : 24),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    emojiPainter.layout();
    emojiPainter.paint(
      canvas,
      Offset(
        size / 2 - emojiPainter.width / 2,
        size / 2 - emojiPainter.height / 2 - 5,
      ),
    );

    // Mental scores
    if (isSelected) {
      final scoreText =
          'F${round.mindsetFocus} C${round.mindsetConfidence} C${round.mindsetControl}';
      final scorePainter = TextPainter(
        text: TextSpan(
          text: scoreText,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      scorePainter.layout();
      scorePainter.paint(
        canvas,
        Offset(
          size / 2 - scorePainter.width / 2,
          size - 20,
        ),
      );
    }

    // Pulse effect for live rounds
    if (round.isLive) {
      final pulsePaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(_createHexagonPath(size + 8), pulsePaint);
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  /// Create custom marker for scorecard
  static Future<BitmapDescriptor> createScorecardMarker({
    required ScorecardRecord scorecard,
    bool isSelected = false,
  }) async {
    final cacheKey =
        'scorecard_${scorecard.totalScore}_${scorecard.scoreDifferential}_$isSelected';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = isSelected ? 110.0 : 75.0;

    // Square with rounded corners for scorecard
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      Radius.circular(size / 5),
    );

    // Background gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size, size),
        [
          Colors.indigo,
          Colors.indigo.shade700,
        ],
      );
    canvas.drawRRect(rect, bgPaint);

    // White inner area
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 5, size - 10, size - 10),
      Radius.circular(size / 5 - 2),
    );
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawRRect(innerRect, innerPaint);

    // Scorecard icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '📋',
        style: TextStyle(fontSize: isSelected ? 24 : 18),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        size / 2 - iconPainter.width / 2,
        10,
      ),
    );

    // Score
    final scorePainter = TextPainter(
      text: TextSpan(
        text: '${scorecard.totalScore}',
        style: TextStyle(
          color: Colors.indigo.shade700,
          fontSize: isSelected ? 20 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(
      canvas,
      Offset(
        size / 2 - scorePainter.width / 2,
        size / 2 - 5,
      ),
    );

    // Differential
    final diffPainter = TextPainter(
      text: TextSpan(
        text: scorecard.scoreDifferential,
        style: TextStyle(
          color: Colors.black87,
          fontSize: isSelected ? 14 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    diffPainter.layout();
    diffPainter.paint(
      canvas,
      Offset(
        size / 2 - diffPainter.width / 2,
        size - 25,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  /// Create custom marker for shot log
  static Future<BitmapDescriptor> createShotLogMarker({
    required ShotLogsRecord shot,
    bool isSelected = false,
  }) async {
    final cacheKey =
        'shot_log_${shot.clubUsed}_${shot.shotOutcome}_$isSelected';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = isSelected ? 90.0 : 60.0;

    // Diamond shape for shots
    final path = _createDiamondPath(size);

    // Background color based on club type
    final bgPaint = Paint()
      ..color = _getClubColor(shot.clubUsed)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // Inner diamond
    final innerPath = _createDiamondPath(size - 8);
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawPath(innerPath, innerPaint);

    // Club emoji
    final clubEmoji =
        shot.clubIcon.isNotEmpty ? shot.clubIcon : _getClubEmoji(shot.clubUsed);
    final clubPainter = TextPainter(
      text: TextSpan(
        text: clubEmoji,
        style: TextStyle(fontSize: isSelected ? 20 : 16),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    clubPainter.layout();
    clubPainter.paint(
      canvas,
      Offset(
        size / 2 - clubPainter.width / 2,
        size / 2 - clubPainter.height / 2 - 8,
      ),
    );

    // Distance
    final distPainter = TextPainter(
      text: TextSpan(
        text: '${shot.distanceAttempted.toInt()}y',
        style: TextStyle(
          color: Colors.black87,
          fontSize: isSelected ? 12 : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    distPainter.layout();
    distPainter.paint(
      canvas,
      Offset(
        size / 2 - distPainter.width / 2,
        size / 2 + 2,
      ),
    );

    // Outcome indicator
    if (isSelected) {
      final outcomeColor = _getShotOutcomeColor(shot.shotOutcome);
      final outcomePaint = Paint()
        ..color = outcomeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(_createDiamondPath(size + 4), outcomePaint);
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  /// Create cluster marker
  static Future<BitmapDescriptor> createClusterMarker({
    required int count,
    required MarkerType primaryType,
    bool isSelected = false,
  }) async {
    final cacheKey = 'cluster_${count}_${primaryType.name}_$isSelected';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = isSelected ? 100.0 : 70.0;

    // Outer circle with gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size / 2, size / 2),
        size / 2,
        [
          _getTypeColor(primaryType),
          _getTypeColor(primaryType).withValues(alpha: 0.3),
        ],
        [0.0, 1.0],
      );
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, bgPaint);

    // Inner circle
    final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 10, innerPaint);

    // Count text
    final countPainter = TextPainter(
      text: TextSpan(
        text: count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: _getTypeColor(primaryType),
          fontSize: isSelected ? 24 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    countPainter.layout();
    countPainter.paint(
      canvas,
      Offset(
        size / 2 - countPainter.width / 2,
        size / 2 - countPainter.height / 2,
      ),
    );

    // Type indicator
    final typeIcon = _getTypeIcon(primaryType);
    final typePainter = TextPainter(
      text: TextSpan(
        text: typeIcon,
        style: TextStyle(fontSize: isSelected ? 16 : 12),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    typePainter.layout();
    typePainter.paint(
      canvas,
      Offset(
        size / 2 - typePainter.width / 2,
        size - 25,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  /// Create hotspot marker
  static Future<BitmapDescriptor> createHotspotMarker({
    required double intensity,
    required String description,
    bool isSelected = false,
  }) async {
    final cacheKey = 'hotspot_${intensity}_$isSelected';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = isSelected ? 120.0 : 80.0;

    // Draw multiple circles for heat effect
    for (double i = size; i > 0; i -= 10) {
      final alpha = (i / size) * intensity;
      final paint = Paint()
        ..color = Colors.red.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size / 2, size / 2), i / 2, paint);
    }

    // Center dot
    final centerPaint = Paint()..color = Colors.red;
    canvas.drawCircle(Offset(size / 2, size / 2), 5, centerPaint);

    // Intensity text
    final intensityText = '${(intensity * 100).toInt()}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: intensityText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 2),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size / 2 - textPainter.width / 2,
        size / 2 - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  /// Create live location marker
  static Future<BitmapDescriptor> createLiveLocationMarker({
    bool isMoving = false,
    double heading = 0,
  }) async {
    final cacheKey = 'live_location_${isMoving}_${heading.toInt()}';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 60.0;

    // Save canvas state for rotation
    canvas.save();
    canvas.translate(size / 2, size / 2);
    canvas.rotate(heading * (pi / 180));
    canvas.translate(-size / 2, -size / 2);

    // Outer pulse ring
    final pulsePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, pulsePaint);

    // Main circle
    final mainPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), 20, mainPaint);

    // White inner circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size / 2, size / 2), 15, innerPaint);

    // Blue center dot
    final centerPaint = Paint()..color = Colors.blue;
    canvas.drawCircle(Offset(size / 2, size / 2), 8, centerPaint);

    // Direction indicator if moving
    if (isMoving) {
      final path = Path()
        ..moveTo(size / 2, 10)
        ..lineTo(size / 2 - 10, 25)
        ..lineTo(size / 2 + 10, 25)
        ..close();

      final arrowPaint = Paint()..color = Colors.blue;
      canvas.drawPath(path, arrowPaint);
    }

    canvas.restore();

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _markerCache[cacheKey] = descriptor;

    return descriptor;
  }

  // Helper methods

  static Future<void> _preloadMarkerAssets() async {
    // Pre-load any custom images if needed
  }

  static Color _getScoreColor(int scoreToPar) {
    if (scoreToPar < -2) return Colors.purple;
    if (scoreToPar < 0) return Colors.blue;
    if (scoreToPar == 0) return Colors.green;
    if (scoreToPar <= 2) return Colors.orange;
    return Colors.red;
  }

  static Color _getMindsetColor(String color) {
    switch (color.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  static Color _getClubColor(String club) {
    final clubLower = club.toLowerCase();
    if (clubLower.contains('driver')) return Colors.red;
    if (clubLower.contains('wood')) return Colors.orange;
    if (clubLower.contains('iron')) return Colors.blue;
    if (clubLower.contains('wedge')) return Colors.purple;
    if (clubLower.contains('putter')) return Colors.green;
    return Colors.grey;
  }

  static Color _getShotOutcomeColor(String outcome) {
    final outcomeLower = outcome.toLowerCase();
    if (outcomeLower.contains('fairway') || outcomeLower.contains('green')) {
      return Colors.green;
    }
    if (outcomeLower.contains('rough') || outcomeLower.contains('sand')) {
      return Colors.orange;
    }
    if (outcomeLower.contains('water') || outcomeLower.contains('ob')) {
      return Colors.red;
    }
    return Colors.blue;
  }

  static Color _getTypeColor(MarkerType type) {
    switch (type) {
      case MarkerType.golfRound:
        return Colors.indigo;
      case MarkerType.roundLog:
        return Colors.teal;
      case MarkerType.scorecard:
        return Colors.purple;
      case MarkerType.shotLog:
        return Colors.orange;
      case MarkerType.cluster:
        return Colors.blue;
      case MarkerType.hotspot:
        return Colors.red;
      case MarkerType.trajectory:
        return Colors.green;
      case MarkerType.liveLocation:
        return Colors.blue;
    }
  }

  static String _getTypeIcon(MarkerType type) {
    switch (type) {
      case MarkerType.golfRound:
        return '⛳';
      case MarkerType.roundLog:
        return '🧠';
      case MarkerType.scorecard:
        return '📋';
      case MarkerType.shotLog:
        return '🏌️';
      case MarkerType.cluster:
        return '📍';
      case MarkerType.hotspot:
        return '🔥';
      case MarkerType.trajectory:
        return '📈';
      case MarkerType.liveLocation:
        return '📍';
    }
  }

  static String _getClubEmoji(String club) {
    final clubLower = club.toLowerCase();
    if (clubLower.contains('driver') || clubLower.contains('wood'))
      return '🏌️';
    if (clubLower.contains('iron')) return '⛳';
    if (clubLower.contains('wedge')) return '🎯';
    if (clubLower.contains('putter')) return '🎱';
    return '🏌️';
  }

  static String _abbreviateCourseName(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(3, name.length)).toUpperCase();
  }

  static Path _createHexagonPath(double size) {
    final path = Path();
    final center = size / 2;
    final radius = size / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final x = center + radius * cos(angle);
      final y = center + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path _createDiamondPath(double size) {
    final path = Path();
    final center = size / 2;

    path.moveTo(center, 0);
    path.lineTo(size, center);
    path.lineTo(center, size);
    path.lineTo(0, center);
    path.close();

    return path;
  }

  /// Clear marker cache
  static void clearCache() {
    _imageCache.clear();
    _markerCache.clear();
  }
}
