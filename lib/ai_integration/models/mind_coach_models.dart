import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Comprehensive MindCoach Session Model matching documentation structure
class MindCoachSession {
  final String sessionId;
  final String userId;
  final DateTime timestamp;
  final String templateId; // e.g., "MC_T02_PRE_SHOT_FOCUS"
  final String? contentId; // from content library
  final String? scenarioTag;
  final String varkMode; // Visual/Aural/ReadWrite/Kinesthetic
  final String level; // Foundation/Build/Compete/Maintain
  final String length; // micro/standard/deep
  final String cueUsed;
  final String routineType;
  final int mindsetBefore; // 1-5 rating
  final int? mindsetAfter; // 1-5 rating (optional)
  final Map<String, dynamic> context; // pressure_level, pace_flag, location, weather, playing_partners
  final String coachingTextDelivered;
  final String? followUpQuestion;
  final String? userResponse;
  final Map<String, bool> successSignals; // mindset_improved, session_completed, etc.
  final String sessionType; // 'coaching' or 'breathing'

  MindCoachSession({
    required this.sessionId,
    required this.userId,
    required this.timestamp,
    required this.templateId,
    this.contentId,
    this.scenarioTag,
    required this.varkMode,
    required this.level,
    required this.length,
    required this.cueUsed,
    required this.routineType,
    required this.mindsetBefore,
    this.mindsetAfter,
    required this.context,
    required this.coachingTextDelivered,
    this.followUpQuestion,
    this.userResponse,
    required this.successSignals,
    this.sessionType = 'coaching',
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'templateId': templateId,
      'contentId': contentId,
      'scenarioTag': scenarioTag,
      'varkMode': varkMode,
      'level': level,
      'length': length,
      'cueUsed': cueUsed,
      'routineType': routineType,
      'mindsetBefore': mindsetBefore,
      'mindsetAfter': mindsetAfter,
      'context': context,
      'coachingTextDelivered': coachingTextDelivered,
      'followUpQuestion': followUpQuestion,
      'userResponse': userResponse,
      'successSignals': successSignals,
      'sessionType': sessionType,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'timestamp': timestamp,
      'templateId': templateId,
      'contentId': contentId,
      'scenarioTag': scenarioTag,
      'varkMode': varkMode,
      'level': level,
      'length': length,
      'cueUsed': cueUsed,
      'routineType': routineType,
      'mindsetBefore': mindsetBefore,
      'mindsetAfter': mindsetAfter,
      'context': context,
      'coachingText': coachingTextDelivered, // Firestore uses 'coachingText'
      'followUpQuestion': followUpQuestion,
      'userResponse': userResponse,
      'successSignalFlags': successSignals, // Firestore uses 'successSignalFlags'
      'sessionType': sessionType,
      'createdTime': timestamp,
      'updatedTime': DateTime.now(),
    };
  }

  factory MindCoachSession.fromMap(Map<String, dynamic> map) {
    return MindCoachSession(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp']
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      templateId: map['templateId'] ?? '',
      contentId: map['contentId'],
      scenarioTag: map['scenarioTag'],
      varkMode: map['varkMode'] ?? 'ReadWrite',
      level: map['level'] ?? 'Foundation',
      length: map['length'] ?? 'standard',
      cueUsed: map['cueUsed'] ?? '',
      routineType: map['routineType'] ?? '',
      mindsetBefore: map['mindsetBefore'] is int
          ? map['mindsetBefore']
          : int.tryParse(map['mindsetBefore']?.toString() ?? '3') ?? 3,
      mindsetAfter: map['mindsetAfter'] is int
          ? map['mindsetAfter']
          : map['mindsetAfter'] != null
              ? int.tryParse(map['mindsetAfter'].toString())
              : null,
      context: Map<String, dynamic>.from(map['context'] ?? {}),
      coachingTextDelivered: map['coachingTextDelivered'] ?? map['coachingText'] ?? '',
      followUpQuestion: map['followUpQuestion'],
      userResponse: map['userResponse'],
      successSignals: map['successSignals'] != null
          ? Map<String, bool>.from(
              (map['successSignals'] as Map).map((k, v) => MapEntry(k.toString(), v is bool ? v : v.toString().toLowerCase() == 'true')))
          : map['successSignalFlags'] != null
              ? Map<String, bool>.from(
                  (map['successSignalFlags'] as Map).map((k, v) => MapEntry(k.toString(), v is bool ? v : v.toString().toLowerCase() == 'true')))
              : {},
      sessionType: map['sessionType'] ?? 'coaching',
    );
  }

