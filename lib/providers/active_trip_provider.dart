import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'passenger_provider.dart';

part 'active_trip_provider.g.dart';

@riverpod
Stream<Map<String, dynamic>?> currentActiveTrip(CurrentActiveTripRef ref) {
  // Watch the passenger profile — this is already live, no asyncMap needed
  final passengerAsync = ref.watch(passengerStreamProvider);
  final passenger = passengerAsync.value;
  if (passenger == null) return Stream.value(null);

  // Live snapshot so the HUD disappears the instant the trip is COMPLETED
  return FirebaseFirestore.instance
      .collection('passengerTrips')
      .where('passengerId', isEqualTo: passenger.passengerId)
      .where('status', isEqualTo: 'BOARDED')
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() : null);
}
