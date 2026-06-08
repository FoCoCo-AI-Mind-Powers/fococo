import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/services/boot_phase_logger.dart';
import '/services/revenuecat_service.dart';

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
    RevenueCatService? revenueCatService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _revenueCatService = revenueCatService ?? RevenueCatService();

  static AuthFlowService? _instance;
  static AuthFlowService get instance => _instance ??= AuthFlowService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final RevenueCatService _revenueCatService;

  /// Best-effort RC access check for routing only. Never throws — auth must
  /// keep flowing even if RevenueCat is unreachable (we'll still consult
  /// `mandatoryPaywallCompleted` in Firestore as the secondary signal).
  Future<bool> _hasRcAccessSafe() async {
    try {
      return await _revenueCatService.hasProAccess();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AuthFlowService: RC access check failed: $e');
      }
      return false;
    }
  }

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

  bool _needsOnboarding(Map<String, dynamic> data) =>
      data['onboardingCompleted'] == false;

  Future<AuthFlowDecision> resolvePostAuthDecision() async {
    try {
      return await _resolvePostAuthDecisionInner();
    } catch (e) {
      debugPrint('❌ AuthFlowService: resolvePostAuthDecision failed: $e');
      // On any Firestore/network error, fall back to the main tab screen
      // for logged-in users so the app doesn't crash or hang on splash.
      return const AuthFlowDecision(routeName: 'fococo');
    }
  }

  Future<AuthFlowDecision> _resolvePostAuthDecisionInner() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthFlowDecision(routeName: 'login');
    }

    final userRef = _userDoc(user.uid);
    await BootPhaseLogger.record('auth_flow_firestore_read_start');
    final snap = await userRef.get();
    await BootPhaseLogger.record('auth_flow_firestore_read_done');

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
        'onboardingCompleted': false,
      }, SetOptions(merge: true));

      if (_isFreshAccount(user)) {
        return const AuthFlowDecision(routeName: 'account_created');
      }

      return const AuthFlowDecision(routeName: 'vark_onboarding');
    }

    final data = snap.data() ?? <String, dynamic>{};

    if (_needsOnboarding(data)) {
      await userRef.set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const AuthFlowDecision(routeName: 'vark_onboarding');
    }

    final mandatoryCompleted = data['mandatoryPaywallCompleted'];

    // RC-only gate: RevenueCat is the single source of truth for access.
    // If RC says the user has access (active entitlement, intro/trial, or
    // grace period), let them in regardless of Firestore lag. If RC says
    // no access, force the paywall — even if Firestore still has the legacy
    // `mandatoryPaywallCompleted = true` flag (recovery path for churned
    // / expired subscribers).
    final hasRcAccess = await _hasRcAccessSafe();

    if (hasRcAccess) {
      await userRef.set({
        'mandatoryPaywallCompleted': true,
        'lastActive': FieldValue.serverTimestamp(),
        if (data['createdTime'] == null)
          'createdTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const AuthFlowDecision(routeName: 'fococo');
    }

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
      // Legacy user migration path: do not hard-gate existing users when RC
      // is unreachable; we still flip the flag so future loads have a stable
      // signal, but routing falls through to the main tab.
      await userRef.set({
        'mandatoryPaywallCompleted': true,
        'lastActive': FieldValue.serverTimestamp(),
        if (data['createdTime'] == null)
          'createdTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const AuthFlowDecision(routeName: 'fococo');
    }

    // Firestore says paywall completed but RC reports no access. Send the
    // user back to the paywall to re-subscribe / start a new trial.
    await userRef.set({
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return const AuthFlowDecision(
      routeName: 'subscription_onboarding',
      extra: {'mandatory': true},
    );
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
