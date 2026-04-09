import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/id_generator.dart';

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
                .collection('passengerTrips')
                .where('busId', isEqualTo: assignedBusId)
                .where('status', isEqualTo: 'BOARDED')
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
                                            'Passenger ${IdGenerator.truncate(pId)}',
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
                                    const SizedBox(width: 8),
                                    _ManualCheckoutButton(tripId: trips[index].id),
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

class _ManualCheckoutButton extends StatefulWidget {
  final String tripId;
  const _ManualCheckoutButton({required this.tripId});

  @override
  State<_ManualCheckoutButton> createState() => _ManualCheckoutButtonState();
}

class _ManualCheckoutButtonState extends State<_ManualCheckoutButton> {
  bool _loading = false;

  Future<void> _manualCheckout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Manual Checkout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will end the passenger\'s trip and deduct the base fare.\n\nUse this only if the passenger cannot scan the exit QR.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.runTransaction((t) async {
        // passengerTrips uses the doc id as the trip record
        final tripRef = FirebaseFirestore.instance.collection('passengerTrips').doc(widget.tripId);
        final tripSnap = await t.get(tripRef);
        if (!tripSnap.exists) throw Exception('Trip not found');
        final tripData = tripSnap.data()!;
        if (tripData['status'] != 'BOARDED') throw Exception('Trip already completed');

        // Base fare: 45.00 LKR (4500 cents); companions not stored in passengerTrips
        const int finalDeduction = 4500;

        final passengerRef = FirebaseFirestore.instance
            .collection('passengers')
            .doc(tripData['passengerId'] as String);
        final passSnap = await t.get(passengerRef);
        if (!passSnap.exists) throw Exception('Passenger not found');
        final currentBalance = (passSnap.data()!['walletBalance'] as int?) ?? 0;
        if (currentBalance < finalDeduction) throw Exception('Insufficient balance');

        t.update(passengerRef, {'walletBalance': currentBalance - finalDeduction});
        t.update(tripRef, {
          'exitLocation': tripData['entryLocation'], // same stop = base fare only
          'droppedAt': FieldValue.serverTimestamp(),
          'fareCents': finalDeduction,
          'status': 'COMPLETED',
          'manualCheckout': true,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger checked out successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          )
        : IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.orange, size: 22),
            tooltip: 'Manual Checkout',
            onPressed: _manualCheckout,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          );
  }
}
