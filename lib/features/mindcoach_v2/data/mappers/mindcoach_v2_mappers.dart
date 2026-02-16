import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

class MindCoachV2Mappers {
  MindCoachV2Mappers._();

  static MindCoachV2GenerateResponse parseGenerateResponse(
    Map<String, dynamic> map, {
    required String userId,
  }) {
    final sessionId = (map['session_id'] ?? '').toString();
    final contextMode = MindCoachV2ContextModeX.fromWire(
      map['context_mode']?.toString(),
    );
    final uiMode = MindCoachV2UiModeX.fromWire(map['ui_mode']?.toString());

    final rawSession = (map['session'] is Map)
        ? Map<String, dynamic>.from(map['session'] as Map)
        : <String, dynamic>{};

    final session = MindCoachV2Session.fromApi(
      rawSession,
      sessionId: sessionId,
      userId: userId,
      contextMode: contextMode,
    );

    return MindCoachV2GenerateResponse(
      sessionId: sessionId,
      contextMode: contextMode,
      uiMode: uiMode,
      session: session,
      runId: map['run_id']?.toString(),
    );
  }

  static MindCoachV2CompleteResponse parseCompleteResponse(
    Map<String, dynamic> map,
  ) {
    return MindCoachV2CompleteResponse(
      runId: (map['run_id'] ?? '').toString(),
      favoriteSaved: map['favorite_saved'] == true,
    );
  }
}
