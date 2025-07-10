import 'package:flutter/foundation.dart';


import '/backend/schema/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '../config/ai_config.dart';

/// Service for tracking AI usage costs and analytics
class AICostTracker {
  AICostTracker._();
  
  static AICostTracker? _instance;
  static AICostTracker get instance => _instance ??= AICostTracker._();

  // Collection name for cost tracking (could be a subcollection of users)
  static const String _costCollectionName = 'ai_usage_logs';

  /// Track insight generation cost
  Future<void> trackInsightGeneration({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
  }) async {
    await _trackUsage(
      userId: userId,
      usageType: 'insight_generation',
      tokensUsed: tokensUsed,
      estimatedCost: estimatedCost,
    );
  }

  /// Track recommendation generation cost
  Future<void> trackRecommendationGeneration({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
  }) async {
    await _trackUsage(
      userId: userId,
      usageType: 'recommendation_generation',
      tokensUsed: tokensUsed,
      estimatedCost: estimatedCost,
    );
  }

  /// Track content generation cost
  Future<void> trackContentGeneration({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
  }) async {
    await _trackUsage(
      userId: userId,
      usageType: 'content_generation',
      tokensUsed: tokensUsed,
      estimatedCost: estimatedCost,
    );
  }

  /// Track feedback generation cost
  Future<void> trackFeedbackGeneration({
    required String userId,
    required int tokensUsed,
    required double estimatedCost,
  }) async {
    await _trackUsage(
      userId: userId,
      usageType: 'feedback_generation',
      tokensUsed: tokensUsed,
      estimatedCost: estimatedCost,
    );
  }

