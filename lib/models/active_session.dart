import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج الجلسة النشطة
class ActiveSession {
  const ActiveSession({
    required this.sessionId,
    required this.userId,
    required this.platform,
    required this.createdAt,
    required this.lastSeen,
    this.isActive = true,
  });

  /// إنشاء من Firestore Document
  factory ActiveSession.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;

    return ActiveSession(
      sessionId: doc.id,
      userId: data['userId'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// إنشاء من Map
  factory ActiveSession.fromMap(Map<String, dynamic> map) => ActiveSession(
      sessionId: map['sessionId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      platform: map['platform'] as String? ?? '',
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as DateTime?) ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );

  final String sessionId;
  final String userId;
  final String platform;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isActive;

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => <String, dynamic>{
      'sessionId': sessionId,
      'userId': userId,
      'platform': platform,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'isActive': isActive,
    };

  /// تحويل إلى Firestore Map
  Map<String, dynamic> toFirestoreMap() => <String, dynamic>{
      'userId': userId,
      'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isActive': isActive,
    };

  /// نسخ مع تعديلات
  ActiveSession copyWith({
    String? sessionId,
    String? userId,
    String? platform,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isActive,
  }) => ActiveSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
    );

  /// تنسيق آخر نشاط
  String get lastSeenFormatted {
    final Duration difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  @override
  String toString() => 'ActiveSession(sessionId: $sessionId, userId: $userId, platform: $platform, createdAt: $createdAt, lastSeen: $lastSeen, isActive: $isActive)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveSession &&
        other.sessionId == sessionId &&
        other.userId == userId &&
        other.platform == platform &&
        other.createdAt == createdAt &&
        other.lastSeen == lastSeen &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => sessionId.hashCode ^
        userId.hashCode ^
        platform.hashCode ^
        createdAt.hashCode ^
        lastSeen.hashCode ^
        isActive.hashCode;
}
