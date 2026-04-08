import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../crew/driver/driver_trip_screen.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: AppTheme.gradientBackground(),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('drivers')
              .where('userId', isEqualTo: user?.uid)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final driverDocs = snapshot.data?.docs ?? [];
            if (driverDocs.isEmpty) {
              return _buildErrorState('Driver profile not found.');
            }

            final driverData = driverDocs.first.data() as Map<String, dynamic>;
            final busId = driverData['assignedBusId'];

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Driver Portal',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: const Icon(Icons.logout, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (busId == null || busId == 'Pending Assignment')
                    _buildWaitingState()
                  else
                    _buildBusCard(context, busId),
                  
                  const Spacer(),
                  const Text(
                    'Recent Shift History',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: AppTheme.glassCard(),
                      child: const Center(
                        child: Text(
                          'No recent trips recorded.',
                          style: TextStyle(color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, String busId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('buses').doc(busId).snapshots(),
      builder: (context, snapshot) {
        final busData = snapshot.data?.data() as Map<String, dynamic>?;
        if (busData == null) return const SizedBox();

        final routeId = busData['routeId'] ?? 'Unassigned Route';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCard(),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_bus, color: AppTheme.purpleLight, size: 40),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned Fleet', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('Bus #01', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              _infoRow(Icons.pin_drop_outlined, 'Route $routeId'),
              const SizedBox(height: 12),
              _infoRow(Icons.confirmation_number_outlined, busData['registrationNumber'] ?? busId),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverTripScreen(busId: busId, routeId: routeId),
                    ),
                  );
                },
                style: AppTheme.primaryButton(),
                child: const Text('START JOURNEY'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassCard(),
      child: const Column(
        children: [
          Icon(Icons.hourglass_empty, size: 64, color: Colors.amber),
          SizedBox(height: 24),
          Text(
            'Waiting for Assignment',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Once your owner assigns you to a bus and it\'s approved by an admin, you can start your shift.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(child: Text(msg, style: const TextStyle(color: Colors.redAccent)));
  }
}
