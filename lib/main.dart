import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'quiz_home.dart';
import 'level_selection.dart';
import 'create_group.dart';
import 'join_group.dart';
// import 'login_screen.dart';

// Toggle from the command line:  flutter run --dart-define=SKIP_AUTH=true
const bool kSkipAuth = bool.fromEnvironment('SKIP_AUTH', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kSkipAuth) {
    // Only initialize when we actually use Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tamil Quiz',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3A86FF),
      ),
      // Auth gate was removed/commented out. When SKIP_AUTH is false the
      // app previously used _AuthGate to drive sign-in; with auth disabled
      // we'll show QuizHome directly.
      home: const QuizHome(),
      routes: {
        '/level-select': (_) => const LevelSelectionPage(),
        '/create-group': (_) => const CreateGroupPage(),
        '/join-group': (_) => const JoinGroupPage(),
      },
    );
  }
}
