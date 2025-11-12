import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/animated_tamil_background.dart';

class EmailInputScreen extends StatefulWidget {
  final AuthService authService;
  const EmailInputScreen({super.key, required this.authService});

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  final TextEditingController _phoneController = TextEditingController(text: '+91');
  // Used to show the loading overlay. Analyzer may report unused in some cases,
  // keep the field and reference it via the LoadingOverlay below.
  // ignore: unused_field
  bool _loading = false;
  String? _debugOutput;
  // Developer test credentials (debug-only). Populated by the "Use test number"
  // helper below and passed to the OTP screen so QA can autofill the code.
  String? _devTestNumber;
  String? _devTestCode;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign in')),
        body: Stack(
          children: [
            // decorative animated background using Kahoot-like accent
            AnimatedTamilBackground(baseColor: Theme.of(context).colorScheme.primary),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Phone number input + OTP
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone (E.164, e.g. +919876543210)'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final phone = _phoneController.text.trim();
                        final navigator = Navigator.of(context);
                        if (phone.isEmpty) {
                          messenger.showSnackBar(const SnackBar(content: Text('Please enter a phone number')));
                          return;
                        }
                        setState(() => _loading = true);
                        try {
                          final verificationId = await widget.authService.verifyPhoneNumber(phoneNumber: phone);
                          if (!mounted) return;
                          navigator.push(MaterialPageRoute(builder: (_) => OtpEntryScreen(authService: widget.authService, verificationId: verificationId, prefilledSmsCode: _devTestCode)));
                        } catch (e) {
                          if (!mounted) return;
                          String message = 'Failed to send OTP: $e';
                          if (e is FirebaseAuthException && e.code == 'operation-not-allowed') {
                            message = 'Phone sign-in is disabled for this Firebase project. Enable it in the Firebase Console: Authentication → Sign-in method → Phone.';
                          }
                          messenger.showSnackBar(SnackBar(content: Text(message)));
                          if (kDebugMode) _debugOutput = message;
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                      icon: const Icon(Icons.sms),
                      label: const Text('Send OTP'),
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 18),

                    // Developer debug helper (minimal)
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Prompt for a test phone number and optional test code.
                            final numberController = TextEditingController(text: _devTestNumber ?? '');
                            final codeController = TextEditingController(text: _devTestCode ?? '');
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Set test credentials (debug)'),
                                content: Column(mainAxisSize: MainAxisSize.min, children: [
                                  TextField(controller: numberController, decoration: const InputDecoration(labelText: 'Test phone (E.164)')),
                                  TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Test SMS code (optional)'), keyboardType: TextInputType.number),
                                ]),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
                                ],
                              ),
                            );
                            if (result == true) {
                              setState(() {
                                _devTestNumber = numberController.text.trim();
                                _devTestCode = codeController.text.trim().isEmpty ? null : codeController.text.trim();
                                if (_devTestNumber != null && _devTestNumber!.isNotEmpty) _phoneController.text = _devTestNumber!;
                              });
                            }
                          },
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Use test number'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _devTestNumber == null
                              ? null
                              : () {
                                  // Autofill the phone controller with the saved test number.
                                  setState(() {
                                    _phoneController.text = _devTestNumber!;
                                  });
                                },
                          icon: const Icon(Icons.phone_android),
                          label: const Text('Fill test number'),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (_debugOutput != null) ...[
                        const Text('Last debug output:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        SelectableText(_debugOutput!),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpEntryScreen extends StatefulWidget {
  final AuthService authService;
  final String verificationId;
  // Optional debug-only prefilled SMS code (from the debug helper in the
  // previous screen). When present we'll seed the text field so QA can
  // verify without typing the code.
  final String? prefilledSmsCode;
  const OtpEntryScreen({
    super.key,
    required this.authService,
    required this.verificationId,
    this.prefilledSmsCode,
  });

  @override
  State<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends State<OtpEntryScreen> {
  final TextEditingController _smsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If a prefilled code was provided (debug), seed the controller so the
    // tester doesn't need to type it manually.
    if (widget.prefilledSmsCode != null && widget.prefilledSmsCode!.isNotEmpty) {
      _smsController.text = widget.prefilledSmsCode!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _smsController, decoration: const InputDecoration(labelText: 'SMS Code'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final code = _smsController.text.trim();
            if (code.isEmpty) {
              messenger.showSnackBar(const SnackBar(content: Text('Please enter the SMS code')));
              return;
            }
            try {
              final cred = await widget.authService.signInWithSmsCode(verificationId: widget.verificationId, smsCode: code);
              if (!mounted) return;
              messenger.showSnackBar(SnackBar(content: Text('Signed in as ${cred.user?.phoneNumber ?? cred.user?.uid}')));
              navigator.pop();
            } catch (e) {
              if (!mounted) return;
              String message = 'OTP verification failed: $e';
              if (e is FirebaseAuthException && e.code == 'invalid-verification-code') {
                message = 'The verification code entered is invalid. Please check the code and try again.';
              }
              messenger.showSnackBar(SnackBar(content: Text(message)));
            }
          },
            child: const Text('Verify OTP'),
          )
        ]),
      ),
    );
  }
}
