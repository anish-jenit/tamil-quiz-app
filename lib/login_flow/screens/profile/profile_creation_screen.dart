import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/house_selector.dart';
import '../../widgets/avatar_picker.dart';
import '../../services/user_service.dart';
import '../../models/user_profile.dart';
import 'package:tamil_quiz_app/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/loading_overlay.dart';
import '../../../level_selection.dart';

class ProfileCreationScreen extends StatefulWidget {
  final String userId;
  final String email;
  final UserService userService;
  final UserProfile? initialProfile;

  const ProfileCreationScreen({super.key, required this.userId, required this.email, required this.userService, this.initialProfile});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _usernameController = TextEditingController();
  String? _house;
  String? _avatar;
  bool _loading = false;

  bool get _isEditing => widget.initialProfile != null;

  Future<void> _createProfile() async {
    // If this is an edit (and username already created), we only allow
    // changing non-unique fields like house and avatar. Username is immutable
    // in the current UX.
    final username = _usernameController.text.trim();
    if (!_isEditing) {
      final v = Validators.validateUsername(username);
      if (v != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v)));
        return;
      }
    }

    if (_house == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a class')));
      return;
    }
    if (_avatar == null || _avatar!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick an avatar')));
      return;
    }

    setState(() => _loading = true);
    // Debug: print current auth user id so we can confirm the client is
    // authenticated against the same Firebase project that holds the rules.
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // ignore: avoid_print
      print('DEBUG: attempting profile create/update as uid=$uid, username=${_usernameController.text}, house=$_house, avatar=$_avatar');
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: failed to read FirebaseAuth.currentUser: $e');
    }
    try {
      if (_isEditing) {
        // Simple update that doesn't touch the `usernames` mapping.
        await widget.userService.updateUserProfile(userId: widget.userId, house: _house, avatar: _avatar).timeout(const Duration(seconds: 30));
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        // Check username availability first to avoid a long failing write.
        final available = await widget.userService.checkUsernameAvailable(username);
        if (!available) {
          if (!mounted) return;
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username already taken')));
          return;
        }

        // Perform the create with a longer timeout so the UI has time to
        // recover on slow networks. If this times out we'll surface a retry
        // action to the user instead of letting the UI hang indefinitely.
        await widget.userService.createUserProfile(
          userId: widget.userId,
          email: widget.email,
          username: username,
          house: _house!,
          avatar: _avatar,
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LevelSelectionPage()));
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(
        content: const Text('Request timed out. Check your network and try again.'),
        action: SnackBarAction(label: 'Retry', onPressed: () => _createProfile()),
      ));
    } catch (e) {
      // Log the error for debugging and show a helpful message to the user.
      // Firestore permission/rules issues commonly manifest here when writes
      // are rejected server-side; printing helps capture the exact error.
      // ignore: avoid_print
      print('Profile create/update failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create/update profile: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    if (p != null) {
      _usernameController.text = p.username;
      _house = p.house;
      _avatar = p.avatar;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remove the animated background on the profile edit/create screen —
    // the user wanted a static color here. Use a subtle primary-tinted
    // scaffold background and a highlighted save button.
    // Use a purple Kahoot-like background gradient and ensure all text is
    // readable on top of it. We keep the scaffold transparent and paint the
    // gradient behind the content.
    const purpleTop = Color(0xFF7C4DFF);
    const purpleBottom = Color(0xFF5E35B1);
    final cs = Theme.of(context).colorScheme;
    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit profile' : 'Create profile'),
          backgroundColor: purpleTop,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [purpleTop, purpleBottom],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              TextField(
                controller: _usernameController,
                enabled: !_isEditing,
                style: TextStyle(color: cs.onPrimary),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: cs.onPrimary.withAlpha((0.85 * 255).round())),
                  helperText: _isEditing ? 'Username is fixed after creation' : null,
                  helperStyle: TextStyle(color: cs.onPrimary.withAlpha((0.7 * 255).round())),
                  // Make the TextField stand out on purple background
                  filled: true,
                  fillColor: cs.onPrimary.withAlpha((0.06 * 255).round()),
                ),
              ),
              const SizedBox(height: 12),
              // Ensure HouseSelector renders with readable text on purple.
              DefaultTextStyle.merge(
                style: TextStyle(color: cs.onPrimary),
                child: HouseSelector(selected: _house, onSelected: (h) => setState(() => _house = h)),
              ),
              const SizedBox(height: 12),
              Text('Pick an avatar (optional)', style: TextStyle(color: cs.onPrimary.withAlpha((0.9 * 255).round()))),
              AvatarPicker(selected: _avatar, onChanged: (a) => setState(() => _avatar = a)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _createProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: purpleTop,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(_isEditing ? 'Save Profile' : 'Create Profile'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
