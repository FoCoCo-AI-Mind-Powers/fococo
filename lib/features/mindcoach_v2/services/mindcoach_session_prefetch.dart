import '../domain/models/mindcoach_v2_models.dart';

/// In-memory prefetch cache for the next likely MindCoach generation.
class MindCoachSessionPrefetch {
  MindCoachSessionPrefetch._();

  static MindCoachV2GenerateResponse? _cached;

  static void store(MindCoachV2GenerateResponse response) {
    _cached = response;
  }

  static MindCoachV2GenerateResponse? take() {
    final cached = _cached;
    _cached = null;
    return cached;
  }

  static void clear() {
    _cached = null;
  }
}
