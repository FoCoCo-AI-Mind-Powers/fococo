import 'package:cloud_firestore/cloud_firestore.dart';

int? _mindCoachParseInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

enum MindCoachV2Pillar {
  focus,
  confidence,
  control,
}

extension MindCoachV2PillarX on MindCoachV2Pillar {
  String get wireValue {
    switch (this) {
      case MindCoachV2Pillar.focus:
        return 'focus';
      case MindCoachV2Pillar.confidence:
        return 'confidence';
      case MindCoachV2Pillar.control:
        return 'control';
    }
  }

  String get label {
    switch (this) {
      case MindCoachV2Pillar.focus:
        return 'FOCUS';
      case MindCoachV2Pillar.confidence:
        return 'CONFIDENCE';
      case MindCoachV2Pillar.control:
        return 'CONTROL';
    }
  }

  static MindCoachV2Pillar fromWire(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'confidence':
        return MindCoachV2Pillar.confidence;
      case 'control':
        return MindCoachV2Pillar.control;
      case 'focus':
      default:
        return MindCoachV2Pillar.focus;
    }
  }
}

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

  String get displayLabel {
    switch (this) {
      case MindCoachV2ContextMode.beforeRound:
        return 'Before Round';
      case MindCoachV2ContextMode.duringRound:
        return 'During Round';
      case MindCoachV2ContextMode.afterRound:
        return 'After Round';
      case MindCoachV2ContextMode.offDay:
        return 'Off Day';
      case MindCoachV2ContextMode.auto:
        return 'Auto';
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
    this.pillar,
    this.sessionKey,
    this.sessionName,
    this.sessionDescriptor,
    this.targetDurationSec,
    this.userMessage,
    this.mindsetBefore,
    this.preferredDeliveryLength = 'auto',
    this.goal,
    this.tone = 'auto',
    this.varkMode = 'auto',
  });

  final MindCoachV2ContextMode contextMode;
  final String entrySource;
  final MindCoachV2Pillar? pillar;
  final String? sessionKey;
  final String? sessionName;
  final String? sessionDescriptor;
  final int? targetDurationSec;
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
      if (pillar != null) 'pillar': pillar!.wireValue,
      if (sessionKey != null && sessionKey!.isNotEmpty) 'session_key': sessionKey,
      if (sessionName != null && sessionName!.isNotEmpty)
        'session_name': sessionName,
      if (sessionDescriptor != null && sessionDescriptor!.isNotEmpty)
        'session_descriptor': sessionDescriptor,
      if (targetDurationSec != null) 'target_duration_sec': targetDurationSec,
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
  });

  final String sessionId;
  final MindCoachV2CompletionStatus completionStatus;
  final String? runId;
  final String? mindsetAfter;

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      if (runId != null && runId!.isNotEmpty) 'run_id': runId,
      'completion_status': completionStatus.wireValue,
      if (mindsetAfter != null && mindsetAfter!.isNotEmpty)
        'mindset_after': mindsetAfter,
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

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'startMs': startMs,
      'durationMs': durationMs,
      'endMs': endMs ?? (startMs + durationMs),
    };
  }

  factory MindCoachV2TimedLine.fromMap(Map<String, dynamic> map) {
    final startMs = _mindCoachParseInt(map['startMs']) ?? 0;
    final durationMs = _mindCoachParseInt(map['durationMs']) ?? 2500;
    final endMs = _mindCoachParseInt(map['endMs'] ?? map['end_ms']);
    return MindCoachV2TimedLine(
      text: (map['text'] ?? '').toString().trim(),
      startMs: startMs,
      durationMs: durationMs,
      endMs: endMs ?? (startMs + durationMs),
    );
  }
}

class MindCoachV2Session {
  MindCoachV2Session({
    required this.sessionId,
    required this.schemaVersion,
    required this.userId,
    required this.pillar,
    required this.contextMode,
    required this.templateId,
    required this.sessionKey,
    required this.sessionName,
    required this.sessionDescriptor,
    required this.durationSec,
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
  final MindCoachV2Pillar pillar;
  final MindCoachV2ContextMode contextMode;
  final String templateId;
  final String sessionKey;
  final String sessionName;
  final String sessionDescriptor;
  final int durationSec;
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

  String get topBarTitle =>
      '${contextMode.displayLabel} · ${durationSec.round()} sec';

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'user_id': userId,
      'pillar': pillar.wireValue,
      'context_mode': contextMode.wireValue,
      'template_id': templateId,
      'session_key': sessionKey,
      'session_name': sessionName,
      'session_descriptor': sessionDescriptor,
      'duration_sec': durationSec,
      'routine_type': routineType,
      'recommended_cue': recommendedCue,
      'delivery_length': deliveryLength,
      'coaching_text': coachingText,
      'follow_up_question': followUpQuestion,
      'validator_status': validatorStatus,
      'model_version': modelVersion,
      'prompt_version': promptVersion,
      'content_id': contentId,
      'scenario_tags': scenarioTags,
      'vark_mode_selected': varkModeSelected,
      'level_selected': levelSelected,
      if (lines != null) 'lines': lines!.map((line) => line.toMap()).toList(),
      if (totalDurationSec != null) 'total_duration_sec': totalDurationSec,
    };
  }

