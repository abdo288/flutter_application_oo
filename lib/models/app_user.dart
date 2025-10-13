import 'package:cloud_firestore/cloud_firestore.dart';

/// أدوار المستخدم
enum UserRole {
  admin,
  seller,
}

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'seller':
      return UserRole.seller;
    default:
      return UserRole.seller;
  }
}

String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.seller:
      return 'seller';
  }
}

/// نموذج مستخدم التطبيق مع الدور
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      email: (data['email'] ?? '') as String,
      displayName: data['displayName'] as String?,
      role: userRoleFromString((data['role'] ?? 'seller') as String),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin;
  bool get isSeller => role == UserRole.seller;

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'role': userRoleToString(role),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : Timestamp.fromDate(DateTime.now()),
        'updatedAt': updatedAt != null
            ? Timestamp.fromDate(updatedAt!)
            : Timestamp.fromDate(DateTime.now()),
      };
}
