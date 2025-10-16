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
    // createdAt may be a Firestore Timestamp (when cloud_firestore is used),
    // a ISO8601 string, or an int millis. Handle common cases defensively.
    final raw = data['createdAt'];
    DateTime createdAt;
    if (raw == null) {
      createdAt = DateTime.now();
    } else if (raw is DateTime) {
      createdAt = raw;
    } else if (raw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      // Unknown shape (e.g., Firestore Timestamp). Try to access .toDate() safely.
      try {
        final dt = (raw as dynamic).toDate();
        if (dt is DateTime) {
          createdAt = dt;
        } else {
          createdAt = DateTime.now();
        }
      } catch (_) {
        createdAt = DateTime.now();
      }
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
        // Store as ISO string by default. If you use Firestore you may want to
        // convert to a Timestamp on write using package:cloud_firestore.
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
