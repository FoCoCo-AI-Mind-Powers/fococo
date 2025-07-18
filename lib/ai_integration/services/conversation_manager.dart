import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/backend/schema/index.dart';
import '../models/gemini_models.dart';

/// Service for managing AI conversation sessions and context
class ConversationManager {
  ConversationManager._();
  
  static ConversationManager? _instance;
  static ConversationManager get instance => _instance ??= ConversationManager._();

  static const String _conversationCollectionName = 'ai_conversation_sessions';
  static const Duration _sessionTimeout = Duration(hours: 24);
  static const int _maxConversationHistory = 50;

  /// Get or create a conversation session
  Future<ConversationSession> getOrCreateSession({
    required String userId,
    required String sessionType,
    String? sessionId,
    Map<String, dynamic>? initialContext,
  }) async {
    try {
      // If sessionId is provided, try to get existing session
      if (sessionId != null) {
        final existingSession = await getSession(sessionId);
        if (existingSession != null && !_isSessionExpired(existingSession)) {
          return existingSession;
        }
      }

      // Create new session
      final newSessionId = sessionId ?? _generateSessionId();
      final newSession = ConversationSession(
        sessionId: newSessionId,
        userId: userId,
        sessionType: sessionType,
        startTime: DateTime.now(),
        lastActivity: DateTime.now(),
        conversationHistory: [],
        sessionContext: initialContext ?? {},
      );

      // Save to Firestore
      await _saveSession(newSession);

      if (kDebugMode) {
        print('✅ Created new conversation session: $newSessionId');
        print('📋 Session type: $sessionType');
      }

      return newSession;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating conversation session: $e');
      }
      rethrow;
    }
  }

  /// Create a new conversation session
  Future<ConversationSession> createConversation({
    required String userId,
    required String conversationType,
    Map<String, dynamic>? initialContext,
  }) async {
    return await getOrCreateSession(
      userId: userId,
      sessionType: conversationType,
      initialContext: initialContext,
    );
  }

  /// Continue an existing conversation
  Future<ConversationTurn> continueConversation({
    required String sessionId,
    required String userMessage,
    Map<String, dynamic>? context,
  }) async {
    // This would need to be implemented with AI client
    // For now, return a placeholder
    final turn = ConversationTurn(
      userMessage: userMessage,
      aiResponse: "AI response would be generated here",
      timestamp: DateTime.now(),
      metadata: context ?? {},
    );
    
    await addToConversation(
      sessionId: sessionId,
      userMessage: userMessage,
      aiResponse: turn.aiResponse,
      metadata: context,
    );
    
    return turn;
  }

  /// Get conversation history
  Future<List<ConversationTurn>> getConversationHistory({
    required String sessionId,
    int? limit,
  }) async {
    final session = await getSession(sessionId);
    if (session == null) {
      return [];
    }
    
    final history = session.conversationHistory;
    if (limit != null && history.length > limit) {
      return history.take(limit).toList();
    }
    
    return history;
  }

  /// Archive a conversation session
  Future<void> archiveConversation({
    required String sessionId,
    String? reason,
  }) async {
    try {
      // Get the specific session
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      // Archive to archive collection
      final archiveRef = FirebaseFirestore.instance
          .collection('ai_conversation_archives')
          .doc(sessionId);
      
      await archiveRef.set({
        ...session.toMap(),
        'archivedAt': FieldValue.serverTimestamp(),
        'archiveReason': reason ?? 'Manual archive',
      });
      
      // Delete from active sessions
      await FirebaseFirestore.instance
          .collection(_conversationCollectionName)
          .doc(sessionId)
          .delete();
      
      if (kDebugMode) {
        print('📦 Archived session $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error archiving session $sessionId: $e');
      }
      rethrow;
    }
  }

  /// Get existing conversation session
  Future<ConversationSession?> getSession(String sessionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_conversationCollectionName)
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return ConversationSession.fromMap(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching conversation session: $e');
      }
      return null;
    }
  }

  /// Add conversation turn to session
  Future<void> addToConversation({
    required String sessionId,
    required String userMessage,
    required String aiResponse,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Conversation session not found');
      }

      // Create new conversation turn
      final newTurn = ConversationTurn(
        userMessage: userMessage,
        aiResponse: aiResponse,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );

      // Add to history (maintain max size)
      final updatedHistory = List<ConversationTurn>.from(session.conversationHistory);
      updatedHistory.add(newTurn);
      
      // Trim history to max size
      if (updatedHistory.length > _maxConversationHistory) {
        updatedHistory.removeAt(0);
      }

      // Update session
      final updatedSession = ConversationSession(
        sessionId: session.sessionId,
        userId: session.userId,
        sessionType: session.sessionType,
        startTime: session.startTime,
        lastActivity: DateTime.now(),
        conversationHistory: updatedHistory,
        sessionContext: session.sessionContext,
      );

      // Save updated session
      await _saveSession(updatedSession);

      if (kDebugMode) {
        print('💬 Added conversation turn to session: $sessionId');
        print('📊 Total turns: ${updatedHistory.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding to conversation: $e');
      }
      rethrow;
    }
  }

  /// Update session context
  Future<void> updateSessionContext({
    required String sessionId,
    required Map<String, dynamic> contextUpdate,
  }) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Conversation session not found');
      }

      // Merge context
      final updatedContext = Map<String, dynamic>.from(session.sessionContext);
      updatedContext.addAll(contextUpdate);

      // Update session
      final updatedSession = ConversationSession(
        sessionId: session.sessionId,
        userId: session.userId,
        sessionType: session.sessionType,
        startTime: session.startTime,
        lastActivity: DateTime.now(),
        conversationHistory: session.conversationHistory,
        sessionContext: updatedContext,
      );

      // Save updated session
      await _saveSession(updatedSession);

      if (kDebugMode) {
        print('🔄 Updated session context: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating session context: $e');
      }
      rethrow;
    }
  }

  /// Get user's active sessions
  Future<List<ConversationSession>> getUserSessions({
    required String userId,
    String? sessionType,
    int limit = 10,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(_conversationCollectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('lastActivity', descending: true)
          .limit(limit);

      if (sessionType != null) {
        query = query.where('sessionType', isEqualTo: sessionType);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => ConversationSession.fromMap(doc.data() as Map<String, dynamic>))
          .where((session) => !_isSessionExpired(session))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user sessions: $e');
      }
      return [];
    }
  }

  /// Get optimized conversation context for AI prompts
  String getOptimizedContext({
    required List<ConversationTurn> conversationHistory,
    int maxTurns = 5,
  }) {
    if (conversationHistory.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    final recentTurns = conversationHistory.take(maxTurns).toList();
    
    for (int i = 0; i < recentTurns.length; i++) {
      final turn = recentTurns[i];
      buffer.writeln('Turn ${i + 1}:');
      buffer.writeln('User: ${_truncateMessage(turn.userMessage)}');
      buffer.writeln('AI: ${_truncateMessage(turn.aiResponse)}');
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Estimate token count for conversation context
  int estimateContextTokens(List<ConversationTurn> conversationHistory) {
    int totalTokens = 0;
    
    for (final turn in conversationHistory) {
      totalTokens += _estimateTokens(turn.userMessage);
      totalTokens += _estimateTokens(turn.aiResponse);
    }
    
    return totalTokens;
  }

  /// Trim conversation history to fit within token limit
  List<ConversationTurn> trimContextToTokenLimit(
    List<ConversationTurn> conversationHistory, {
    int maxTokens = 6000,
  }) {
    if (conversationHistory.isEmpty) return [];
    
    final trimmedHistory = <ConversationTurn>[];
    int currentTokens = 0;
    
    // Add turns from most recent, going backwards
    for (int i = conversationHistory.length - 1; i >= 0; i--) {
      final turn = conversationHistory[i];
      final turnTokens = _estimateTokens(turn.userMessage) + _estimateTokens(turn.aiResponse);
      
      if (currentTokens + turnTokens <= maxTokens) {
        trimmedHistory.insert(0, turn);
        currentTokens += turnTokens;
      } else {
        break;
      }
    }
    
    return trimmedHistory;
  }

  /// Clean up expired sessions
  Future<void> cleanupExpiredSessions() async {
    try {
      final cutoffTime = DateTime.now().subtract(_sessionTimeout);
      
      final expiredSessions = await FirebaseFirestore.instance
          .collection(_conversationCollectionName)
          .where('lastActivity', isLessThan: cutoffTime)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in expiredSessions.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('🧹 Cleaned up ${expiredSessions.docs.length} expired sessions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up expired sessions: $e');
      }
    }
  }

  /// Get conversation analytics for a user
  Future<ConversationAnalytics> getConversationAnalytics({
    required String userId,
    int days = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final sessions = await FirebaseFirestore.instance
          .collection(_conversationCollectionName)
          .where('userId', isEqualTo: userId)
          .where('lastActivity', isGreaterThan: cutoffDate)
          .get();

      int totalSessions = sessions.docs.length;
      int totalTurns = 0;
      final sessionTypes = <String, int>{};
      Duration totalSessionTime = Duration.zero;
      
      for (final doc in sessions.docs) {
        final session = ConversationSession.fromMap(doc.data());
        totalTurns += session.conversationHistory.length;
        
        final sessionType = session.sessionType;
        sessionTypes[sessionType] = (sessionTypes[sessionType] ?? 0) + 1;
        
        totalSessionTime += session.lastActivity.difference(session.startTime);
      }

      return ConversationAnalytics(
        totalSessions: totalSessions,
        totalTurns: totalTurns,
        sessionTypes: sessionTypes,
        averageSessionLength: totalSessions > 0 
            ? totalSessionTime.inMinutes / totalSessions 
            : 0,
        averageTurnsPerSession: totalSessions > 0 
            ? totalTurns / totalSessions 
            : 0,
        period: days,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversation analytics: $e');
      }
      return ConversationAnalytics.empty();
    }
  }

  /// Archive old conversation sessions
  Future<void> archiveOldSessions({
    required String userId,
    int daysToKeep = 90,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final oldSessions = await FirebaseFirestore.instance
          .collection(_conversationCollectionName)
          .where('userId', isEqualTo: userId)
          .where('startTime', isLessThan: cutoffDate)
          .get();

      // Archive to a separate collection
      final archiveBatch = FirebaseFirestore.instance.batch();
      
      for (final doc in oldSessions.docs) {
        final archiveRef = FirebaseFirestore.instance
            .collection('ai_conversation_archives')
            .doc(doc.id);
        
        archiveBatch.set(archiveRef, {
          ...doc.data(),
          'archivedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await archiveBatch.commit();
      
      // Delete from active sessions
      final deleteBatch = FirebaseFirestore.instance.batch();
      for (final doc in oldSessions.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
      
      if (kDebugMode) {
        print('📦 Archived ${oldSessions.docs.length} old sessions for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error archiving old sessions: $e');
      }
    }
  }

  /// Delete all sessions for a user
  Future<void> deleteUserSessions(String userId) async {
    try {
      final userSessions = await FirebaseFirestore.instance
          .collection(_conversationCollectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      
      for (final doc in userSessions.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('🗑️ Deleted ${userSessions.docs.length} sessions for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting user sessions: $e');
      }
    }
  }

  /// Save conversation session to Firestore
  Future<void> _saveSession(ConversationSession session) async {
    await FirebaseFirestore.instance
        .collection(_conversationCollectionName)
        .doc(session.sessionId)
        .set(session.toMap());
  }

  /// Check if session is expired
  bool _isSessionExpired(ConversationSession session) {
    return DateTime.now().difference(session.lastActivity) > _sessionTimeout;
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// Generate random string
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length]).join();
  }

  /// Truncate message for context optimization
  String _truncateMessage(String message, {int maxLength = 200}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  /// Estimate token count (simplified)
  int _estimateTokens(String text) {
    // Rough approximation: 1 token ≈ 4 characters
    return (text.length / 4).ceil();
  }
}

/// Analytics model for conversation data
class ConversationAnalytics {
  final int totalSessions;
  final int totalTurns;
  final Map<String, int> sessionTypes;
  final double averageSessionLength; // in minutes
  final double averageTurnsPerSession;
  final int period; // days

  const ConversationAnalytics({
    required this.totalSessions,
    required this.totalTurns,
    required this.sessionTypes,
    required this.averageSessionLength,
    required this.averageTurnsPerSession,
    required this.period,
  });

  factory ConversationAnalytics.empty() => const ConversationAnalytics(
    totalSessions: 0,
    totalTurns: 0,
    sessionTypes: {},
    averageSessionLength: 0,
    averageTurnsPerSession: 0,
    period: 0,
  );

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'totalTurns': totalTurns,
      'sessionTypes': sessionTypes,
      'averageSessionLength': averageSessionLength,
      'averageTurnsPerSession': averageTurnsPerSession,
      'period': period,
    };
  }
} 