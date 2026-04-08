import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the `conductors/{conductorId}` document.
/// [conductorId] is prefixed: "CON-XXXXXXXX"
class ConductorModel {
  final String conductorId;
  final String userId;
  final String fullName;
  final String nicNumber;
  final String phoneSecondary;
  final String address;
  final String profilePhotoUrl;
  final String selfiePhotoUrl;
  final String? licenseNumber; // optional
  final String ticketExperience;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String verificationStatus; // "pending" | "approved" | "rejected"
  final String verificationNote;
  final int verificationLevel;
  final String? assignedBusId;
  final String accountStatus;
  final String deviceId;
  final DateTime createdAt;

  ConductorModel({
    required this.conductorId,
    required this.userId,
    required this.fullName,
    this.nicNumber = '',
    this.phoneSecondary = '',
    this.address = '',
    this.profilePhotoUrl = '',
    this.selfiePhotoUrl = '',
    this.licenseNumber,
    this.ticketExperience = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.verificationStatus = 'pending',
    this.verificationNote = '',
    this.verificationLevel = 1,
    this.assignedBusId,
    this.accountStatus = 'active',
    this.deviceId = 'unknown',
    required this.createdAt,
  });

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  factory ConductorModel.fromMap(Map<String, dynamic> map, String id) {
    return ConductorModel(
      conductorId: id,
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      nicNumber: map['nicNumber'] ?? '',
      phoneSecondary: map['phoneSecondary'] ?? '',
      address: map['address'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'] ?? '',
      selfiePhotoUrl: map['selfiePhotoUrl'] ?? '',
      licenseNumber: map['licenseNumber'],
      ticketExperience: map['ticketExperience'] ?? '',
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '',
      verificationStatus: map['verificationStatus'] ?? 'pending',
      verificationNote: map['verificationNote'] ?? '',
      verificationLevel: map['verificationLevel']?.toInt() ?? 1,
      assignedBusId: map['assignedBusId'],
      accountStatus: map['accountStatus'] ?? 'active',
      deviceId: map['deviceId'] ?? 'unknown',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conductorId': conductorId,
      'userId': userId,
      'fullName': fullName,
      'nicNumber': nicNumber,
      'phoneSecondary': phoneSecondary,
      'address': address,
      'profilePhotoUrl': profilePhotoUrl,
      'selfiePhotoUrl': selfiePhotoUrl,
      'licenseNumber': licenseNumber,
      'ticketExperience': ticketExperience,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'verificationStatus': verificationStatus,
      'verificationNote': verificationNote,
      'verificationLevel': verificationLevel,
      'assignedBusId': assignedBusId,
      'accountStatus': accountStatus,
      'deviceId': deviceId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
