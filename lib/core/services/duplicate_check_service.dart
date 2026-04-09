import 'package:cloud_firestore/cloud_firestore.dart';

/// Prevents duplicate registrations for unique fields (NIC, license, vehicle number).
///
/// Run checks BEFORE writing any registration document.
/// All methods return true if the value is ALREADY taken.
class DuplicateCheckService {
  DuplicateCheckService._();

  /// Checks if a NIC is already registered in the given [collection].
  /// Use 'drivers', 'conductors', or 'owners' as the collection name.
  static Future<bool> isNicRegistered(String nic, String collection) async {
    final query = await FirebaseFirestore.instance
        .collection(collection)
        .where('nicNumber', isEqualTo: nic.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Checks if a driving license number is already registered in 'drivers'.
  static Future<bool> isLicenseRegistered(String licenseNo) async {
    final query = await FirebaseFirestore.instance
        .collection('drivers')
        .where('licenseNumber', isEqualTo: licenseNo.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Checks if a vehicle/bus registration number is already registered in 'buses'.
  static Future<bool> isVehicleRegistered(String vehicleNumber) async {
    final query = await FirebaseFirestore.instance
        .collection('buses')
        .where('registrationNumber', isEqualTo: vehicleNumber.trim().toUpperCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }
}
