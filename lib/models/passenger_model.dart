import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the `passengers/{passengerId}` document.
/// [passengerId] is prefixed: "PAS-XXXXXXXX"
/// [userId] is the Firebase Auth UID — used for queries.
/// [walletBalance] is in LKR cents (LKR 45.00 = 4500).
class PassengerModel {
  final String passengerId;
  final String userId;
  final String fullName;
  final String profilePhotoUrl;
  final String nicNumber;
  final String homeAddress;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final int walletBalance; // LKR cents
  final String accountStatus; // "active" | "suspended"
  final int profileCompletion; // 0-100
  final DateTime createdAt;

  PassengerModel({
    required this.passengerId,
    required this.userId,
    required this.fullName,
    this.profilePhotoUrl = '',
    this.nicNumber = '',
    this.homeAddress = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.walletBalance = 0,
    this.accountStatus = 'active',
    this.profileCompletion = 0,
    required this.createdAt,
  });

  factory PassengerModel.fromMap(Map<String, dynamic> map, String id) {
    return PassengerModel(
      passengerId: id,
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? map['name'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'] ?? map['profileImageUrl'] ?? '',
      nicNumber: map['nicNumber'] ?? '',
      homeAddress: map['homeAddress'] ?? map['address'] ?? '',
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '',
      walletBalance: map['walletBalance']?.toInt() ?? 0,
      accountStatus: map['accountStatus'] ?? 'active',
      profileCompletion: map['profileCompletion']?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'userId': userId,
      'fullName': fullName,
      'profilePhotoUrl': profilePhotoUrl,
      'nicNumber': nicNumber,
      'homeAddress': homeAddress,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'walletBalance': walletBalance,
      'accountStatus': accountStatus,
      'profileCompletion': profileCompletion,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Calculates profile completion % based on filled fields.
  static int computeCompletion(Map<String, dynamic> data) {
    final fields = [
      'fullName',
      'profilePhotoUrl',
      'nicNumber',
      'homeAddress',
      'emergencyContactName',
      'emergencyContactPhone',
    ];
    final filled = fields
        .where((f) => data[f] != null && data[f].toString().isNotEmpty)
        .length;
    return ((filled / fields.length) * 100).round();
  }

  PassengerModel copyWith({int? walletBalance}) {
    return PassengerModel(
      passengerId: passengerId,
      userId: userId,
      fullName: fullName,
      profilePhotoUrl: profilePhotoUrl,
      nicNumber: nicNumber,
      homeAddress: homeAddress,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      walletBalance: walletBalance ?? this.walletBalance,
      accountStatus: accountStatus,
      profileCompletion: profileCompletion,
      createdAt: createdAt,
    );
  }
}
