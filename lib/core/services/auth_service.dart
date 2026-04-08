import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_login_result.dart';
import '../utils/device_info_util.dart';
import '../utils/audit_logger.dart';
import '../utils/id_generator.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> signInWithOTP(
      String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Handles creating new users, lazy migrating old ones to the new schema,
  /// updating last login, checking bans/suspensions, and finding staff invites.
  Future<PostLoginResult> handlePostLogin(String userId, String phone) async {
    final docRef = _db.collection('users').doc(userId);
    final doc = await docRef.get();

    // 1. BRAND NEW USER
    if (!doc.exists) {
      final deviceInfo = await DeviceInfoUtil.getInfo();
      await docRef.set({
        'userId': userId,
        'phonePrimary': phone,
        'displayName': '',
        'roles': [],
        'activeRole': '',
        'profileCompleted': false,
        'accountStatus': 'active',
        'deviceId': deviceInfo['deviceId'],
        'deviceModel': deviceInfo['deviceModel'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      await AuditLogger.log(userId, 'REGISTER_NEW_USER');
      return const NeedsRoleSelection();
    }

    // 2. EXISTING USER
    await docRef.update({'lastLoginAt': FieldValue.serverTimestamp()});
    await AuditLogger.log(userId, 'LOGIN');

    final data = doc.data()!;

    // 3. LAZY AUTO-MIGRATION (Legacy schema -> New schema)
    if (data.containsKey('walletBalance')) {
      final passengerQuery = await _db
          .collection('passengers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (passengerQuery.docs.isEmpty) {
        final passengerId = IdGenerator.generate('PAS');
        await _db.collection('passengers').doc(passengerId).set({
          'passengerId': passengerId,
          'userId': userId,
          'fullName': data['name'] ?? '',
          'profilePhotoUrl': data['profileImageUrl'] ?? '',
          'walletBalance': data['walletBalance'] ?? 0,
          'accountStatus': 'active',
          'profileCompletion': 100, // Legacy profiles assumed complete
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Clean old data & initialize new role array
        await docRef.update({
          'roles': FieldValue.arrayUnion(['passenger']),
          'activeRole': 'passenger',
          'profileCompleted': true,
          'walletBalance': FieldValue.delete(),
          'role': FieldValue.delete(),
          'name': FieldValue.delete(),
          'profileImageUrl': FieldValue.delete(),
        });

        data['roles'] = ['passenger'];
        data['activeRole'] = 'passenger';
        data['profileCompleted'] = true;
      }
    }

    // 4. CHECK ACCOUNT STATUS
    final accountStatus = data['accountStatus'] ?? 'active';
    if (accountStatus == 'banned') return const AccountBanned();
    if (accountStatus == 'suspended') return const AccountSuspended();

    // 5. CHECK PROFILE COMPLETION
    final roles = List<String>.from(data['roles'] ?? []);
    final profileCompleted = data['profileCompleted'] ?? false;

    if (roles.isEmpty || !profileCompleted) {
      return const NeedsRoleSelection();
    }

    // 6. CHECK PENDING STAFF INVITES
    final invite = await _checkStaffInvite(phone);
    if (invite != null) return HasStaffInvite(invite);

    // 7. CHECK PROFESSIONAL VERIFICATION STATUS FOR STAFF
    if (roles.contains('driver') || roles.contains('conductor')) {
      final String roleToCheck = roles.contains('driver') ? 'driver' : 'conductor';
      final collection = roleToCheck == 'driver' ? 'drivers' : 'conductors';
      
      final staffQuery = await _db
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
          
      if (staffQuery.docs.isNotEmpty) {
        final staffData = staffQuery.docs.first.data();
        final status = staffData['verificationStatus'] ?? 'pending';
        
        if (status == 'pending') return const VerificationPending();
        if (status == 'rejected') {
          return VerificationRejected(staffData['verificationNote'] ?? 'Identity document verification failed.');
        }
      }
    }

    // 8. ROUTING
    if (roles.contains('admin')) {
      return const GoToDashboard('admin');
    }
    if (roles.length == 1) {
      return GoToDashboard(roles.first);
    }
    return MultipleRoles(roles);
  }

  Future<Map<String, dynamic>?> _checkStaffInvite(String phone) async {
    String cleaned = phone.trim();
    if (cleaned.startsWith('+94')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('94')) {
      cleaned = '0${cleaned.substring(2)}';
    }

    final invites = await _db
        .collection('staffInvites')
        .where('targetPhone', isEqualTo: cleaned)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (invites.docs.isEmpty) return null;
    return invites.docs.first.data();
  }
}
