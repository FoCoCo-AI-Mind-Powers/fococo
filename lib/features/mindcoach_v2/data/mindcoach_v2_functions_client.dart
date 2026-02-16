import 'package:cloud_functions/cloud_functions.dart';

import '/features/mindcoach_v2/data/mappers/mindcoach_v2_mappers.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

class MindCoachV2FunctionsClient {
  MindCoachV2FunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<MindCoachV2GenerateResponse> generateSession({
    required String userId,
    required MindCoachV2GenerateRequest request,
  }) async {
    final callable = _functions.httpsCallable('generateMindCoachSessionV2');
    try {
      final result = await callable.call(request.toMap());
      final raw = result.data;
      if (raw is! Map) {
        throw Exception('Invalid generate response payload');
      }

      return MindCoachV2Mappers.parseGenerateResponse(
        Map<String, dynamic>.from(raw),
        userId: userId,
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to generate MindCoach v2 session');
    }
  }

  Future<MindCoachV2CompleteResponse> completeRun(
    MindCoachV2CompleteRequest request,
  ) async {
    final callable = _functions.httpsCallable('completeMindCoachSessionRunV2');
    try {
      final result = await callable.call(request.toMap());
      final raw = result.data;
      if (raw is! Map) {
        throw Exception('Invalid complete response payload');
      }
      return MindCoachV2Mappers.parseCompleteResponse(
        Map<String, dynamic>.from(raw),
      );
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Failed to complete MindCoach v2 run');
    }
  }
}
