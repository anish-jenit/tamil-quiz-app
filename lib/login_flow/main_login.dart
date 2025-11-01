import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/auth/email_input_screen.dart';
import '../firebase_options.dart';

/// Small error screen shown when Firebase fails to initialize.
class _InitErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stack;

  const _InitErrorScreen({required this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization error')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Firebase failed to initialize:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(error.toString()),
                const SizedBox(height: 12),
                if (stack != null) ...[
                  const Text('Stack trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(stack.toString()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Route uncaught Flutter errors to the console (also visible in browser console on web)
  FlutterError.onError = (details) {
    // Default behavior still prints the error in debug mode; we mirror to stdout as well.
    FlutterError.presentError(details);
    // Print so run captures it as well.
    // ignore: avoid_print
    print('FlutterError caught: ${details.exceptionAsString()}\n${details.stack}');
  };

  // Guard zone to catch async errors during initialization and surface them in terminal/browser console.
  runZonedGuarded(() async {
    try {
      // Try to initialize Firebase with platform options. If the generated
      // `lib/firebase_options.dart` is missing or incomplete this may fail on web.
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Debug: print initialized apps and options so developer can confirm
      try {
        final apps = Firebase.apps;
        // ignore: avoid_print
        print('Firebase initialized, apps: ${apps.map((a) => a.name).toList()}');
        final defaultApp = Firebase.app();
        // ignore: avoid_print
        print('Default app projectId: ${defaultApp.options.projectId}');
        // ignore: avoid_print
        print('Default app appId: ${defaultApp.options.appId}');
      } catch (e) {
        // ignore: avoid_print
        print('Error reading Firebase.app() after initialization: $e');
      }

      // Normal app start
      runApp(const LoginFlowApp());
    } catch (e, st) {
      // Log the error clearly so it's easy to copy from terminal or browser console.
      // ignore: avoid_print
      print('=== Firebase.initializeApp failed ===');
      // ignore: avoid_print
      print(e);
      // ignore: avoid_print
      print(st);

      // Show a minimal error UI so the app doesn't remain white/blank on web.
      runApp(_InitErrorScreen(error: e, stack: st));
    }
  }, (error, stack) {
    // Final catch-all for uncaught errors.
    // ignore: avoid_print
    print('Uncaught error in runZonedGuarded: $error');
    // ignore: avoid_print
    print(stack);
  });
}

class LoginFlowApp extends StatelessWidget {
  const LoginFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MaterialApp(
      title: 'Login Flow (test)',
      theme: ThemeData(useMaterial3: true),
      home: EmailInputScreen(authService: authService),
    );
  }
}
