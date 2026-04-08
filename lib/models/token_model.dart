import 'package:cloud_firestore/cloud_firestore.dart';

class TokenModel {
  final String tokenId;
  final String passengerId;
  final String destinationStopId;
  final int companionCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;
  final DateTime? usedAt;

  TokenModel({
    required this.tokenId,
    required this.passengerId,
    required this.destinationStopId,
    required this.companionCount,
    required this.createdAt,
    required this.expiresAt,
    required this.used,
    this.usedAt,
  });

  factory TokenModel.fromMap(Map<String, dynamic> map, String id) {
    return TokenModel(
      tokenId: id,
      passengerId: map['passengerId'] ?? '',
      destinationStopId: map['destinationStopId'] ?? '',
      companionCount: map['companionCount']?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(seconds: 60)),
      used: map['used'] ?? false,
      usedAt: (map['usedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'destinationStopId': destinationStopId,
      'companionCount': companionCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'used': used,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }
}