  factory MindCoachSession.fromFirestore(Map<String, dynamic> data, String docId) {
    return MindCoachSession(
      sessionId: docId,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      templateId: data['templateId'] ?? '',
      contentId: data['contentId'],
      scenarioTag: data['scenarioTag'],
      varkMode: data['varkMode'] ?? 'ReadWrite',
      level: data['level'] ?? 'Foundation',
      length: data['length'] ?? data['deliveryLength'] ?? 'standard',
      cueUsed: data['cueUsed'] ?? '',
      routineType: data['routineType'] ?? '',
      mindsetBefore: data['mindsetBefore'] is int
          ? data['mindsetBefore']
          : int.tryParse(data['mindsetBefore']?.toString() ?? '3') ?? 3,
      mindsetAfter: data['mindsetAfter'] is int
          ? data['mindsetAfter']
          : data['mindsetAfter'] != null
              ? int.tryParse(data['mindsetAfter'].toString())
              : null,
      context: Map<String, dynamic>.from(data['context'] ?? {}),
      coachingTextDelivered: data['coachingTextDelivered'] ?? data['coachingText'] ?? '',
      followUpQuestion: data['followUpQuestion'],
      userResponse: data['userResponse'],
      successSignals: data['successSignals'] != null
          ? Map<String, bool>.from(
              (data['successSignals'] as Map).map((k, v) => MapEntry(k.toString(), v is bool ? v : v.toString().toLowerCase() == 'true')))
          : data['successSignalFlags'] != null
              ? Map<String, bool>.from(
                  (data['successSignalFlags'] as Map).map((k, v) => MapEntry(k.toString(), v is bool ? v : v.toString().toLowerCase() == 'true')))
              : {},
      sessionType: data['sessionType'] ?? 'coaching',
    );
  }

  bool validate() {
    if (sessionId.isEmpty || userId.isEmpty || templateId.isEmpty) {
      return false;
    }
    if (mindsetBefore < 1 || mindsetBefore > 5) {
      return false;
    }
    if (mindsetAfter != null && (mindsetAfter! < 1 || mindsetAfter! > 5)) {
      return false;
    }
    return true;
  }
}

/// Breathing Session Model extending MindCoachSession
class BreathingSession extends MindCoachSession {
  final String breathingTechnique; // e.g., "4-7-8", "box_breathing"
  final int duration; // seconds
  final int cyclesCompleted;
  final int inhaleTime;
  final int holdTime;
  final int exhaleTime;

  BreathingSession({
    required super.sessionId,
    required super.userId,
    required super.timestamp,
    required this.breathingTechnique,
    required this.duration,
    required this.cyclesCompleted,
    required this.inhaleTime,
    required this.holdTime,
    required this.exhaleTime,
    super.mindsetBefore = 3,
    super.mindsetAfter,
    super.context = const {},
  }) : super(
          templateId: 'BREATHING',
          varkMode: 'Kinesthetic',
          level: 'Foundation',
          length: 'standard',
          cueUsed: breathingTechnique,
          routineType: 'Breathing Exercise',
          coachingTextDelivered: 'Breathing exercise completed',
          successSignals: {
            'session_completed': cyclesCompleted > 0,
            'mindset_improved': false, // Will be updated after completion
          },
          sessionType: 'breathing',
        );

  @override
  Map<String, dynamic> toFirestoreMap() {
    final map = super.toFirestoreMap();
    map.addAll({
      'breathingTechnique': breathingTechnique,
      'duration': duration,
      'cyclesCompleted': cyclesCompleted,
      'inhaleTime': inhaleTime,
      'holdTime': holdTime,
      'exhaleTime': exhaleTime,
    });
    return map;
  }

  factory BreathingSession.fromMap(Map<String, dynamic> map) {
    return BreathingSession(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp']
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      breathingTechnique: map['breathingTechnique'] ?? '4-7-8',
      duration: map['duration'] ?? 60,
      cyclesCompleted: map['cyclesCompleted'] ?? 0,
      inhaleTime: map['inhaleTime'] ?? 4,
      holdTime: map['holdTime'] ?? 7,
      exhaleTime: map['exhaleTime'] ?? 8,
      mindsetBefore: map['mindsetBefore'] is int
          ? map['mindsetBefore']
          : int.tryParse(map['mindsetBefore']?.toString() ?? '3') ?? 3,
      mindsetAfter: map['mindsetAfter'] is int
          ? map['mindsetAfter']
          : map['mindsetAfter'] != null
              ? int.tryParse(map['mindsetAfter'].toString())
              : null,
      context: Map<String, dynamic>.from(map['context'] ?? {}),
    );
  }

