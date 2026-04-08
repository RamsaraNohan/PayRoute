import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String passengerId;
  final String tripId;
  final String busId;
  final String targetRole; // "conductor", "driver", "owner"
  final String targetUserId;
  final String category; // "reckless_driving", "overcharging", "misconduct", "accident", "other"
  final String description;
  final String status; // "open", "reviewed", "resolved"
  final DateTime createdAt;

  ComplaintModel({
    required this.complaintId,
    required this.passengerId,
    required this.tripId,
    required this.busId,
    required this.targetRole,
    required this.targetUserId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      complaintId: id,
      passengerId: map['passengerId'] ?? '',
      tripId: map['tripId'] ?? '',
      busId: map['busId'] ?? '',
      targetRole: map['targetRole'] ?? '',
      targetUserId: map['targetUserId'] ?? '',
      category: map['category'] ?? 'other',
      description: map['description'] ?? '',
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'tripId': tripId,
      'busId': busId,
      'targetRole': targetRole,
      'targetUserId': targetUserId,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
