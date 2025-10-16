import 'package:flutter/material.dart';
// provider import removed: not used in this screen
import '../../services/auth_service.dart';
import 'package:tamil_quiz_app/utils/validators.dart';
import '../../widgets/loading_overlay.dart';
import 'email_link_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
// firebase_core import removed: not used in this screen

class EmailInputScreen extends StatefulWidget {
  final AuthService authService;
  const EmailInputScreen({super.key, required this.authService});

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    final err = Validators.validateEmail(email);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    setState(() => _loading = true);
    try {
      final acs = ActionCodeSettings(
        url: 'https://example.page.link/finishSignIn',
        handleCodeInApp: true,
      );
      await widget.authService.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmailLinkScreen(email: email, authService: widget.authService)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send link: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign in')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _sendLink, child: const Text('Send Verification Link')),
          ]),
        ),
      ),
    );
  }
}
