// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RecommendationStruct extends FFFirebaseStruct {
  RecommendationStruct({
    String? action,
    String? priority,
    String? category,
    String? relatedModuleId,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _action = action,
        _priority = priority,
        _category = category,
        _relatedModuleId = relatedModuleId,
        super(firestoreUtilData);

  // "action" field.
  String? _action;
  String get action => _action ?? '';
  set action(String? val) => _action = val;

  bool hasAction() => _action != null;

  // "priority" field.
  String? _priority;
  String get priority => _priority ?? '';
  set priority(String? val) => _priority = val;

  bool hasPriority() => _priority != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  set category(String? val) => _category = val;

  bool hasCategory() => _category != null;

  // "relatedModuleId" field.
  String? _relatedModuleId;
  String get relatedModuleId => _relatedModuleId ?? '';
  set relatedModuleId(String? val) => _relatedModuleId = val;

  bool hasRelatedModuleId() => _relatedModuleId != null;

  static RecommendationStruct fromMap(Map<String, dynamic> data) => RecommendationStruct(
        action: data['action'] as String?,
        priority: data['priority'] as String?,
        category: data['category'] as String?,
        relatedModuleId: data['relatedModuleId'] as String?,
      );

  static RecommendationStruct? maybeFromMap(dynamic data) => data is Map
      ? RecommendationStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'action': _action,
        'priority': _priority,
        'category': _category,
        'relatedModuleId': _relatedModuleId,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'action': serializeParam(_action, ParamType.String),
        'priority': serializeParam(_priority, ParamType.String),
        'category': serializeParam(_category, ParamType.String),
        'relatedModuleId': serializeParam(_relatedModuleId, ParamType.String),
      }.withoutNulls;

  static RecommendationStruct fromSerializableMap(Map<String, dynamic> data) =>
      RecommendationStruct(
        action: deserializeParam(data['action'], ParamType.String, false),
        priority: deserializeParam(data['priority'], ParamType.String, false),
        category: deserializeParam(data['category'], ParamType.String, false),
        relatedModuleId: deserializeParam(data['relatedModuleId'], ParamType.String, false),
      );

  @override
  String toString() => 'RecommendationStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is RecommendationStruct &&
        action == other.action &&
        priority == other.priority &&
        category == other.category &&
        relatedModuleId == other.relatedModuleId;
  }

  @override
  int get hashCode => const ListEquality().hash([action, priority, category, relatedModuleId]);
} 