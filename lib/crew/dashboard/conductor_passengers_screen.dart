import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class ConductorPassengersScreen extends StatelessWidget {
  const ConductorPassengersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conductorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      decoration: AppTheme.gradientBackground(),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conductors')
            .where('userId', isEqualTo: conductorId)
            .limit(1)
            .snapshots(),
        builder: (context, conductorSnap) {
          final conductorDocs = conductorSnap.data?.docs ?? [];
          final assignedBusId = conductorDocs.isNotEmpty
              ? (conductorDocs.first.data() as Map<String, dynamic>)['assignedBusId'] as String?
              : null;

          if (assignedBusId == null || assignedBusId == 'Pending Assignment') {
            return const Center(
              child: Text('Not yet assigned to a bus.', style: TextStyle(color: Colors.white54)),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .where('busId', isEqualTo: assignedBusId)
                .where('status', isEqualTo: 'ONGOING')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              final trips = snapshot.data?.docs ?? [];

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.glassCard(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Active Passengers', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            Text(
                              '${trips.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.people_alt, color: AppTheme.purpleLight, size: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: trips.isEmpty
                        ? const Center(
                            child: Text('No active passengers on bus', style: TextStyle(color: Colors.white54)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: trips.length,
                            itemBuilder: (context, index) {
                              final trip = trips[index].data() as Map<String, dynamic>;
                              final pId = trip['passengerId'] as String? ?? '';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.glassCard(),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: AppTheme.purpleLight,
                                      child: Icon(Icons.person, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Passenger ${pId.length >= 8 ? pId.substring(0, 8) : pId}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            'To: ${trip['destinationStopId'] ?? 'Unknown'}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '+${(trip['companionCount'] ?? 0) + 1}',
                                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
