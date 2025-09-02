import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/backend/schema/round_logs_record.dart';
import '/backend/schema/shot_logs_record.dart';
import '/auth/firebase_auth/auth_util.dart';

class FoCoMapTestDataGenerator {
  static final Random _random = Random();
  
  // Golf courses with realistic coordinates
  static final List<Map<String, dynamic>> _golfCourses = [
    {
      'name': 'Pebble Beach Golf Links',
      'type': 'championship',
      'coordinates': LatLng(36.5668, -121.9495),
      'holes': 18,
    },
    {
      'name': 'Augusta National Golf Club',
      'type': 'championship',
      'coordinates': LatLng(33.5031, -82.0228),
      'holes': 18,
    },
    {
      'name': 'St Andrews Old Course',
      'type': 'links',
      'coordinates': LatLng(56.3435, -2.8027),
      'holes': 18,
    },
    {
      'name': 'Pinehurst No. 2',
      'type': 'championship',
      'coordinates': LatLng(35.1954, -79.4697),
      'holes': 18,
    },
    {
      'name': 'Cypress Point Club',
      'type': 'championship',
      'coordinates': LatLng(36.5797, -121.9638),
      'holes': 18,
    },
    {
      'name': 'Royal Melbourne Golf Club',
      'type': 'championship',
      'coordinates': LatLng(-37.9731, 145.0359),
      'holes': 18,
    },
    {
      'name': 'Oakmont Country Club',
      'type': 'championship',
      'coordinates': LatLng(40.5254, -79.8259),
      'holes': 18,
    },
    {
      'name': 'TPC Sawgrass',
      'type': 'championship',
      'coordinates': LatLng(30.1975, -81.3950),
      'holes': 18,
    },
  ];

  // Mental state variations
  static final List<Map<String, dynamic>> _mentalStates = [
    {
      'focus': 9,
      'confidence': 8,
      'control': 9,
      'emoji': '😊',
      'color': 'green',
      'cues': ['Deep breathing', 'Smooth tempo', 'Trust the process'],
    },
    {
      'focus': 7,
      'confidence': 6,
      'control': 7,
      'emoji': '🙂',
      'color': 'yellow',
      'cues': ['Stay present', 'One shot at a time', 'Commit to the target'],
    },
    {
      'focus': 5,
      'confidence': 4,
      'control': 5,
      'emoji': '😟',
      'color': 'red',
      'cues': ['Reset routine', 'Back to basics', 'Find your rhythm'],
    },
    {
      'focus': 8,
      'confidence': 9,
      'control': 8,
      'emoji': '🤩',
      'color': 'green',
      'cues': ['Feel the flow', 'Trust your swing', 'Visualize success'],
    },
  ];

  // Club data with realistic distances
  static final Map<String, Map<String, dynamic>> _clubData = {
    'Driver': {'avgDistance': 285, 'icon': '🏌️', 'variability': 20},
    '3 Wood': {'avgDistance': 245, 'icon': '🏌️', 'variability': 15},
    '5 Wood': {'avgDistance': 225, 'icon': '🏌️', 'variability': 15},
    '3 Iron': {'avgDistance': 210, 'icon': '⛳', 'variability': 12},
    '4 Iron': {'avgDistance': 195, 'icon': '⛳', 'variability': 10},
    '5 Iron': {'avgDistance': 180, 'icon': '⛳', 'variability': 10},
    '6 Iron': {'avgDistance': 165, 'icon': '⛳', 'variability': 8},
    '7 Iron': {'avgDistance': 150, 'icon': '⛳', 'variability': 8},
    '8 Iron': {'avgDistance': 135, 'icon': '⛳', 'variability': 6},
    '9 Iron': {'avgDistance': 120, 'icon': '⛳', 'variability': 6},
    'PW': {'avgDistance': 105, 'icon': '⛳', 'variability': 5},
    'SW': {'avgDistance': 85, 'icon': '⛳', 'variability': 5},
    'LW': {'avgDistance': 65, 'icon': '⛳', 'variability': 4},
    'Putter': {'avgDistance': 0, 'icon': '🏌️', 'variability': 0},
  };

  // Shot outcomes with realistic probabilities based on mental state
  static final Map<String, List<String>> _shotOutcomes = {
    'green': ['fairway', 'green', 'fairway', 'green', 'fairway', 'rough', 'bunker'],
    'yellow': ['fairway', 'rough', 'fairway', 'rough', 'bunker', 'green', 'water'],
    'red': ['rough', 'bunker', 'rough', 'water', 'ob', 'fairway', 'trees'],
  };