  factory MindCoachV2Session.fromApi(
    Map<String, dynamic> map, {
    required String sessionId,
    required String userId,
    required MindCoachV2ContextMode contextMode,
  }) {
    final templateId = (map['template_id'] ?? '').toString();
    return MindCoachV2Session(
      sessionId: sessionId,
      schemaVersion:
          (map['schema_version'] ?? 'mindcoach_session_v2').toString(),
      userId: userId,
      pillar: MindCoachV2PillarX.fromWire(
        map['pillar']?.toString() ?? _inferPillarFromTemplate(templateId),
      ),
      contextMode: contextMode,
      templateId: templateId,
      sessionKey: (map['session_key'] ?? templateId).toString(),
      sessionName: (map['session_name'] ?? map['routine_type'] ?? '')
          .toString(),
      sessionDescriptor:
          (map['session_descriptor'] ?? map['follow_up_question'] ?? '')
              .toString(),
      durationSec: _parseInt(map['duration_sec']) ??
          _parseInt(map['total_duration_sec']) ??
          0,
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
    final templateId = (map['template_id'] ?? map['templateId'] ?? '').toString();
    final routineType = (map['routine_type'] ?? map['routineType'] ?? '').toString();
    return MindCoachV2Session(
      sessionId: docId,
      schemaVersion: (map['schema_version'] ??
              map['schemaVersion'] ??
              'mindcoach_session_v2')
          .toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      pillar: MindCoachV2PillarX.fromWire(
        map['pillar']?.toString() ?? _inferPillarFromTemplate(templateId),
      ),
      contextMode: MindCoachV2ContextModeX.fromWire(contextRaw),
      templateId: templateId,
      sessionKey: (map['session_key'] ?? map['sessionKey'] ?? templateId)
          .toString(),
      sessionName:
          (map['session_name'] ?? map['sessionName'] ?? routineType).toString(),
      sessionDescriptor: (map['session_descriptor'] ??
              map['sessionDescriptor'] ??
              map['follow_up_question'] ??
              map['followUpQuestion'] ??
              '')
          .toString(),
      durationSec: _parseInt(map['duration_sec'] ?? map['durationSec']) ??
          _parseInt(map['total_duration_sec'] ?? map['totalDurationSec']) ??
          0,
      routineType: routineType,
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

  static String _inferPillarFromTemplate(String templateId) {
    switch (templateId) {
      case 'MC_T06_PRESSURE_MOMENTS':
      case 'MC_T07_MOMENTUM_PROTECTION':
        return 'confidence';
      case 'MC_T03_BETWEEN_SHOTS_RESET':
      case 'MC_T05_MISTAKE_RECOVERY':
        return 'control';
      case 'MC_T01_PRE_ROUND_CLARITY':
      case 'MC_T02_PRE_SHOT_FOCUS':
      case 'MC_T04_POST_SHOT_LETTING_GO':
      case 'MC_T08_END_OF_ROUND_REFLECTION':
      case 'MC_T09_POST_ROUND_INSIGHT':
      default:
        return 'focus';
    }
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
      final line = MindCoachV2TimedLine.fromMap(Map<String, dynamic>.from(item));
      if (line.text.isEmpty) continue;
      out.add(line);
    }
    return out.isEmpty ? null : out;
  }

  static int? _parseInt(dynamic raw) {
    return _mindCoachParseInt(raw);
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

class MindCoachV2Favorite {
  MindCoachV2Favorite({
    required this.favoriteId,
    required this.userId,
    required this.pillar,
    required this.contextMode,
    required this.sessionKey,
    required this.sessionName,
    required this.sessionDescriptor,
    required this.durationSec,
    required this.templateId,
    required this.savedAt,
    required this.session,
  });

  final String favoriteId;
  final String userId;
  final MindCoachV2Pillar pillar;
  final MindCoachV2ContextMode contextMode;
  final String sessionKey;
  final String sessionName;
  final String sessionDescriptor;
  final int durationSec;
  final String templateId;
  final DateTime? savedAt;
  final MindCoachV2Session session;

  factory MindCoachV2Favorite.fromFirestore(
    String docId,
    Map<String, dynamic> map,
  ) {
    final payload = (map['session_payload'] is Map)
        ? Map<String, dynamic>.from(map['session_payload'] as Map)
        : <String, dynamic>{};
    final sessionId = (map['session_id'] ?? payload['session_id'] ?? docId)
        .toString();
    final sessionMap = <String, dynamic>{
      ...payload,
      if (!payload.containsKey('user_id') && map['user_id'] != null)
        'user_id': map['user_id'],
      if (!payload.containsKey('pillar') && map['pillar'] != null)
        'pillar': map['pillar'],
      if (!payload.containsKey('context_mode') && map['context_mode'] != null)
        'context_mode': map['context_mode'],
    };

    final session = MindCoachV2Session.fromFirestore(sessionId, sessionMap);
    return MindCoachV2Favorite(
      favoriteId: docId,
      userId: (map['user_id'] ?? '').toString(),
      pillar: MindCoachV2PillarX.fromWire(map['pillar']?.toString()),
      contextMode:
          MindCoachV2ContextModeX.fromWire(map['context_mode']?.toString()),
      sessionKey: (map['session_key'] ?? '').toString(),
      sessionName: (map['session_name'] ?? '').toString(),
      sessionDescriptor: (map['session_descriptor'] ?? '').toString(),
      durationSec: MindCoachV2Session._parseInt(map['duration_sec']) ?? 0,
      templateId: (map['template_id'] ?? '').toString(),
      savedAt: MindCoachV2Session._timestampToDate(map['saved_at']),
      session: session,
    );
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
    this.reflection,
  });

  final String runId;
  final String? reflection;
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
