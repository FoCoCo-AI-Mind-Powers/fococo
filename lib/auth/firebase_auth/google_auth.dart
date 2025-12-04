import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// GoogleSignIn 7.2.0 uses a singleton pattern
final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
bool _isInitialized = false;

Future<UserCredential?> googleSignInFunc() async {
  if (kIsWeb) {
    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }

  // Initialize GoogleSignIn if not already initialized
  if (!_isInitialized) {
    await _googleSignIn.initialize();
    _isInitialized = true;
  }

  // Sign out any existing session
  await _googleSignIn.signOut().catchError((_) => null);

  // Authenticate the user (this replaces signIn() in the new API)
  final GoogleSignInAccount googleUser;
  try {
    googleUser = await _googleSignIn.authenticate(
      scopeHint: <String>['profile', 'email'],
    );
  } catch (e) {
    // User canceled or error occurred
    return null;
  }

  // Obtain the authentication tokens
  final GoogleSignInAuthentication googleAuth = googleUser.authentication;
  if (googleAuth.idToken == null) {
    return null;
  }

  // Get access token via authorization client
  String? accessToken;
  try {
    final authz = await googleUser.authorizationClient.authorizeScopes(
      <String>['profile', 'email'],
    );
    accessToken = authz.accessToken;
  } catch (e) {
    // If authorization fails, we can still proceed with just idToken
    accessToken = null;
  }

  // Create a new credential
  final credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
    accessToken: accessToken,
  );

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

Future<void> signOutWithGoogle() async {
  if (_isInitialized) {
    await _googleSignIn.signOut();
  }
}
