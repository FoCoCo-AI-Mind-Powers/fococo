/// Data models for Mind Coach Studio features

class MindCoachInsight {
  final String insightText;
  final String suggestionType; // 'consistency', 'recovery', 'exploration'
  final String? recommendedModuleId;
  final int priority; // Higher = more important
  final String? recommendedModuleTitle;
  final String? actionText; // Custom action text if needed

  MindCoachInsight({
    required this.insightText,
    required this.suggestionType,
    this.recommendedModuleId,
    this.priority = 0,
    this.recommendedModuleTitle,
    this.actionText,
  });

  Map<String, dynamic> toMap() {
    return {
      'insightText': insightText,
      'suggestionType': suggestionType,
      'recommendedModuleId': recommendedModuleId,
      'priority': priority,
      'recommendedModuleTitle': recommendedModuleTitle,
      'actionText': actionText,
    };
  }

  factory MindCoachInsight.fromMap(Map<String, dynamic> map) {
    return MindCoachInsight(
      insightText: map['insightText'] ?? '',
      suggestionType: map['suggestionType'] ?? 'exploration',
      recommendedModuleId: map['recommendedModuleId'],
      priority: map['priority'] ?? 0,
      recommendedModuleTitle: map['recommendedModuleTitle'],
      actionText: map['actionText'],
    );
  }
}

class PillarStatus {
  final String pillar; // 'focus', 'confidence', 'control'
  final String status; // 'getting_sharper', 'strongest_area', 'needs_attention'
  final double score; // 0-100
  final double trend; // positive/negative trend (-1 to 1)

  PillarStatus({
    required this.pillar,
    required this.status,
    required this.score,
    required this.trend,
  });

  String get statusMessage {
    switch (status) {
      case 'strongest_area':
        return 'Your strongest area this week';
      case 'getting_sharper':
        return 'Getting sharper';
      case 'needs_attention':
        return 'Needs attention';
      default:
        return 'In progress';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'pillar': pillar,
      'status': status,
      'score': score,
      'trend': trend,
    };
  }

  factory PillarStatus.fromMap(Map<String, dynamic> map) {
    return PillarStatus(
      pillar: map['pillar'] ?? '',
      status: map['status'] ?? 'getting_sharper',
      score: (map['score'] ?? 0.0).toDouble(),
      trend: (map['trend'] ?? 0.0).toDouble(),
    );
  }
}

class WeeklyProgress {
  final int completed;
  final int target;
  final double percentage;
  final int currentStreak;

  WeeklyProgress({
    required this.completed,
    this.target = 7,
    required this.percentage,
    required this.currentStreak,
  });

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'target': target,
      'percentage': percentage,
      'currentStreak': currentStreak,
    };
  }

  factory WeeklyProgress.fromMap(Map<String, dynamic> map) {
    return WeeklyProgress(
      completed: map['completed'] ?? 0,
      target: map['target'] ?? 7,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      currentStreak: map['currentStreak'] ?? 0,
    );
  }
}


