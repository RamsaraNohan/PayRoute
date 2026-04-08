import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'active_trip_provider.g.dart';

@riverpod
Stream<Map<String, dynamic>?> currentActiveTrip(CurrentActiveTripRef ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

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
