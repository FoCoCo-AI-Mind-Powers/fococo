import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/schema/golf_rounds_record.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/scorecard_record.dart';
import '/backend/schema/shot_logs_record.dart';
import '/pages/foco_map/platform_map_widget.dart';
import '/ai_integration/config/gemini_live_config.dart';

/// AI-powered spatial analysis and embeddings for FoCo Map
/// Integrates Gemini Embedding and Robotics-ER 1.5 models for enhanced map intelligence
/// Uses embeddings for similarity search and Robotics-ER 1.5 for spatial reasoning and real-time guidance
class FoCoMapAIService {
  static const String _embeddingModel = 'gemini-embedding-001';
  static const String _roboticsModel = 'gemini-robotics-er-1.5-preview';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Get API key from Secret Manager / cache / dart-define
  Future<String> get _apiKey => GeminiLiveAPIConfig.getApiKey();

  // Embedding cache for performance
  final Map<String, List<double>> _embeddingCache = {};

  // Spatial analysis results
  final StreamController<SpatialAnalysis> _spatialAnalysisController =
      StreamController<SpatialAnalysis>.broadcast();

  // Pattern recognition results
  final StreamController<PatternInsight> _patternController =
      StreamController<PatternInsight>.broadcast();

  // Real-time guidance stream
  final StreamController<RealtimeGuidance> _guidanceController =
      StreamController<RealtimeGuidance>.broadcast();

  Stream<SpatialAnalysis> get spatialAnalysisStream =>
      _spatialAnalysisController.stream;
  Stream<PatternInsight> get patternStream => _patternController.stream;
  Stream<RealtimeGuidance> get guidanceStream => _guidanceController.stream;

  FoCoMapAIService();

  /// Initialize the AI service
  Future<void> initialize() async {
    debugPrint(
        'FoCoMapAIService: Initializing with embedding and robotics models');
  }

  /// Generate embeddings for golf data using gemini-embedding-001
  Future<List<double>> generateEmbedding(
    String text, {
    String taskType = 'SEMANTIC_SIMILARITY',
    int outputDimensionality = 768,
  }) async {
    final apiKey = await _apiKey;
    // Skip if API key is not set or is placeholder
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint(
          '⚠️ FoCoMapAIService: API key not set, skipping embedding generation');
      return [];
    }

