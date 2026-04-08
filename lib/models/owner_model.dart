import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the `owners/{ownerId}` document.
/// [ownerId] is prefixed: "OWN-XXXXXXXX"
class OwnerModel {
  final String ownerId;
  final String userId;
  final String fullName;
  final String nicNumber;
  final String phoneSecondary;
  final String address;
  final String profilePhotoUrl;
  final String selfiePhotoUrl;
  final String businessName;
  final int totalBuses;
  final String verificationStatus; // "pending" | "approved" | "rejected"
  final String verificationNote;
  final int verificationLevel;
  final String accountStatus;
  final String deviceId;
  final DateTime createdAt;

  OwnerModel({
    required this.ownerId,
    required this.userId,
    required this.fullName,
    this.nicNumber = '',
    this.phoneSecondary = '',
    this.address = '',
    this.profilePhotoUrl = '',
    this.selfiePhotoUrl = '',
    this.businessName = '',
    this.totalBuses = 1,
    this.verificationStatus = 'pending',
    this.verificationNote = '',
    this.verificationLevel = 1,
    this.accountStatus = 'active',
    this.deviceId = 'unknown',
    required this.createdAt,
  });

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  factory OwnerModel.fromMap(Map<String, dynamic> map, String id) {
    return OwnerModel(
      ownerId: id,
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      nicNumber: map['nicNumber'] ?? '',
      phoneSecondary: map['phoneSecondary'] ?? '',
      address: map['address'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'] ?? '',
      selfiePhotoUrl: map['selfiePhotoUrl'] ?? '',
      businessName: map['businessName'] ?? '',
      totalBuses: map['totalBuses']?.toInt() ?? 1,
      verificationStatus: map['verificationStatus'] ?? 'pending',
      verificationNote: map['verificationNote'] ?? '',
      verificationLevel: map['verificationLevel']?.toInt() ?? 1,
      accountStatus: map['accountStatus'] ?? 'active',
      deviceId: map['deviceId'] ?? 'unknown',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'userId': userId,
      'fullName': fullName,
      'nicNumber': nicNumber,
      'phoneSecondary': phoneSecondary,
      'address': address,
      'profilePhotoUrl': profilePhotoUrl,
      'selfiePhotoUrl': selfiePhotoUrl,
      'businessName': businessName,
      'totalBuses': totalBuses,
      'verificationStatus': verificationStatus,
      'verificationNote': verificationNote,
      'verificationLevel': verificationLevel,
      'accountStatus': accountStatus,
      'deviceId': deviceId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
