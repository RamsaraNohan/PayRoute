import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the `users/{uid}` document — global identity only.
/// Role-specific data (wallet, photos, NIC, etc.) lives in role sub-collections.
class UserModel {
  final String userId;
  final String phonePrimary;
  final String displayName;
  final List<String> roles;
  final String activeRole;
  final bool profileCompleted;
  final String accountStatus; // "active" | "suspended" | "banned"
  final String deviceId;
  final String deviceModel;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.userId,
    required this.phonePrimary,
    this.displayName = '',
    this.roles = const [],
    this.activeRole = '',
    this.profileCompleted = false,
    this.accountStatus = 'active',
    this.deviceId = 'unknown',
    this.deviceModel = 'unknown',
    required this.createdAt,
    required this.lastLoginAt,
  });

  bool get isBanned => accountStatus == 'banned';
  bool get isSuspended => accountStatus == 'suspended';
  bool get isActive => accountStatus == 'active';
  bool get hasRoles => roles.isNotEmpty;
  bool get isMultiRole => roles.length > 1;

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      userId: id,
      phonePrimary: map['phonePrimary'] ?? map['phone'] ?? '',
      displayName: map['displayName'] ?? map['name'] ?? '',
      roles: map['roles'] != null
          ? List<String>.from(map['roles'])
          : _legacyRoleToList(map['role']),
      activeRole: map['activeRole'] ?? map['role'] ?? '',
      profileCompleted: map['profileCompleted'] ?? (map['role'] != null),
      accountStatus: map['accountStatus'] ?? 'active',
      deviceId: map['deviceId'] ?? 'unknown',
      deviceModel: map['deviceModel'] ?? 'unknown',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'phonePrimary': phonePrimary,
      'displayName': displayName,
      'roles': roles,
      'activeRole': activeRole,
      'profileCompleted': profileCompleted,
      'accountStatus': accountStatus,
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  /// Handles old schema where `role` was a single string.
  static List<String> _legacyRoleToList(dynamic role) {
    if (role is String && role.isNotEmpty) return [role];
    return [];
  }
}
