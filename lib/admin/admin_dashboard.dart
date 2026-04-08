import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Admin Mission Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.purpleLight,
          labelColor: AppTheme.purpleLight,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Staff Verif'),
            Tab(text: 'Fleet Approval'),
            Tab(text: 'Assignments'),
            Tab(text: 'Complaints'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdminStaffVerifTab(),
          _AdminFleetTab(),
          _AdminAssignmentsTab(),
          _AdminComplaintsTab(),
        ],
      ),
    );
  }
}

// ─── Staff Verification Tab ───────────────────────────────────────────────────
class _AdminStaffVerifTab extends StatelessWidget {
  const _AdminStaffVerifTab();

  Future<void> _approve(BuildContext context, String collection, String docId, bool approve) async {
    final status = approve ? 'approved' : 'rejected';
    await FirebaseFirestore.instance.collection(collection).doc(docId).update({
      'verificationStatus': status,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildVerifList('drivers', 'New Driver Application');
  }

  Widget _buildVerifList(String collection, String title) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No pending verifications.', style: TextStyle(color: Colors.white24)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.badge, color: AppTheme.purpleLight),
                      const SizedBox(width: 12),
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('User ID: ${data['userId']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _approve(context, collection, docs[i].id, false),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                          child: const Text('REJECT', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approve(context, collection, docs[i].id, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('APPROVE'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Fleet Approval Tab ───────────────────────────────────────────────────────
class _AdminFleetTab extends StatelessWidget {
  const _AdminFleetTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buses')
          .where('verificationStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No buses pending approval.', style: TextStyle(color: Colors.white24)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.directions_bus, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Text(data['registrationNumber'] ?? 'Bus', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => FirebaseFirestore.instance.collection('buses').doc(docs[i].id).update({'verificationStatus': 'approved'}),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 36)),
                    child: const Text('APPROVE BUS'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Assignments Tab ──────────────────────────────────────────────────────────
class _AdminAssignmentsTab extends StatelessWidget {
  const _AdminAssignmentsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('staffAssignments')
          .where('status', isEqualTo: 'pending_approval')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No pending assignments.', style: TextStyle(color: Colors.white24)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final role = data['role'] ?? 'staff';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Column(
                children: [
                  Text('Assign $role to ${data['busId']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final batch = FirebaseFirestore.instance.batch();
                      // 1. Approve assignment
                      batch.update(docs[i].reference, {'status': 'active'});
                      // 2. Link bus to staff member
                      final busRef = FirebaseFirestore.instance.collection('buses').doc(data['busId']);
                      batch.update(busRef, {
                        role == 'driver' ? 'driverId' : 'conductorId': data['userId']
                      });
                      // 3. Link staff to bus
                      final staffColl = role == 'driver' ? 'drivers' : 'conductors';
                      final staffQuery = await FirebaseFirestore.instance.collection(staffColl).where('userId', isEqualTo: data['userId']).limit(1).get();
                      if (staffQuery.docs.isNotEmpty) {
                        batch.update(staffQuery.docs.first.reference, {'assignedBusId': data['busId']});
                      }
                      await batch.commit();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 36)),
                    child: const Text('APPROVE ASSIGNMENT'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Complaints Tab ───────────────────────────────────────────────────────────
class _AdminComplaintsTab extends StatelessWidget {
  const _AdminComplaintsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No complaints found.', style: TextStyle(color: Colors.white24)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['category'] ?? 'General Complaint', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(data['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                  const Divider(color: Colors.white10, height: 24),
                  Text('Bus: ${data['busId']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
