import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class TripReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> tripData;
  const TripReceiptScreen({super.key, required this.tripData});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0.00', 'en_US');
    final fareCents = (tripData['fareCents'] as int?) ?? 4500;
    final boardingTime = tripData['boardingTime'] != null
        ? DateFormat('MMM dd, yyyy  hh:mm a').format(DateTime.parse(tripData['boardingTime']))
        : '—';
    final dropTime = tripData['dropTime'] != null
        ? DateFormat('hh:mm a').format(DateTime.parse(tripData['dropTime']))
        : '—';
    final companions = (tripData['companionCount'] as int?) ?? 0;
    final totalFare = fareCents * (1 + companions);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Trip Receipt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {}, // Share receipt
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Receipt Card
              Container(
                width: double.infinity,
                decoration: AppTheme.glassCard(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text('Trip Completed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(boardingTime, style: const TextStyle(color: Colors.white54, fontSize: 12)),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 16),

                    // Route info
                    _receiptRow('Bus', tripData['busId'] ?? '—'),
                    _receiptRow('Destination', tripData['destinationStopId'] ?? '—'),
                    _receiptRow('Boarded', boardingTime),
                    _receiptRow('Dropped', dropTime),
                    if (companions > 0) _receiptRow('Companions', '+$companions'),
                    _receiptRow('Seat No.', '${tripData['seatNumber'] ?? '—'}'),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 16),

                    // Fare summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fare per person', style: TextStyle(color: Colors.white54)),
                        Text('LKR ${currency.format(fareCents / 100)}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    if (companions > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('x${1 + companions} persons', style: const TextStyle(color: Colors.white54)),
                          Text('LKR ${currency.format(totalFare / 100)}', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.purpleLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Charged', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'LKR ${currency.format(totalFare / 100)}',
                            style: const TextStyle(color: AppTheme.purpleLight, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
