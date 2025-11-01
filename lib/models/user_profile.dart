import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String email;
  final String username;
  final String house;
  final String? avatar;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.email,
    required this.username,
    required this.house,
    this.avatar,
    required this.createdAt,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['createdAt'];
    DateTime createdAt;
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is DateTime) {
      createdAt = raw;
    } else {
      createdAt = DateTime.now();
    }

    return UserProfile(
      userId: id,
      email: data['email'] as String,
      username: data['username'] as String,
      house: data['house'] as String,
      avatar: data['avatar'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'username': username,
        'house': house,
        'avatar': avatar,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // Firestore-friendly map
}
