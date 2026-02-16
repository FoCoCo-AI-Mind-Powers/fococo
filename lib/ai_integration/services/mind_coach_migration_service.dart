import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/mindcoach_sessions_record.dart';

/// Service for migrating existing MindCoach sessions to new structure
class MindCoachMigrationService {
  static MindCoachMigrationService? _instance;
  static MindCoachMigrationService get instance {
    _instance ??= MindCoachMigrationService._();
    return _instance!;
  }

  MindCoachMigrationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate a single session record
  Future<bool> migrateSession(MindcoachSessionsRecord record) async {
    try {
      final data = <String, dynamic>{};

      // Convert mindsetBefore from String to int
      if (record.hasMindsetBefore()) {
        final mindsetBeforeStr = record.mindsetBefore;
        data['mindsetBefore'] = _parseMindsetRating(mindsetBeforeStr);
      } else {
        data['mindsetBefore'] = 3; // Default
      }

      // Convert mindsetAfter from String to int
      if (record.hasMindsetAfter()) {
        final mindsetAfterStr = record.mindsetAfter;
        data['mindsetAfter'] = _parseMindsetRating(mindsetAfterStr);
      }

      // Add new fields with defaults if missing
      if (!record.hasTemplateId() || record.templateId.isEmpty) {
        data['templateId'] = 'MC_T01_PRE_ROUND_CLARITY'; // Default template
      }

      data['varkMode'] = 'ReadWrite'; // Default VARK mode
      data['level'] = 'Foundation'; // Default level
      data['length'] = record.hasDeliveryLength()
          ? record.deliveryLength
          : 'standard'; // Use deliveryLength or default

      // Preserve existing fields
      if (record.hasContext()) {
        data['context'] = record.context;
      } else {
        data['context'] = {};
      }

      if (record.hasSuccessSignalFlags()) {
        // Convert successSignalFlags to proper boolean map
        final flags = record.successSignalFlags;
        final boolFlags = <String, bool>{};
        flags.forEach((key, value) {
          if (value is bool) {
            boolFlags[key.toString()] = value;
          } else if (value is String) {
            boolFlags[key.toString()] = value.toLowerCase() == 'true';
          } else {
            boolFlags[key.toString()] = false;
          }
        });
        data['successSignalFlags'] = boolFlags;
      } else {
        data['successSignalFlags'] = {};
      }

      // Preserve other existing fields
      if (record.hasRoutineType()) {
        data['routineType'] = record.routineType;
      }
      if (record.hasCueUsed()) {
        data['cueUsed'] = record.cueUsed;
      }
      if (record.hasCoachingText()) {
        data['coachingText'] = record.coachingText;
      }
      if (record.hasFollowUpQuestion()) {
        data['followUpQuestion'] = record.followUpQuestion;
      }

      // Set session type
      data['sessionType'] = 'coaching';

      // Update timestamps
      data['updatedTime'] = FieldValue.serverTimestamp();
      if (record.hasCreatedTime()) {
        data['createdTime'] = record.createdTime;
      } else if (record.hasTimestamp()) {
        data['createdTime'] = record.timestamp;
      }

      // Update the document
      await record.reference.update(data);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parse mindset rating from String to int
  /// Handles emoji ratings like "😐 Neutral" or numeric strings
  int _parseMindsetRating(String rating) {
    // Try to extract number from string
    final numberMatch = RegExp(r'(\d)').firstMatch(rating);
    if (numberMatch != null) {
      return int.parse(numberMatch.group(1)!);
    }

    // Map common emoji/text ratings to numbers
    final lowerRating = rating.toLowerCase();
    if (lowerRating.contains('struggling') || lowerRating.contains('😰') || lowerRating.contains('1')) {
      return 1;
    } else if (lowerRating.contains('needs') || lowerRating.contains('😐') || lowerRating.contains('2')) {
      return 2;
    } else if (lowerRating.contains('neutral') || lowerRating.contains('😌') || lowerRating.contains('3')) {
      return 3;
    } else if (lowerRating.contains('calm') || lowerRating.contains('😊') || lowerRating.contains('4')) {
      return 4;
    } else if (lowerRating.contains('confident') || lowerRating.contains('😎') || lowerRating.contains('5')) {
      return 5;
    }

    return 3; // Default
  }

  /// Migrate all sessions for a user
  Future<MigrationResult> migrateUserSessions(String userId) async {
    int successCount = 0;
    int failureCount = 0;
    final failures = <String>[];

    try {
      final snapshot = await _firestore
          .collection('mindcoach_sessions')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        final record = MindcoachSessionsRecord.fromSnapshot(doc);
        final success = await migrateSession(record);

        if (success) {
          successCount++;
        } else {
          failureCount++;
          failures.add(doc.id);
        }
      }

      return MigrationResult(
        successCount: successCount,
        failureCount: failureCount,
        failures: failures,
      );
    } catch (e) {
      return MigrationResult(
        successCount: successCount,
        failureCount: failureCount,
        failures: failures,
        error: e.toString(),
      );
    }
  }

  /// Migrate all sessions in batches
  Future<MigrationResult> migrateAllSessions({
    int batchSize = 50,
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    final failures = <String>[];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('mindcoach_sessions')
          .limit(batchSize)
          .get();

      int totalProcessed = 0;
      DocumentSnapshot? lastDoc;

      while (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final record = MindcoachSessionsRecord.fromSnapshot(doc);
          final success = await migrateSession(record);

          if (success) {
            successCount++;
          } else {
            failureCount++;
            failures.add(doc.id);
          }

          totalProcessed++;
          onProgress?.call(totalProcessed, totalProcessed);
        }

        if (snapshot.docs.length < batchSize) {
          break; // No more documents
        }

        lastDoc = snapshot.docs.last;
        snapshot = await _firestore
            .collection('mindcoach_sessions')
            .startAfterDocument(lastDoc)
            .limit(batchSize)
            .get();
      }

      return MigrationResult(
        successCount: successCount,
        failureCount: failureCount,
        failures: failures,
      );
    } catch (e) {
      return MigrationResult(
        successCount: successCount,
        failureCount: failureCount,
        failures: failures,
        error: e.toString(),
      );
    }
  }
}

/// Result of migration operation
class MigrationResult {
  final int successCount;
  final int failureCount;
  final List<String> failures;
  final String? error;

  MigrationResult({
    required this.successCount,
    required this.failureCount,
    required this.failures,
    this.error,
  });

  bool get isSuccess => failureCount == 0 && error == null;
  int get totalCount => successCount + failureCount;
}
