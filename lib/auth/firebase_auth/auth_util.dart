import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_auth_manager.dart';

export 'firebase_auth_manager.dart';

FirebaseAuthManager? _authManager;
FirebaseAuthManager get authManager => _authManager ??= FirebaseAuthManager();

String get currentUserEmail => currentUser?.email ?? '';

String get currentUserUid => currentUser?.uid ?? '';

String get currentUserDisplayName => currentUser?.displayName ?? '';

String get currentUserPhoto => currentUser?.photoUrl ?? '';

String get currentPhoneNumber => currentUser?.phoneNumber ?? '';

String get currentJwtToken => _currentJwtToken ?? '';

bool get currentUserEmailVerified => currentUser?.emailVerified ?? false;

/// Create a Stream that listens to the current user's JWT Token, since Firebase
/// generates a new token every hour.
String? _currentJwtToken;
Stream<Future<String?>>? _jwtTokenStream;
Stream<Future<String?>> get jwtTokenStream =>
    _jwtTokenStream ??= FirebaseAuth.instance
        .idTokenChanges()
        .map((user) async => _currentJwtToken = await user?.getIdToken())
        .asBroadcastStream();
