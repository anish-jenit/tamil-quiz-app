import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthService authService;
  User? user;

  AuthProvider({required this.authService}) {
    authService.authStateChanges.listen((u) {
      user = u;
      notifyListeners();
    });
  }
}
