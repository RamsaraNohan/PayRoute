import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('passengerId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.purpleLight));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 72, color: Colors.white24),
                    SizedBox(height: 16),
                    Text('No bookings yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                      'Use "Book Ride" on the home screen\nto reserve your seat in advance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data() as Map<String, dynamic>;
                return _BookingCard(
                  bookingId: doc.id,
                  data: data,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;

  const _BookingCard({required this.bookingId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'CONFIRMED';
    final route = data['route'] as String? ?? 'Unknown Route';
    final scheduledTimeStr = data['scheduledTime'] as String?;
    final seatPref = data['seatPreference'] as String? ?? 'Any';
    final companions = (data['companionCount'] as int?) ?? 0;

    DateTime? scheduledTime;
    if (scheduledTimeStr != null) {
      try {
        scheduledTime = DateTime.parse(scheduledTimeStr);
      } catch (_) {}
    }

    final isPast = scheduledTime != null && scheduledTime.isBefore(DateTime.now());
    final isCancelled = status == 'CANCELLED';
    final statusColor = isCancelled
        ? Colors.redAccent
        : isPast
            ? Colors.white38
            : Colors.greenAccent;
    final statusLabel = isCancelled ? 'CANCELLED' : isPast ? 'PAST' : 'CONFIRMED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  route,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (scheduledTime != null)
            _infoRow(
              Icons.access_time_outlined,
              DateFormat('EEE, MMM d yyyy  •  h:mm a').format(scheduledTime),
            ),
          const SizedBox(height: 6),
          _infoRow(Icons.event_seat_outlined, 'Seat: $seatPref'),
          if (companions > 0) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.people_outline, '+$companions companion${companions > 1 ? 's' : ''}'),
          ],
          if (!isCancelled && !isPast) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelBooking(context),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel Booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
          'status': 'CANCELLED',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled.'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
