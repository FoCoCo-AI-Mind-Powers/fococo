import 'package:cloud_firestore/cloud_firestore.dart';

enum MindCoachV2ContextMode {
  auto,
  beforeRound,
  duringRound,
  afterRound,
  offDay,
}

extension MindCoachV2ContextModeX on MindCoachV2ContextMode {
  String get wireValue {
    switch (this) {
      case MindCoachV2ContextMode.auto:
        return 'auto';
      case MindCoachV2ContextMode.beforeRound:
        return 'before_round';
      case MindCoachV2ContextMode.duringRound:
        return 'during_round';
      case MindCoachV2ContextMode.afterRound:
        return 'after_round';
      case MindCoachV2ContextMode.offDay:
        return 'off_day';
    }
  }

  static MindCoachV2ContextMode fromWire(String? value) {
    switch (value) {
      case 'before_round':
        return MindCoachV2ContextMode.beforeRound;
      case 'during_round':
        return MindCoachV2ContextMode.duringRound;
      case 'after_round':
        return MindCoachV2ContextMode.afterRound;
      case 'off_day':
        return MindCoachV2ContextMode.offDay;
      case 'auto':
      default:
        return MindCoachV2ContextMode.auto;
    }
  }
}

enum MindCoachV2UiMode {
  liveMinimal,
  guidedExtended,
}

extension MindCoachV2UiModeX on MindCoachV2UiMode {
  String get wireValue {
    switch (this) {
      case MindCoachV2UiMode.liveMinimal:
        return 'live_minimal';
      case MindCoachV2UiMode.guidedExtended:
        return 'guided_extended';
    }
  }

  static MindCoachV2UiMode fromWire(String? value) {
    switch (value) {
      case 'live_minimal':
        return MindCoachV2UiMode.liveMinimal;
      case 'guided_extended':
      default:
        return MindCoachV2UiMode.guidedExtended;
    }
  }
}

enum MindCoachV2CompletionStatus {
  completed,
  abandoned,
  autoDismissed,
}

extension MindCoachV2CompletionStatusX on MindCoachV2CompletionStatus {
  String get wireValue {
    switch (this) {
      case MindCoachV2CompletionStatus.completed:
        return 'completed';
      case MindCoachV2CompletionStatus.abandoned:
        return 'abandoned';
      case MindCoachV2CompletionStatus.autoDismissed:
        return 'auto_dismissed';
    }
  }
}

class MindCoachV2GenerateRequest {
  MindCoachV2GenerateRequest({
    required this.contextMode,
    required this.entrySource,
    this.userMessage,
    this.mindsetBefore,
    this.preferredDeliveryLength = 'auto',
    this.goal,
    this.tone = 'auto',
    this.varkMode = 'auto',
  });

  final MindCoachV2ContextMode contextMode;
  final String entrySource;
  final String? userMessage;
  final String? mindsetBefore;
  final String preferredDeliveryLength;
  final String? goal;
  final String tone;
  final String varkMode;

  Map<String, dynamic> toMap() {
    return {
      'context_mode': contextMode.wireValue,
      'entry_source': entrySource,
      if (userMessage != null && userMessage!.isNotEmpty)
        'user_message': userMessage,
      if (mindsetBefore != null && mindsetBefore!.isNotEmpty)
        'mindset_before': mindsetBefore,
      'preferred_delivery_length': preferredDeliveryLength,
      'customization': {
        if (goal != null && goal!.isNotEmpty) 'goal': goal,
        'tone': tone,
        'vark_mode': varkMode,
      },
    };
  }
}

class MindCoachV2CompleteRequest {
  MindCoachV2CompleteRequest({
    required this.sessionId,
    required this.completionStatus,
    this.runId,
    this.mindsetAfter,
    this.helpfulnessRating,
    this.saveFavorite = false,
  });

  final String sessionId;
  final MindCoachV2CompletionStatus completionStatus;
  final String? runId;
  final String? mindsetAfter;
  final int? helpfulnessRating;
  final bool saveFavorite;

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      if (runId != null && runId!.isNotEmpty) 'run_id': runId,
      'completion_status': completionStatus.wireValue,
      if (mindsetAfter != null && mindsetAfter!.isNotEmpty)
        'mindset_after': mindsetAfter,
      if (helpfulnessRating != null) 'helpfulness_rating': helpfulnessRating,
      'save_favorite': saveFavorite,
    };
  }
}

class MindCoachV2TimedLine {
  const MindCoachV2TimedLine({
    required this.text,
    required this.startMs,
    required this.durationMs,
    this.endMs,
  });

  final String text;
  final int startMs;
  final int durationMs;
  final int? endMs;
}

class MindCoachV2Session {
  MindCoachV2Session({
    required this.sessionId,
    required this.schemaVersion,
    required this.userId,
    required this.contextMode,
    required this.templateId,
    required this.routineType,
    required this.recommendedCue,
    required this.deliveryLength,
    required this.coachingText,
    required this.validatorStatus,
    required this.modelVersion,
    required this.promptVersion,
    this.followUpQuestion,
    this.contentId,
    this.scenarioTags = const <String>[],
    this.createdAt,
    this.lines,
    this.totalDurationSec,
    this.varkModeSelected,
    this.levelSelected,
  });

  final String sessionId;
  final String schemaVersion;
  final String userId;
  final MindCoachV2ContextMode contextMode;
  final String templateId;
  final String routineType;
  final String recommendedCue;
  final String deliveryLength;
  final String coachingText;
  final String? followUpQuestion;
  final String validatorStatus;
  final String modelVersion;
  final String promptVersion;
  final String? contentId;
  final List<String> scenarioTags;
  final DateTime? createdAt;
  final List<MindCoachV2TimedLine>? lines;
  final int? totalDurationSec;
  final String? varkModeSelected;
  final String? levelSelected;

