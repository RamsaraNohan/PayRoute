import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class ConductorEarningsScreen extends StatelessWidget {
  const ConductorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conductorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final currency = NumberFormat('#,##0.00', 'en_US');

    return Container(
      decoration: AppTheme.gradientBackground(),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .where('conductorId', isEqualTo: conductorId)
            .where('boardingTime', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
            .snapshots(),
        builder: (context, snapshot) {
          final trips = snapshot.data?.docs ?? [];
          final totalCents = trips.fold<int>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + ((data['finalFare'] as int?) ?? (data['fareCents'] as int?) ?? 0);
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassCard(),
                child: Column(
                  children: [
                    const Text("Today's Earnings", style: TextStyle(color: Colors.white60)),
                    const SizedBox(height: 12),
                    Text(
                      'LKR ${currency.format(totalCents / 100)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${trips.length} trips completed',
                      style: const TextStyle(color: AppTheme.purpleLight, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Avg Fare', 
                      trips.isEmpty ? 'LKR 0.00' : 'LKR ${currency.format((totalCents / trips.length) / 100)}',
                      Icons.trending_up),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Passengers', '${trips.length}', Icons.people),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Trip History Today', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...trips.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final time = data['boardingTime'] != null
                    ? DateFormat('hh:mm a').format(DateTime.parse(data['boardingTime']))
                    : '—';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.glassCard(),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, color: AppTheme.purpleLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To: ${data['destinationStopId'] ?? 'Unknown'}',
                                style: const TextStyle(color: Colors.white)),
                            Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        'LKR ${currency.format(((data['finalFare'] as int?) ?? (data['fareCents'] as int?) ?? 0) / 100)}',
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.purpleLight),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
