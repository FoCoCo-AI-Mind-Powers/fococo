import '/auth/firebase_auth/auth_util.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_firestore_client.dart';
import '/features/mindcoach_v2/data/mindcoach_v2_functions_client.dart';
import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

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

  final MindCoachV2FunctionsClient _functionsClient;
  final MindCoachV2FirestoreClient _firestoreClient;

  Future<MindCoachV2GenerateResponse> generateSession(
    MindCoachV2GenerateRequest request,
  ) async {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    return _functionsClient.generateSession(userId: userId, request: request);
  }

  Future<MindCoachV2CompleteResponse> completeRun(
    MindCoachV2CompleteRequest request,
  ) {
    return _functionsClient.completeRun(request);
  }

  Stream<List<MindCoachV2Session>> streamHistory({int limit = 30}) {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      return const Stream<List<MindCoachV2Session>>.empty();
    }
    return _firestoreClient.streamHistory(userId: userId, limit: limit);
  }

  Stream<Set<String>> streamFavoriteSessionIds() {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      return const Stream<Set<String>>.empty();
    }
    return _firestoreClient.streamFavoriteSessionIds(userId: userId);
  }

  Future<MindCoachV2ResumePayload?> getResumePayload() async {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      return null;
    }

    final run = await _firestoreClient.getLatestInProgressRun(userId);
    if (run == null) {
      return null;
    }

    final session = await _firestoreClient.getSessionById(run.sessionId);
    if (session == null) {
      return null;
    }

    return MindCoachV2ResumePayload(run: run, session: session);
  }
}