    // Check cache first
    final cacheKey = '$text-$taskType-$outputDimensionality';
    if (_embeddingCache.containsKey(cacheKey)) {
      return _embeddingCache[cacheKey]!;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_embeddingModel:embedContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'model': 'models/$_embeddingModel',
          'content': {
            'parts': [
              {'text': text}
            ]
          },
          'taskType': taskType,
          'outputDimensionality': outputDimensionality,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embeddings = data['embedding'] ?? data['embeddings'];
        if (embeddings == null) {
          throw Exception('No embedding data in response: ${response.body}');
        }
        // Handle both single embedding and array of embeddings
        final embeddingData = embeddings is List ? embeddings[0] : embeddings;
        final embedding = List<double>.from(embeddingData['values'] ?? []);

        // Normalize embedding for better similarity calculations
        final normalized = _normalizeEmbedding(embedding);

        // Cache the result
        _embeddingCache[cacheKey] = normalized;

        return normalized;
      } else {
        throw Exception('Failed to generate embedding: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating embedding: $e');
      return [];
    }
  }

  /// Use robotics model for spatial understanding and pattern recognition
  Future<RoboticsAnalysis> analyzeSpatialPatterns({
    required List<LatLng> positions,
    required Map<String, dynamic> contextData,
  }) async {
    final apiKey = await _apiKey;
    // Skip if API key is not set or is placeholder
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint(
          '⚠️ FoCoMapAIService: API key not set, skipping spatial analysis');
      return RoboticsAnalysis.empty();
    }

    try {
      // Prepare spatial data for robotics model
      final spatialPrompt = _buildSpatialPrompt(positions, contextData);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_roboticsModel:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': spatialPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysis = _parseRoboticsResponse(data);

        // Emit spatial analysis
        _spatialAnalysisController.add(SpatialAnalysis(
          timestamp: DateTime.now(),
          patterns: analysis.patterns,
          hotspots: analysis.hotspots,
          trajectories: analysis.trajectories,
        ));

        return analysis;
      } else {
        throw Exception('Robotics analysis failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in spatial analysis: $e');
      return RoboticsAnalysis.empty();
    }
  }

  /// Find similar shots/rounds using embeddings
  Future<List<SimilarityResult>> findSimilarData({
    required String queryText,
    required List<dynamic> dataRecords,
    int topK = 5,
  }) async {
    // Generate embedding for query
    final queryEmbedding = await generateEmbedding(queryText);
    if (queryEmbedding.isEmpty) return [];

    // Calculate similarities
    final results = <SimilarityResult>[];

    for (final record in dataRecords) {
      final recordText = _extractTextFromRecord(record);
      final recordEmbedding = await generateEmbedding(recordText);

      if (recordEmbedding.isNotEmpty) {
        final similarity = _cosineSimilarity(queryEmbedding, recordEmbedding);
        results.add(SimilarityResult(
          record: record,
          similarity: similarity,
          embedding: recordEmbedding,
        ));
      }
    }

    // Sort by similarity and return top K
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results.take(topK).toList();
  }

  /// Analyze patterns across multiple rounds/shots
  Future<PatternInsight> analyzePerformancePatterns({
    required List<RoundLogsRecord> rounds,
    required List<ShotLogsRecord> shots,
  }) async {
    // Generate embeddings for all data
    final roundEmbeddings = <String, List<double>>{};
    final shotEmbeddings = <String, List<double>>{};

    // Process rounds
    for (final round in rounds) {
      final text = _buildRoundText(round);
      final embedding = await generateEmbedding(text, taskType: 'CLUSTERING');
      roundEmbeddings[round.roundId] = embedding;
    }

    // Process shots
    for (final shot in shots) {
      final text = _buildShotText(shot);
      final embedding = await generateEmbedding(text, taskType: 'CLUSTERING');
      shotEmbeddings[shot.shotId] = embedding;
    }

    // Cluster similar patterns
    final clusters = _performClustering(roundEmbeddings, shotEmbeddings);

    // Extract insights
    final insight = PatternInsight(
      timestamp: DateTime.now(),
      clusters: clusters,
      recommendations: _generateRecommendations(clusters),
      trends: _identifyTrends(rounds, shots),
    );

    _patternController.add(insight);
    return insight;
  }

  /// Real-time marker clustering for performance
  Future<List<MarkerCluster>> clusterMarkers({
    required List<MapMarker> markers,
    required double zoomLevel,
  }) async {
    if (markers.length < 10) {
      // Don't cluster small sets
      return [MarkerCluster(markers: markers, center: markers.first.position)];
    }

    // Generate embeddings for marker data
    final markerEmbeddings = <MapMarker, List<double>>{};

    for (final marker in markers) {
      final text = '${marker.infoWindow.title} ${marker.infoWindow.snippet}';
      final embedding =
          await generateEmbedding(text, outputDimensionality: 256);
      markerEmbeddings[marker] = embedding;
    }

    // Perform spatial clustering using embeddings and positions
    return _spatialClustering(markerEmbeddings, zoomLevel);
  }

  // Helper methods

  List<double> _normalizeEmbedding(List<double> embedding) {
    final magnitude = _calculateMagnitude(embedding);
    if (magnitude == 0) return embedding;

    return embedding.map((value) => value / magnitude).toList();
  }

  double _calculateMagnitude(List<double> vector) {
    return sqrt(vector.fold(0.0, (sum, value) => sum + (value * value)));
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
    }

    return dotProduct; // Already normalized
  }

  String _buildSpatialPrompt(
      List<LatLng> positions, Map<String, dynamic> context) {
    return '''
    Analyze the following golf shot positions and provide spatial insights:
    
    Positions: ${positions.map((p) => '(${p.latitude}, ${p.longitude})').join(', ')}
    
    Context:
    - Course: ${context['courseName']}
    - Weather: ${context['weather']}
    - Player skill: ${context['playerSkill']}
    
    Provide:
    1. Spatial patterns and tendencies
    2. Hot zones (areas of high activity)
    3. Trajectory analysis
    4. Strategic recommendations based on spatial data
    
    Format response as structured JSON.
    ''';
  }

  String _extractTextFromRecord(dynamic record) {
    if (record is RoundLogsRecord) {
      return _buildRoundText(record);
    } else if (record is ShotLogsRecord) {
      return _buildShotText(record);
    } else if (record is GolfRoundsRecord) {
      return '''
      Golf round at ${record.courseName} on ${record.date}.
      Score: ${record.score} (${record.scoreToPar > 0 ? '+' : ''}${record.scoreToPar}).
      Fairways: ${record.fairwaysHit}/${record.fairwaysTotal}.
      GIR: ${record.greensInRegulation}/${record.greensTotal}.
      Putts: ${record.totalPutts}.
      Mental focus: ${record.mentalFocus}/10.
      Weather: ${record.weather.condition}.
      Notes: ${record.notes}
      ''';
    } else if (record is ScorecardRecord) {
      return '''
      Scorecard for ${record.courseName} round ${record.roundId}.
      Total score: ${record.totalScore} vs par ${record.totalPar}.
      Differential: ${record.scoreDifferential}.
      ''';
    }
    return '';
  }

  String _buildRoundText(RoundLogsRecord round) {
    return '''
    Round at ${round.courseName} (${round.courseType}) on ${round.date}.
    Mental state: Focus ${round.mindsetFocus}/10, Confidence ${round.mindsetConfidence}/10, Control ${round.mindsetControl}/10.
    Overall mindset: ${round.overallMindsetEmoji} (${round.mindsetColor}).
    Best cue: ${round.bestCue}.
    Recovery holes: ${round.recoveryHoles.join(', ')}.
    Technical: ${round.technicalSummary}.
    AI insights: ${round.aiRoundSummary}.
    Voice notes: ${round.voiceTranscription}
    ''';
  }

  String _buildShotText(ShotLogsRecord shot) {
    return '''
    Shot on hole ${shot.holeNumber} with ${shot.clubUsed}.
    Distance: ${shot.distanceAttempted}y, Shape: ${shot.shotShape}, Outcome: ${shot.shotOutcome}.
    Mental: Confidence ${shot.confidenceLevel}/10, Cue used: ${shot.cueUsed}.
    Conditions: ${shot.windCondition}.
    Trend: ${shot.shotTrend}, Pattern: ${shot.missPattern}.
    AI tip: ${shot.aiShotInsight}.
    Voice: ${shot.voiceTranscription}
    ''';
  }

  RoboticsAnalysis _parseRoboticsResponse(Map<String, dynamic> data) {
    try {
      // Null-safe access to nested properties
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint(
            'Error parsing robotics response: No candidates in response');
        return RoboticsAnalysis.empty();
      }

      final candidate = candidates[0] as Map<String, dynamic>?;
      if (candidate == null) {
        debugPrint(
            'Error parsing robotics response: Invalid candidate structure');
        return RoboticsAnalysis.empty();
      }

      final contentObj = candidate['content'] as Map<String, dynamic>?;
      if (contentObj == null) {
        debugPrint('Error parsing robotics response: No content in candidate');
        return RoboticsAnalysis.empty();
      }

      final parts = contentObj['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        debugPrint('Error parsing robotics response: No parts in content');
        return RoboticsAnalysis.empty();
      }

      final part = parts[0] as Map<String, dynamic>?;
      if (part == null) {
        debugPrint('Error parsing robotics response: Invalid part structure');
        return RoboticsAnalysis.empty();
      }

      String content = part['text'] as String? ?? '';

      if (content.isEmpty) {
        debugPrint('Error parsing robotics response: Empty content');
        return RoboticsAnalysis.empty();
      }

      // Strip markdown code blocks if present
      content = _stripMarkdownCodeBlocks(content);

      // Use safe JSON parser to handle malformed responses
      final parsed = _safeJsonParse(content);
      if (parsed == null) {
        debugPrint('Error parsing robotics response: Could not parse JSON');
        return RoboticsAnalysis.empty();
      }

      return RoboticsAnalysis(
        patterns:
            (parsed['patterns'] as List?)?.map((p) => p.toString()).toList() ??
                [],
        hotspots: (parsed['hotspots'] as List?)?.map((h) {
              final hotspot = h as Map<String, dynamic>;
              return HotSpot(
                center: LatLng(
                  (hotspot['lat'] as num?)?.toDouble() ?? 0.0,
                  (hotspot['lng'] as num?)?.toDouble() ?? 0.0,
                ),
                radius: (hotspot['radius'] as num?)?.toDouble() ?? 0.0,
                intensity: (hotspot['intensity'] as num?)?.toDouble() ?? 0.0,
                description: hotspot['description']?.toString() ?? '',
              );
            }).toList() ??
            [],
        trajectories: (parsed['trajectories'] as List?)?.map((t) {
              final trajectory = t as Map<String, dynamic>;
              return Trajectory(
                points: ((trajectory['points'] as List?) ?? []).map((p) {
                  final point = p as Map<String, dynamic>;
                  return LatLng(
                    (point['lat'] as num?)?.toDouble() ?? 0.0,
                    (point['lng'] as num?)?.toDouble() ?? 0.0,
                  );
                }).toList(),
                type: trajectory['type']?.toString() ?? '',
                confidence:
                    (trajectory['confidence'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList() ??
            [],
      );
    } catch (e) {
      debugPrint('Error parsing robotics response: $e');
      return RoboticsAnalysis.empty();
    }
  }

  Map<String, List<String>> _performClustering(
    Map<String, List<double>> roundEmbeddings,
    Map<String, List<double>> shotEmbeddings,
  ) {
    // Simple clustering based on embedding similarity
    final clusters = <String, List<String>>{};
    final threshold = 0.8; // Similarity threshold

    // Cluster rounds
    final roundIds = roundEmbeddings.keys.toList();
    for (int i = 0; i < roundIds.length; i++) {
      final clusterId = 'round_cluster_$i';
      clusters[clusterId] = [roundIds[i]];

      for (int j = i + 1; j < roundIds.length; j++) {
        final similarity = _cosineSimilarity(
          roundEmbeddings[roundIds[i]]!,
          roundEmbeddings[roundIds[j]]!,
        );

        if (similarity > threshold) {
          clusters[clusterId]!.add(roundIds[j]);
        }
      }
    }

    return clusters;
  }

  List<String> _generateRecommendations(Map<String, List<String>> clusters) {
    final recommendations = <String>[];

    for (final entry in clusters.entries) {
      if (entry.value.length > 3) {
        recommendations.add(
            'Pattern detected: ${entry.value.length} similar ${entry.key.contains('round') ? 'rounds' : 'shots'} grouped together');
      }
    }

    return recommendations;
  }

  List<Trend> _identifyTrends(
      List<RoundLogsRecord> rounds, List<ShotLogsRecord> shots) {
    final trends = <Trend>[];

    // Sort by date
    rounds.sort((a, b) => a.date!.compareTo(b.date!));

    // Analyze mindset trends
    if (rounds.length > 5) {
      final recentAvg = rounds
              .take(5)
              .map((r) =>
                  (r.mindsetFocus + r.mindsetConfidence + r.mindsetControl) /
                  3.0)
              .reduce((a, b) => a + b) /
          5;

      final overallAvg = rounds
              .map((r) =>
                  (r.mindsetFocus + r.mindsetConfidence + r.mindsetControl) /
                  3.0)
              .reduce((a, b) => a + b) /
          rounds.length;

      if (recentAvg > overallAvg) {
        trends.add(Trend(
          type: 'mindset_improvement',
          description: 'Mental game improving recently',
          confidence: (recentAvg - overallAvg) / overallAvg,
        ));
      }
    }

    return trends;
  }

  List<MarkerCluster> _spatialClustering(
    Map<MapMarker, List<double>> markerEmbeddings,
    double zoomLevel,
  ) {
    // Dynamic clustering based on zoom level
    final clusterRadius = 100 / pow(2, zoomLevel - 10); // Adjust based on zoom
    final clusters = <MarkerCluster>[];
    final processedMarkers = <MapMarker>{};

    for (final entry in markerEmbeddings.entries) {
      if (processedMarkers.contains(entry.key)) continue;

      final cluster = <MapMarker>[entry.key];
      processedMarkers.add(entry.key);

      // Find nearby markers with similar embeddings
      for (final other in markerEmbeddings.entries) {
        if (processedMarkers.contains(other.key)) continue;

        final distance = _calculateDistance(
          entry.key.position,
          other.key.position,
        );

        final similarity = _cosineSimilarity(entry.value, other.value);

        if (distance < clusterRadius && similarity > 0.7) {
          cluster.add(other.key);
          processedMarkers.add(other.key);
        }
      }

      // Calculate cluster center
      final center = _calculateCenter(cluster.map((m) => m.position).toList());
      clusters.add(MarkerCluster(markers: cluster, center: center));
    }

    return clusters;
  }

  double _calculateDistance(LatLng a, LatLng b) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371000; // meters
    final lat1Rad = a.latitude * (pi / 180);
    final lat2Rad = b.latitude * (pi / 180);
    final deltaLatRad = (b.latitude - a.latitude) * (pi / 180);
    final deltaLngRad = (b.longitude - a.longitude) * (pi / 180);

    final aValue = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final c = 2 * atan2(sqrt(aValue), sqrt(1 - aValue));

    return earthRadius * c;
  }

  LatLng _calculateCenter(List<LatLng> positions) {
    double totalLat = 0;
    double totalLng = 0;

    for (final pos in positions) {
      totalLat += pos.latitude;
      totalLng += pos.longitude;
    }

    return LatLng(
      totalLat / positions.length,
      totalLng / positions.length,
    );
  }

  /// Generate real-time guidance based on user's last activity and current map context
  /// Uses Robotics-ER 1.5 for spatial reasoning and embeddings for context similarity
  Future<RealtimeGuidance> generateRealtimeGuidance({
    required List<RoundLogsRecord> recentRounds,
    required List<ShotLogsRecord> recentShots,
    required LatLng? currentPosition,
    required Map<String, dynamic> mapContext,
  }) async {
    final apiKey = await _apiKey;
    if (apiKey.isEmpty) {
      // Silently skip guidance generation if API key is not configured
      return RealtimeGuidance.empty();
    }

    try {
      // Build context from last activity using embeddings
      final lastActivityContext = await _buildLastActivityContext(
        recentRounds: recentRounds,
        recentShots: recentShots,
      );

      // Build spatial prompt for Robotics-ER 1.5
      final guidancePrompt = _buildGuidancePrompt(
        lastActivityContext: lastActivityContext,
        currentPosition: currentPosition,
        mapContext: mapContext,
        recentRounds: recentRounds,
        recentShots: recentShots,
      );

      // Call Robotics-ER 1.5 for spatial reasoning and guidance
      final response = await http.post(
        Uri.parse('$_baseUrl/$_roboticsModel:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': guidancePrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1024,
            'thinkingConfig': {
              'thinkingBudget': 1000, // Use thinking for better reasoning
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final guidance = _parseGuidanceResponse(data, lastActivityContext);

        // Emit guidance
        _guidanceController.add(guidance);

        return guidance;
      } else {
        throw Exception('Guidance generation failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating real-time guidance: $e');
      return RealtimeGuidance.empty();
    }
  }

  /// Build context from last activity using embeddings for similarity
  Future<String> _buildLastActivityContext({
    required List<RoundLogsRecord> recentRounds,
    required List<ShotLogsRecord> recentShots,
  }) async {
    if (recentRounds.isEmpty && recentShots.isEmpty) {
      return 'No recent activity data available.';
    }

    final contextParts = <String>[];

    // Analyze last round (embeddings used for similarity in other methods)
    if (recentRounds.isNotEmpty) {
      final lastRound = recentRounds.first;

      contextParts.add('Last Round Analysis:');
      contextParts.add('- Course: ${lastRound.courseName}');
      contextParts.add('- Date: ${lastRound.date}');
      contextParts.add(
          '- Mental State: Focus ${lastRound.mindsetFocus}/10, Confidence ${lastRound.mindsetConfidence}/10, Control ${lastRound.mindsetControl}/10');
      contextParts.add('- Overall Mindset: ${lastRound.overallMindsetEmoji}');
      contextParts.add('- Best Cue: ${lastRound.bestCue}');

      if (lastRound.aiRoundSummary.isNotEmpty) {
        contextParts.add('- AI Insights: ${lastRound.aiRoundSummary}');
      }
    }

    // Analyze recent shots (embeddings used for similarity in other methods)
    if (recentShots.isNotEmpty) {
      contextParts.add('\nRecent Shots Pattern:');
      final clubsUsed = recentShots.map((s) => s.clubUsed).toSet().toList();
      final outcomes = recentShots.map((s) => s.shotOutcome).toList();
      contextParts.add('- Clubs Used: ${clubsUsed.join(", ")}');
      contextParts.add('- Common Outcomes: ${outcomes.join(", ")}');

      // Find patterns
      if (recentShots.length > 3) {
        final avgConfidence =
            recentShots.map((s) => s.confidenceLevel).reduce((a, b) => a + b) /
                recentShots.length;
        contextParts.add(
            '- Average Confidence: ${avgConfidence.toStringAsFixed(1)}/10');
      }
    }

    return contextParts.join('\n');
  }

  /// Build guidance prompt for Robotics-ER 1.5
  String _buildGuidancePrompt({
    required String lastActivityContext,
    required LatLng? currentPosition,
    required Map<String, dynamic> mapContext,
    required List<RoundLogsRecord> recentRounds,
    required List<ShotLogsRecord> recentShots,
  }) {
    return '''
You are FoCoCo's AI golf mental performance coach analyzing a golfer's activity on the map.

**Last Activity Context:**
$lastActivityContext

**Current Map Context:**
- Current Position: ${currentPosition != null ? 'Lat ${currentPosition.latitude}, Lng ${currentPosition.longitude}' : 'Unknown'}
- Total Rounds on Map: ${recentRounds.length}
- Total Shots on Map: ${recentShots.length}
- Map Context: ${mapContext.toString()}

**Your Task:**
Based on the golfer's last activity and spatial patterns on the map, provide:

1. **Immediate Guidance** (2-3 sentences): What should they focus on right now based on their recent performance?

2. **Spatial Insights** (if applicable): Are there patterns in where they play best/worst? Any location-specific recommendations?

3. **Mental Game Focus**: Based on their mindset scores, what mental skill needs the most attention?

4. **Actionable Recommendation**: One specific, actionable tip they can apply in their next round or practice session.

**Response Format (JSON):**
{
  "immediateGuidance": "Your immediate guidance here",
  "spatialInsight": "Spatial pattern or location insight",
  "mentalFocus": "What mental skill to focus on",
  "actionableTip": "One specific actionable tip",
  "confidence": 0.0-1.0
}

Be specific, encouraging, and golf-focused. Reference their actual data when possible.
''';
  }

  /// Parse guidance response from Robotics-ER 1.5
  RealtimeGuidance _parseGuidanceResponse(
      Map<String, dynamic> data, String context) {
    try {
      // Null-safe access to nested properties
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint(
            'Error parsing guidance response: No candidates in response');
        return RealtimeGuidance.empty();
      }

      final candidate = candidates[0] as Map<String, dynamic>?;
      if (candidate == null) {
        debugPrint(
            'Error parsing guidance response: Invalid candidate structure');
        return RealtimeGuidance.empty();
      }

      final contentObj = candidate['content'] as Map<String, dynamic>?;
      if (contentObj == null) {
        debugPrint('Error parsing guidance response: No content in candidate');
        return RealtimeGuidance.empty();
      }

      final parts = contentObj['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        debugPrint('Error parsing guidance response: No parts in content');
        return RealtimeGuidance.empty();
      }

      final part = parts[0] as Map<String, dynamic>?;
      if (part == null) {
        debugPrint('Error parsing guidance response: Invalid part structure');
        return RealtimeGuidance.empty();
      }

      String content = part['text'] as String? ?? '';

      if (content.isEmpty) {
        debugPrint('Error parsing guidance response: Empty content');
        return RealtimeGuidance.empty();
      }

      // Strip markdown code blocks if present
      content = _stripMarkdownCodeBlocks(content);

      // Try to parse as JSON using safe parser
      final parsed = _safeJsonParse(content);
      if (parsed != null) {
        return RealtimeGuidance(
          timestamp: DateTime.now(),
          immediateGuidance: parsed['immediateGuidance']?.toString() ?? '',
          spatialInsight: parsed['spatialInsight']?.toString() ?? '',
          mentalFocus: parsed['mentalFocus']?.toString() ?? '',
          actionableTip: parsed['actionableTip']?.toString() ?? '',
          confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.8,
          context: context,
        );
      } else {
        // If not JSON, treat as plain text guidance
        return RealtimeGuidance(
          timestamp: DateTime.now(),
          immediateGuidance:
              content.length > 500 ? content.substring(0, 500) : content,
          spatialInsight: '',
          mentalFocus: '',
          actionableTip: '',
          confidence: 0.6,
          context: context,
        );
      }
    } catch (e) {
      debugPrint('Error parsing guidance response: $e');
      return RealtimeGuidance.empty();
    }
  }

  /// Strip markdown code blocks from text and sanitize for JSON parsing
  String _stripMarkdownCodeBlocks(String text) {
    if (text.isEmpty) return text;

    // Remove ```json, ```JSON, ``` markers (case insensitive)
    text = text.replaceAll(RegExp(r'```json\s*', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'```\s*'), '');

    // Remove leading/trailing whitespace
    text = text.trim();

    // Try to extract JSON object if text contains other content
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      text = jsonMatch.group(0) ?? text;
    }

    return text;
  }

  /// Safely extract JSON from potentially malformed response
  Map<String, dynamic>? _safeJsonParse(String content) {
    if (content.isEmpty) return null;

    try {
      // First try direct parsing
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      // Try to fix common JSON issues

      // Fix unterminated strings by finding the last complete JSON structure
      String fixedContent = content;

      // Try to find a valid JSON object
      int braceCount = 0;
      int lastValidEnd = -1;

      for (int i = 0; i < content.length; i++) {
        if (content[i] == '{') braceCount++;
        if (content[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            lastValidEnd = i;
          }
        }
      }

      if (lastValidEnd > 0) {
        fixedContent = content.substring(0, lastValidEnd + 1);
        try {
          return jsonDecode(fixedContent) as Map<String, dynamic>;
        } catch (_) {
          // Still failed, try more aggressive fixing
        }
      }

      // Try removing problematic trailing content
      final lines = content.split('\n');
      for (int i = lines.length; i > 0; i--) {
        final truncated = lines.take(i).join('\n');
        // Ensure we have balanced braces
        final openBraces = truncated.split('{').length - 1;
        final closeBraces = truncated.split('}').length - 1;

        if (openBraces > closeBraces) {
          // Add missing closing braces
          final fixed = truncated + ('}' * (openBraces - closeBraces));
          try {
            return jsonDecode(fixed) as Map<String, dynamic>;
          } catch (_) {
            continue;
          }
        }
      }

      debugPrint('⚠️ Could not parse JSON even after fixing attempts');
      return null;
    }
  }

  void dispose() {
    _spatialAnalysisController.close();
    _patternController.close();
    _guidanceController.close();
    _embeddingCache.clear();
  }
}

// Data models

class SpatialAnalysis {
  final DateTime timestamp;
  final List<String> patterns;
  final List<HotSpot> hotspots;
  final List<Trajectory> trajectories;

  SpatialAnalysis({
    required this.timestamp,
    required this.patterns,
    required this.hotspots,
    required this.trajectories,
  });
}

class PatternInsight {
  final DateTime timestamp;
  final Map<String, List<String>> clusters;
  final List<String> recommendations;
  final List<Trend> trends;

  PatternInsight({
    required this.timestamp,
    required this.clusters,
    required this.recommendations,
    required this.trends,
  });
}

class RoboticsAnalysis {
  final List<String> patterns;
  final List<HotSpot> hotspots;
  final List<Trajectory> trajectories;

  RoboticsAnalysis({
    required this.patterns,
    required this.hotspots,
    required this.trajectories,
  });

  factory RoboticsAnalysis.empty() => RoboticsAnalysis(
        patterns: [],
        hotspots: [],
        trajectories: [],
      );
}

class HotSpot {
  final LatLng center;
  final double radius;
  final double intensity;
  final String description;

  HotSpot({
    required this.center,
    required this.radius,
    required this.intensity,
    required this.description,
  });
}

class Trajectory {
  final List<LatLng> points;
  final String type;
  final double confidence;

  Trajectory({
    required this.points,
    required this.type,
    required this.confidence,
  });
}

class SimilarityResult {
  final dynamic record;
  final double similarity;
  final List<double> embedding;

  SimilarityResult({
    required this.record,
    required this.similarity,
    required this.embedding,
  });
}

class Trend {
  final String type;
  final String description;
  final double confidence;

  Trend({
    required this.type,
    required this.description,
    required this.confidence,
  });
}

class MarkerCluster {
  final List<MapMarker> markers;
  final LatLng center;

  MarkerCluster({
    required this.markers,
    required this.center,
  });
}

class RealtimeGuidance {
  final DateTime timestamp;
  final String immediateGuidance;
  final String spatialInsight;
  final String mentalFocus;
  final String actionableTip;
  final double confidence;
  final String context;

  RealtimeGuidance({
    required this.timestamp,
    required this.immediateGuidance,
    required this.spatialInsight,
    required this.mentalFocus,
    required this.actionableTip,
    required this.confidence,
    required this.context,
  });

  factory RealtimeGuidance.empty() => RealtimeGuidance(
        timestamp: DateTime.now(),
        immediateGuidance: '',
        spatialInsight: '',
        mentalFocus: '',
        actionableTip: '',
        confidence: 0.0,
        context: '',
      );

  bool get isEmpty => immediateGuidance.isEmpty && actionableTip.isEmpty;
}
