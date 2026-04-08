import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/route_model.dart';

int calculateFareCents({
  required RouteModel route,
  required String boardingStopId,
  required String destinationStopId,
  required int totalPassengers,
}) {
  final stops = route.stops;
  final boardingIndex = stops.indexWhere((s) => s.stopId == boardingStopId);
  final destIndex = stops.indexWhere((s) => s.stopId == destinationStopId);
  if (boardingIndex == -1 || destIndex == -1 || boardingIndex >= destIndex) return 0;

  double totalKm = 0;
  for (int i = boardingIndex; i < destIndex; i++) {
    totalKm += haversineDistance(stops[i].location, stops[i + 1].location);
  }

  int fareCents = route.baseFareCents + (totalKm * route.farePerKmCents).round();
  return fareCents * totalPassengers;
}

double haversineDistance(GeoPoint a, GeoPoint b) {
  const R = 6371.0;
  final dLat = _toRad(b.latitude - a.latitude);
  final dLon = _toRad(b.longitude - a.longitude);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(a.latitude)) * cos(_toRad(b.latitude)) *
      sin(dLon / 2) * sin(dLon / 2);
  return 2 * R * asin(sqrt(h));
}

double _toRad(double degree) {
  return degree * pi / 180;
}
