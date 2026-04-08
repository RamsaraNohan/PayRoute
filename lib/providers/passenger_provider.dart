import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/passenger_model.dart';
import 'auth_provider.dart';

part 'passenger_provider.g.dart';

@riverpod
Stream<PassengerModel?> passengerStream(PassengerStreamRef ref) {
  final userAsyncValue = ref.watch(currentUserStreamProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      // CRITICAL FIX: Query the passengers collection by userId field, NOT doc id
      return FirebaseFirestore.instance
          .collection('passengers')
          .where('userId', isEqualTo: user.userId)
          .limit(1)
          .snapshots()
          .map((snap) => snap.docs.isEmpty
              ? null
              : PassengerModel.fromMap(snap.docs.first.data(), snap.docs.first.id));
    },
    loading: () => Stream.value(null),
    error: (err, stack) => Stream.value(null),
  );
}

@riverpod
Future<PassengerModel?> passengerFuture(PassengerFutureRef ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final snap = await FirebaseFirestore.instance
      .collection('passengers')
      .where('userId', isEqualTo: user.uid)
      .limit(1)
      .get();
      
  if (snap.docs.isEmpty) return null;
  return PassengerModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
}
