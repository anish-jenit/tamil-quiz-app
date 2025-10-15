import 'package:flutter/material.dart';

// Authentication is disabled. Commented out Firebase auth and Google sign-in.
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart' as gsi;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication is disabled.')),
            );
          },
          icon: const Icon(Icons.login),
          label: const Text('Continue with Google'),
        ),
      ),
    );
  }
}
