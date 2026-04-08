import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String tripId;
  final String passengerId;
  final String busId;
  final String conductorId;
  final String routeId;
  final String boardingStopId;
  final String boardingStopName;
  final String destinationStopId;
  final String destinationStopName;
  final int companionCount;
  final int totalPassengers;
  final int fareCents;
  final int? seatNumber;
  final String status; // "queued", "seated", "completed", "cancelled"
  final DateTime boardedAt;
  final DateTime? droppedAt;
  final bool isAdvanceBooking;
  final bool isRefundable;
  final String tokenUsed;
  final DateTime createdAt;

  TripModel({
    required this.tripId,
    required this.passengerId,
    required this.busId,
    required this.conductorId,
    required this.routeId,
    required this.boardingStopId,
    required this.boardingStopName,
    required this.destinationStopId,
    required this.destinationStopName,
    required this.companionCount,
    required this.totalPassengers,
    required this.fareCents,
    this.seatNumber,
    required this.status,
    required this.boardedAt,
    this.droppedAt,
    required this.isAdvanceBooking,
    required this.isRefundable,
    required this.tokenUsed,
    required this.createdAt,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      tripId: id,
      passengerId: map['passengerId'] ?? '',
      busId: map['busId'] ?? '',
      conductorId: map['conductorId'] ?? '',
      routeId: map['routeId'] ?? '',
      boardingStopId: map['boardingStopId'] ?? '',
      boardingStopName: map['boardingStopName'] ?? '',
      destinationStopId: map['destinationStopId'] ?? '',
      destinationStopName: map['destinationStopName'] ?? '',
      companionCount: map['companionCount']?.toInt() ?? 0,
      totalPassengers: map['totalPassengers']?.toInt() ?? 1,
      fareCents: map['fareCents']?.toInt() ?? 0,
      seatNumber: map['seatNumber']?.toInt(),
      status: map['status'] ?? 'queued',
      boardedAt: (map['boardedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      droppedAt: (map['droppedAt'] as Timestamp?)?.toDate(),
      isAdvanceBooking: map['isAdvanceBooking'] ?? false,
      isRefundable: map['isRefundable'] ?? false,
      tokenUsed: map['tokenUsed'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passengerId': passengerId,
      'busId': busId,
      'conductorId': conductorId,
      'routeId': routeId,
      'boardingStopId': boardingStopId,
      'boardingStopName': boardingStopName,
      'destinationStopId': destinationStopId,
      'destinationStopName': destinationStopName,
      'companionCount': companionCount,
      'totalPassengers': totalPassengers,
      'fareCents': fareCents,
      'seatNumber': seatNumber,
      'status': status,
      'boardedAt': Timestamp.fromDate(boardedAt),
      'droppedAt': droppedAt != null ? Timestamp.fromDate(droppedAt!) : null,
      'isAdvanceBooking': isAdvanceBooking,
      'isRefundable': isRefundable,
      'tokenUsed': tokenUsed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
