import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String passengerId;
  final String routeId;
  final String? busId;
  final DateTime scheduledDeparture;
  final String destinationStopId;
  final int companionCount;
  final int fareCents;
  final bool isRefundable;
  final String status; // "pending", "boarded", "cancelled"
  final String? qrTokenId;
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.passengerId,
    required this.routeId,
    this.busId,
    required this.scheduledDeparture,
    required this.destinationStopId,
    required this.companionCount,
    required this.fareCents,
    required this.isRefundable,
    required this.status,
    this.qrTokenId,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      bookingId: id,
      passengerId: map['passengerId'] ?? '',
      routeId: map['routeId'] ?? '',
      busId: map['busId'],
      scheduledDeparture: (map['scheduledDeparture'] as Timestamp?)?.toDate() ?? DateTime.now(),
      destinationStopId: map['destinationStopId'] ?? '',
      companionCount: map['companionCount']?.toInt() ?? 0,
      fareCents: map['fareCents']?.toInt() ?? 0,
      isRefundable: map['isRefundable'] ?? false,
      status: map['status'] ?? 'pending',
      qrTokenId: map['qrTokenId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'routeId': routeId,
      'busId': busId,
      'scheduledDeparture': Timestamp.fromDate(scheduledDeparture),
      'destinationStopId': destinationStopId,
      'companionCount': companionCount,
      'fareCents': fareCents,
      'isRefundable': isRefundable,
      'status': status,
      'qrTokenId': qrTokenId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
