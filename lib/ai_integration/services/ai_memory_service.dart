import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/structs/index.dart';
import '/auth/firebase_auth/auth_util.dart';

/// AI Memory Service for FoCoCo
/// Manages user conversation history, insights, and patterns for enhanced AI reasoning
/// Implements NLP analysis and context building based on concept.md and ai_concept.md
class AIMemoryService {
  static final AIMemoryService _instance = AIMemoryService._internal();
  factory AIMemoryService() => _instance;
  AIMemoryService._internal();

  // Firestore collections
  static const String _aiMemoryCollection = 'ai_memory';

  // Memory management
  final Map<String, AiMemoryStruct> _memoryCache = {};
  String? _currentSessionId;
  Timer? _saveTimer;

  // Stream controllers
  final StreamController<AiMemoryStruct> _memoryUpdateController =
      StreamController<AiMemoryStruct>.broadcast();

  // Getters
  Stream<AiMemoryStruct> get memoryUpdates => _memoryUpdateController.stream;
  String? get currentSessionId => _currentSessionId;

  /// Initialize AI Memory Service
  Future<void> initialize() async {
    try {
      await _loadUserMemory();
      _startNewSession();

      if (kDebugMode) {
        print('🧠 AI Memory Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing AI Memory Service: $e');
      }
    }
  }

