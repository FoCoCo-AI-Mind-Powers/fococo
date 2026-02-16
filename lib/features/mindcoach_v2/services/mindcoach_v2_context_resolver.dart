import 'package:cloud_firestore/cloud_firestore.dart';

import '/features/mindcoach_v2/domain/models/mindcoach_v2_models.dart';

class MindCoachV2ContextResolver {
  MindCoachV2ContextResolver({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<MindCoachV2ContextMode> inferContextMode(String userId) async {
    try {
      final rounds = await _firestore
          .collection('golf_rounds')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (rounds.docs.isNotEmpty) {
        final data = rounds.docs.first.data();
        final rawDate = data['date'];
        final roundDate = _asDate(rawDate);
        if (roundDate != null) {
          final delta = DateTime.now().difference(roundDate);
          if (delta.inHours <= 4) {
            return MindCoachV2ContextMode.duringRound;
          }
          if (delta.inHours <= 24) {
            return MindCoachV2ContextMode.afterRound;
          }
        }
      }

      final hour = DateTime.now().hour;
      if (hour < 10) {
        return MindCoachV2ContextMode.beforeRound;
      }
      return MindCoachV2ContextMode.offDay;
    } catch (_) {
      return MindCoachV2ContextMode.offDay;
    }
  }

  DateTime? _asDate(dynamic raw) {
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
