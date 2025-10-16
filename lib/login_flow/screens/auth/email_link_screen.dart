import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class EmailLinkScreen extends StatefulWidget {
  final String email;
  final AuthService authService;

  const EmailLinkScreen({super.key, required this.email, required this.authService});

  @override
  State<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends State<EmailLinkScreen> {
  // _loading is unused in this screen; remove it.

  Future<void> _checkLink() async {
    // In a real app you'd capture the initial link via FirebaseDynamicLinks or
    // handle incoming intents. Here we simply show instructions to the user.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open your email and click the link')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check your email')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('We sent a link to your email. Click it to sign in.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _checkLink, child: const Text('I clicked the link')),
        ]),
      ),
    );
  }
}
