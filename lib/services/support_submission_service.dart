import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum SupportSubmissionType {
  bug('bug'),
  feedback('feedback');

  const SupportSubmissionType(this.value);
  final String value;
}

/// Queues in-app bug reports and product feedback to Firestore.
class SupportSubmissionService {
  SupportSubmissionService._();

  static const String collection = 'support_submissions';

  static Future<void> submit({
    required SupportSubmissionType type,
    required String message,
    String? title,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to submit.');
    }

    final trimmed = message.trim();
    if (trimmed.length < 10) {
      throw ArgumentError('Please enter at least 10 characters.');
    }

    var appVersion = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (e) {
      if (kDebugMode) debugPrint('SupportSubmissionService version: $e');
    }

    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    await FirebaseFirestore.instance.collection(collection).add({
      'userId': uid,
      'email': email,
      'type': type.value,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      'message': trimmed,
      'appVersion': appVersion,
      'platform': _platformLabel(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return 'unknown';
  }
}
