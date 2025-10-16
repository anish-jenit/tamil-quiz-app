import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService userService;
  UserProfile? profile;

  UserProvider({required this.userService});

  Future<void> loadProfile(String userId) async {
    profile = await userService.getUserProfile(userId);
    notifyListeners();
  }

  Stream<UserProfile?> watchProfile(String userId) => userService.watchUserProfile(userId);
}
