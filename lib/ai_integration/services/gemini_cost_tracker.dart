import 'package:flutter/foundation.dart';
import '/backend/schema/index.dart';
import '../config/gemini_config.dart';

/// Service for tracking Gemini AI usage, costs, and tokens
class GeminiCostTracker {
  GeminiCostTracker._();
  
  static GeminiCostTracker? _instance;
  static GeminiCostTracker get instance => _instance ??= GeminiCostTracker._();

  static const String _costTrackingCollection = 'ai_usage_tracking';
  static const String _userTokensCollection = 'user_tokens';
  
  // Gemini API pricing (approximate, update with actual pricing)
  static const double _inputTokenCost = 0.000001; // $0.000001 per input token
  static const double _outputTokenCost = 0.000002; // $0.000002 per output token
  static const int _freeTokensPerMonth = 5000; // Free tokens for BASE tier
  static const int _baseTokensPerMonth = 50000; // BASE tier monthly limit
  static const int _plusTokensPerMonth = 200000; // PLUS tier monthly limit
  // PRIME tier has unlimited tokens

  /// Initialize the cost tracker
  Future<void> initialize() async {
    if (kDebugMode) {
      print('💰 Gemini Cost Tracker initialized');
    }
  }

  /// Track insight generation usage
  Future<void> trackInsightGeneration({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
    String? sessionId,
    String? insightType = 'golf_performance',
  }) async {
    try {
      await _recordUsage(
        userId: userId,
        usageType: 'insight_generation',
        tokensUsed: tokensUsed,
        estimatedCost: estimatedCost,
        metadata: {
          'session_id': sessionId,
          'insight_type': insightType,
          'model': GeminiConfig.defaultModel,
        },
      );

      // Deduct tokens from user balance
      await _deductTokens(userId: userId, tokensUsed: tokensUsed);

      if (kDebugMode) {
        print('💡 Tracked insight generation: $tokensUsed tokens, \$${estimatedCost.toStringAsFixed(6)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking insight generation: $e');
      }
      rethrow;
    }
  }

  /// Track recommendation generation usage
  Future<void> trackRecommendationGeneration({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
    String? sessionId,
    String? recommendationType = 'mental_coaching',
  }) async {
    try {
      await _recordUsage(
        userId: userId,
        usageType: 'recommendation_generation',
        tokensUsed: tokensUsed,
        estimatedCost: estimatedCost,
        metadata: {
          'session_id': sessionId,
          'recommendation_type': recommendationType,
          'model': GeminiConfig.defaultModel,
        },
      );

      // Deduct tokens from user balance
      await _deductTokens(userId: userId, tokensUsed: tokensUsed);

      if (kDebugMode) {
        print('📚 Tracked recommendation generation: $tokensUsed tokens, \$${estimatedCost.toStringAsFixed(6)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking recommendation generation: $e');
      }
      rethrow;
    }
  }

  /// Track content generation usage
  Future<void> trackContentGeneration({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
    String? sessionId,
    String? contentType = 'personalized_content',
  }) async {
    try {
      await _recordUsage(
        userId: userId,
        usageType: 'content_generation',
        tokensUsed: tokensUsed,
        estimatedCost: estimatedCost,
        metadata: {
          'session_id': sessionId,
          'content_type': contentType,
          'model': GeminiConfig.defaultModel,
        },
      );

      // Deduct tokens from user balance
      await _deductTokens(userId: userId, tokensUsed: tokensUsed);

      if (kDebugMode) {
        print('📝 Tracked content generation: $tokensUsed tokens, \$${estimatedCost.toStringAsFixed(6)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking content generation: $e');
      }
      rethrow;
    }
  }

  /// Track conversation usage (PRIME tier)
  Future<void> trackConversationUsage({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
    required String sessionId,
    String? conversationType = 'coaching_conversation',
  }) async {
    try {
      await _recordUsage(
        userId: userId,
        usageType: 'conversation',
        tokensUsed: tokensUsed,
        estimatedCost: estimatedCost,
        metadata: {
          'session_id': sessionId,
          'conversation_type': conversationType,
          'model': GeminiConfig.defaultModel,
        },
      );

      // For PRIME tier, conversations don't deduct tokens
      // But we still track usage for analytics
      
      if (kDebugMode) {
        print('💬 Tracked conversation usage: $tokensUsed tokens, \$${estimatedCost.toStringAsFixed(6)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking conversation usage: $e');
      }
      rethrow;
    }
  }

