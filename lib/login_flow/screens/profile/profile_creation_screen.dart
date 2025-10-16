import 'package:flutter/material.dart';
import '../../widgets/house_selector.dart';
import '../../widgets/avatar_picker.dart';
import '../../services/user_service.dart';
import 'package:tamil_quiz_app/utils/validators.dart';
import '../../widgets/loading_overlay.dart';

class ProfileCreationScreen extends StatefulWidget {
  final String userId;
  final String email;
  final UserService userService;

  const ProfileCreationScreen({super.key, required this.userId, required this.email, required this.userService});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _usernameController = TextEditingController();
  String? _house;
  String? _avatar;
  bool _loading = false;

  Future<void> _createProfile() async {
    final username = _usernameController.text.trim();
    final v = Validators.validateUsername(username);
    if (v != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v)));
      return;
    }
    if (_house == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a house')));
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.userService.createUserProfile(
        userId: widget.userId,
        email: widget.email,
        username: username,
        house: _house!,
        avatar: _avatar,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create profile: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      loading: _loading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create profile')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            HouseSelector(selected: _house, onSelected: (h) => setState(() => _house = h)),
            const SizedBox(height: 12),
            const Text('Pick an avatar (optional)'),
            AvatarPicker(selected: _avatar, onChanged: (a) => setState(() => _avatar = a)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _createProfile, child: const Text('Create Profile')),
          ]),
        ),
      ),
    );
  }
}
