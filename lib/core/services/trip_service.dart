import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/id_generator.dart';
import '../utils/fare_calculator.dart';

class TripService {
  static final _db = FirebaseFirestore.instance;

  /// Starts a new active trip session for a bus.
  static Future<String> startTrip({
    required String busId,
    required String driverId,
    required String conductorId,
    required String routeId,
  }) async {
    final tripId = IdGenerator.generate('TRIP');
    
    await _db.collection('activeTrips').doc(tripId).set({
      'tripId': tripId,
      'busId': busId,
      'driverId': driverId,
      'conductorId': conductorId,
      'routeId': routeId,
      'status': 'ON_GOING',
      'startTime': FieldValue.serverTimestamp(),
    });
    
    return tripId;
  }

  /// Handles passenger boarding (Check-In).
  static Future<void> processBoarding({
    required String tripId,
    required String passengerId,
    required String busId,
    required GeoPoint location,
  }) async {
    final passengerTripId = IdGenerator.generate('PT');
    
    await _db.collection('passengerTrips').doc(passengerTripId).set({
      'passengerTripId': passengerTripId,
      'tripId': tripId,
      'passengerId': passengerId,
      'busId': busId,
      'entryLocation': location,
      'boardedAt': FieldValue.serverTimestamp(),
      'status': 'BOARDED',
    });
  }

  /// Marks an active trip session as COMPLETED (called by conductor).
  static Future<void> endTrip({required String tripId}) async {
    await _db.collection('activeTrips').doc(tripId).update({
      'status': 'COMPLETED',
      'endTime': FieldValue.serverTimestamp(),
    });
  }

  /// Handles passenger dropping (Check-Out) and financial transaction.
  static Future<void> processDropping({
    required String tripId,
    required String passengerId,
    required GeoPoint exitLocation,
  }) async {
    // 1. Find the active boarding record
    final query = await _db
        .collection('passengerTrips')
        .where('tripId', isEqualTo: tripId)
        .where('passengerId', isEqualTo: passengerId)
        .where('status', isEqualTo: 'BOARDED')
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('No active boarding record found.');

    final boardingDoc = query.docs.first;
    final boardingData = boardingDoc.data();
    final entryLocation = boardingData['entryLocation'] as GeoPoint;

    // 2. Calculate Distance & Fare
    final distanceKm = haversineDistance(entryLocation, exitLocation);
    // Rough logic: 45.00 LKR base + 10.00 LKR per KM (stored in cents)
    const int baseFareCents = 4500;
    const int perKmCents = 1000;
    final int finalFareCents = baseFareCents + (distanceKm * perKmCents).round();

    // 3. Perform Transactional Wallet Update
    await _db.runTransaction((transaction) async {
      // Get Passenger details
      final passengerRef = _db.collection('passengers').doc(passengerId);
      final passengerSnap = await transaction.get(passengerRef);
      if (!passengerSnap.exists) throw Exception('Passenger data missing.');
      
      final currentBalance = (passengerSnap.data() as Map)['walletBalance'] ?? 0;
      if (currentBalance < finalFareCents) throw Exception('Insufficient wallet balance.');

      // Get Owner through Bus — use transaction.get() for atomicity
      final tripRef = _db.collection('activeTrips').doc(tripId);
      final tripSnap = await transaction.get(tripRef);
      final busId = tripSnap.data()?['busId'];

      final busRef = _db.collection('buses').doc(busId);
      final busSnap = await transaction.get(busRef);
      final ownerId = busSnap.data()?['ownerId'];
      final ownerRef = _db.collection('owners').doc(ownerId);

      // Perform Transfers
      transaction.update(passengerRef, {'walletBalance': currentBalance - finalFareCents});
      transaction.update(ownerRef, {'totalEarningsCents': FieldValue.increment(finalFareCents)});
      
      // Update Bus income for the day
      transaction.update(_db.collection('buses').doc(busId), {
        'todayIncomeCents': FieldValue.increment(finalFareCents)
      });

      // Close the trip record
      transaction.update(boardingDoc.reference, {
        'exitLocation': exitLocation,
        'droppedAt': FieldValue.serverTimestamp(),
        'fareCents': finalFareCents,
        'status': 'COMPLETED',
      });
    });
  }
}
