import 'dart:ui';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: passengerId.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.purpleLight))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('passengerTrips')
                    .where('passengerId', isEqualTo: passengerId)
                    .orderBy('boardedAt', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.purpleLight));
                  }

                  final trips = snapshot.data?.docs ?? [];

                  if (trips.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_bus_outlined,
                                size: 56, color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          const SizedBox(height: 20),
                          const Text('No trips yet',
                              style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Your completed trips will appear here',
                              style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final data = trips[index].data() as Map<String, dynamic>;
                      final fareCents = (data['fareCents'] as int?) ?? 0;
                      final boardedAtTs = data['boardedAt'] as Timestamp?;
                      final boardingTime = boardedAtTs != null
                          ? DateFormat('MMM dd, hh:mm a').format(boardedAtTs.toDate())
                          : '—';
                      final isCompleted = data['status'] == 'COMPLETED';
                      final isOngoing  = data['status'] == 'BOARDED';
                      final busId      = data['busId'] as String? ?? '—';
                      final statusColor = isOngoing ? Colors.green : isCompleted ? AppTheme.purpleLight : Colors.orange;
                      final statusLabel = isOngoing ? 'ON BUS' : (data['status'] as String? ?? '—');

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
                                  color: statusColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isOngoing ? Icons.directions_bus_rounded : Icons.check_circle_rounded,
                                  color: statusColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Bus: $busId',
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(boardingTime,
                                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'LKR ${currency.format(fareCents / 100)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  AppTheme.statusBadge(statusLabel, statusColor),
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
      ),
    );
  }
}
