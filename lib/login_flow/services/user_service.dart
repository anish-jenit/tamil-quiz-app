import '../models/user_profile.dart';

/// Minimal stub of UserService.
///
/// This avoids a hard dependency on cloud_firestore in the main project so the
/// analyzer remains happy. Replace with a real implementation that uses
/// package:cloud_firestore when you upgrade firebase packages and want
/// Firestore integration.
class UserService {
  Future<bool> checkUsernameAvailable(String username) async {
    // Not implemented (no Firestore available). Treat as available.
    return true;
  }

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String username,
    required String house,
    String? avatar,
  }) async {
    // TODO: implement with Firestore. For now, no-op or throw if you want.
    return;
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    return null;
  }

  Stream<UserProfile?> watchUserProfile(String userId) async* {
    yield null;
  }
}
