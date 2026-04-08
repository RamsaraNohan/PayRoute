import 'package:cloud_firestore/cloud_firestore.dart';

class BusModel {
  final String busId;
  final String registrationNumber;
  final String ownerId;
  final int capacity;
  final String routeId;
  final String? driverId;
  final String? conductorId;
  final String status; // "active", "idle", "offline"
  final GeoPoint? currentLocation;
  final int todayIncomeCents;
  final String verificationStatus; // "pending" | "approved" | "rejected"
  final String verificationNote;

  BusModel({
    required this.busId,
    required this.registrationNumber,
    required this.ownerId,
    required this.capacity,
    required this.routeId,
    this.driverId,
    this.conductorId,
    required this.status,
    this.currentLocation,
    this.todayIncomeCents = 0,
    this.verificationStatus = 'pending',
    this.verificationNote = '',
  });

  factory BusModel.fromMap(Map<String, dynamic> map, String id) {
    return BusModel(
      busId: id,
      registrationNumber: map['registrationNumber'] ?? '',
      ownerId: map['ownerId'] ?? '',
      capacity: map['capacity']?.toInt() ?? 0,
      routeId: map['routeId'] ?? '',
      driverId: map['driverId'],
      conductorId: map['conductorId'],
      status: map['status'] ?? 'offline',
      currentLocation: map['currentLocation'] as GeoPoint?,
      todayIncomeCents: map['todayIncomeCents']?.toInt() ?? 0,
      verificationStatus: map['verificationStatus'] ?? 'pending',
      verificationNote: map['verificationNote'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'registrationNumber': registrationNumber,
      'ownerId': ownerId,
      'capacity': capacity,
      'routeId': routeId,
      'driverId': driverId,
      'conductorId': conductorId,
      'status': status,
      'currentLocation': currentLocation,
      'todayIncomeCents': todayIncomeCents,
      'verificationStatus': verificationStatus,
      'verificationNote': verificationNote,
    };
  }
}
