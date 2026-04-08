import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../models/bus_model.dart';
import '../../models/route_model.dart';
import '../../models/trip_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> createUser(UserModel user) async {
    await _firestore.collection(AppConstants.usersCollection).doc(user.userId).set(user.toMap());
  }

  Future<void> updatePassengerBalance(String passengerId, int amountToAdd) async {
    await _firestore.collection('passengers').doc(passengerId).update({
      'walletBalance': FieldValue.increment(amountToAdd),
    });
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }
}
