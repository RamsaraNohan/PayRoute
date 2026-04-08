import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class ConductorPassengersScreen extends StatelessWidget {
  const ConductorPassengersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String activeBusId = 'bus_123'; // Would come from conductor's Firestore profile

    return Container(
      decoration: AppTheme.gradientBackground(),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('busId', isEqualTo: activeBusId)
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
                                        'Passenger ${(trip['passengerId'] as String).substring(0, 8)}',
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
                                    color: Colors.greenAccent.withOpacity(0.2),
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
      ),
    );
  }
}
