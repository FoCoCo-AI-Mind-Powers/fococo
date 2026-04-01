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

class MindCoachV2SaveFavoriteResult {
  MindCoachV2SaveFavoriteResult({
    required this.saved,
    required this.needsReplacement,
    this.favoriteId,
    this.currentFavorites = const <MindCoachV2Favorite>[],
  });

  final bool saved;
  final bool needsReplacement;
  final String? favoriteId;
  final List<MindCoachV2Favorite> currentFavorites;
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
      final response = await _functionsClient.generateSession(
          userId: userId, request: request);
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
        'hasReflection': (response.reflection != null).toString(),
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

  Stream<List<MindCoachV2Favorite>> streamFavorites({
    MindCoachV2Pillar? pillar,
  }) {
    final userId = currentUserUid;
    _logger.log(_tag, 'streamFavorites', {
      'userId': userId,
      'pillar': pillar?.wireValue ?? 'all',
    });
    if (userId.isEmpty) {
      return const Stream<List<MindCoachV2Favorite>>.empty();
    }
    return _firestoreClient.streamFavorites(userId: userId, pillar: pillar);
  }

  Future<List<MindCoachV2Favorite>> fetchFavorites({
    MindCoachV2Pillar? pillar,
  }) async {
    final userId = currentUserUid;
    _logger.log(_tag, 'fetchFavorites', {
      'userId': userId,
      'pillar': pillar?.wireValue ?? 'all',
    });
    if (userId.isEmpty) {
      return const <MindCoachV2Favorite>[];
    }
    return _firestoreClient.fetchFavorites(userId: userId, pillar: pillar);
  }

  Future<MindCoachV2SaveFavoriteResult> saveFavorite({
    required MindCoachV2Session session,
    String? replaceFavoriteId,
  }) async {
    final userId = currentUserUid;
    _logger.log(_tag, 'saveFavorite: entry', {
      'userId': userId,
      'sessionId': session.sessionId,
      'pillar': session.pillar.wireValue,
      'replaceFavoriteId': replaceFavoriteId ?? 'null',
    });
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final currentFavorites = await _firestoreClient.fetchFavorites(
      userId: userId,
      pillar: session.pillar,
    );

    try {
      final favoriteId = await _firestoreClient.upsertFavorite(
        userId: userId,
        session: session,
        replaceFavoriteId: replaceFavoriteId,
      );
      return MindCoachV2SaveFavoriteResult(
        saved: true,
        needsReplacement: false,
        favoriteId: favoriteId,
        currentFavorites: currentFavorites,
      );
    } on StateError catch (error, stackTrace) {
      if (error.message == 'favorite_replacement_required') {
        _logger.warn(_tag, 'saveFavorite: replacement required', {
          'sessionId': session.sessionId,
          'pillar': session.pillar.wireValue,
        });
        return MindCoachV2SaveFavoriteResult(
          saved: false,
          needsReplacement: true,
          currentFavorites: currentFavorites,
        );
      }
      _logger.error(_tag, 'saveFavorite: state error', null, error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      _logger.error(_tag, 'saveFavorite: failed', null, error, stackTrace);
      rethrow;
    }
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
