import 'package:flutter/foundation.dart';

import '/backend/schema/index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Utility functions for AI integration
class AIUtils {
  AIUtils._();

  // ============================================================================
  // TOKEN ESTIMATION
  // ============================================================================

  /// Estimate token count for text (rough approximation)
  /// OpenAI's actual tokenization is more complex, but this gives a reasonable estimate
  static int estimateTokenCount(String text) {
    if (text.isEmpty) return 0;
    
    // Rough approximation: 1 token ≈ 4 characters for English text
    // This is a simplified estimate - actual tokenization varies by model
    const averageCharsPerToken = 4;
    return (text.length / averageCharsPerToken).ceil();
  }

  /// Estimate tokens for a chat completion request
  static int estimateRequestTokens({
    required String systemPrompt,
    required String userPrompt,
    int estimatedResponseTokens = 500,
  }) {
    final systemTokens = estimateTokenCount(systemPrompt);
    final userTokens = estimateTokenCount(userPrompt);
    
    // Add some overhead for message formatting
    const messageOverhead = 10;
    
    return systemTokens + userTokens + estimatedResponseTokens + messageOverhead;
  }

  /// Check if text is within token limit
  static bool isWithinTokenLimit(String text, int maxTokens) {
    return estimateTokenCount(text) <= maxTokens;
  }

  /// Truncate text to fit within token limit
  static String truncateToTokenLimit(String text, int maxTokens) {
    final estimatedTokens = estimateTokenCount(text);
    if (estimatedTokens <= maxTokens) return text;
    
    // Estimate how much to truncate
    const averageCharsPerToken = 4;
    final targetLength = maxTokens * averageCharsPerToken;
    
    if (text.length <= targetLength) return text;
    
    // Truncate and add ellipsis
    return '${text.substring(0, targetLength - 3)}...';
  }

  // ============================================================================
  // PROMPT SANITIZATION
  // ============================================================================

  /// Sanitize user input for AI prompts
  static String sanitizePromptInput(String input) {
    if (input.isEmpty) return input;
    
    String sanitized = input;
    
    // Remove potentially harmful characters
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\s\.,!?;:-]'), '');
    
    // Limit length
    const maxInputLength = 2000;
    if (sanitized.length > maxInputLength) {
      sanitized = '${sanitized.substring(0, maxInputLength)}...';
    }
    
