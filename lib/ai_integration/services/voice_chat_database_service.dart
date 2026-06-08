import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/backend/schema/structs/vark_preferences_struct.dart';

/// Voice Chat Message Model for database storage
class VoiceChatMessage {
  final String id;
  final String userId;
  final String sessionId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? audioUrl;
  final String? imageUrl;
  final bool? isSystem;
  final String messageType; // 'text', 'audio', 'native_audio', 'image'
  final String? thinkingProcess;

  VoiceChatMessage({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.metadata,
    this.audioUrl,
    this.imageUrl,
    this.isSystem,
    this.messageType = 'text',
    this.thinkingProcess,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'content': content,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata ?? {},
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'isSystem': isSystem ?? false,
      'messageType': messageType,
      'thinkingProcess': thinkingProcess,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static VoiceChatMessage fromFirestore(Map<String, dynamic> data) {
    return VoiceChatMessage(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
      audioUrl: data['audioUrl'],
      imageUrl: data['imageUrl'],
      isSystem: data['isSystem'],
      messageType: data['messageType'] ?? 'text',
      thinkingProcess: data['thinkingProcess'],
    );
  }
}

/// Voice Chat Session Model for database storage
class VoiceChatSession {
  final String id;
  final String userId;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> sessionMetadata;
  final VarkPreferencesStruct? varkPreferences;
  final int messageCount;
  final bool isDeepThinking;
  final String status; // 'active', 'completed', 'error'
  final String? preview;
  final String? summary;
  final String lifecycleStatus; // active | completed | archived
  final bool mindCoachRecommendationShown;

  VoiceChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.sessionMetadata,
    this.varkPreferences,
    this.messageCount = 0,
    this.isDeepThinking = false,
    this.status = 'active',
    this.preview,
    this.summary,
    this.lifecycleStatus = 'active',
    this.mindCoachRecommendationShown = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'sessionMetadata': sessionMetadata,
      'varkPreferences': varkPreferences?.toMap(),
      'messageCount': messageCount,
      'isDeepThinking': isDeepThinking,
      'status': status,
      if (preview != null) 'preview': preview,
      if (summary != null) 'summary': summary,
      'lifecycleStatus': lifecycleStatus,
      'mindCoachRecommendationShown': mindCoachRecommendationShown,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  static VoiceChatSession fromFirestore(Map<String, dynamic> data) {
    return VoiceChatSession(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      sessionMetadata: data['sessionMetadata'] ?? {},
      varkPreferences: data['varkPreferences'] != null
          ? VarkPreferencesStruct.fromMap(data['varkPreferences'])
          : null,
      messageCount: data['messageCount'] ?? 0,
      isDeepThinking: data['isDeepThinking'] ?? false,
      status: data['status'] ?? 'active',
      preview: data['preview'] as String?,
      summary: data['summary'] as String?,
      lifecycleStatus: (data['lifecycleStatus'] ?? data['status'] ?? 'active')
          .toString(),
      mindCoachRecommendationShown:
          data['mindCoachRecommendationShown'] == true,
    );
  }
}

/// User Voice Chat Stats Model
class UserVoiceChatStats {
  final String userId;
  final int totalSessions;
  final int totalMessages;
  final Duration totalChatTime;
  final Map<String, int> messageTypeBreakdown;
  final Map<String, double> varkUsageStats;
  final DateTime lastChatTime;
  final List<String> topTopics;
  final Map<String, dynamic> preferences;

  UserVoiceChatStats({
    required this.userId,
    required this.totalSessions,
    required this.totalMessages,
    required this.totalChatTime,
    required this.messageTypeBreakdown,
    required this.varkUsageStats,
    required this.lastChatTime,
    required this.topTopics,
    required this.preferences,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalSessions': totalSessions,
      'totalMessages': totalMessages,
      'totalChatTimeMinutes': totalChatTime.inMinutes,
      'messageTypeBreakdown': messageTypeBreakdown,
      'varkUsageStats': varkUsageStats,
      'lastChatTime': Timestamp.fromDate(lastChatTime),
      'topTopics': topTopics,
      'preferences': preferences,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  static UserVoiceChatStats fromFirestore(Map<String, dynamic> data) {
    return UserVoiceChatStats(
      userId: data['userId'] ?? '',
      totalSessions: data['totalSessions'] ?? 0,
      totalMessages: data['totalMessages'] ?? 0,
      totalChatTime: Duration(minutes: data['totalChatTimeMinutes'] ?? 0),
      messageTypeBreakdown:
          Map<String, int>.from(data['messageTypeBreakdown'] ?? {}),
      varkUsageStats: Map<String, double>.from(data['varkUsageStats'] ?? {}),
      lastChatTime:
          (data['lastChatTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      topTopics: List<String>.from(data['topTopics'] ?? []),
      preferences: data['preferences'] ?? {},
    );
  }
}

/// Voice Chat Database Service for comprehensive data management
class VoiceChatDatabaseService {
  static const String _messagesCollection = 'voice_chat_messages';
  static const String _sessionsCollection = 'voice_chat_sessions';
  static const String _userStatsCollection = 'user_voice_chat_stats';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Make sure the Firestore SDK has a fresh auth token attached before
  /// hitting collections that are gated by `request.auth.uid`. This is the
  /// single biggest source of `[cloud_firestore/permission-denied]` right
  /// after sign-in / app cold start.
  Future<bool> _ensureAuthReady() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    try {
      await user.getIdToken();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ VoiceChat: failed to refresh ID token: $e');
      }
      return false;
    }
  }

  /// Initialize the service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('📊 Voice Chat Database Service initializing...');
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Start a new voice chat session
  Future<VoiceChatSession> startSession({
    String? title,
    VarkPreferencesStruct? varkPreferences,
    bool isDeepThinking = false,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _ensureAuthReady();

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final sessionTitle = title ?? _generateSessionTitle();

    final session = VoiceChatSession(
      id: sessionId,
      userId: _currentUserId!,
      title: sessionTitle,
      startTime: DateTime.now(),
      sessionMetadata: metadata ?? {},
      varkPreferences: varkPreferences,
      isDeepThinking: isDeepThinking,
      status: 'active',
    );

    await _firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .set(session.toFirestore());

    if (kDebugMode) {
      print('✅ Started voice chat session: $sessionId');
    }

    return session;
  }

  /// End a voice chat session
  Future<void> endSession(String sessionId) async {
    if (_currentUserId == null) return;

    await _firestore.collection(_sessionsCollection).doc(sessionId).update({
      'endTime': Timestamp.fromDate(DateTime.now()),
      'status': 'completed',
      'lifecycleStatus': 'completed',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Update user stats
    await _updateUserStats();

    if (kDebugMode) {
      print('✅ Ended voice chat session: $sessionId');
    }
  }

  Future<void> updateSessionFields(
    String sessionId,
    Map<String, dynamic> fields,
  ) async {
    if (_currentUserId == null || sessionId.trim().isEmpty) return;
    await _firestore.collection(_sessionsCollection).doc(sessionId).update({
      ...fields,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Archive and summarize a completed GolfChat session (async server-side).
  Future<void> archiveGolfChatSession(String sessionId) async {
    if (_currentUserId == null || sessionId.trim().isEmpty) return;
    try {
      await FirebaseFunctions.instance
          .httpsCallable('archiveGolfChatSession')
          .call(<String, dynamic>{'sessionId': sessionId});
    } catch (e) {
      if (kDebugMode) {
        print('archiveGolfChatSession failed: $e');
      }
    }
  }

  /// Live list of GolfChat sessions for the signed-in user (newest first).
  Stream<List<VoiceChatSession>> streamGolfChatSessions({int limit = 40}) {
    if (_currentUserId == null) {
      return const Stream<List<VoiceChatSession>>.empty();
    }

    return _firestore
        .collection(_sessionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs
          .map((doc) => VoiceChatSession.fromFirestore(
                doc.data(),
              ))
          .where(
            (session) => session.sessionMetadata['surface'] == 'golfchat',
          )
          .toList();
      return sessions;
    });
  }

  /// Fetch a single persisted session by id.
  Future<VoiceChatSession?> getSessionById(String sessionId) async {
    if (_currentUserId == null || sessionId.trim().isEmpty) {
      return null;
    }

    final doc =
        await _firestore.collection(_sessionsCollection).doc(sessionId).get();
    if (!doc.exists) {
      return null;
    }

    final session = VoiceChatSession.fromFirestore(doc.data()!);
    if (session.userId != _currentUserId) {
      return null;
    }
    return session;
  }

  /// Get user's voice chat sessions
  Future<List<VoiceChatSession>> getUserSessions({
    int limit = 20,
    String? lastSessionId,
  }) async {
    if (_currentUserId == null) return [];

    Query query = _firestore
        .collection(_sessionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('startTime', descending: true)
        .limit(limit);

    if (lastSessionId != null) {
      final lastDoc = await _firestore
          .collection(_sessionsCollection)
          .doc(lastSessionId)
          .get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) =>
            VoiceChatSession.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get active session for user
  Future<VoiceChatSession?> getActiveSession() async {
    if (_currentUserId == null) return null;

    final snapshot = await _firestore
        .collection(_sessionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'active')
        .orderBy('startTime', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return VoiceChatSession.fromFirestore(
      snapshot.docs.first.data(),
    );
  }

  // ============================================================================
  // MESSAGE MANAGEMENT
  // ============================================================================

  /// Save a voice chat message
  Future<void> saveMessage(VoiceChatMessage message) async {
    if (_currentUserId == null) return;

    await _ensureAuthReady();

    await _firestore
        .collection(_messagesCollection)
        .doc(message.id)
        .set(message.toFirestore());

    // Update session message count
    await _firestore
        .collection(_sessionsCollection)
        .doc(message.sessionId)
        .update({
      'messageCount': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    if (kDebugMode) {
      print('💾 Saved voice chat message: ${message.id}');
    }
  }

  /// Get messages for a session
  /// Query includes userId so Firestore security rules allow read.
  Future<List<VoiceChatMessage>> getSessionMessages({
    required String sessionId,
    int limit = 50,
    String? lastMessageId,
  }) async {
    if (_currentUserId == null) return [];

    Query query = _firestore
        .collection(_messagesCollection)
        .where('userId', isEqualTo: _currentUserId!)
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .limit(limit);

    if (lastMessageId != null) {
      final lastDoc = await _firestore
          .collection(_messagesCollection)
          .doc(lastMessageId)
          .get();
      if (lastDoc.exists) {
        query = query.startAfterDocument(lastDoc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) =>
            VoiceChatMessage.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Search messages by content
  Future<List<VoiceChatMessage>> searchMessages({
    required String searchTerm,
    int limit = 20,
  }) async {
    if (_currentUserId == null) return [];

    // Note: This is a basic text search. For production, consider using
    // Algolia or Elasticsearch for advanced search capabilities
    final snapshot = await _firestore
        .collection(_messagesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Get more to search through
        .get();

    return snapshot.docs
        .map((doc) => VoiceChatMessage.fromFirestore(doc.data()))
        .where((message) =>
            message.content.toLowerCase().contains(searchTerm.toLowerCase()))
        .take(limit)
        .toList();
  }

  /// Get recent conversations for context
  Future<List<VoiceChatMessage>> getRecentMessages({
    int limit = 10,
  }) async {
    if (_currentUserId == null) return [];

    final snapshot = await _firestore
        .collection(_messagesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => VoiceChatMessage.fromFirestore(doc.data()))
        .toList()
        .reversed
        .toList();
  }

  // ============================================================================
  // USER STATISTICS
  // ============================================================================

  /// Get user voice chat statistics
  Future<UserVoiceChatStats?> getUserStats() async {
    if (_currentUserId == null) return null;

    final doc = await _firestore
        .collection(_userStatsCollection)
        .doc(_currentUserId)
        .get();

    if (!doc.exists) {
      // Create initial stats
      await _createInitialUserStats();
      return getUserStats();
    }

    return UserVoiceChatStats.fromFirestore(doc.data()!);
  }

  /// Update user statistics
  Future<void> _updateUserStats() async {
    if (_currentUserId == null) return;

    // Calculate stats from user's data
    final sessions = await getUserSessions(limit: 1000);
    final messages = await _firestore
        .collection(_messagesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .get();

    final messageTypeBreakdown = <String, int>{};
    for (final doc in messages.docs) {
      final messageType = doc.data()['messageType'] as String? ?? 'text';
      messageTypeBreakdown[messageType] =
          (messageTypeBreakdown[messageType] ?? 0) + 1;
    }

    // Calculate VARK usage stats
    final varkStats = <String, double>{
      'visual': 0.0,
      'aural': 0.0,
      'readWrite': 0.0,
      'kinesthetic': 0.0,
    };

    int sessionCount = 0;
    for (final session in sessions) {
      if (session.varkPreferences != null) {
        sessionCount++;
        if (session.varkPreferences!.visual)
          varkStats['visual'] = varkStats['visual']! + 1;
        if (session.varkPreferences!.aural)
          varkStats['aural'] = varkStats['aural']! + 1;
        if (session.varkPreferences!.readWrite)
          varkStats['readWrite'] = varkStats['readWrite']! + 1;
        if (session.varkPreferences!.kinesthetic)
          varkStats['kinesthetic'] = varkStats['kinesthetic']! + 1;
      }
    }

    // Convert to percentages
    if (sessionCount > 0) {
      varkStats.forEach((key, value) {
        varkStats[key] = (value / sessionCount) * 100;
      });
    }

    // Calculate total chat time
    Duration totalTime = Duration.zero;
    for (final session in sessions) {
      if (session.endTime != null) {
        totalTime += session.endTime!.difference(session.startTime);
      }
    }

    final stats = UserVoiceChatStats(
      userId: _currentUserId!,
      totalSessions: sessions.length,
      totalMessages: messages.docs.length,
      totalChatTime: totalTime,
      messageTypeBreakdown: messageTypeBreakdown,
      varkUsageStats: varkStats,
      lastChatTime:
          sessions.isNotEmpty ? sessions.first.startTime : DateTime.now(),
      topTopics: await _extractTopTopics(messages.docs),
      preferences: {},
    );

    await _firestore
        .collection(_userStatsCollection)
        .doc(_currentUserId)
        .set(stats.toFirestore());

    if (kDebugMode) {
      print('📊 Updated user voice chat stats');
    }
  }

  /// Create initial user statistics
  Future<void> _createInitialUserStats() async {
    if (_currentUserId == null) return;

    final stats = UserVoiceChatStats(
      userId: _currentUserId!,
      totalSessions: 0,
      totalMessages: 0,
      totalChatTime: Duration.zero,
      messageTypeBreakdown: {},
      varkUsageStats: {
        'visual': 0.0,
        'aural': 0.0,
        'readWrite': 0.0,
        'kinesthetic': 0.0,
      },
      lastChatTime: DateTime.now(),
      topTopics: [],
      preferences: {},
    );

    await _firestore
        .collection(_userStatsCollection)
        .doc(_currentUserId)
        .set(stats.toFirestore());
  }

  // ============================================================================
  // ANALYTICS & INSIGHTS
  // ============================================================================

  /// Extract top topics from conversation messages
  Future<List<String>> _extractTopTopics(
      List<QueryDocumentSnapshot> messages) async {
    final topicMap = <String, int>{};
    final golfTopics = [
      'putting',
      'driving',
      'chipping',
      'pitching',
      'bunker',
      'iron',
      'wedge',
      'confidence',
      'focus',
      'pressure',
      'nerves',
      'visualization',
      'routine',
      'mental game',
      'course management',
      'competition',
      'practice'
    ];

    for (final doc in messages) {
      final content =
          (doc.data() as Map<String, dynamic>)['content'] as String? ?? '';
      final lowercaseContent = content.toLowerCase();

      for (final topic in golfTopics) {
        if (lowercaseContent.contains(topic)) {
          topicMap[topic] = (topicMap[topic] ?? 0) + 1;
        }
      }
    }

    final sortedTopics = topicMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTopics.take(5).map((entry) => entry.key).toList();
  }

  /// Get conversation insights
  Future<Map<String, dynamic>> getConversationInsights({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentUserId == null) return {};

    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final messagesQuery = await _firestore
        .collection(_messagesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final sessionsQuery = await _firestore
        .collection(_sessionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return {
      'totalMessages': messagesQuery.docs.length,
      'totalSessions': sessionsQuery.docs.length,
      'averageMessagesPerSession': sessionsQuery.docs.isNotEmpty
          ? messagesQuery.docs.length / sessionsQuery.docs.length
          : 0,
      'mostActiveDay': _getMostActiveDay(messagesQuery.docs),
      'preferredMessageType': _getPreferredMessageType(messagesQuery.docs),
      'topTopics': await _extractTopTopics(messagesQuery.docs),
      'thinkingModeUsage': _getThinkingModeUsage(sessionsQuery.docs),
    };
  }

  String _getMostActiveDay(List<QueryDocumentSnapshot> messages) {
    final dayCount = <String, int>{};
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    for (final doc in messages) {
      final timestamp =
          (doc.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final day = dayNames[timestamp.toDate().weekday - 1];
        dayCount[day] = (dayCount[day] ?? 0) + 1;
      }
    }

    if (dayCount.isEmpty) return 'N/A';

    return dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getPreferredMessageType(List<QueryDocumentSnapshot> messages) {
    final typeCount = <String, int>{};

    for (final doc in messages) {
      final messageType =
          (doc.data() as Map<String, dynamic>)['messageType'] as String? ??
              'text';
      typeCount[messageType] = (typeCount[messageType] ?? 0) + 1;
    }

    if (typeCount.isEmpty) return 'text';

    return typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double _getThinkingModeUsage(List<QueryDocumentSnapshot> sessions) {
    if (sessions.isEmpty) return 0.0;

    int thinkingModeSessions = 0;
    for (final doc in sessions) {
      final isDeepThinking =
          (doc.data() as Map<String, dynamic>)['isDeepThinking'] as bool? ??
              false;
      if (isDeepThinking) thinkingModeSessions++;
    }

    return (thinkingModeSessions / sessions.length) * 100;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Generate a session title based on context
  String _generateSessionTitle() {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12
        ? 'Morning'
        : now.hour < 17
            ? 'Afternoon'
            : 'Evening';
    return '$timeOfDay Chat - ${now.day}/${now.month}/${now.year}';
  }

  /// Clean up old data (retention policy)
  Future<void> cleanupOldData({
    Duration retentionPeriod = const Duration(days: 90),
  }) async {
    if (_currentUserId == null) return;

    final cutoffDate = DateTime.now().subtract(retentionPeriod);

    try {
      // Delete old messages
      final oldMessages = await _firestore
          .collection(_messagesCollection)
          .where('userId', isEqualTo: _currentUserId)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }

      // Delete old sessions
      final oldSessions = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .where('startTime', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in oldSessions.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) {
        print(
            '🧹 Cleaned up ${oldMessages.docs.length} messages and ${oldSessions.docs.length} sessions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up old data: $e');
      }
    }
  }

  /// Export user data (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData() async {
    if (_currentUserId == null) return {};

    final sessions = await getUserSessions(limit: 1000);
    final messages = await _firestore
        .collection(_messagesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .get();

    final stats = await getUserStats();

    return {
      'userId': _currentUserId,
      'exportDate': DateTime.now().toIso8601String(),
      'sessions': sessions.map((s) => s.toFirestore()).toList(),
      'messages': messages.docs.map((doc) => doc.data()).toList(),
      'stats': stats?.toFirestore(),
    };
  }
}