  /// Get user's daily AI usage statistics
  Future<DailyUsageStats> getDailyUsageStats(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection(_costCollectionName)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      return _calculateUsageStats(snapshot.docs);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting daily usage stats: $e');
      }
      return DailyUsageStats.empty();
    }
  }

  /// Get user's monthly AI usage statistics
  Future<MonthlyUsageStats> getMonthlyUsageStats(String userId) async {
    try {
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);
      final endOfMonth = DateTime(today.year, today.month + 1, 0, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection(_costCollectionName)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .get();

      return _calculateMonthlyStats(snapshot.docs);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting monthly usage stats: $e');
      }
      return MonthlyUsageStats.empty();
    }
  }

  /// Get cost breakdown by usage type
  Future<Map<String, UsageTypeStats>> getCostBreakdown({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_costCollectionName)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      final breakdown = <String, UsageTypeStats>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final usageType = data['usageType'] as String;
        final tokens = data['tokensUsed'] as int;
        final cost = data['estimatedCost'] as double;

        if (breakdown.containsKey(usageType)) {
          breakdown[usageType] = breakdown[usageType]!.copyWith(
            requestCount: breakdown[usageType]!.requestCount + 1,
            totalTokens: breakdown[usageType]!.totalTokens + tokens,
            totalCost: breakdown[usageType]!.totalCost + cost,
          );
        } else {
          breakdown[usageType] = UsageTypeStats(
            usageType: usageType,
            requestCount: 1,
            totalTokens: tokens,
            totalCost: cost,
          );
        }
      }

      return breakdown;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cost breakdown: $e');
      }
      return {};
    }
  }

  /// Check if user is approaching cost limits
  Future<CostAlert?> checkCostAlerts(String userId) async {
    try {
      final dailyStats = await getDailyUsageStats(userId);
      final monthlyStats = await getMonthlyUsageStats(userId);

      // Define cost thresholds (these could be configurable per user tier)
      const dailyCostThreshold = 0.50; // $0.50 per day
      const monthlyCostThreshold = 15.0; // $15.00 per month
      const dailyRequestThreshold = 30;
      const monthlyRequestThreshold = 300;

      // Check daily limits
      if (dailyStats.totalCost >= dailyCostThreshold) {
        return CostAlert(
          type: CostAlertType.dailyCostLimit,
          message: 'Daily cost limit reached: \$${dailyStats.totalCost.toStringAsFixed(2)}',
          severity: AlertSeverity.high,
        );
      }

      if (dailyStats.totalRequests >= dailyRequestThreshold) {
        return CostAlert(
          type: CostAlertType.dailyRequestLimit,
          message: 'Daily request limit reached: ${dailyStats.totalRequests} requests',
          severity: AlertSeverity.high,
        );
      }

      // Check monthly limits
      if (monthlyStats.totalCost >= monthlyCostThreshold) {
        return CostAlert(
          type: CostAlertType.monthlyCostLimit,
          message: 'Monthly cost limit reached: \$${monthlyStats.totalCost.toStringAsFixed(2)}',
          severity: AlertSeverity.high,
        );
      }

      // Check warning thresholds (80% of limits)
      if (dailyStats.totalCost >= dailyCostThreshold * 0.8) {
        return CostAlert(
          type: CostAlertType.dailyCostWarning,
          message: 'Approaching daily cost limit: \$${dailyStats.totalCost.toStringAsFixed(2)}/\$${dailyCostThreshold.toStringAsFixed(2)}',
          severity: AlertSeverity.medium,
        );
      }

      if (monthlyStats.totalCost >= monthlyCostThreshold * 0.8) {
        return CostAlert(
          type: CostAlertType.monthlyCostWarning,
          message: 'Approaching monthly cost limit: \$${monthlyStats.totalCost.toStringAsFixed(2)}/\$${monthlyCostThreshold.toStringAsFixed(2)}',
          severity: AlertSeverity.medium,
        );
      }

      return null; // No alerts
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking cost alerts: $e');
      }
      return null;
    }
  }

  /// Get aggregated system-wide costs (admin function)
  Future<SystemCostStats> getSystemWideCosts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_costCollectionName)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      double totalCost = 0;
      int totalRequests = 0;
      int totalTokens = 0;
      final Set<String> uniqueUsers = {};
      final Map<String, int> usageTypeCount = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalCost += data['estimatedCost'] as double;
        totalRequests++;
        totalTokens += data['tokensUsed'] as int;
        uniqueUsers.add(data['userId'] as String);
        
        final usageType = data['usageType'] as String;
        usageTypeCount[usageType] = (usageTypeCount[usageType] ?? 0) + 1;
      }

      return SystemCostStats(
        totalCost: totalCost,
        totalRequests: totalRequests,
        totalTokens: totalTokens,
        uniqueUsers: uniqueUsers.length,
        usageTypeBreakdown: usageTypeCount,
        period: '${startDate.toIso8601String().split('T')[0]} to ${endDate.toIso8601String().split('T')[0]}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting system-wide costs: $e');
      }
      return SystemCostStats.empty();
    }
  }

  /// Private method to track usage
  Future<void> _trackUsage({
    required String userId,
    required String usageType,
    required int tokensUsed,
    required double estimatedCost,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_costCollectionName).add({
        'userId': userId,
        'usageType': usageType,
        'tokensUsed': tokensUsed,
        'estimatedCost': estimatedCost,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0], // For easier daily queries
        'month': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}', // For monthly queries
      });

      if (kDebugMode && AIConfig.enableDetailedLogging) {
        print('💰 Tracked $usageType usage for user $userId: $tokensUsed tokens, \$${estimatedCost.toStringAsFixed(4)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking AI usage: $e');
      }
      // Don't rethrow - cost tracking failures shouldn't break AI functionality
    }
  }

  /// Calculate usage statistics from Firestore documents
  DailyUsageStats _calculateUsageStats(List<QueryDocumentSnapshot> docs) {
    double totalCost = 0;
    int totalRequests = docs.length;
    int totalTokens = 0;
    final usageTypes = <String, int>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalCost += data['estimatedCost'] as double;
      totalTokens += data['tokensUsed'] as int;
      
      final usageType = data['usageType'] as String;
      usageTypes[usageType] = (usageTypes[usageType] ?? 0) + 1;
    }

    return DailyUsageStats(
      totalCost: totalCost,
      totalRequests: totalRequests,
      totalTokens: totalTokens,
      usageTypeBreakdown: usageTypes,
    );
  }

  /// Calculate monthly usage statistics
  MonthlyUsageStats _calculateMonthlyStats(List<QueryDocumentSnapshot> docs) {
    final dailyStats = _calculateUsageStats(docs);
    final dailyBreakdown = <String, DailyUsageStats>{};

    // Group by date
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = data['date'] as String;
      
      if (!dailyBreakdown.containsKey(date)) {
        dailyBreakdown[date] = DailyUsageStats.empty();
      }
      
      // This is simplified - in practice, you'd want to recalculate properly
    }

    return MonthlyUsageStats(
      totalCost: dailyStats.totalCost,
      totalRequests: dailyStats.totalRequests,
      totalTokens: dailyStats.totalTokens,
      usageTypeBreakdown: dailyStats.usageTypeBreakdown,
      dailyBreakdown: dailyBreakdown,
      daysActive: dailyBreakdown.length,
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class DailyUsageStats {
  final double totalCost;
  final int totalRequests;
  final int totalTokens;
  final Map<String, int> usageTypeBreakdown;

  const DailyUsageStats({
    required this.totalCost,
    required this.totalRequests,
    required this.totalTokens,
    required this.usageTypeBreakdown,
  });

  factory DailyUsageStats.empty() => const DailyUsageStats(
    totalCost: 0,
    totalRequests: 0,
    totalTokens: 0,
    usageTypeBreakdown: {},
  );

  double get averageCostPerRequest => totalRequests > 0 ? totalCost / totalRequests : 0;
  double get averageTokensPerRequest => totalRequests > 0 ? totalTokens / totalRequests : 0;
}

class MonthlyUsageStats extends DailyUsageStats {
  final Map<String, DailyUsageStats> dailyBreakdown;
  final int daysActive;

  const MonthlyUsageStats({
    required super.totalCost,
    required super.totalRequests,
    required super.totalTokens,
    required super.usageTypeBreakdown,
    required this.dailyBreakdown,
    required this.daysActive,
  });

  factory MonthlyUsageStats.empty() => const MonthlyUsageStats(
    totalCost: 0,
    totalRequests: 0,
    totalTokens: 0,
    usageTypeBreakdown: {},
    dailyBreakdown: {},
    daysActive: 0,
  );

  double get averageCostPerDay => daysActive > 0 ? totalCost / daysActive : 0;
  double get averageRequestsPerDay => daysActive > 0 ? totalRequests / daysActive : 0;
}

class UsageTypeStats {
  final String usageType;
  final int requestCount;
  final int totalTokens;
  final double totalCost;

  const UsageTypeStats({
    required this.usageType,
    required this.requestCount,
    required this.totalTokens,
    required this.totalCost,
  });

  UsageTypeStats copyWith({
    String? usageType,
    int? requestCount,
    int? totalTokens,
    double? totalCost,
  }) {
    return UsageTypeStats(
      usageType: usageType ?? this.usageType,
      requestCount: requestCount ?? this.requestCount,
      totalTokens: totalTokens ?? this.totalTokens,
      totalCost: totalCost ?? this.totalCost,
    );
  }

  double get averageCostPerRequest => requestCount > 0 ? totalCost / requestCount : 0;
  double get averageTokensPerRequest => requestCount > 0 ? totalTokens / requestCount : 0;
}

class CostAlert {
  final CostAlertType type;
  final String message;
  final AlertSeverity severity;

  const CostAlert({
    required this.type,
    required this.message,
    required this.severity,
  });
}

enum CostAlertType {
  dailyCostLimit,
  dailyRequestLimit,
  monthlyCostLimit,
  monthlyRequestLimit,
  dailyCostWarning,
  monthlyCostWarning,
}

enum AlertSeverity {
  low,
  medium,
  high,
}

class SystemCostStats {
  final double totalCost;
  final int totalRequests;
  final int totalTokens;
  final int uniqueUsers;
  final Map<String, int> usageTypeBreakdown;
  final String period;

  const SystemCostStats({
    required this.totalCost,
    required this.totalRequests,
    required this.totalTokens,
    required this.uniqueUsers,
    required this.usageTypeBreakdown,
    required this.period,
  });

  factory SystemCostStats.empty() => const SystemCostStats(
    totalCost: 0,
    totalRequests: 0,
    totalTokens: 0,
    uniqueUsers: 0,
    usageTypeBreakdown: {},
    period: '',
  );

  double get averageCostPerUser => uniqueUsers > 0 ? totalCost / uniqueUsers : 0;
  double get averageRequestsPerUser => uniqueUsers > 0 ? totalRequests / uniqueUsers : 0;
} 