import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthFlowDecision {
  const AuthFlowDecision({
    required this.routeName,
    this.extra,
  });

  final String routeName;
  final Map<String, dynamic>? extra;
}

class AuthFlowService {
  AuthFlowService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static final AuthFlowService instance = AuthFlowService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection('user').doc(userId);

  bool _isFreshAccount(User user) {
    final createdAt = user.metadata.creationTime;
    final lastSignInAt = user.metadata.lastSignInTime;
    if (createdAt == null || lastSignInAt == null) {
      return false;
    }

    return lastSignInAt.difference(createdAt).abs() <
        const Duration(minutes: 2);
  }

  Future<AuthFlowDecision> resolvePostAuthDecision() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthFlowDecision(routeName: 'login');
    }

    final userRef = _userDoc(user.uid);
    final snap = await userRef.get();

    if (!snap.exists) {
      await userRef.set({
        'email': user.email ?? '',
        'displayName': (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName
            : 'Golfer',
        'profileImageUrl': user.photoURL ?? '',
        'createdTime': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'currentMembershipTier': 'junior',
        'mandatoryPaywallCompleted': false,
      }, SetOptions(merge: true));

      if (_isFreshAccount(user)) {
        return const AuthFlowDecision(routeName: 'account_created');
      }

      return const AuthFlowDecision(
        routeName: 'subscription_onboarding',
        extra: {'mandatory': true},
      );
    }

    final data = snap.data() ?? <String, dynamic>{};
    final mandatoryCompleted = data['mandatoryPaywallCompleted'];

    if (mandatoryCompleted == false) {
      await userRef.set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return const AuthFlowDecision(
        routeName: 'subscription_onboarding',
        extra: {'mandatory': true},
      );
    }

    if (mandatoryCompleted == null) {
      // Legacy user migration path: do not hard-gate existing users.
      await userRef.set({
        'mandatoryPaywallCompleted': true,
        'lastActive': FieldValue.serverTimestamp(),
        if (data['createdTime'] == null)
          'createdTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await userRef.set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return const AuthFlowDecision(routeName: 'mind_coach');
  }

  Future<void> markMandatoryPaywallCompleted() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await _userDoc(user.uid).set({
      'mandatoryPaywallCompleted': true,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
