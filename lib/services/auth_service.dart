import 'package:firebase_auth/firebase_auth.dart';

/// Lightweight wrapper for Firebase Auth email-link flows used by the app.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send an email link for sign-in. Caller provides ActionCodeSettings so
  /// platform-specific values (android/iOS) can be configured by the UI code.
  Future<void> sendSignInLinkToEmail({required String email, required ActionCodeSettings actionCodeSettings}) async {
    await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: actionCodeSettings);
  }

  bool isSignInWithEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<UserCredential> signInWithEmailLink({required String email, required String emailLink}) {
    return _auth.signInWithEmailLink(email: email, emailLink: emailLink);
  }

  Future<void> signOut() => _auth.signOut();
}
