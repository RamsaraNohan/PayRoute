import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the `drivers/{driverId}` document.
/// [driverId] is prefixed: "DRV-XXXXXXXX"
class DriverModel {
  final String driverId;
  final String userId;
  final String fullName;
  final String nicNumber;
  final String phoneSecondary;
  final String address;
  final String profilePhotoUrl;
  final String selfiePhotoUrl;
  final String licenseNumber;
  final String licenseFrontUrl;
  final String licenseBackUrl;
  final DateTime? licenseExpiry;
  final String experienceYears;
  final List<String> skills;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String verificationStatus; // "pending" | "approved" | "rejected"
  final String verificationNote;
  final int verificationLevel; // 1=basic, 2=docs, 3=selfie
  final String? assignedBusId;
  final String accountStatus; // "active" | "suspended" | "banned"
  final String deviceId;
  final DateTime createdAt;

  DriverModel({
    required this.driverId,
    required this.userId,
    required this.fullName,
    this.nicNumber = '',
    this.phoneSecondary = '',
    this.address = '',
    this.profilePhotoUrl = '',
    this.selfiePhotoUrl = '',
    this.licenseNumber = '',
    this.licenseFrontUrl = '',
    this.licenseBackUrl = '',
    this.licenseExpiry,
    this.experienceYears = '',
    this.skills = const [],
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

  factory DriverModel.fromMap(Map<String, dynamic> map, String id) {
    return DriverModel(
      driverId: id,
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      nicNumber: map['nicNumber'] ?? '',
      phoneSecondary: map['phoneSecondary'] ?? '',
      address: map['address'] ?? '',
      profilePhotoUrl: map['profilePhotoUrl'] ?? '',
      selfiePhotoUrl: map['selfiePhotoUrl'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      licenseFrontUrl: map['licenseFrontUrl'] ?? '',
      licenseBackUrl: map['licenseBackUrl'] ?? '',
      licenseExpiry: (map['licenseExpiry'] as Timestamp?)?.toDate(),
      experienceYears: map['experienceYears'] ?? '',
      skills: map['skills'] != null ? List<String>.from(map['skills']) : [],
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
      'driverId': driverId,
      'userId': userId,
      'fullName': fullName,
      'nicNumber': nicNumber,
      'phoneSecondary': phoneSecondary,
      'address': address,
      'profilePhotoUrl': profilePhotoUrl,
      'selfiePhotoUrl': selfiePhotoUrl,
      'licenseNumber': licenseNumber,
      'licenseFrontUrl': licenseFrontUrl,
      'licenseBackUrl': licenseBackUrl,
      'licenseExpiry':
          licenseExpiry != null ? Timestamp.fromDate(licenseExpiry!) : null,
      'experienceYears': experienceYears,
      'skills': skills,
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