  factory BreathingSession.fromFirestore(Map<String, dynamic> data, String docId) {
    return BreathingSession(
      sessionId: docId,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      breathingTechnique: data['breathingTechnique'] ?? '4-7-8',
      duration: data['duration'] ?? 60,
      cyclesCompleted: data['cyclesCompleted'] ?? 0,
      inhaleTime: data['inhaleTime'] ?? 4,
      holdTime: data['holdTime'] ?? 7,
      exhaleTime: data['exhaleTime'] ?? 8,
      mindsetBefore: data['mindsetBefore'] is int
          ? data['mindsetBefore']
          : int.tryParse(data['mindsetBefore']?.toString() ?? '3') ?? 3,
      mindsetAfter: data['mindsetAfter'] is int
          ? data['mindsetAfter']
          : data['mindsetAfter'] != null
              ? int.tryParse(data['mindsetAfter'].toString())
              : null,
      context: Map<String, dynamic>.from(data['context'] ?? {}),
    );
  }
}

/// Content Library Entry Model
class ContentLibraryEntry {
  final String contentId;
  final String templateId;
  final String templateName;
  final String pillar;
  final String varkMode;
  final String level;
  final String length;
  final List<String> scenarioTags;
  final String? pressureLevel;
  final String? lieType;
  final String? windCondition;
  final String? regionVariant;
  final String scriptText;
  final String? ctaQuestion;
  final String? followUpPrompt;
  final String? confidenceRatingHint;
  final List<String> doNotSayFlags;

  ContentLibraryEntry({
    required this.contentId,
    required this.templateId,
    required this.templateName,
    required this.pillar,
    required this.varkMode,
    required this.level,
    required this.length,
    required this.scenarioTags,
    this.pressureLevel,
    this.lieType,
    this.windCondition,
    this.regionVariant,
    required this.scriptText,
    this.ctaQuestion,
    this.followUpPrompt,
    this.confidenceRatingHint,
    required this.doNotSayFlags,
  });

  factory ContentLibraryEntry.fromCsvRow(Map<String, dynamic> row) {
    return ContentLibraryEntry(
      contentId: row['content_id'] ?? '',
      templateId: row['template_id'] ?? '',
      templateName: row['template_name'] ?? '',
      pillar: row['pillar'] ?? '',
      varkMode: row['vark_mode'] ?? 'ReadWrite',
      level: row['level'] ?? 'Foundation',
      length: row['length'] ?? 'standard',
      scenarioTags: (row['scenario_tags'] ?? '')
          .toString()
          .split(';')
          .where((tag) => tag.trim().isNotEmpty)
          .map((tag) => tag.trim())
          .toList(),
      pressureLevel: row['pressure_level'],
      lieType: row['lie_type'],
      windCondition: row['wind_condition'],
      regionVariant: row['region_variant'],
      scriptText: row['script_text'] ?? '',
      ctaQuestion: row['cta_question'],
      followUpPrompt: row['follow_up_prompt'],
      confidenceRatingHint: row['confidence_rating_hint'],
      doNotSayFlags: (row['do_not_say_flags'] ?? '')
          .toString()
          .split(',')
          .where((flag) => flag.trim().isNotEmpty)
          .map((flag) => flag.trim())
          .toList(),
    );
  }
}

/// Scenario Tag Model
class ScenarioTag {
  final String tagId;
  final String tagName;
  final String description;
  final List<String> detectionPhrases;
  final List<String> templateAffinity;
  final List<String> contextSignals;

  ScenarioTag({
    required this.tagId,
    required this.tagName,
    required this.description,
    required this.detectionPhrases,
    required this.templateAffinity,
    required this.contextSignals,
  });

  factory ScenarioTag.fromCsvRow(Map<String, dynamic> row) {
    return ScenarioTag(
      tagId: row['scenario_tag'] ?? '',
      tagName: row['scenario_tag'] ?? '',
      description: row['description'] ?? '',
      detectionPhrases: (row['detection_phrases'] ?? '')
          .toString()
          .split(',')
          .where((phrase) => phrase.trim().isNotEmpty)
          .map((phrase) => phrase.trim())
          .toList(),
      templateAffinity: (row['template_affinity'] ?? '')
          .toString()
          .split(',')
          .where((template) => template.trim().isNotEmpty)
          .map((template) => template.trim())
          .toList(),
      contextSignals: (row['context_signals'] ?? '')
          .toString()
          .split(',')
          .where((signal) => signal.trim().isNotEmpty)
          .map((signal) => signal.trim())
          .toList(),
    );
  }
}


