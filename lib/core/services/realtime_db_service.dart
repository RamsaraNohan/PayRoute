import 'package:firebase_database/firebase_database.dart';
import '../constants/app_constants.dart';

class RealtimeDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> updateBusLocation(String busId, double lat, double lng, double speed, double heading) async {
    await _db.ref('${AppConstants.busLocationsNode}/$busId').set({
      'lat': lat,
      'lng': lng,
      'updatedAt': ServerValue.timestamp,
      'speed': speed,
      'heading': heading,
    });
  }

  Stream<DatabaseEvent> streamBusLocations() {
    return _db.ref(AppConstants.busLocationsNode).onValue;
  }

  Stream<DatabaseEvent> streamActiveTrip(String busId) {
    return _db.ref('${AppConstants.activeTripsNode}/$busId').onValue;
  }
}
