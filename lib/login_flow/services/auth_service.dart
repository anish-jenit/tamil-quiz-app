import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// Read optional server client id from dart-define so CI/devs can provide a
// Web OAuth client id without hardcoding it in source. Example:
// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID="<WEB_CLIENT_ID>"
const String kGoogleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendSignInLinkToEmail({required String email, required ActionCodeSettings actionCodeSettings}) async {
    await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: actionCodeSettings);
  }

  bool isSignInWithEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<UserCredential> signInWithEmailLink({required String email, required String emailLink}) {
    return _auth.signInWithEmailLink(email: email, emailLink: emailLink);
  }

  Future<void> signOut() => _auth.signOut();

  // NOTE: Google Sign-In was intentionally removed in this branch and
  // replaced with phone number + OTP flows. The old Google sign-in helper
  // was present here; keep the kGoogleServerClientId definition above for
  // backwards compatibility with any build flags, but do not use the
  // google_sign_in package here.

  /// Start phone number verification. Returns a [verificationId] string
  /// when the SMS code has been sent to the provided [phoneNumber].
  Future<String> verifyPhoneNumber({required String phoneNumber}) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // Automatic handling on some devices: directly sign in with the
      // provided credential. We still complete the flow for the caller.
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {
          // ignore errors here; we still want to surface other callbacks.
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  /// Sign in using the SMS [smsCode] and the [verificationId] obtained from
  /// [verifyPhoneNumber]. Returns the created [UserCredential].
  Future<UserCredential> signInWithSmsCode({required String verificationId, required String smsCode}) {
    final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    return _auth.signInWithCredential(credential);
  }

  /// Persist the email locally so we can complete email-link sign-in when the
  /// dynamic link opens the app.
  Future<void> persistEmailForLink(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_email_link', email);
  }

  Future<String?> takePersistedEmailForLink() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('pending_email_link');
    if (v != null) await prefs.remove('pending_email_link');
    return v;
  }

  /// Persist the pending dynamic link URL itself so that if the app was
  /// launched by the link before the UI was ready we can complete the flow
  /// once the app's navigator/context is available.
  Future<void> persistPendingEmailLinkUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_email_link_url', url);
  }

  Future<String?> takePersistedPendingEmailLinkUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('pending_email_link_url');
    if (v != null) await prefs.remove('pending_email_link_url');
    return v;
  }
}