  factory MindCoachV2Session.fromApi(
    Map<String, dynamic> map, {
    required String sessionId,
    required String userId,
    required MindCoachV2ContextMode contextMode,
  }) {
    return MindCoachV2Session(
      sessionId: sessionId,
      schemaVersion:
          (map['schema_version'] ?? 'mindcoach_session_v2').toString(),
      userId: userId,
      contextMode: contextMode,
      templateId: (map['template_id'] ?? '').toString(),
      routineType: (map['routine_type'] ?? '').toString(),
      recommendedCue: (map['recommended_cue'] ?? '').toString(),
      deliveryLength: (map['delivery_length'] ?? 'standard').toString(),
      coachingText: (map['coaching_text'] ?? '').toString(),
      followUpQuestion: map['follow_up_question']?.toString(),
      validatorStatus: (map['validator_status'] ?? 'PASS').toString(),
      modelVersion: (map['model_version'] ?? 'unknown').toString(),
      promptVersion:
          (map['prompt_version'] ?? 'mindcoach_system_v1').toString(),
      contentId: map['content_id']?.toString(),
      scenarioTags: _stringList(map['scenario_tags']),
      lines: _parseTimedLines(map['lines']),
      totalDurationSec: _parseInt(map['total_duration_sec']),
      varkModeSelected: map['vark_mode_selected']?.toString(),
      levelSelected: map['level_selected']?.toString(),
    );
  }

  factory MindCoachV2Session.fromFirestore(
    String docId,
    Map<String, dynamic> map,
  ) {
    final contextRaw =
        (map['context_mode'] ?? map['contextMode'] ?? 'off_day').toString();
    return MindCoachV2Session(
      sessionId: docId,
      schemaVersion: (map['schema_version'] ??
              map['schemaVersion'] ??
              'mindcoach_session_v2')
          .toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      contextMode: MindCoachV2ContextModeX.fromWire(contextRaw),
      templateId: (map['template_id'] ?? map['templateId'] ?? '').toString(),
      routineType: (map['routine_type'] ?? map['routineType'] ?? '').toString(),
      recommendedCue:
          (map['recommended_cue'] ?? map['cueUsed'] ?? '').toString(),
      deliveryLength:
          (map['delivery_length'] ?? map['deliveryLength'] ?? 'standard')
              .toString(),
      coachingText:
          (map['coaching_text'] ?? map['coachingText'] ?? '').toString(),
      followUpQuestion:
          (map['follow_up_question'] ?? map['followUpQuestion'])?.toString(),
      validatorStatus:
          (map['validator_status'] ?? map['validatorStatus'] ?? 'PASS')
              .toString(),
      modelVersion:
          (map['model_version'] ?? map['modelVersion'] ?? 'unknown').toString(),
      promptVersion: (map['prompt_version'] ??
              map['promptVersion'] ??
              'mindcoach_system_v1')
          .toString(),
      contentId: (map['content_id'] ?? map['contentId'])?.toString(),
      scenarioTags: _stringList(map['scenario_tags'] ?? map['scenarioTags']),
      createdAt: _timestampToDate(map['created_at'] ?? map['createdTime']),
      lines: _parseTimedLines(map['lines']),
      totalDurationSec:
          _parseInt(map['total_duration_sec'] ?? map['totalDurationSec']),
      varkModeSelected:
          (map['vark_mode_selected'] ?? map['varkModeSelected'])?.toString(),
      levelSelected:
          (map['level_selected'] ?? map['levelSelected'])?.toString(),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw == null) {
      return const <String>[];
    }
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static List<MindCoachV2TimedLine>? _parseTimedLines(dynamic raw) {
    if (raw == null || raw is! List || raw.isEmpty) {
      return null;
    }
    final out = <MindCoachV2TimedLine>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final text = (item['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;
      final startMs = _parseInt(item['startMs']) ?? 0;
      final durationMs = _parseInt(item['durationMs']) ?? 2500;
      final endMs = _parseInt(item['endMs'] ?? item['end_ms']);
      out.add(MindCoachV2TimedLine(
        text: text,
        startMs: startMs,
        durationMs: durationMs,
        endMs: endMs ?? (startMs + durationMs),
      ));
    }
    return out.isEmpty ? null : out;
  }

  static int? _parseInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static DateTime? _timestampToDate(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

class MindCoachV2GenerateResponse {
  MindCoachV2GenerateResponse({
    required this.sessionId,
    required this.contextMode,
    required this.uiMode,
    required this.session,
    this.runId,
  });

  final String sessionId;
  final MindCoachV2ContextMode contextMode;
  final MindCoachV2UiMode uiMode;
  final MindCoachV2Session session;
  final String? runId;
}

class MindCoachV2CompleteResponse {
  MindCoachV2CompleteResponse({
    required this.runId,
    required this.favoriteSaved,
  });

  final String runId;
  final bool favoriteSaved;
}

class MindCoachV2SessionRun {
  MindCoachV2SessionRun({
    required this.runId,
    required this.sessionId,
    required this.userId,
    required this.status,
    required this.startedAt,
    this.completedAt,
  });

  final String runId;
  final String sessionId;
  final String userId;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;

  factory MindCoachV2SessionRun.fromFirestore(
    String docId,
    Map<String, dynamic> map,
  ) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) {
        return raw.toDate();
      }
      if (raw is DateTime) {
        return raw;
      }
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return MindCoachV2SessionRun(
      runId: docId,
      sessionId: (map['session_id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      status: (map['status'] ?? 'in_progress').toString(),
      startedAt: parseDate(map['started_at']),
      completedAt:
          map['completed_at'] == null ? null : parseDate(map['completed_at']),
    );
  }
}
