import '/auth/firebase_auth/auth_util.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_firestore_client.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_functions_client.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';
import '/features/mindcoach_v2/services/mindcoach_v2_debug_logger.dart';

class MindCoachV2ResumePayload {
  MindCoachV2ResumePayload({
    required this.run,
    required this.session,
  });

  final MindCoachV2SessionRun run;
  final MindCoachV2Session session;
}

class MindCoachV2Repository {
  MindCoachV2Repository._({
    MindCoachV2FunctionsClient? functionsClient,
    MindCoachV2FirestoreClient? firestoreClient,
  })  : _functionsClient = functionsClient ?? MindCoachV2FunctionsClient(),
        _firestoreClient = firestoreClient ?? MindCoachV2FirestoreClient();

  static MindCoachV2Repository? _instance;
  static MindCoachV2Repository get instance =>
      _instance ??= MindCoachV2Repository._();

  static const String _tag = 'REPOSITORY';
  final MindCoachV2DebugLogger _logger = MindCoachV2DebugLogger.instance;
  final MindCoachV2FunctionsClient _functionsClient;
  final MindCoachV2FirestoreClient _firestoreClient;

  Future<MindCoachV2GenerateResponse> generateSession(
    MindCoachV2GenerateRequest request,
  ) async {
    final userId = currentUserUid;
    _logger.log(_tag, 'generateSession: entry', {
      'userId': userId,
      'contextMode': request.contextMode.wireValue,
      'entrySource': request.entrySource,
    });

    if (userId.isEmpty) {
      _logger.error(_tag, 'generateSession: user not authenticated');
      throw Exception('User not authenticated');
    }

    try {
      final response =
          await _functionsClient.generateSession(userId: userId, request: request);
      _logger.log(_tag, 'generateSession: success', {
        'sessionId': response.sessionId,
      });
      return response;
    } catch (e, s) {
      _logger.error(_tag, 'generateSession: failed', null, e, s);
      rethrow;
    }
  }

  Future<MindCoachV2CompleteResponse> completeRun(
    MindCoachV2CompleteRequest request,
  ) async {
    _logger.log(_tag, 'completeRun: entry', {
      'sessionId': request.sessionId,
      'status': request.completionStatus.wireValue,
    });
    try {
      final response = await _functionsClient.completeRun(request);
      _logger.log(_tag, 'completeRun: success', {
        'runId': response.runId,
        'favoriteSaved': response.favoriteSaved.toString(),
      });
      return response;
    } catch (e, s) {
      _logger.error(_tag, 'completeRun: failed', null, e, s);
      rethrow;
    }
  }

  Stream<List<MindCoachV2Session>> streamHistory({int limit = 30}) {
    final userId = currentUserUid;
    _logger.log(_tag, 'streamHistory', {'userId': userId, 'limit': limit});
    if (userId.isEmpty) {
      return const Stream<List<MindCoachV2Session>>.empty();
    }
    return _firestoreClient.streamHistory(userId: userId, limit: limit);
  }

  Stream<Set<String>> streamFavoriteSessionIds() {
    final userId = currentUserUid;
    _logger.log(_tag, 'streamFavoriteSessionIds', {'userId': userId});
    if (userId.isEmpty) {
      return const Stream<Set<String>>.empty();
    }
    return _firestoreClient.streamFavoriteSessionIds(userId: userId);
  }

  Future<MindCoachV2ResumePayload?> getResumePayload() async {
    final userId = currentUserUid;
    _logger.log(_tag, 'getResumePayload: entry', {'userId': userId});
    if (userId.isEmpty) {
      return null;
    }

    try {
      final run = await _firestoreClient.getLatestInProgressRun(userId);
      if (run == null) {
        _logger.log(_tag, 'getResumePayload: no in-progress run');
        return null;
      }

      final session = await _firestoreClient.getSessionById(run.sessionId);
      if (session == null) {
        _logger.warn(_tag, 'getResumePayload: run found but session missing', {
          'runId': run.runId,
          'sessionId': run.sessionId,
        });
        return null;
      }

      _logger.log(_tag, 'getResumePayload: resume available', {
        'runId': run.runId,
        'sessionId': session.sessionId,
      });
      return MindCoachV2ResumePayload(run: run, session: session);
    } catch (e, s) {
      _logger.error(_tag, 'getResumePayload: failed', null, e, s);
      return null;
    }
  }
}
