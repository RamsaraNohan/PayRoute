import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String routeId;
  final String name;
  final String number;
  final List<RouteStop> stops;
  final int baseFareCents;
  final int farePerKmCents;

  RouteModel({
    required this.routeId,
    required this.name,
    required this.number,
    required this.stops,
    required this.baseFareCents,
    required this.farePerKmCents,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, String id) {
    return RouteModel(
      routeId: id,
      name: map['name'] ?? '',
      number: map['number'] ?? '',
      stops: List<RouteStop>.from(
        (map['stops'] ?? []).map((x) => RouteStop.fromMap(x)),
      ),
      baseFareCents: map['baseFareCents']?.toInt() ?? 0,
      farePerKmCents: map['farePerKmCents']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'stops': stops.map((x) => x.toMap()).toList(),
      'baseFareCents': baseFareCents,
      'farePerKmCents': farePerKmCents,
    };
  }
}

class RouteStop {
  final String stopId;
  final String stopName;
  final int order;
  final GeoPoint location;

  RouteStop({
    required this.stopId,
    required this.stopName,
    required this.order,
    required this.location,
  });

  factory RouteStop.fromMap(Map<String, dynamic> map) {
    return RouteStop(
      stopId: map['stopId'] ?? '',
      stopName: map['stopName'] ?? '',
      order: map['order']?.toInt() ?? 0,
      location: map['location'] as GeoPoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopId': stopId,
      'stopName': stopName,
      'order': order,
      'location': location,
    };
  }
}
