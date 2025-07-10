import 'dart:async';


import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UserSubscriptionsRecord extends FirestoreRecord {
  UserSubscriptionsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userId" field.
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  // "platform" field.
  String? _platform;
  String get platform => _platform ?? '';
  bool hasPlatform() => _platform != null;

  // "productId" field.
  String? _productId;
  String get productId => _productId ?? '';
  bool hasProductId() => _productId != null;

  // "originalTransactionId" field.
  String? _originalTransactionId;
  String get originalTransactionId => _originalTransactionId ?? '';
  bool hasOriginalTransactionId() => _originalTransactionId != null;

  // "purchaseToken" field.
  String? _purchaseToken;
  String get purchaseToken => _purchaseToken ?? '';
  bool hasPurchaseToken() => _purchaseToken != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "membershipTier" field.
  String? _membershipTier;
  String get membershipTier => _membershipTier ?? '';
  bool hasMembershipTier() => _membershipTier != null;

  // "currentPeriodStart" field.
  DateTime? _currentPeriodStart;
  DateTime? get currentPeriodStart => _currentPeriodStart;
  bool hasCurrentPeriodStart() => _currentPeriodStart != null;

  // "currentPeriodEnd" field.
  DateTime? _currentPeriodEnd;
  DateTime? get currentPeriodEnd => _currentPeriodEnd;
  bool hasCurrentPeriodEnd() => _currentPeriodEnd != null;

  // "nextBillingDate" field.
  DateTime? _nextBillingDate;
  DateTime? get nextBillingDate => _nextBillingDate;
  bool hasNextBillingDate() => _nextBillingDate != null;

  // "cancelAtPeriodEnd" field.
  bool? _cancelAtPeriodEnd;
  bool get cancelAtPeriodEnd => _cancelAtPeriodEnd ?? false;
  bool hasCancelAtPeriodEnd() => _cancelAtPeriodEnd != null;

  // "autoRenewing" field.
  bool? _autoRenewing;
  bool get autoRenewing => _autoRenewing ?? false;
  bool hasAutoRenewing() => _autoRenewing != null;

  // "purchaseDate" field.
  DateTime? _purchaseDate;
  DateTime? get purchaseDate => _purchaseDate;
  bool hasPurchaseDate() => _purchaseDate != null;

  // "originalPurchaseDate" field.
  DateTime? _originalPurchaseDate;
  DateTime? get originalPurchaseDate => _originalPurchaseDate;
  bool hasOriginalPurchaseDate() => _originalPurchaseDate != null;

  // "priceAmountMicros" field.
  int? _priceAmountMicros;
  int get priceAmountMicros => _priceAmountMicros ?? 0;
  bool hasPriceAmountMicros() => _priceAmountMicros != null;

  // "priceCurrencyCode" field.
  String? _priceCurrencyCode;
  String get priceCurrencyCode => _priceCurrencyCode ?? '';
  bool hasPriceCurrencyCode() => _priceCurrencyCode != null;

  // "isTrialPeriod" field.
  bool? _isTrialPeriod;
  bool get isTrialPeriod => _isTrialPeriod ?? false;
  bool hasIsTrialPeriod() => _isTrialPeriod != null;

  // "trialEndDate" field.
  DateTime? _trialEndDate;
  DateTime? get trialEndDate => _trialEndDate;
  bool hasTrialEndDate() => _trialEndDate != null;

  // "cancellationDate" field.
  DateTime? _cancellationDate;
  DateTime? get cancellationDate => _cancellationDate;
  bool hasCancellationDate() => _cancellationDate != null;

  // "cancellationReason" field.
  String? _cancellationReason;
  String get cancellationReason => _cancellationReason ?? '';
  bool hasCancellationReason() => _cancellationReason != null;

  // "refundDate" field.
  DateTime? _refundDate;
  DateTime? get refundDate => _refundDate;
  bool hasRefundDate() => _refundDate != null;

  // "createdTime" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "updatedTime" field.
  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  // "lastValidated" field.
  DateTime? _lastValidated;
  DateTime? get lastValidated => _lastValidated;
  bool hasLastValidated() => _lastValidated != null;

  // "rawReceiptData" field.
  String? _rawReceiptData;
  String get rawReceiptData => _rawReceiptData ?? '';
  bool hasRawReceiptData() => _rawReceiptData != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _platform = snapshotData['platform'] as String?;
    _productId = snapshotData['productId'] as String?;
    _originalTransactionId = snapshotData['originalTransactionId'] as String?;
    _purchaseToken = snapshotData['purchaseToken'] as String?;
    _status = snapshotData['status'] as String?;
    _membershipTier = snapshotData['membershipTier'] as String?;
    _currentPeriodStart = snapshotData['currentPeriodStart'] as DateTime?;
    _currentPeriodEnd = snapshotData['currentPeriodEnd'] as DateTime?;
    _nextBillingDate = snapshotData['nextBillingDate'] as DateTime?;
    _cancelAtPeriodEnd = snapshotData['cancelAtPeriodEnd'] as bool?;
    _autoRenewing = snapshotData['autoRenewing'] as bool?;
    _purchaseDate = snapshotData['purchaseDate'] as DateTime?;
    _originalPurchaseDate = snapshotData['originalPurchaseDate'] as DateTime?;
    _priceAmountMicros = castToType<int>(snapshotData['priceAmountMicros']);
    _priceCurrencyCode = snapshotData['priceCurrencyCode'] as String?;
    _isTrialPeriod = snapshotData['isTrialPeriod'] as bool?;
    _trialEndDate = snapshotData['trialEndDate'] as DateTime?;
    _cancellationDate = snapshotData['cancellationDate'] as DateTime?;
    _cancellationReason = snapshotData['cancellationReason'] as String?;
    _refundDate = snapshotData['refundDate'] as DateTime?;
    _createdTime = snapshotData['createdTime'] as DateTime?;
    _updatedTime = snapshotData['updatedTime'] as DateTime?;
    _lastValidated = snapshotData['lastValidated'] as DateTime?;
    _rawReceiptData = snapshotData['rawReceiptData'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user_subscriptions');

  static Stream<UserSubscriptionsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UserSubscriptionsRecord.fromSnapshot(s));

  static Future<UserSubscriptionsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UserSubscriptionsRecord.fromSnapshot(s));

  static UserSubscriptionsRecord fromSnapshot(DocumentSnapshot snapshot) => UserSubscriptionsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UserSubscriptionsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UserSubscriptionsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UserSubscriptionsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UserSubscriptionsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
} 