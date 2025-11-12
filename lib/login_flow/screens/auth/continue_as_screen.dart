import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_input_screen.dart';
// HomeScreen import removed; we route to LevelSelectionPage or ProfileCreationScreen instead.
import '../../services/user_service.dart';
import '../profile/profile_creation_screen.dart';
import '../../../quiz_home.dart';
import '../../widgets/animated_tamil_background.dart';

class ContinueAsScreen extends StatefulWidget {
  final AuthService authService;
  final String email;

  const ContinueAsScreen({super.key, required this.authService, required this.email});

  @override
  State<ContinueAsScreen> createState() => _ContinueAsScreenState();
}

class _ContinueAsScreenState extends State<ContinueAsScreen> {
  String? _displayName;
  String? _photoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() { _displayName = widget.email; _photoUrl = null; _loading = false; });
      return;
    }
    final us = UserService();
    try {
      final profile = await us.getUserProfile(user.uid);
      if (!mounted) return;
      if (profile != null && profile.username.trim() != '?') {
        setState(() {
          _displayName = profile.username;
          _photoUrl = profile.avatar != null ? 'assets/avatars/${profile.avatar}.png' : user.photoURL;
          _loading = false;
        });
      } else {
        setState(() {
          _displayName = widget.email.isNotEmpty ? widget.email : (user.phoneNumber ?? '?');
          _photoUrl = user.photoURL;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayName = widget.email.isNotEmpty ? widget.email : (user.phoneNumber ?? '?');
        _photoUrl = user.photoURL;
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EmailInputScreen(authService: widget.authService)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-out failed: $e')));
    }
  }

  Future<void> _continueImpl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userService = UserService();
    try {
      final profile = await userService.getUserProfile(user.uid);
      // Profile exists and username not equal to '?' indicates completion.
      if (profile != null && profile.username.trim() != '?') {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const QuizHome()));
        return;
      }
      // No profile yet or incomplete (username == '?') — send user to profile creation screen.
      final email = user.email ?? user.phoneNumber ?? '';
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ProfileCreationScreen(userId: user.uid, email: email, userService: userService)));
    } catch (e) {
      // On error, route to profile creation as a safe default so the user can
      // complete their profile rather than ending up at the generic Home screen.
      if (!mounted) return;
      final email = user.email ?? user.phoneNumber ?? '';
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ProfileCreationScreen(userId: user.uid, email: email, userService: userService)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = _photoUrl ?? user?.photoURL;
    final display = (_displayName ?? widget.email).trim().isNotEmpty ? (_displayName ?? widget.email) : '?';
    final initials = display.isNotEmpty ? display[0].toUpperCase() : '?';
    return Scaffold(
      body: Stack(
        children: [
          AnimatedTamilBackground(baseColor: Theme.of(context).colorScheme.primary),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: _loading ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOut,
                        child: AnimatedScale(
                          scale: _loading ? 0.90 : 1.0,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          child: Card(
                            elevation: 14,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Center(child: Text('Continue as', style: TextStyle(fontSize: 16))),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: CircleAvatar(
                                      radius: 44,
                                      backgroundColor: Colors.grey.shade100,
                                      backgroundImage: photoUrl != null ? (photoUrl.startsWith('assets/') ? AssetImage(photoUrl) as ImageProvider : NetworkImage(photoUrl)) : null,
                                      child: photoUrl == null ? Text(initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(child: _loading ? const CircularProgressIndicator() : Text(display, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                                  const SizedBox(height: 18),
                                  ElevatedButton(onPressed: _continueImpl, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Continue')),
                                  const SizedBox(height: 10),
                                  TextButton(onPressed: _signOut, child: const Text('Sign out')),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
