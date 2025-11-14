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
  // store uid field to match Firestore security rules (request.auth.uid)
  batch.set(usernameRef, {'uid': userId});
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

  /// Update an existing user's profile. This intentionally does not touch the
  /// `usernames` collection because username changes are not allowed in the
  /// current UX. Only fields supplied (house/avatar) are written.
  Future<void> updateUserProfile({
    required String userId,
    String? house,
    String? avatar,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final data = <String, dynamic>{};
    if (house != null) data['house'] = house;
    if (avatar != null) data['avatar'] = avatar;
    if (data.isEmpty) return;
    data['updatedAt'] = DateTime.now();
    await userRef.update(data);
  }
}
