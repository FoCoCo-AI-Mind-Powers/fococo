import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class NotificationsRecord extends FirestoreRecord {
  NotificationsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "body" field.
  String? _body;
  String get body => _body ?? '';
  bool hasBody() => _body != null;

  // "type" field.
  String? _type;
  String get type => _type ?? 'general';
  bool hasType() => _type != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "isRead" field.
  bool? _isRead;
  bool get isRead => _isRead ?? false;
  bool hasIsRead() => _isRead != null;

  // "actionUrl" field.
  String? _actionUrl;
  String get actionUrl => _actionUrl ?? '';
  bool hasActionUrl() => _actionUrl != null;

  // "actionData" field.
  Map<String, dynamic>? _actionData;
  Map<String, dynamic> get actionData => _actionData ?? {};
  bool hasActionData() => _actionData != null;

  // "imageUrl" field.
  String? _imageUrl;
  String get imageUrl => _imageUrl ?? '';
  bool hasImageUrl() => _imageUrl != null;

  // "priority" field.
  String? _priority;
  String get priority => _priority ?? 'normal';
  bool hasPriority() => _priority != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "readTime" field.
  DateTime? _readTime;
  DateTime? get readTime => _readTime;
  bool hasReadTime() => _readTime != null;

  // "expiresAt" field.
  DateTime? _expiresAt;
  DateTime? get expiresAt => _expiresAt;
  bool hasExpiresAt() => _expiresAt != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _title = snapshotData['title'] as String?;
    _body = snapshotData['body'] as String?;
    _type = snapshotData['type'] as String?;
    _category = snapshotData['category'] as String?;
    _isRead = snapshotData['isRead'] as bool?;
    _actionUrl = snapshotData['actionUrl'] as String?;
    _actionData = snapshotData['actionData'] != null
        ? Map<String, dynamic>.from(snapshotData['actionData'] as Map)
        : {};
    _imageUrl = snapshotData['imageUrl'] as String?;
    _priority = snapshotData['priority'] as String?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _readTime = snapshotData['readTime'] as DateTime?;
    _expiresAt = snapshotData['expiresAt'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('notifications');

  static Stream<NotificationsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => NotificationsRecord.fromSnapshot(s));

  static Future<NotificationsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => NotificationsRecord.fromSnapshot(s));

  static NotificationsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      NotificationsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static NotificationsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      NotificationsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'NotificationsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is NotificationsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createNotificationsRecordData({
  String? userId,
  String? title,
  String? body,
  String? type,
  String? category,
  bool? isRead,
  String? actionUrl,
  Map<String, dynamic>? actionData,
  String? imageUrl,
  String? priority,
  DateTime? createdTime,
  DateTime? readTime,
  DateTime? expiresAt,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'isRead': isRead,
      'actionUrl': actionUrl,
      'actionData': actionData,
      'imageUrl': imageUrl,
      'priority': priority,
      'createdTime': createdTime,
      'readTime': readTime,
      'expiresAt': expiresAt,
    }.withoutNulls,
  );

  return firestoreData;
}
