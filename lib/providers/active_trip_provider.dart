import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'active_trip_provider.g.dart';

@riverpod
Stream<Map<String, dynamic>?> activePassengerTrip(ActivePassengerTripRef ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('passengerTrips')
      .where('passengerId', isGreaterThan: '') // Hack to find current passenger's trips
      .where('status', isEqualTo: 'BOARDED')
      .snapshots()
      .map((snapshot) {
        // Find the one belonging to CURRENT user (ideally query by passengerId if we have it here)
        // For efficiency, normally we'd need the passengerId index.
        if (snapshot.docs.isNotEmpty) {
           return snapshot.docs.first.data();
        }
        return null;
      });
}

// Better version once we have the passenger profile
@riverpod
Stream<Map<String, dynamic>?> currentActiveTrip(CurrentActiveTripRef ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  // We need to fetch the passengerId first
  return FirebaseFirestore.instance
      .collection('passengers')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .asyncMap((snap) async {
        if (snap.docs.isEmpty) return null;
        final pId = snap.docs.first.id;
        
        final tripSnap = await FirebaseFirestore.instance
            .collection('passengerTrips')
            .where('passengerId', isEqualTo: pId)
            .where('status', isEqualTo: 'BOARDED')
            .limit(1)
            .get();
            
        return tripSnap.docs.isNotEmpty ? tripSnap.docs.first.data() : null;
      });
}
