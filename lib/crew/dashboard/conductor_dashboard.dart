import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../conductor/conductor_trip_screen.dart';
import 'conductor_earnings_screen.dart';
import 'conductor_passengers_screen.dart';

class ConductorDashboard extends StatefulWidget {
  const ConductorDashboard({super.key});

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const _ConductorHomeTab(),
      const ConductorPassengersScreen(),
      const ConductorEarningsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppTheme.backgroundDark,
        selectedItemColor: AppTheme.purpleLight,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Passengers'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Earnings'),
        ],
      ),
    );
  }
}

class _ConductorHomeTab extends StatelessWidget {
  const _ConductorHomeTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conductors')
            .where('userId', isEqualTo: user?.uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final conductorDocs = snapshot.data?.docs ?? [];
          if (conductorDocs.isEmpty) {
            return const Center(child: Text('Conductor profile not found.', style: TextStyle(color: Colors.redAccent)));
          }

          final conductorData = conductorDocs.first.data() as Map<String, dynamic>;
          final busId = conductorData['assignedBusId'];

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Conductor Hub',
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
              ],
            ),
          );
        },
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
              Row(
                children: [
                  const Icon(Icons.qr_code_2, color: AppTheme.purpleLight, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Fleet', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(busData['registrationNumber'] ?? busId, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              Row(children: [
                const Icon(Icons.route_outlined, color: Colors.white38, size: 18),
                const SizedBox(width: 12),
                Text('Route $routeId', style: const TextStyle(color: Colors.white70, fontSize: 15)),
              ]),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConductorTripScreen(busId: busId, routeId: routeId),
                    ),
                  );
                },
                style: AppTheme.primaryButton(),
                child: const Text('START TRIP SESSION'),
              ),
            ],
          ),
        );
      },
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
            'Once you are assigned to a bus, you can start processing passenger check-ins.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
