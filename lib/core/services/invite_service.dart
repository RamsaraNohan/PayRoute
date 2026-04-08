import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/id_generator.dart';
import 'package:share_plus/share_plus.dart';

class InviteService {
  static final _db = FirebaseFirestore.instance;

  /// Generates a staff invitation and returns a shareable link.
  /// Format: payroute://invite?id=XYZ
  static Future<String> createStaffInvite({
    required String ownerId,
    required String busId,
    required String role,
    required String businessName,
  }) async {
    final inviteId = IdGenerator.generate('INV');
    
    await _db.collection('staffInvites').doc(inviteId).set({
      'inviteId': inviteId,
      'ownerId': ownerId,
      'busId': busId,
      'role': role,
      'businessName': businessName,
      'status': 'pending', 
      'createdAt': FieldValue.serverTimestamp(),
    });

    final link = 'payroute://invite?id=$inviteId';
    return link;
  }

  static Future<void> shareInvite(String link) async {
    await Share.share(
      'Join my transport staff on PayRoute! Click the link to accept: $link',
      subject: 'PayRoute Staff Invitation',
    );
  }

  static Future<Map<String, dynamic>?> getInvite(String inviteId) async {
    final doc = await _db.collection('staffInvites').doc(inviteId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  static Future<void> respondToInvite(String inviteId, String userId, bool accept) async {
    if (!accept) {
      await _db.collection('staffInvites').doc(inviteId).update({'status': 'rejected'});
      return;
    }

    final inviteSnap = await _db.collection('staffInvites').doc(inviteId).get();
    final data = inviteSnap.data();
    if (data == null) return;

    final role = data['role'];
    final ownerId = data['ownerId'];
    final busId = data['busId'];

    await _db.runTransaction((transaction) async {
      // 1. Update User Roles
      final userRef = _db.collection('users').doc(userId);
      transaction.update(userRef, {
        'roles': FieldValue.arrayUnion([role]),
        'activeRole': role,
      });

      // 2. Create Staff Assignment (Pending Admin Approval)
      final assignmentId = IdGenerator.generate('ASG');
      final assignmentRef = _db.collection('staffAssignments').doc(assignmentId);
      transaction.set(assignmentRef, {
        'assignmentId': assignmentId,
        'userId': userId,
        'ownerId': ownerId,
        'busId': busId,
        'role': role,
        'status': 'pending_approval', // Requires Admin approval
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Mark Invite as Accepted
      transaction.update(_db.collection('staffInvites').doc(inviteId), {
        'status': 'accepted',
        'acceptedBy': userId,
      });
    });
  }
}
