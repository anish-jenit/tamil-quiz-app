import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_flow/services/user_service.dart';
import 'login_flow/screens/profile/profile_creation_screen.dart';
import 'login_flow/services/auth_service.dart';
import 'login_flow/screens/auth/email_input_screen.dart';
import 'sample_questions.dart';
import 'play_solo.dart';
import 'services/questions_repository.dart';
class LevelSelectionPage extends StatelessWidget {
  // mode can be 'solo', 'create_group', 'join_group' to adapt behavior
  final String mode;

  const LevelSelectionPage({super.key, this.mode = 'solo'});

  void _start(BuildContext context, List<Question> questions, String level) {
    // For now, group flows also start the same PlaySoloPage (no real sync implemented)
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaySoloPage(questions: questions, level: level)));
  }

  Future<List<Question>> _loadFromAsset(String assetPathOrLevel) async {
    // Accepts level names ('easy','intermediate','expert') or asset path fallback.
    final level = assetPathOrLevel.contains('questions_')
        ? (assetPathOrLevel.contains('beginner') ? 'easy' : assetPathOrLevel.contains('intermediate') ? 'intermediate' : 'expert')
        : assetPathOrLevel;
    return QuestionsRepository.load(level);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Level'),
        backgroundColor: cs.primary,
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.person),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to edit profile')));
                return;
              }
              final us = UserService();
              try {
                final profile = await us.getUserProfile(user.uid);
                if (!context.mounted) return;
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileCreationScreen(userId: user.uid, email: user.email ?? '', userService: us, initialProfile: profile)));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open profile: $e')));
              }
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              try {
                await AuthService().signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EmailInputScreen(authService: AuthService())));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                // show modal loading indicator while parsing large asset on background isolate
                showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  final qs = await _loadFromAsset('assets/questions_beginner.json');
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _start(context, qs, 'easy');
                } catch (e, st) {
                  // close loader if still open
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  debugPrint('Failed to load beginner questions: $e\n$st');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Center(child: Text('Beginner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  final qs = await _loadFromAsset('assets/questions_intermediate.json');
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _start(context, qs, 'intermediate');
                } catch (e, st) {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  debugPrint('Failed to load intermediate questions: $e\n$st');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), padding: const EdgeInsets.symmetric(vertical: 18), foregroundColor: Colors.black),
              child: const Center(child: Text('Intermediate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Show an informative dialog while expert questions are prepared.
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Preparing expert questions'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Expert questions are being prepared. This may take a few seconds.'),
                        SizedBox(height: 12),
                        Center(child: CircularProgressIndicator()),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    ],
                  ),
                );

                try {
                  final qs = await _loadFromAsset('assets/questions_expert.json');
                  if (!context.mounted) return;
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  _start(context, qs, 'expert');
                } catch (e, st) {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  debugPrint('Failed to load expert questions: $e\n$st');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Center(child: Text('Expert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
      ),
    );
  }
}
