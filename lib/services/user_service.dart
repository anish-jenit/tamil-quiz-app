import '../models/user_profile.dart';

/// Minimal stub of UserService used by the main app. Replace with a real
/// Firestore-backed implementation when upgrading firebase packages.
class UserService {
  Future<bool> checkUsernameAvailable(String username) async => true;

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String username,
    required String house,
    String? avatar,
  }) async {
    // no-op for now
    return;
  }

  Future<UserProfile?> getUserProfile(String userId) async => null;

  Stream<UserProfile?> watchUserProfile(String userId) async* {
    yield null;
  }
}