    // Remove excessive whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return sanitized;
  }

  /// Clean and format golf round data for AI prompts
  static Map<String, dynamic> formatRoundDataForPrompt(GolfRoundsRecord round) {
    return {
      'course': sanitizePromptInput(round.courseName),
      'date': round.date?.toIso8601String().split('T')[0] ?? 'Unknown',
      'score': round.score,
      'par': round.parTotal,
      'scoreToPar': round.scoreToPar,
      'mentalFocus': round.mentalFocus,
      'courseManagement': round.courseManagement,
      'emotionalControl': round.emotionalControl,
      'preRoundMood': sanitizePromptInput(round.preRoundMood),
      'postRoundMood': sanitizePromptInput(round.postRoundMood),
      'notes': sanitizePromptInput(round.notes),
      'lessonsLearned': sanitizePromptInput(round.lessonsLearned),
      'keyMoments': sanitizePromptInput(round.keyMoments),
    };
  }

  /// Format user profile data for AI prompts
  static Map<String, dynamic> formatUserProfileForPrompt(UserRecord user) {
    return {
      'handicap': user.handicap,
      'experience': sanitizePromptInput(user.golfExperience),
      'mentalPerformanceScore': user.mentalPerformanceScore,
      'coachingStreak': user.coachingStreak,
      'totalModulesCompleted': user.totalModulesCompleted,
      'varkPreferences': {
        'visual': user.varkPreferences.visual,
        'aural': user.varkPreferences.aural,
        'readWrite': user.varkPreferences.readWrite,
        'kinesthetic': user.varkPreferences.kinesthetic,
      },
    };
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is AIException) {
      // Retry on server errors, rate limits, but not on authentication or bad requests
      return error.statusCode != null && 
             error.statusCode! >= 500 ||
             error.statusCode == 429; // Rate limit
    }
    
    // Retry on network errors
    return error.toString().toLowerCase().contains('network') ||
           error.toString().toLowerCase().contains('timeout') ||
           error.toString().toLowerCase().contains('connection');
  }

  /// Get user-friendly error message
  static String getUserFriendlyErrorMessage(dynamic error) {
    if (error is AIException) {
      switch (error.statusCode) {
        case 401:
          return 'AI service authentication failed. Please try again later.';
        case 403:
          return 'AI service access denied. Please check your subscription.';
        case 429:
          return 'AI service is busy. Please wait a moment and try again.';
        case 500:
        case 502:
        case 503:
          return 'AI service is temporarily unavailable. Please try again later.';
        default:
          return 'AI service error: ${error.message}';
      }
    }
    
    if (error.toString().toLowerCase().contains('network')) {
      return 'Network connection issue. Please check your internet connection.';
    }
    
    if (error.toString().toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Validate AI response structure
  static bool validateAIResponse(Map<String, dynamic> response) {
    try {
      // Check for required OpenAI response structure
      if (!response.containsKey('choices') || 
          !response.containsKey('usage') ||
          response['choices'] is! List ||
          (response['choices'] as List).isEmpty) {
        return false;
      }
      
      final choice = response['choices'][0] as Map<String, dynamic>;
      if (!choice.containsKey('message') ||
          choice['message'] is! Map<String, dynamic>) {
        return false;
      }
      
      final message = choice['message'] as Map<String, dynamic>;
      if (!message.containsKey('content') ||
          message['content'] is! String) {
        return false;
      }
      
      // Try to parse the content as JSON
      final content = message['content'] as String;
      jsonDecode(content);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AI response validation failed: $e');
      }
      return false;
    }
  }

  /// Validate insight response structure
  static bool validateInsightResponse(Map<String, dynamic> insightData) {
    final requiredFields = [
      'insightTitle',
      'category',
      'priority',
      'keyPoints',
      'recommendations',
      'personalizedElements',
      'summaryText'
    ];
    
    for (final field in requiredFields) {
      if (!insightData.containsKey(field)) {
        if (kDebugMode) {
          print('❌ Missing required field in insight response: $field');
        }
        return false;
      }
    }
    
    // Validate specific field types
    if (insightData['keyPoints'] is! List ||
        insightData['recommendations'] is! List ||
        insightData['personalizedElements'] is! List) {
      if (kDebugMode) {
        print('❌ Invalid field types in insight response');
      }
      return false;
    }
    
    return true;
  }

  // ============================================================================
  // CACHING & OPTIMIZATION
  // ============================================================================

  /// Generate cache key for AI requests
  static String generateCacheKey({
    required String userId,
    required String requestType,
    required Map<String, dynamic> parameters,
  }) {
    final sortedParams = Map.fromEntries(
      parameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    final paramString = jsonEncode(sortedParams);
    final combined = '$userId:$requestType:$paramString';
    
    // Generate a hash for the cache key
    return combined.hashCode.abs().toString();
  }

  /// Check if request should be cached
  static bool shouldCacheRequest(String requestType) {
    // Don't cache real-time or personalized requests
    const nonCacheableTypes = [
      'session_feedback',
      'real_time_analysis',
    ];
    
    return !nonCacheableTypes.contains(requestType);
  }

  // ============================================================================
  // PERFORMANCE METRICS
  // ============================================================================

  /// Calculate AI response quality score
  static double calculateResponseQualityScore({
    required int userRating,
    required String userFeedback,
    required int tokensUsed,
    required double responseTime,
  }) {
    double score = 0;
    
    // User rating component (40% of score)
    score += (userRating / 5.0) * 0.4;
    
    // Feedback sentiment (20% of score)
    final feedbackScore = _analyzeFeedbackSentiment(userFeedback);
    score += feedbackScore * 0.2;
    
    // Efficiency component (20% of score)
    // Lower token usage for same quality is better
    const optimalTokens = 1000;
    final efficiencyScore = min(1.0, optimalTokens / tokensUsed);
    score += efficiencyScore * 0.2;
    
    // Response time component (20% of score)
    // Faster responses are better
    const optimalResponseTime = 3.0; // 3 seconds
    final speedScore = min(1.0, optimalResponseTime / responseTime);
    score += speedScore * 0.2;
    
    return score.clamp(0.0, 1.0);
  }

  /// Simple sentiment analysis for feedback
  static double _analyzeFeedbackSentiment(String feedback) {
    if (feedback.isEmpty) return 0.5; // neutral
    
    final positiveWords = ['good', 'great', 'excellent', 'helpful', 'useful', 'accurate', 'insightful'];
    final negativeWords = ['bad', 'poor', 'wrong', 'unhelpful', 'useless', 'inaccurate', 'confusing'];
    
    final words = feedback.toLowerCase().split(' ');
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in words) {
      if (positiveWords.contains(word)) positiveCount++;
      if (negativeWords.contains(word)) negativeCount++;
    }
    
    if (positiveCount + negativeCount == 0) return 0.5; // neutral
    
    return positiveCount / (positiveCount + negativeCount);
  }

  // ============================================================================
  // CONTENT FILTERING
  // ============================================================================

  /// Check if content is appropriate
  static bool isContentAppropriate(String content) {
    // Simple content filtering - in production, you might use more sophisticated methods
    final inappropriatePatterns = [
      RegExp(r'(hate|violence|explicit)', caseSensitive: false),
      // Add more patterns as needed
    ];
    
    for (final pattern in inappropriatePatterns) {
      if (pattern.hasMatch(content)) {
        return false;
      }
    }
    
    return true;
  }

  /// Filter and clean AI-generated content
  static String filterAIContent(String content) {
    if (!isContentAppropriate(content)) {
      return 'Content filtered for appropriateness. Please try again.';
    }
    
    // Remove any potential injection attempts
    String filtered = content;
    
    // Remove script tags and other potentially harmful content
    filtered = filtered.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
    filtered = filtered.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    
    return filtered;
  }

  // ============================================================================
  // DEBUGGING & LOGGING
  // ============================================================================

  /// Log AI request details
  static void logAIRequest({
    required String userId,
    required String requestType,
    required int estimatedTokens,
    required double estimatedCost,
  }) {
    if (kDebugMode) {
      print('🤖 AI Request: $requestType for user $userId');
      print('📊 Estimated tokens: $estimatedTokens');
      print('💰 Estimated cost: \$${estimatedCost.toStringAsFixed(4)}');
    }
  }

  /// Log AI response details
  static void logAIResponse({
    required String requestType,
    required int actualTokens,
    required double actualCost,
    required Duration responseTime,
  }) {
    if (kDebugMode) {
      print('✅ AI Response: $requestType completed');
      print('📊 Actual tokens: $actualTokens');
      print('💰 Actual cost: \$${actualCost.toStringAsFixed(4)}');
      print('⏱️ Response time: ${responseTime.inMilliseconds}ms');
    }
  }
}

/// Custom exception for AI-related errors
class AIException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorType;

  const AIException({
    required this.message,
    this.statusCode,
    this.errorType,
  });

  @override
  String toString() => 'AIException: $message (Status: $statusCode, Type: $errorType)';
} 