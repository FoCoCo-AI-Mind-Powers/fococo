import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class ActivityRecord extends FirestoreRecord {
  ActivityRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // Activity details
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  String? _subtitle;
  String get subtitle => _subtitle ?? '';
  bool hasSubtitle() => _subtitle != null;

  String? _activityType;
  String get activityType => _activityType ?? 'round';
  bool hasActivityType() => _activityType != null;

  String? _score;
  String get score => _score ?? '';
  bool hasScore() => _score != null;

  DateTime? _activityDate;
  DateTime? get activityDate => _activityDate;
  bool hasActivityDate() => _activityDate != null;

  // Statistics
  Map<String, dynamic>? _stats;
  Map<String, dynamic> get stats => _stats ?? {};
  bool hasStats() => _stats != null;

  // Achievements
  List<Map<String, dynamic>>? _achievements;
  List<Map<String, dynamic>> get achievements => _achievements ?? const [];
  bool hasAchievements() => _achievements != null;

  bool? _isPersonalRecord;
  bool get isPersonalRecord => _isPersonalRecord ?? false;
  bool hasIsPersonalRecord() => _isPersonalRecord != null;

  // Additional data
  String? _courseName;
  String get courseName => _courseName ?? '';
  bool hasCourseName() => _courseName != null;

  int? _duration;
  int get duration => _duration ?? 0;
  bool hasDuration() => _duration != null;

  double? _rating;
  double get rating => _rating ?? 0.0;
  bool hasRating() => _rating != null;

  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  void _initializeFields() {
    _title = snapshotData['title'] as String?;
    _subtitle = snapshotData['subtitle'] as String?;
    _activityType = snapshotData['activityType'] as String?;
    _score = snapshotData['score'] as String?;
    _activityDate = snapshotData['activityDate'] as DateTime?;
    _stats = snapshotData['stats'] != null
        ? Map<String, dynamic>.from(snapshotData['stats'] as Map)
        : {};
    _achievements = getStructList(
      snapshotData['achievements'],
      (d) => d,
    );
    _isPersonalRecord = snapshotData['isPersonalRecord'] as bool?;
    _courseName = snapshotData['courseName'] as String?;
    _duration = castToType<int>(snapshotData['duration']);
    _rating = castToType<double>(snapshotData['rating']);
    _notes = snapshotData['notes'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('activities');

  static Stream<ActivityRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ActivityRecord.fromSnapshot(s));

  static Future<ActivityRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ActivityRecord.fromSnapshot(s));

  static ActivityRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ActivityRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ActivityRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ActivityRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ActivityRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ActivityRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createActivityRecordData({
  String? title,
  String? subtitle,
  String? activityType,
  String? score,
  DateTime? activityDate,
  Map<String, dynamic>? stats,
  bool? isPersonalRecord,
  String? courseName,
  int? duration,
  double? rating,
  String? notes,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'activityType': activityType,
      'score': score,
      'activityDate': activityDate,
      'stats': stats,
      'isPersonalRecord': isPersonalRecord,
      'courseName': courseName,
      'duration': duration,
      'rating': rating,
      'notes': notes,
    }.withoutNulls,
  );

  return firestoreData;
}
