import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Maps thrown errors to calm, user-facing copy. Never exposes technical details.
class FriendlyErrorMapper {
  FriendlyErrorMapper._();

  static String message(
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return fallback;

    if (error is FirebaseFunctionsException) {
      return _fromFunctions(error, fallback);
    }

    if (error is FirebaseAuthException) {
      return _fromAuth(error, fallback);
    }

    final raw = error.toString();
    if (raw.contains('preferred_delivery_length') ||
        raw.contains('Invalid preferred')) {
      return "Couldn't replay that session. Try again.";
    }
    if (raw.contains('MindCoach generation limit') ||
        raw.contains('Hourly MindCoach') ||
        raw.contains('Daily MindCoach')) {
      return 'MindCoach is busy right now. Please try again in a moment.';
    }
    if (raw.contains('SocketException') ||
        raw.contains('Network') ||
        raw.contains('connection')) {
      return 'No connection right now. Check your network and try again.';
    }
    if (raw.contains('timeout') || raw.contains('Timeout')) {
      return 'That took too long. Please try again.';
    }

    return fallback;
  }

  static String _fromFunctions(
    FirebaseFunctionsException error,
    String fallback,
  ) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Please sign in again to continue.';
      case 'permission-denied':
        return "You don't have access to do that right now.";
      case 'resource-exhausted':
        return 'Too many requests. Please wait a moment and try again.';
      case 'invalid-argument':
        if ((error.message ?? '').contains('preferred_delivery_length')) {
          return "Couldn't replay that session. Try again.";
        }
        return fallback;
      default:
        return fallback;
    }
  }

  static String _fromAuth(FirebaseAuthException error, String fallback) {
    switch (error.code) {
      case 'requires-recent-login':
        return 'For your security, sign in again, then retry.';
      case 'network-request-failed':
        return 'No connection right now. Check your network and try again.';
      default:
        return fallback;
    }
  }
}
