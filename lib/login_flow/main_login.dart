import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/auth/email_input_screen.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LoginFlowApp());
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
