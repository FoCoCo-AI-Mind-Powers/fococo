import 'package:cloud_functions/cloud_functions.dart';

import '/features/mindcoach_v2/data/mappers/mindcoach_v2_mappers.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';

class MindCoachV2FunctionsClient {
  MindCoachV2FunctionsClient({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  static const String _tag = 'FUNCTIONS_CLIENT';
  final MindCoachV2DebugLogger _logger = MindCoachV2DebugLogger.instance;
  final FirebaseFunctions _functions;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  Future<MindCoachV2GenerateResponse> generateSession({
    required String userId,
    required MindCoachV2GenerateRequest request,
  }) async {
    final payload = request.toMap();
    _logger.log(_tag, 'generateSession: calling Cloud Function', {
      'userId': userId,
      'contextMode': payload['context_mode'],
      'entrySource': payload['entry_source'],
      'deliveryLength': payload['preferred_delivery_length'],
    });

    final callable = _functions.httpsCallable('generateMindCoachSessionV2');
    FirebaseFunctionsException? lastFunctionsError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final result = await callable.call(payload);
        final raw = result.data;
        if (raw is! Map) {
          _logger.error(_tag, 'generateSession: invalid response type', {
            'type': raw.runtimeType.toString(),
          });
          throw Exception('Invalid generate response payload');
        }

        _logger.log(_tag, 'generateSession: raw response received', {
          'keys': raw.keys.toList().toString(),
          'sessionId': raw['session_id']?.toString(),
          'uiMode': raw['ui_mode']?.toString(),
          'contextMode': raw['context_mode']?.toString(),
        });

        final response = MindCoachV2Mappers.parseGenerateResponse(
          Map<String, dynamic>.from(raw),
          userId: userId,
        );

        _logger.log(_tag, 'generateSession: parsed successfully', {
          'sessionId': response.sessionId,
          'uiMode': response.uiMode.wireValue,
          'templateId': response.session.templateId,
          'validatorStatus': response.session.validatorStatus,
          'hasTimedLines': (response.session.lines != null).toString(),
        });

        return response;
      } on FirebaseFunctionsException catch (e, s) {
        lastFunctionsError = e;
        _logger.error(_tag, 'generateSession: FirebaseFunctionsException', {
          'code': e.code,
          'message': e.message,
          'details': e.details?.toString(),
          'attempt': '${attempt + 1}/2',
        }, e, s);
        if (!_isRetryable(e) || attempt == 1) {
          break;
        }
        await Future<void>.delayed(_retryDelay);
      } catch (e, s) {
        _logger.error(
            _tag, 'generateSession: unexpected error', null, e, s);
        rethrow;
      }
    }
    if (lastFunctionsError != null) {
      throw Exception(_humanizeGenerateSessionError(lastFunctionsError));
    }
    throw Exception('Failed to generate MindCoach v2 session');
  }

  bool _isRetryable(FirebaseFunctionsException error) {
    return error.code == 'internal' ||
        error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'resource-exhausted';
  }

  String _humanizeGenerateSessionError(FirebaseFunctionsException error) {
    if (error.code == 'resource-exhausted') {
      return 'MindCoach is busy right now. Please try again in a moment.';
    }
    if (error.code == 'failed-precondition') {
      return error.message ??
          'MindCoach is not ready yet. Please refresh data/config and try again.';
    }
    if (error.code == 'internal' || error.code == 'unavailable') {
      return 'MindCoach is temporarily unavailable. Please retry in a few seconds.';
    }
    return error.message ?? 'Failed to generate MindCoach v2 session';
  }

  Future<MindCoachV2CompleteResponse> completeRun(
    MindCoachV2CompleteRequest request,
  ) async {
    final payload = request.toMap();
    _logger.log(_tag, 'completeRun: calling Cloud Function', {
      'sessionId': payload['session_id'],
      'completionStatus': payload['completion_status'],
    });

    final callable = _functions.httpsCallable('completeMindCoachSessionRunV2');
    try {
      final result = await callable.call(payload);
      final raw = result.data;
      if (raw is! Map) {
        _logger.error(_tag, 'completeRun: invalid response type', {
          'type': raw.runtimeType.toString(),
        });
        throw Exception('Invalid complete response payload');
      }

      _logger.log(_tag, 'completeRun: raw response received', {
        'runId': raw['run_id']?.toString(),
        'hasReflection': (raw['reflection'] != null).toString(),
      });

      final response = MindCoachV2Mappers.parseCompleteResponse(
        Map<String, dynamic>.from(raw),
      );

      _logger.log(_tag, 'completeRun: parsed successfully', {
        'runId': response.runId,
        'hasReflection': (response.reflection != null).toString(),
      });

      return response;
    } on FirebaseFunctionsException catch (e, s) {
      _logger.error(_tag, 'completeRun: FirebaseFunctionsException', {
        'code': e.code,
        'message': e.message,
        'details': e.details?.toString(),
      }, e, s);
      throw Exception(e.message ?? 'Failed to complete MindCoach v2 run');
    } catch (e, s) {
      _logger.error(
          _tag, 'completeRun: unexpected error', null, e, s);
      rethrow;
    }
  }
}
