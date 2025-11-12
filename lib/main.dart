import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'quiz_home.dart';
import 'login_flow/main_login.dart' show LoginFlowApp;
import 'services/questions_repository.dart';
import 'level_selection.dart';
import 'create_group.dart';
import 'join_group.dart';
// import 'login_screen.dart';

// Toggle from the command line:  flutter run --dart-define=SKIP_AUTH=true
const bool kSkipAuth = bool.fromEnvironment('SKIP_AUTH', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kSkipAuth) {
    // Only initialize when we actually use Firebase. Also avoid duplicate
    // initialization when another runner or test harness already initialized
    // Firebase in the same process.
    try {
      if (Firebase.apps.isEmpty) {
        // On web we must provide options. On native platforms the
        // generated `google-services.json` / `GoogleService-Info.plist`
        // will be used by the platform SDKs, so call initializeApp()
        // without options to let the native SDK pick them up.
        // The repository's `lib/firebase_options.dart` currently contains
        // placeholders for Android/iOS which would incorrectly override
        // the native config if passed here.
        // For web, pass the options object.
        if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
          await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        } else {
          await Firebase.initializeApp();
        }
      } else {
        // ignore: avoid_print
        print('Firebase already initialized (main), skipping initializeApp.');
      }
    } catch (e) {
      // Some environments may attempt to initialize Firebase twice (tests,
      // alternative runners). If a duplicate-app FirebaseException occurs,
      // treat it as non-fatal and continue. Log other exceptions.
      try {
        // FirebaseException is not always available at this callsite during
        // early init; inspect string if necessary.
        final msg = e.toString();
        if (msg.contains('duplicate-app') || msg.contains('A Firebase App named "[DEFAULT]" already exists')) {
          // ignore: avoid_print
          print('Caught duplicate-app during Firebase.initializeApp; continuing.');
        } else {
          // Unexpected error — rethrow so it surfaces during startup.
          rethrow;
        }
      } catch (_) {
        // If inspecting throws, rethrow the original exception.
        rethrow;
      }
    }
  }

  // Kick off background preloads for large assets so the expert level feels snappier
  // when a user taps it from the level selection screen.
  QuestionsRepository.preload('expert');

  if (!kSkipAuth) {
    // When authentication is enabled, run the auth-driven LoginFlowApp which
    // listens to authStateChanges and shows the appropriate screens.
    runApp(const LoginFlowApp());
  } else {
    // When skipping auth (dev/testing), run the normal App that starts at QuizHome.
    runApp(const App());
  }
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
