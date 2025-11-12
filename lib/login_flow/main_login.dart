import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/auth/email_input_screen.dart';
import 'screens/auth/continue_as_screen.dart';
import '../quiz_home.dart';
import 'services/user_service.dart';
import 'models/user_profile.dart';
import 'screens/profile/profile_creation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

// A global navigator key so dynamic-link handlers that run before the UI is
// visible can still show dialogs once the app's navigator is available.
final GlobalKey<NavigatorState> kLoginNavigatorKey = GlobalKey<NavigatorState>();

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
      // Try to initialize Firebase with platform options. If Firebase was
      // already initialized earlier (for example when using a different
      // runner), avoid calling initializeApp again which would throw
      // a duplicate-app error on Android/iOS/web.
      // Debug: print how many Firebase apps are currently registered before init.
      try {
        // ignore: avoid_print
        print('DEBUG: Firebase.apps.length = ${Firebase.apps.length}');
      } catch (err) {
        // ignore: avoid_print
        print('DEBUG: Firebase.apps lookup threw: $err');
      }

      if (Firebase.apps.isEmpty) {
        // ignore: avoid_print
        print('DEBUG: calling Firebase.initializeApp()');
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } else {
        // ignore: avoid_print
        print('Firebase already initialized, skipping initializeApp call.');
      }

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

      // For local development use the Firestore emulator when running in
      // debug mode. This lets developers test without enabling cloud APIs
      // or affecting production data. The Android emulator should reach
      // the host machine at 10.0.2.2.
      // Allow opting into the local Firestore emulator via a dart-define so
      // developers don't accidentally point debug runs at an emulator when
      // they intend to test against the real cloud Firestore.
      const bool useEmulator = bool.fromEnvironment('USE_FIRESTORE_EMULATOR', defaultValue: false);
      try {
        if (kDebugMode && useEmulator) {
          // Use the default emulator host/port. If you run the emulator on
          // a different host/port, update these values.
          FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
          // ignore: avoid_print
          print('Firestore emulator enabled at 10.0.2.2:8080 (debug + env)');
        }
      } catch (e) {
        // ignore: avoid_print
        print('Failed to enable Firestore emulator: $e');
      }

      // Set up Dynamic Links handler to complete email-link sign-in when a
      // link opens the app.
      try {
  // Handle the initial dynamic link that may have opened the app.
  // NOTE: Firebase Dynamic Links is deprecated; keep this code for
  // compatibility while migrating. Add a TODO to replace this when
  // moving off Dynamic Links.
  // TODO(maintainer): migrate away from firebase_dynamic_links before Aug 25, 2025.
  // ignore: deprecated_member_use
  final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
        if (initialLink != null) {
          final Uri deepLink = initialLink.link;
          // ignore: avoid_print
          print('DEBUG: initial dynamic link: $deepLink');
          await _maybeCompleteEmailLinkSignIn(deepLink.toString());
        }

        // Listen for incoming links while the app is running.
        // ignore: deprecated_member_use
        FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
          final Uri deepLink = dynamicLinkData.link;
          // ignore: avoid_print
          print('DEBUG: received dynamic link: $deepLink');
          await _maybeCompleteEmailLinkSignIn(deepLink.toString());
        });
      } catch (err) {
        // ignore: avoid_print
        print('Dynamic Links setup failed: $err');
      }

      // Normal app start
      runApp(const LoginFlowApp());
    } catch (e, st) {
      // If Firebase was already initialized in another part of the process
      // we may receive a duplicate-app error. Treat that as non-fatal and
      // continue to start the app.
      try {
        if (e is FirebaseException && e.code == 'duplicate-app') {
          // ignore: avoid_print
          print('Firebase duplicate-app detected; continuing without re-initializing.');
          runApp(const LoginFlowApp());
          return;
        }
      } catch (_) {
        // ignore any errors while checking the exception type and fall through
      }

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

/// Try to complete email-link sign-in if [link] is an email sign-in link.
Future<void> _maybeCompleteEmailLinkSignIn(String link) async {
  try {
    final auth = FirebaseAuth.instance;
    final authService = AuthService();
    if (authService.isSignInWithEmailLink(link)) {
      // Get any stored pending email and attempt sign-in.
      final email = await authService.takePersistedEmailForLink();
      // ignore: avoid_print
      print('DEBUG: completing email link sign-in with stored email=$email');
      if (email != null) {
        try {
          await auth.signInWithEmailLink(email: email, emailLink: link);
          // ignore: avoid_print
          print('DEBUG: signInWithEmailLink succeeded for $email');
        } catch (e) {
          // ignore: avoid_print
          print('DEBUG: signInWithEmailLink failed: $e');
        }
      } else {
        // No stored email; to simplify UX we won't prompt for the email in a
        // modal dialog. Instead, persist the pending link and navigate the
        // user to the EmailInputScreen where they can enter their email to
        // complete sign-in. This avoids asking for the email out-of-band.
        // ignore: avoid_print
        print('DEBUG: no stored email to complete email-link sign-in - persisting and navigating to EmailInputScreen');

        // Persist the pending link; the app will consume it after startup or
        // when the EmailInputScreen inspects persisted pending link values.
        await authService.persistPendingEmailLinkUrl(link);

        // If navigator is available, bring up the EmailInputScreen so the
        // user can enter the email there and finish the flow.
        if (kLoginNavigatorKey.currentState != null) {
          try {
            kLoginNavigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => EmailInputScreen(authService: authService)));
          } catch (e) {
            // ignore: avoid_print
            print('Error navigating to EmailInputScreen after persisting pending link: $e');
          }
        }
      }
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error while attempting to complete email-link sign-in: $e');
  }
}

