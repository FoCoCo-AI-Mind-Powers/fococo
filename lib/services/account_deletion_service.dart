import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/services/app_session_prefs_service.dart';

/// Queues server deletion and clears local session data.
class AccountDeletionService {
  AccountDeletionService._();

  static Future<void> requestDeletion({
    required String email,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('account_deletion_requests')
        .add({
      'userId': uid,
      'email': email,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  static Future<void> clearLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      if (kDebugMode) debugPrint('AccountDeletionService.clearLocal: $e');
    }
    await AppSessionPrefsService.setPostLoginTabFoCoCo();
  }
}
