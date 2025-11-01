import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkUsernameAvailable(String username) async {
    final doc = await _firestore.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String username,
    required String house,
    String? avatar,
  }) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final usernameRef = _firestore.collection('usernames').doc(username.toLowerCase());

    final profile = UserProfile(
      userId: userId,
      email: email,
      username: username,
      house: house,
      avatar: avatar,
      createdAt: DateTime.now(),
    );

    batch.set(userRef, profile.toMap());
    batch.set(usernameRef, {'userId': userId});
    await batch.commit();
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
  if (!doc.exists) return null;
  return UserProfile.fromMap(doc.id, doc.data()!);
  }

  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snap) {
  if (!snap.exists) return null;
  return UserProfile.fromMap(snap.id, snap.data()!);
    });
  }
}