  // Shot shapes
  static final List<String> _shotShapes = ['straight', 'draw', 'fade', 'push', 'pull', 'hook', 'slice'];

  // Wind conditions
  static final List<String> _windConditions = [
    'calm',
    'light breeze',
    'moderate wind',
    'strong headwind',
    'strong tailwind',
    'crosswind left',
    'crosswind right',
  ];

  // Voice transcriptions for different scenarios
  static final Map<String, List<String>> _voiceTranscriptions = {
    'mental_positive': [
      'Feeling really confident today, my breathing routine is working perfectly',
      'Great focus on the front nine, staying committed to my process',
      'Recovered well after that tough hole, used my reset routine',
      'Mental game is strong today, trusting every shot',
    ],
    'mental_negative': [
      'Lost focus after that bad shot on 5, need to reset',
      'Struggling with confidence on these greens',
      'Getting frustrated, need to get back to my breathing',
      'Mind is wandering, having trouble staying present',
    ],
    'technical_positive': [
      'Perfect drive on 10, crushed it 290 down the middle',
      '7 iron from 155, stuck it to 6 feet',
      'Great recovery shot from the trees with my 6 iron',
      'Nailed my approach shot, exactly the distance I wanted',
    ],
    'technical_negative': [
      'Pushed my driver right into the rough again',
      'Came up short with my 8 iron, misjudged the wind',
      'Pulled my wedge left of the green',
      'Third time today I\'ve missed right with my driver',
    ],
    'mixed': [
      'Driver on 5 went right because I got quick, lost my tempo',
      'Used my breathing cue before this iron shot and striped it',
      'When I trust my routine, my driver stays in play',
      'Confidence dropped after that water ball, affecting my iron play',
    ],
  };

  // AI insights based on patterns
  static final List<String> _aiInsights = [
    'Your best shots come when using the breathing cue - 85% success rate',
    'Driver accuracy improves 40% when confidence is above 7',
    'Recovery shots are strongest after using reset routine',
    'Wind adjustment needs work - consistently coming up short in headwinds',
    'Mental scores above 21 correlate with 73% fairways hit',
    'Your putting confidence directly impacts approach shot accuracy',
    'Best performance comes after pre-shot visualization routine',
    'Fatigue affects your back nine focus - consider energy management',
  ];

  /// Generate comprehensive test data for all FoCoMap features
  static Future<Map<String, dynamic>> generateCompleteTestData({
    required String userId,
    int roundCount = 10,
    int shotsPerRound = 50,
    bool includeLiveRound = true,
  }) async {
    final results = {
      'roundsGenerated': 0,
      'shotsGenerated': 0,
      'errors': <String>[],
    };

    try {
      // Generate historical rounds
      for (int i = 0; i < roundCount; i++) {
        final roundResult = await generateTestRound(
          userId: userId,
          daysAgo: i * 3 + 1,
          isLive: false,
          shotCount: shotsPerRound,
        );
        
        if (roundResult['success']) {
          results['roundsGenerated']++;
          results['shotsGenerated'] += roundResult['shotsGenerated'];
        } else {
          results['errors'].add(roundResult['error'] ?? 'Unknown error');
        }
      }

      // Generate a live round if requested
      if (includeLiveRound) {
        final liveResult = await generateTestRound(
          userId: userId,
          daysAgo: 0,
          isLive: true,
          shotCount: 9, // Partial round
        );
        
        if (liveResult['success']) {
          results['roundsGenerated']++;
          results['shotsGenerated'] += liveResult['shotsGenerated'];
          results['liveRoundId'] = liveResult['roundId'];
        }
      }

      results['success'] = true;
    } catch (e) {
      results['success'] = false;
      results['errors'].add(e.toString());
    }

    return results;
  }