  /// Check if user has sufficient tokens for operation
  Future<bool> hasTokensForOperation({
    required String userId,
    required int tokensRequired,
  }) async {
    try {
      final userTokens = await getUserTokenBalance(userId);
      return userTokens.availableTokens >= tokensRequired;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking token balance: $e');
      }
      return false;
    }
  }

  /// Get user's token balance and limits
  Future<UserTokenBalance> getUserTokenBalance(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_userTokensCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Create new token balance for user
        return await _createUserTokenBalance(userId);
      }

      final data = doc.data()!;
      return UserTokenBalance.fromMap(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user token balance: $e');
      }
      rethrow;
    }
  }

  /// Get user's usage statistics
  Future<UserUsageStatistics> getUserUsageStatistics({
    required String userId,
    int days = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await FirebaseFirestore.instance
          .collection(_costTrackingCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: cutoffDate)
          .orderBy('timestamp', descending: true)
          .get();

      final usageRecords = snapshot.docs
          .map((doc) => UsageRecord.fromMap(doc.data()))
          .toList();

      return _calculateUsageStatistics(usageRecords, days);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user usage statistics: $e');
      }
      return UserUsageStatistics.empty();
    }
  }

  /// Get system-wide usage analytics (admin only)
  Future<SystemUsageAnalytics> getSystemUsageAnalytics({
    int days = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await FirebaseFirestore.instance
          .collection(_costTrackingCollection)
          .where('timestamp', isGreaterThan: cutoffDate)
          .orderBy('timestamp', descending: true)
          .get();

      final usageRecords = snapshot.docs
          .map((doc) => UsageRecord.fromMap(doc.data()))
          .toList();

      return _calculateSystemAnalytics(usageRecords, days);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting system usage analytics: $e');
      }
      return SystemUsageAnalytics.empty();
    }
  }

  /// Purchase additional tokens
  Future<void> purchaseTokens({
    required String userId,
    required int tokensToAdd,
    required double amountPaid,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      // Record token purchase
      await _recordTokenPurchase(
        userId: userId,
        tokensToAdd: tokensToAdd,
        amountPaid: amountPaid,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      // Add tokens to user balance
      await _addTokens(userId: userId, tokensToAdd: tokensToAdd);

      if (kDebugMode) {
        print('💳 Token purchase completed: $tokensToAdd tokens for \$${amountPaid.toStringAsFixed(2)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing token purchase: $e');
      }
      rethrow;
    }
  }

  /// Reset monthly token allocation
  Future<void> resetMonthlyTokens(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(_userTokensCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        await _createUserTokenBalance(userId);
        return;
      }

      final userTokens = UserTokenBalance.fromMap(userDoc.data()!);
      final newMonthlyAllocation = _getMonthlyTokenAllocation(userTokens.subscriptionTier);

      await FirebaseFirestore.instance
          .collection(_userTokensCollection)
          .doc(userId)
          .update({
            'monthlyTokens': newMonthlyAllocation,
            'tokensUsedThisMonth': 0,
            'lastResetDate': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (kDebugMode) {
        print('🔄 Reset monthly tokens for user $userId: $newMonthlyAllocation tokens');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resetting monthly tokens: $e');
      }
      rethrow;
    }
  }

  /// Update user subscription tier
  Future<void> updateUserSubscriptionTier({
    required String userId,
    required String newTier,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(_userTokensCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        await _createUserTokenBalance(userId);
      }

      final newMonthlyAllocation = _getMonthlyTokenAllocation(newTier);

      await FirebaseFirestore.instance
          .collection(_userTokensCollection)
          .doc(userId)
          .update({
            'subscriptionTier': newTier,
            'monthlyTokens': newMonthlyAllocation,
            'isUnlimited': newTier == 'PRIME',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (kDebugMode) {
        print('📊 Updated subscription tier for $userId: $newTier ($newMonthlyAllocation tokens)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating subscription tier: $e');
      }
      rethrow;
    }
  }

  /// Estimate cost for token usage
  double estimateCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    final inputCost = inputTokens * _inputTokenCost;
    final outputCost = outputTokens * _outputTokenCost;
    return inputCost + outputCost;
  }

  /// Check if user needs to purchase more tokens
  Future<bool> needsTokenPurchase({
    required String userId,
    int threshold = 1000,
  }) async {
    try {
      final userTokens = await getUserTokenBalance(userId);
      return userTokens.availableTokens < threshold && !userTokens.isUnlimited;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking token purchase need: $e');
      }
      return false;
    }
  }

  /// Get token pricing tiers
  Map<String, TokenPricingTier> getTokenPricingTiers() {
    return {
      'starter': TokenPricingTier(
        name: 'Starter Pack',
        tokens: 10000,
        price: 4.99,
        description: 'Perfect for getting started',
      ),
      'standard': TokenPricingTier(
        name: 'Standard Pack',
        tokens: 50000,
        price: 19.99,
        description: 'Great for regular users',
      ),
      'premium': TokenPricingTier(
        name: 'Premium Pack',
        tokens: 150000,
        price: 49.99,
        description: 'Best value for power users',
      ),
      'enterprise': TokenPricingTier(
        name: 'Enterprise Pack',
        tokens: 500000,
        price: 149.99,
        description: 'For unlimited coaching',
      ),
    };
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Record usage in Firestore
  Future<void> _recordUsage({
    required String userId,
    required String usageType,
    required int tokensUsed,
    required double estimatedCost,
    Map<String, dynamic>? metadata,
  }) async {
    final record = UsageRecord(
      userId: userId,
      usageType: usageType,
      tokensUsed: tokensUsed,
      estimatedCost: estimatedCost,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    await FirebaseFirestore.instance
        .collection(_costTrackingCollection)
        .add(record.toMap());
  }

  /// Create new user token balance
  Future<UserTokenBalance> _createUserTokenBalance(String userId) async {
    final userDoc = await UserRecord.collection.doc(userId).get();
    final subscriptionTier = userDoc.exists 
        ? (userDoc.data() as Map<String, dynamic>)['subscriptionTier'] ?? 'BASE'
        : 'BASE';

    final monthlyAllocation = _getMonthlyTokenAllocation(subscriptionTier);
    
    final userTokens = UserTokenBalance(
      userId: userId,
      subscriptionTier: subscriptionTier,
      monthlyTokens: monthlyAllocation,
      purchasedTokens: 0,
      tokensUsedThisMonth: 0,
      isUnlimited: subscriptionTier == 'PRIME',
      lastResetDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection(_userTokensCollection)
        .doc(userId)
        .set(userTokens.toMap());

    return userTokens;
  }

  /// Deduct tokens from user balance
  Future<void> _deductTokens({
    required String userId,
    required int tokensUsed,
  }) async {
    final userTokens = await getUserTokenBalance(userId);
    
    if (userTokens.isUnlimited) {
      // PRIME tier has unlimited tokens, just track usage
      await FirebaseFirestore.instance
          .collection(_userTokensCollection)
          .doc(userId)
          .update({
            'tokensUsedThisMonth': FieldValue.increment(tokensUsed),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return;
    }

    if (userTokens.availableTokens < tokensUsed) {
      throw Exception('Insufficient tokens. Required: $tokensUsed, Available: ${userTokens.availableTokens}');
    }

    await FirebaseFirestore.instance
        .collection(_userTokensCollection)
        .doc(userId)
        .update({
          'tokensUsedThisMonth': FieldValue.increment(tokensUsed),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Add tokens to user balance
  Future<void> _addTokens({
    required String userId,
    required int tokensToAdd,
  }) async {
    await FirebaseFirestore.instance
        .collection(_userTokensCollection)
        .doc(userId)
        .update({
          'purchasedTokens': FieldValue.increment(tokensToAdd),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Record token purchase
  Future<void> _recordTokenPurchase({
    required String userId,
    required int tokensToAdd,
    required double amountPaid,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final purchase = TokenPurchase(
      userId: userId,
      tokensAdded: tokensToAdd,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      purchaseDate: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('token_purchases')
        .add(purchase.toMap());
  }

  /// Get monthly token allocation based on subscription tier
  int _getMonthlyTokenAllocation(String subscriptionTier) {
    switch (subscriptionTier) {
      case 'BASE':
        return _baseTokensPerMonth;
      case 'PLUS':
        return _plusTokensPerMonth;
      case 'PRIME':
        return -1; // Unlimited
      default:
        return _freeTokensPerMonth;
    }
  }

  /// Calculate user usage statistics
  UserUsageStatistics _calculateUsageStatistics(
    List<UsageRecord> records,
    int days,
  ) {
    if (records.isEmpty) return UserUsageStatistics.empty();

    final totalTokens = records.fold(0, (sum, record) => sum + record.tokensUsed);
    final totalCost = records.fold(0.0, (sum, record) => sum + record.estimatedCost);
    
    final usageByType = <String, int>{};
    final costByType = <String, double>{};
    
    for (final record in records) {
      usageByType[record.usageType] = (usageByType[record.usageType] ?? 0) + record.tokensUsed;
      costByType[record.usageType] = (costByType[record.usageType] ?? 0.0) + record.estimatedCost;
    }

    final averageTokensPerDay = totalTokens / days;
    final averageCostPerDay = totalCost / days;

    return UserUsageStatistics(
      totalTokensUsed: totalTokens,
      totalCost: totalCost,
      averageTokensPerDay: averageTokensPerDay,
      averageCostPerDay: averageCostPerDay,
      usageByType: usageByType,
      costByType: costByType,
      period: days,
    );
  }

  /// Calculate system analytics
  SystemUsageAnalytics _calculateSystemAnalytics(
    List<UsageRecord> records,
    int days,
  ) {
    if (records.isEmpty) return SystemUsageAnalytics.empty();

    final totalTokens = records.fold(0, (sum, record) => sum + record.tokensUsed);
    final totalCost = records.fold(0.0, (sum, record) => sum + record.estimatedCost);
    
    final uniqueUsers = records.map((r) => r.userId).toSet().length;
    final averageTokensPerUser = totalTokens / uniqueUsers;
    
    final usageByType = <String, int>{};
    final usersByTier = <String, int>{};
    
    for (final record in records) {
      usageByType[record.usageType] = (usageByType[record.usageType] ?? 0) + record.tokensUsed;
    }

    return SystemUsageAnalytics(
      totalTokensUsed: totalTokens,
      totalCost: totalCost,
      totalUsers: uniqueUsers,
      averageTokensPerUser: averageTokensPerUser,
      usageByType: usageByType,
      usersByTier: usersByTier,
      period: days,
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// User token balance model
class UserTokenBalance {
  final String userId;
  final String subscriptionTier;
  final int monthlyTokens;
  final int purchasedTokens;
  final int tokensUsedThisMonth;
  final bool isUnlimited;
  final DateTime lastResetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserTokenBalance({
    required this.userId,
    required this.subscriptionTier,
    required this.monthlyTokens,
    required this.purchasedTokens,
    required this.tokensUsedThisMonth,
    required this.isUnlimited,
    required this.lastResetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get available tokens
  int get availableTokens {
    if (isUnlimited) return 999999; // Effectively unlimited
    return (monthlyTokens + purchasedTokens) - tokensUsedThisMonth;
  }

  /// Get usage percentage
  double get usagePercentage {
    if (isUnlimited) return 0.0;
    final totalTokens = monthlyTokens + purchasedTokens;
    return totalTokens > 0 ? (tokensUsedThisMonth / totalTokens) * 100 : 0.0;
  }

  factory UserTokenBalance.fromMap(Map<String, dynamic> map) {
    return UserTokenBalance(
      userId: map['userId'] as String,
      subscriptionTier: map['subscriptionTier'] as String,
      monthlyTokens: map['monthlyTokens'] as int,
      purchasedTokens: map['purchasedTokens'] as int,
      tokensUsedThisMonth: map['tokensUsedThisMonth'] as int,
      isUnlimited: map['isUnlimited'] as bool,
      lastResetDate: (map['lastResetDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subscriptionTier': subscriptionTier,
      'monthlyTokens': monthlyTokens,
      'purchasedTokens': purchasedTokens,
      'tokensUsedThisMonth': tokensUsedThisMonth,
      'isUnlimited': isUnlimited,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// Usage record model
class UsageRecord {
  final String userId;
  final String usageType;
  final int tokensUsed;
  final double estimatedCost;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const UsageRecord({
    required this.userId,
    required this.usageType,
    required this.tokensUsed,
    required this.estimatedCost,
    required this.timestamp,
    required this.metadata,
  });

  factory UsageRecord.fromMap(Map<String, dynamic> map) {
    return UsageRecord(
      userId: map['userId'] as String,
      usageType: map['usageType'] as String,
      tokensUsed: map['tokensUsed'] as int,
      estimatedCost: (map['estimatedCost'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'usageType': usageType,
      'tokensUsed': tokensUsed,
      'estimatedCost': estimatedCost,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

/// Token purchase record
class TokenPurchase {
  final String userId;
  final int tokensAdded;
  final double amountPaid;
  final String paymentMethod;
  final String? transactionId;
  final DateTime purchaseDate;

  const TokenPurchase({
    required this.userId,
    required this.tokensAdded,
    required this.amountPaid,
    required this.paymentMethod,
    this.transactionId,
    required this.purchaseDate,
  });

  factory TokenPurchase.fromMap(Map<String, dynamic> map) {
    return TokenPurchase(
      userId: map['userId'] as String,
      tokensAdded: map['tokensAdded'] as int,
      amountPaid: (map['amountPaid'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      transactionId: map['transactionId'] as String?,
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tokensAdded': tokensAdded,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
    };
  }
}

/// Token pricing tier
class TokenPricingTier {
  final String name;
  final int tokens;
  final double price;
  final String description;

  const TokenPricingTier({
    required this.name,
    required this.tokens,
    required this.price,
    required this.description,
  });

  double get pricePerToken => price / tokens;
}

/// User usage statistics
class UserUsageStatistics {
  final int totalTokensUsed;
  final double totalCost;
  final double averageTokensPerDay;
  final double averageCostPerDay;
  final Map<String, int> usageByType;
  final Map<String, double> costByType;
  final int period;

  const UserUsageStatistics({
    required this.totalTokensUsed,
    required this.totalCost,
    required this.averageTokensPerDay,
    required this.averageCostPerDay,
    required this.usageByType,
    required this.costByType,
    required this.period,
  });

  factory UserUsageStatistics.empty() => const UserUsageStatistics(
    totalTokensUsed: 0,
    totalCost: 0.0,
    averageTokensPerDay: 0.0,
    averageCostPerDay: 0.0,
    usageByType: {},
    costByType: {},
    period: 0,
  );
}

/// System usage analytics
class SystemUsageAnalytics {
  final int totalTokensUsed;
  final double totalCost;
  final int totalUsers;
  final double averageTokensPerUser;
  final Map<String, int> usageByType;
  final Map<String, int> usersByTier;
  final int period;

  const SystemUsageAnalytics({
    required this.totalTokensUsed,
    required this.totalCost,
    required this.totalUsers,
    required this.averageTokensPerUser,
    required this.usageByType,
    required this.usersByTier,
    required this.period,
  });

  factory SystemUsageAnalytics.empty() => const SystemUsageAnalytics(
    totalTokensUsed: 0,
    totalCost: 0.0,
    totalUsers: 0,
    averageTokensPerUser: 0.0,
    usageByType: {},
    usersByTier: {},
    period: 0,
  );
}

/// Exception for token-related errors
class TokenException implements Exception {
  final String message;
  final String? code;

  const TokenException(this.message, [this.code]);

  @override
  String toString() => 'TokenException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception for Gemini API errors
class GeminiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const GeminiException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'GeminiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
} 