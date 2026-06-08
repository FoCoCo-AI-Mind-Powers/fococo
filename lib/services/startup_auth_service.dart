import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/firebase_user_provider.dart';
import '/services/boot_phase_logger.dart';

typedef AuthUserChangedCallback = Future<void> Function(BaseAuthUser user);
typedef AuthErrorCallback = void Function(Object error, StackTrace stackTrace);

class StartupAuthService {
  StartupAuthService._();

  static final StartupAuthService instance = StartupAuthService._();

  Stream<BaseAuthUser>? _userStream;
  StreamSubscription<BaseAuthUser>? _userStreamSubscription;
  StreamSubscription<User?>? _jwtTokenStreamSubscription;
  Completer<void>? _bootstrapCompleter;

  AuthUserChangedCallback? _onUserChanged;
  AuthErrorCallback? _onError;

  bool _userStreamStarted = false;
  bool _jwtStreamStarted = false;
  bool _bootstrapComplete = false;

  void configure({
    required AuthUserChangedCallback onUserChanged,
    required AuthErrorCallback onError,
  }) {
    _onUserChanged = onUserChanged;
    _onError = onError;
  }

  Future<void> bootstrap() async {
    if (StartupIsolationConfig.bypassAuthBootstrap) {
      return;
    }

    _bootstrapCompleter ??= Completer<void>();
    _startUserStreamIfNeeded();

    try {
      await _bootstrapCompleter!.future.timeout(const Duration(seconds: 6));
    } on TimeoutException {
      if (kDebugMode) {
        print('⚠️ Auth bootstrap timed out; continuing with current auth state');
      }
    } finally {
      _bootstrapComplete = true;
      try {
        _startJwtTokenStreamIfNeeded();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ JWT token stream failed to start: $e');
        }
      }
      try {
        await BootPhaseLogger.setCrashlyticsUserIdentifier(
            currentUser?.uid ?? '');
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Crashlytics user identifier update failed: $e');
        }
      }
    }
  }

  void _startUserStreamIfNeeded() {
    if (_userStreamStarted) {
      return;
    }

    _userStreamStarted = true;
    _bootstrapCompleter ??= Completer<void>();

    try {
      _userStream = foCoCoFirebaseUserStream();
      _userStreamSubscription = _userStream!.listen(
        (user) async {
          final callback = _onUserChanged;
          if (callback != null) {
            await callback(user);
          }

          if (!_bootstrapCompleter!.isCompleted) {
            _bootstrapCompleter!.complete();
          }

          if (_bootstrapComplete) {
            unawaited(
              BootPhaseLogger.setCrashlyticsUserIdentifier(user.uid ?? ''),
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (kDebugMode) {
            print('❌ Error in auth bootstrap stream: $error');
          }
          _onError?.call(error, stackTrace);
          if (!_bootstrapCompleter!.isCompleted) {
            _bootstrapCompleter!.complete();
          }
        },
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('❌ Error starting auth bootstrap stream: $error');
      }
      _onError?.call(error, stackTrace);
      if (!_bootstrapCompleter!.isCompleted) {
        _bootstrapCompleter!.complete();
      }
    }
  }

  void _startJwtTokenStreamIfNeeded() {
    if (_jwtStreamStarted) {
      return;
    }

    _jwtStreamStarted = true;

    try {
      _jwtTokenStreamSubscription = FirebaseAuth.instance
          .idTokenChanges()
          .listen(
        (user) {
          // Fetch token in a guarded async block so unhandled Future errors
          // never crash the app.
          if (user != null) {
            // Proactive refresh keeps Functions / Firestore IAM in sync after rotation.
            user.getIdToken(true).catchError((Object e) {
              if (kDebugMode) {
                print('⚠️ getIdToken failed: $e');
              }
              return null;
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (kDebugMode) {
            print('❌ Error in JWT token stream: $error');
          }
          _onError?.call(error, stackTrace);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to start JWT token stream: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _userStreamSubscription?.cancel();
    await _jwtTokenStreamSubscription?.cancel();
    _userStreamSubscription = null;
    _jwtTokenStreamSubscription = null;
    _userStreamStarted = false;
    _jwtStreamStarted = false;
    _bootstrapComplete = false;
    _bootstrapCompleter = null;
  }
}
