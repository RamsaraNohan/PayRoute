import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';
import '../receipt/trip_receipt_screen.dart';

class TripHistoryScreen extends ConsumerWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat('#,##0.00', 'en_US');
    final passengerAsync = ref.watch(passengerStreamProvider);
    final passengerId = passengerAsync.value?.passengerId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: passengerId.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('passengerTrips')
            .where('passengerId', isEqualTo: passengerId)
            .orderBy('boardedAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final trips = snapshot.data?.docs ?? [];

          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text('No trips yet', style: TextStyle(color: Colors.white54, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Your completed trips will appear here', style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final data = trips[index].data() as Map<String, dynamic>;
              final fareCents = (data['fareCents'] as int?) ?? 0;
              final boardedAtTs = data['boardedAt'] as Timestamp?;
              final boardingTime = boardedAtTs != null
                  ? DateFormat('MMM dd, hh:mm a').format(boardedAtTs.toDate())
                  : '—';
              final isCompleted = data['status'] == 'COMPLETED';
              final isOngoing = data['status'] == 'BOARDED';
              final busId = data['busId'] as String? ?? '—';

              return GestureDetector(
                onTap: isCompleted
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripReceiptScreen(tripData: {
                              ...data,
                              'boardingTime': boardedAtTs?.toDate().toIso8601String(),
                            }),
                          ),
                        )
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isOngoing ? Colors.green : AppTheme.purpleLight).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOngoing ? Icons.directions_bus : Icons.check_circle,
                          color: isOngoing ? Colors.green : AppTheme.purpleLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus: $busId',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(boardingTime, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'LKR ${currency.format(fareCents / 100)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isOngoing ? Colors.green : (isCompleted ? Colors.blue : Colors.orange)).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isOngoing ? 'ON BUS' : (data['status'] ?? '—'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOngoing ? Colors.green : (isCompleted ? Colors.blue : Colors.orange),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