  /// Start a new conversation session
  void _startNewSession() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    if (kDebugMode) {
      print('🆕 Started new AI session: $_currentSessionId');
    }
  }

  /// Load user memory from Firestore with enhanced error handling
  Future<void> _loadUserMemory() async {
    if (currentUserUid.isEmpty) {
      if (kDebugMode) {
        print('⚠️ No authenticated user - creating temporary memory');
      }
      _memoryCache['temp'] = _createNewMemory();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection(_aiMemoryCollection)
          .doc(currentUserUid)
          .get();

      if (doc.exists && doc.data() != null) {
        final memory = AiMemoryStruct.fromMap(doc.data()!);
        _memoryCache[currentUserUid] = memory;

        if (kDebugMode) {
          print(
              '📖 Loaded user memory: ${memory.totalInteractions} interactions');
        }
      } else {
        // Create new memory structure
        final newMemory = _createNewMemory();
        _memoryCache[currentUserUid] = newMemory;

        // Try to save initial memory structure
        try {
          await FirebaseFirestore.instance
              .collection(_aiMemoryCollection)
              .doc(currentUserUid)
              .set(newMemory.toMap());

          if (kDebugMode) {
            print('✅ Created new user memory in Firestore');
          }
        } catch (saveError) {
          if (kDebugMode) {
            print('⚠️ Could not save initial memory to Firestore: $saveError');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading user memory: $e');
      }

      // Create local memory as fallback
      _memoryCache[currentUserUid] = _createNewMemory();

      // Check if it's a permission error and provide helpful message
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print('🔒 Firestore permission denied - using local memory only');
          print('💡 AI will still work but won\'t remember across sessions');
        }
      }
    }
  }

  /// Create new memory structure for user
  AiMemoryStruct _createNewMemory() {
    return AiMemoryStruct(
      sessionId: _currentSessionId ?? '',
      conversationHistory: [],
      userInsights: {
        'communicationStyle': 'unknown',
        'primaryConcerns': [],
        'learningPreference': 'mixed',
        'motivationLevel': 'medium',
        'experienceLevel': 'intermediate',
      },
      golfPatterns: {
        'commonChallenges': [],
        'strengthAreas': [],
        'preferredTopics': [],
        'courseDifficulties': [],
        'mentalGameFocus': [],
      },
      mentalPatterns: {
        'stressResponses': [],
        'confidencePatterns': [],
        'focusIssues': [],
        'emotionalTriggers': [],
        'copingStrategies': [],
      },
      keyTopics: [],
      lastUpdated: DateTime.now(),
      totalInteractions: 0,
      engagementScore: 0.0,
      personalityTraits: {
        'openness': 0.5,
        'conscientiousness': 0.5,
        'extraversion': 0.5,
        'agreeableness': 0.5,
        'neuroticism': 0.5,
      },
    );
  }

  /// Add conversation turn and analyze for insights
  Future<void> addConversationTurn({
    required String userMessage,
    required String aiResponse,
    String messageType = 'text',
  }) async {
    if (currentUserUid.isEmpty || _currentSessionId == null) return;

    try {
      // Create conversation turn
      final turn = ConversationTurnStruct(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userMessage: userMessage,
        aiResponse: aiResponse,
        timestamp: DateTime.now(),
        messageType: messageType,
        sentiment: await _analyzeSentiment(userMessage),
        extractedTopics: _extractTopics(userMessage),
        confidenceScore: 0.8, // Default confidence
      );

      // Get or create memory
      final memory = _memoryCache[currentUserUid] ?? _createNewMemory();

      // Add turn to history (keep last 20 turns)
      memory.conversationHistory.add(turn);
      if (memory.conversationHistory.length > 20) {
        memory.conversationHistory.removeAt(0);
      }

      // Update insights based on new conversation
      await _updateInsights(memory, turn);

      // Update memory
      memory.lastUpdated = DateTime.now();
      memory.totalInteractions = memory.totalInteractions + 1;
      memory.sessionId = _currentSessionId!;

      // Cache and save
      _memoryCache[currentUserUid] = memory;
      _scheduleSave();

      // Notify listeners
      _memoryUpdateController.add(memory);

      if (kDebugMode) {
        print('💬 Added conversation turn: ${turn.extractedTopics}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding conversation turn: $e');
      }
    }
  }

  /// Analyze sentiment of user message
  Future<Map<String, dynamic>> _analyzeSentiment(String message) async {
    // Simple sentiment analysis - in production, use more sophisticated NLP
    final lowerMessage = message.toLowerCase();

    double positivity = 0.5;
    double confidence = 0.5;
    double frustration = 0.0;

    // Positive indicators
    final positiveWords = [
      'good',
      'great',
      'excellent',
      'confident',
      'ready',
      'excited',
      'better',
      'improved'
    ];
    final negativeWords = [
      'bad',
      'terrible',
      'frustrated',
      'angry',
      'nervous',
      'worried',
      'scared',
      'difficult'
    ];
    final confidenceWords = [
      'confident',
      'ready',
      'prepared',
      'strong',
      'focused'
    ];
    final frustrationWords = ['frustrated', 'angry', 'annoyed', 'upset', 'mad'];

    for (final word in positiveWords) {
      if (lowerMessage.contains(word)) positivity += 0.1;
    }

    for (final word in negativeWords) {
      if (lowerMessage.contains(word)) positivity -= 0.1;
    }

    for (final word in confidenceWords) {
      if (lowerMessage.contains(word)) confidence += 0.1;
    }

    for (final word in frustrationWords) {
      if (lowerMessage.contains(word)) frustration += 0.2;
    }

    // Clamp values
    positivity = positivity.clamp(0.0, 1.0);
    confidence = confidence.clamp(0.0, 1.0);
    frustration = frustration.clamp(0.0, 1.0);

    return {
      'positivity': positivity,
      'confidence': confidence,
      'frustration': frustration,
      'energy': _calculateEnergyLevel(message),
      'clarity': _calculateClarityLevel(message),
    };
  }

  /// Extract topics from user message
  List<String> _extractTopics(String message) {
    final lowerMessage = message.toLowerCase();
    final topics = <String>[];

    // Golf-specific topics
    final golfTopics = {
      'putting': ['putt', 'putting', 'green', 'read'],
      'driving': ['drive', 'driving', 'tee', 'distance'],
      'iron_play': ['iron', 'approach', 'accuracy', 'target'],
      'short_game': ['chip', 'pitch', 'wedge', 'around'],
      'mental_game': ['mental', 'mind', 'focus', 'confidence', 'pressure'],
      'course_management': ['strategy', 'course', 'management', 'decision'],
      'practice': ['practice', 'training', 'drill', 'exercise'],
      'competition': ['tournament', 'competition', 'match', 'round'],
      'equipment': ['club', 'equipment', 'gear', 'ball'],
      'fitness': ['fitness', 'strength', 'flexibility', 'exercise'],
    };

    for (final entry in golfTopics.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          topics.add(entry.key);
          break;
        }
      }
    }

    // Mental performance topics
    final mentalTopics = {
      'anxiety': ['nervous', 'anxiety', 'worried', 'scared'],
      'confidence': ['confidence', 'belief', 'trust', 'doubt'],
      'focus': ['focus', 'concentration', 'distracted', 'attention'],
      'pressure': ['pressure', 'stress', 'tension', 'clutch'],
      'routine': ['routine', 'preparation', 'process', 'ritual'],
      'visualization': ['visualize', 'imagine', 'picture', 'see'],
      'breathing': ['breath', 'breathing', 'calm', 'relax'],
    };

    for (final entry in mentalTopics.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          topics.add(entry.key);
          break;
        }
      }
    }

    return topics.toSet().toList(); // Remove duplicates
  }

  /// Calculate energy level from message
  double _calculateEnergyLevel(String message) {
    final exclamationCount = message.split('!').length - 1;
    final capsCount = message
        .split('')
        .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
        .length;
    final energyWords = ['excited', 'pumped', 'ready', 'fired', 'motivated'];

    double energy = 0.5;
    energy += exclamationCount * 0.1;
    energy += (capsCount / message.length) * 0.5;

    for (final word in energyWords) {
      if (message.toLowerCase().contains(word)) energy += 0.1;
    }

    return energy.clamp(0.0, 1.0);
  }

  /// Calculate clarity level from message
  double _calculateClarityLevel(String message) {
    final questionCount = message.split('?').length - 1;
    final uncertainWords = [
      'maybe',
      'perhaps',
      'not sure',
      'confused',
      'unclear'
    ];
    final clearWords = [
      'exactly',
      'specifically',
      'clearly',
      'definitely',
      'precisely'
    ];

    double clarity = 0.5;
    clarity -= questionCount * 0.05; // Questions indicate uncertainty

    for (final word in uncertainWords) {
      if (message.toLowerCase().contains(word)) clarity -= 0.1;
    }

    for (final word in clearWords) {
      if (message.toLowerCase().contains(word)) clarity += 0.1;
    }

    return clarity.clamp(0.0, 1.0);
  }

  /// Update insights based on conversation turn
  Future<void> _updateInsights(
      AiMemoryStruct memory, ConversationTurnStruct turn) async {
    // Update key topics
    for (final topic in turn.extractedTopics) {
      if (!memory.keyTopics.contains(topic)) {
        memory.keyTopics.add(topic);
      }
    }

    // Update golf patterns
    final golfPatterns = Map<String, dynamic>.from(memory.golfPatterns);
    final mentalPatterns = Map<String, dynamic>.from(memory.mentalPatterns);
    final userInsights = Map<String, dynamic>.from(memory.userInsights);

    // Analyze golf-specific patterns
    if (turn.extractedTopics.contains('putting')) {
      _updateListInMap(golfPatterns, 'preferredTopics', 'putting');
    }
    if (turn.extractedTopics.contains('mental_game')) {
      _updateListInMap(mentalPatterns, 'mentalGameFocus', 'mental_performance');
    }

    // Update communication style based on message characteristics
    final messageLength = turn.userMessage.length;
    if (messageLength > 100) {
      userInsights['communicationStyle'] = 'detailed';
    } else if (messageLength < 30) {
      userInsights['communicationStyle'] = 'concise';
    }

    // Update personality traits based on sentiment
    final sentiment = turn.sentiment;
    if (sentiment.isNotEmpty) {
      final personalityTraits =
          Map<String, dynamic>.from(memory.personalityTraits);

      // Update openness based on topic diversity
      if (turn.extractedTopics.length > 2) {
        personalityTraits['openness'] =
            ((personalityTraits['openness'] as double) + 0.05).clamp(0.0, 1.0);
      }

      // Update neuroticism based on frustration
      final frustration = sentiment['frustration'] as double? ?? 0.0;
      if (frustration > 0.5) {
        personalityTraits['neuroticism'] =
            ((personalityTraits['neuroticism'] as double) + 0.05)
                .clamp(0.0, 1.0);
      }

      memory.personalityTraits = personalityTraits;
    }

    // Update engagement score
    memory.engagementScore = _calculateEngagementScore(memory);

    // Save updated patterns
    memory.golfPatterns = golfPatterns;
    memory.mentalPatterns = mentalPatterns;
    memory.userInsights = userInsights;
  }

  /// Helper to update list in map
  void _updateListInMap(Map<String, dynamic> map, String key, String value) {
    final list = (map[key] as List<dynamic>?) ?? [];
    if (!list.contains(value)) {
      list.add(value);
      map[key] = list;
    }
  }

  /// Calculate engagement score based on conversation patterns
  double _calculateEngagementScore(AiMemoryStruct memory) {
    double score = 0.5;

    // Factor in total interactions
    score += (memory.totalInteractions * 0.01).clamp(0.0, 0.3);

    // Factor in topic diversity
    score += (memory.keyTopics.length * 0.02).clamp(0.0, 0.2);

    // Factor in recent activity
    if (memory.conversationHistory.isNotEmpty) {
      final recentTurns = memory.conversationHistory
          .where((turn) =>
              turn.timestamp != null &&
              DateTime.now().difference(turn.timestamp!).inDays < 7)
          .length;
      score += (recentTurns * 0.05).clamp(0.0, 0.3);
    }

    return score.clamp(0.0, 1.0);
  }

  /// Get conversation context for AI prompts
  String getConversationContext({int maxTurns = 5}) {
    if (currentUserUid.isEmpty) return '';

    final memory = _memoryCache[currentUserUid];
    if (memory == null || memory.conversationHistory.isEmpty) return '';

    final buffer = StringBuffer();
    final recentTurns =
        memory.conversationHistory.reversed.take(maxTurns).toList().reversed;

    for (final turn in recentTurns) {
      buffer.writeln('Golfer: ${turn.userMessage}');
      buffer.writeln('Coach: ${turn.aiResponse}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get user insights for AI personalization
  Map<String, dynamic> getUserInsights() {
    if (currentUserUid.isEmpty) return {};

    final memory = _memoryCache[currentUserUid];
    if (memory == null) return {};

    return {
      'userInsights': memory.userInsights,
      'golfPatterns': memory.golfPatterns,
      'mentalPatterns': memory.mentalPatterns,
      'keyTopics': memory.keyTopics,
      'personalityTraits': memory.personalityTraits,
      'engagementScore': memory.engagementScore,
      'totalInteractions': memory.totalInteractions,
    };
  }

  /// Get personalized system prompt based on user memory
  String getPersonalizedSystemPrompt() {
    final insights = getUserInsights();
    if (insights.isEmpty) return '';

    final buffer = StringBuffer();

    // Add user-specific context
    final userInsights =
        insights['userInsights'] as Map<String, dynamic>? ?? {};
    final golfPatterns =
        insights['golfPatterns'] as Map<String, dynamic>? ?? {};
    final mentalPatterns =
        insights['mentalPatterns'] as Map<String, dynamic>? ?? {};
    final keyTopics = insights['keyTopics'] as List<dynamic>? ?? [];

    buffer.writeln('\n--- USER CONTEXT ---');

    if (userInsights['communicationStyle'] != 'unknown') {
      buffer.writeln(
          'Communication Style: ${userInsights['communicationStyle']}');
    }

    if (keyTopics.isNotEmpty) {
      buffer.writeln('Primary Interests: ${keyTopics.take(5).join(', ')}');
    }

    final commonChallenges =
        golfPatterns['commonChallenges'] as List<dynamic>? ?? [];
    if (commonChallenges.isNotEmpty) {
      buffer.writeln('Known Challenges: ${commonChallenges.join(', ')}');
    }

    final strengthAreas = golfPatterns['strengthAreas'] as List<dynamic>? ?? [];
    if (strengthAreas.isNotEmpty) {
      buffer.writeln('Strength Areas: ${strengthAreas.join(', ')}');
    }

    final mentalFocus =
        mentalPatterns['mentalGameFocus'] as List<dynamic>? ?? [];
    if (mentalFocus.isNotEmpty) {
      buffer.writeln('Mental Game Focus: ${mentalFocus.join(', ')}');
    }

    buffer.writeln('Total Interactions: ${insights['totalInteractions']}');
    buffer.writeln('--- END CONTEXT ---\n');

    return buffer.toString();
  }

  /// Schedule save to Firestore
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 5), _saveToFirestore);
  }

  /// Save memory to Firestore
  Future<void> _saveToFirestore() async {
    if (currentUserUid.isEmpty) return;

    final memory = _memoryCache[currentUserUid];
    if (memory == null) return;

    try {
      await FirebaseFirestore.instance
          .collection(_aiMemoryCollection)
          .doc(currentUserUid)
          .set(memory.toMap(), SetOptions(merge: true));

      if (kDebugMode) {
        print('💾 Saved AI memory to Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving AI memory: $e');
      }
    }
  }

  /// Clear user memory (for privacy/GDPR)
  Future<void> clearUserMemory() async {
    if (currentUserUid.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection(_aiMemoryCollection)
          .doc(currentUserUid)
          .delete();

      _memoryCache.remove(currentUserUid);
      _startNewSession();

      if (kDebugMode) {
        print('🗑️ Cleared user AI memory');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing user memory: $e');
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    _saveTimer?.cancel();
    _memoryUpdateController.close();
  }
}