class LoginFlowApp extends StatefulWidget {
  const LoginFlowApp({super.key});

  @override
  State<LoginFlowApp> createState() => _LoginFlowAppState();
}

class _LoginFlowAppState extends State<LoginFlowApp> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // After the first frame, consume any pending dynamic link that was
    // persisted during early startup and attempt to complete sign-in.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final pending = await _authService.takePersistedPendingEmailLinkUrl();
        if (pending != null) {
          // Try to complete the flow: first check for a stored email.
          final email = await _authService.takePersistedEmailForLink();
          if (email != null) {
            try {
              await FirebaseAuth.instance.signInWithEmailLink(email: email, emailLink: pending);
              // ignore: avoid_print
              print('DEBUG: signInWithEmailLink (post-start) succeeded for persisted email');
            } catch (e) {
              // ignore: avoid_print
              print('DEBUG: signInWithEmailLink (post-start) failed: $e');
            }
          } else {
            // Prompt user for email since we have a pending link.
            await _promptForEmailAndComplete(pending);
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error processing pending dynamic link after startup: $e');
      }
    });
  }

  Future<void> _promptForEmailAndComplete(String link) async {
    // During startup we don't show modal dialogs; instead persist the
    // pending link and navigate the user to the EmailInputScreen so they can
    // enter their email and complete the sign-in flow from a clear place in
    // the app. This avoids blocking startup with modal prompts.
    try {
      final authService = AuthService();
      await authService.persistPendingEmailLinkUrl(link);
      if (kLoginNavigatorKey.currentState != null) {
        try {
          kLoginNavigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => EmailInputScreen(authService: authService)));
        } catch (e) {
          // ignore: avoid_print
          print('Error navigating to EmailInputScreen after persisting pending link (post-start): $e');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error persisting pending link after startup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the app and react to authentication state changes so the UI
    // updates automatically when the user signs in or out.
    
    return MaterialApp(
      navigatorKey: kLoginNavigatorKey,
      title: 'Login Flow (test)',
      theme: ThemeData(useMaterial3: true),
      home: Builder(builder: (rootCtx) {
        final authStream = StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            // Show a small loading indicator while we don't yet have auth state.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final user = snapshot.data;
            if (user != null) {
              // If the user signed in with email-link, show the continue-as
              // screen to confirm the email.
              if (user.email != null) {
                return ContinueAsScreen(authService: _authService, email: user.email!);
              }

              // For other sign-ins (phone/OTP) ensure the user has a profile
              // in Firestore. If not, route them to the ProfileCreationScreen.
              final userService = UserService();
              return FutureBuilder<UserProfile?>(
                future: userService.getUserProfile(user.uid),
                builder: (context, AsyncSnapshot<UserProfile?> snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }
                  final UserProfile? profile = snap.data;
                  // Treat a profile with username == '?' as incomplete and show
                  // the profile creation screen in that case.
                  if (profile != null && (profile.username.trim() != '?')) {
                    // Profile is complete — go to the main home where the user
                    // chooses Play Solo / Create Group / Join Group.
                    return const QuizHome();
                  }
                  // No profile yet or incomplete profile — ask user to create one.
                  final email = user.email ?? user.phoneNumber ?? '';
                  return ProfileCreationScreen(userId: user.uid, email: email, userService: userService);
                },
              );
            }

            return EmailInputScreen(authService: _authService);
          },
        );

        // Overlay small profile/edit and logout actions so they're available at
        // the top-right of the app regardless of which inner page is shown.
        return Stack(
          children: [
            authStream,
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: StreamBuilder<User?>(
                  stream: _authService.authStateChanges,
                  builder: (c, snap) {
                    final u = snap.data;
                    if (u == null) return const SizedBox.shrink();
                    final us = UserService();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit profile',
                          icon: const Icon(Icons.person),
                          onPressed: () async {
                            try {
                              final profile = await us.getUserProfile(u.uid);
                              if (!rootCtx.mounted) return;
                              Navigator.of(rootCtx).push(MaterialPageRoute(builder: (_) => ProfileCreationScreen(userId: u.uid, email: u.email ?? '', userService: us, initialProfile: profile)));
                            } catch (e) {
                              if (!rootCtx.mounted) return;
                              ScaffoldMessenger.of(rootCtx).showSnackBar(SnackBar(content: Text('Failed to open profile: $e')));
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Sign out',
                          icon: const Icon(Icons.logout_rounded),
                          onPressed: () async {
                            try {
                              await _authService.signOut();
                              // After sign-out the StreamBuilder will show the sign-in UI.
                            } catch (e) {
                              if (!rootCtx.mounted) return;
                              ScaffoldMessenger.of(rootCtx).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