  /// Generate a single test round with associated shots
  static Future<Map<String, dynamic>> generateTestRound({
    required String userId,
    int daysAgo = 0,
    bool isLive = false,
    int shotCount = 50,
  }) async {
    final result = {
      'success': false,
      'roundId': '',
      'shotsGenerated': 0,
    };

    try {
      final course = _golfCourses[_random.nextInt(_golfCourses.length)];
      final mentalState = _mentalStates[_random.nextInt(_mentalStates.length)];
      final roundId = 'round_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
      final date = DateTime.now().subtract(Duration(days: daysAgo));

      // Generate round coordinates with slight offset from course center
      final roundLat = course['coordinates'].latitude + (_random.nextDouble() - 0.5) * 0.01;
      final roundLng = course['coordinates'].longitude + (_random.nextDouble() - 0.5) * 0.01;

      // Create RoundLog
      final roundData = {
        'userId': userId,
        'roundId': roundId,
        'date': date,
        'courseName': course['name'],
        'courseType': course['type'],
        'coordinates': LatLng(roundLat, roundLng),
        'mindsetFocus': mentalState['focus'],
        'mindsetConfidence': mentalState['confidence'],
        'mindsetControl': mentalState['control'],
        'bestCue': mentalState['cues'][_random.nextInt(mentalState['cues'].length)],
        'recoveryHoles': _generateRecoveryHoles(),
        'overallMindsetEmoji': mentalState['emoji'],
        'technicalSummary': _generateTechnicalSummary(),
        'aiRoundSummary': _aiInsights[_random.nextInt(_aiInsights.length)],
        'voiceTranscription': _generateRoundVoiceTranscription(mentalState['color']),
        'nlpProcessed': true,
        'isLive': isLive,
        'mindsetColor': mentalState['color'],
        'linkedGolfRoundId': '',
        'createdTime': date,
        'updatedTime': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('round_logs')
          .doc(roundId)
          .set(roundData);

      result['roundId'] = roundId;

      // Generate shots for this round
      final holesPlayed = isLive ? _random.nextInt(9) + 1 : 18;
      final shotsToGenerate = min(shotCount, holesPlayed * 4);

      for (int i = 0; i < shotsToGenerate; i++) {
        final shotResult = await generateTestShot(
          userId: userId,
          roundId: roundId,
          courseCoordinates: course['coordinates'],
          mentalColor: mentalState['color'],
          holeNumber: (i ~/ 4) + 1,
          timestamp: date.add(Duration(minutes: i * 5)),
        );

        if (shotResult['success']) {
          result['shotsGenerated']++;
        }
      }

      result['success'] = true;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Generate a single test shot
  static Future<Map<String, dynamic>> generateTestShot({
    required String userId,
    required String roundId,
    required LatLng courseCoordinates,
    required String mentalColor,
    required int holeNumber,
    required DateTime timestamp,
  }) async {
    final result = {'success': false, 'shotId': ''};

    try {
      final club = _clubData.keys.toList()[_random.nextInt(_clubData.length)];
      final clubInfo = _clubData[club]!;
      final shotId = 'shot_${timestamp.millisecondsSinceEpoch}_${_random.nextInt(1000)}';

      // Generate shot coordinates near the course
      final shotLat = courseCoordinates.latitude + (_random.nextDouble() - 0.5) * 0.005;
      final shotLng = courseCoordinates.longitude + (_random.nextDouble() - 0.5) * 0.005;

      // Determine shot outcome based on mental state
      final outcomes = _shotOutcomes[mentalColor]!;
      final outcome = outcomes[_random.nextInt(outcomes.length)];

      // Calculate distance with variability
      final baseDistance = clubInfo['avgDistance'] as int;
      final variability = clubInfo['variability'] as int;
      final distance = baseDistance + _random.nextInt(variability * 2) - variability;

      final shotData = {
        'userId': userId,
        'roundId': roundId,
        'shotId': shotId,
        'holeNumber': holeNumber,
        'clubUsed': club,
        'distanceAttempted': distance.toDouble(),
        'shotShape': _shotShapes[_random.nextInt(_shotShapes.length)],
        'shotOutcome': outcome,
        'cueUsed': _generateShotCue(mentalColor),
        'confidenceLevel': _generateConfidenceLevel(mentalColor),
        'windCondition': _windConditions[_random.nextInt(_windConditions.length)],
        'coordinates': LatLng(shotLat, shotLng),
        'aiShotInsight': _generateShotInsight(club, outcome),
        'voiceTranscription': _generateShotVoiceTranscription(club, outcome, mentalColor),
        'nlpProcessed': true,
        'shotTrend': _generateShotTrend(outcome),
        'missPattern': _generateMissPattern(outcome),
        'performanceRating': _generatePerformanceRating(outcome),
        'clubIcon': clubInfo['icon'],
        'timestamp': timestamp,
        'createdTime': timestamp,
        'updatedTime': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('shot_logs')
          .doc(shotId)
          .set(shotData);

      result['shotId'] = shotId;
      result['success'] = true;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  // Helper methods for generating realistic data
  static List<String> _generateRecoveryHoles() {
    final holes = <String>[];
    final recoveryCount = _random.nextInt(3) + 1;
    for (int i = 0; i < recoveryCount; i++) {
      holes.add((_random.nextInt(18) + 1).toString());
    }
    return holes..sort();
  }

  static String _generateTechnicalSummary() {
    final summaries = [
      'Strong driving, struggled with short irons',
      'Excellent iron play, putting needs work',
      'Consistent ball striking throughout',
      'Wind management was challenging today',
      'Best wedge play of the season',
      'Driver accuracy improved significantly',
    ];
    return summaries[_random.nextInt(summaries.length)];
  }

  static String _generateRoundVoiceTranscription(String mentalColor) {
    final category = mentalColor == 'green' ? 'mental_positive' : 
                     mentalColor == 'red' ? 'mental_negative' : 'mixed';
    final transcriptions = _voiceTranscriptions[category]!;
    return transcriptions[_random.nextInt(transcriptions.length)];
  }

  static String _generateShotCue(String mentalColor) {
    final cues = {
      'green': ['Smooth tempo', 'Trust the target', 'Commit fully'],
      'yellow': ['Stay balanced', 'Focus on contact', 'One thought'],
      'red': ['Back to basics', 'Simple swing', 'Just make contact'],
    };
    final colorCues = cues[mentalColor]!;
    return colorCues[_random.nextInt(colorCues.length)];
  }

  static int _generateConfidenceLevel(String mentalColor) {
    switch (mentalColor) {
      case 'green':
        return 7 + _random.nextInt(3); // 7-9
      case 'yellow':
        return 5 + _random.nextInt(3); // 5-7
      case 'red':
        return 3 + _random.nextInt(3); // 3-5
      default:
        return 5;
    }
  }

  static String _generateShotInsight(String club, String outcome) {
    final insights = [
      'Great $club shot when you trust your swing',
      'Consider club up in this wind condition',
      'Your $club is most accurate with smooth tempo',
      'This miss pattern suggests alignment check needed',
      'Excellent distance control with $club today',
    ];
    return insights[_random.nextInt(insights.length)];
  }

  static String _generateShotVoiceTranscription(String club, String outcome, String mentalColor) {
    final category = outcome == 'fairway' || outcome == 'green' ? 'technical_positive' :
                     outcome == 'water' || outcome == 'ob' ? 'technical_negative' : 'mixed';
    final transcriptions = _voiceTranscriptions[category]!;
    return transcriptions[_random.nextInt(transcriptions.length)];
  }

  static String _generateShotTrend(String outcome) {
    if (outcome == 'fairway' || outcome == 'green') return 'improving';
    if (outcome == 'water' || outcome == 'ob') return 'declining';
    return 'stable';
  }

  static String _generateMissPattern(String outcome) {
    final patterns = {
      'rough': ['right', 'left', 'long', 'short'],
      'bunker': ['short-right', 'short-left', 'greenside'],
      'water': ['pull-hook', 'push-slice', 'thin'],
      'trees': ['right', 'left'],
      'fairway': ['none'],
      'green': ['none'],
      'ob': ['slice', 'hook'],
    };
    final outcomePatterns = patterns[outcome] ?? ['unknown'];
    return outcomePatterns[_random.nextInt(outcomePatterns.length)];
  }

  static int _generatePerformanceRating(String outcome) {
    final ratings = {
      'green': 9,
      'fairway': 8,
      'rough': 5,
      'bunker': 4,
      'water': 2,
      'trees': 3,
      'ob': 1,
    };
    return ratings[outcome] ?? 5;
  }

  /// Clear all test data for a user
  static Future<void> clearTestData(String userId) async {
    // Delete round logs
    final roundsQuery = await FirebaseFirestore.instance
        .collection('round_logs')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in roundsQuery.docs) {
      await doc.reference.delete();
    }

    // Delete shot logs
    final shotsQuery = await FirebaseFirestore.instance
        .collection('shot_logs')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in shotsQuery.docs) {
      await doc.reference.delete();
    }
  }
}