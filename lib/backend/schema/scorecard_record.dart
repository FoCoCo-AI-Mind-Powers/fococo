import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class ScorecardRecord extends FirestoreRecord {
  ScorecardRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // Scorecard holes data (18 holes)
  List<int>? _holeScores;
  List<int> get holeScores => _holeScores ?? List.filled(18, 0);
  bool hasHoleScores() => _holeScores != null;

  List<int>? _holePars;
  List<int> get holePars => _holePars ?? List.filled(18, 4);
  bool hasHolePars() => _holePars != null;

  // STAL (Shots to Aiming Line) data
  List<String>? _stalScores;
  List<String> get stalScores => _stalScores ?? List.filled(18, '0');
  bool hasStalScores() => _stalScores != null;

  // Summary data
  int? _totalScore;
  int get totalScore => _totalScore ?? 0;
  bool hasTotalScore() => _totalScore != null;

  int? _totalPar;
  int get totalPar => _totalPar ?? 72;
  bool hasTotalPar() => _totalPar != null;

  String? _scoreDifferential;
  String get scoreDifferential => _scoreDifferential ?? '+0';
  bool hasScoreDifferential() => _scoreDifferential != null;

  // Shot overview
  Map<String, dynamic>? _shotOverview;
  Map<String, dynamic> get shotOverview => _shotOverview ?? {};
  bool hasShotOverview() => _shotOverview != null;

  // Round info
  String? _roundId;
  String get roundId => _roundId ?? '';
  bool hasRoundId() => _roundId != null;

  DateTime? _roundDate;
  DateTime? get roundDate => _roundDate;
  bool hasRoundDate() => _roundDate != null;

  String? _courseName;
  String get courseName => _courseName ?? '';
  bool hasCourseName() => _courseName != null;

  void _initializeFields() {
    _holeScores = getDataList(snapshotData['holeScores']);
    _holePars = getDataList(snapshotData['holePars']);
    _stalScores = getDataList(snapshotData['stalScores']);
    _totalScore = castToType<int>(snapshotData['totalScore']);
    _totalPar = castToType<int>(snapshotData['totalPar']);
    _scoreDifferential = snapshotData['scoreDifferential'] as String?;
    _shotOverview = snapshotData['shotOverview'] as Map<String, dynamic>?;
    _roundId = snapshotData['roundId'] as String?;
    _roundDate = snapshotData['roundDate'] as DateTime?;
    _courseName = snapshotData['courseName'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('scorecards');

  static Stream<ScorecardRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ScorecardRecord.fromSnapshot(s));

  static Future<ScorecardRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ScorecardRecord.fromSnapshot(s));

  static ScorecardRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ScorecardRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ScorecardRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ScorecardRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ScorecardRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ScorecardRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createScorecardRecordData({
  int? totalScore,
  int? totalPar,
  String? scoreDifferential,
  Map<String, dynamic>? shotOverview,
  String? roundId,
  DateTime? roundDate,
  String? courseName,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'totalScore': totalScore,
      'totalPar': totalPar,
      'scoreDifferential': scoreDifferential,
      'shotOverview': shotOverview,
      'roundId': roundId,
      'roundDate': roundDate,
      'courseName': courseName,
    }.withoutNulls,
  );

  return firestoreData;
}

class ScorecardRecordDocumentEquality implements Equality<ScorecardRecord> {
  const ScorecardRecordDocumentEquality();

  @override
  bool equals(ScorecardRecord? e1, ScorecardRecord? e2) {
    const listEquality = ListEquality();
    const mapEquality = MapEquality();
    return listEquality.equals(e1?.holeScores, e2?.holeScores) &&
        listEquality.equals(e1?.holePars, e2?.holePars) &&
        listEquality.equals(e1?.stalScores, e2?.stalScores) &&
        e1?.totalScore == e2?.totalScore &&
        e1?.totalPar == e2?.totalPar &&
        e1?.scoreDifferential == e2?.scoreDifferential &&
        mapEquality.equals(e1?.shotOverview, e2?.shotOverview) &&
        e1?.roundId == e2?.roundId &&
        e1?.roundDate == e2?.roundDate &&
        e1?.courseName == e2?.courseName;
  }

  @override
  int hash(ScorecardRecord? e) => const ListEquality().hash([
        e?.holeScores,
        e?.holePars,
        e?.stalScores,
        e?.totalScore,
        e?.totalPar,
        e?.scoreDifferential,
        e?.shotOverview,
        e?.roundId,
        e?.roundDate,
        e?.courseName
      ]);

  @override
  bool isValidKey(Object? o) => o is ScorecardRecord;
}

