import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/trip_service.dart';

class ConductorTripScreen extends StatefulWidget {
  final String busId;
  final String routeId;

  const ConductorTripScreen({
    super.key, 
    required this.busId, 
    required this.routeId
  });

  @override
  State<ConductorTripScreen> createState() => _ConductorTripScreenState();
}

class _ConductorTripScreenState extends State<ConductorTripScreen> {
  String? _tripId;
  bool _tripStarted = false;
  bool _isLoading = false;

  Future<void> _toggleTrip() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (!_tripStarted) {
        // Find driverId for this bus (required for trip start)
        final busDoc = await FirebaseFirestore.instance.collection('buses').doc(widget.busId).get();
        final driverId = busDoc.data()?['driverId'] ?? 'pending';

        final id = await TripService.startTrip(
          busId: widget.busId,
          driverId: driverId,
          conductorId: user.uid,
          routeId: widget.routeId,
        );
        setState(() {
          _tripId = id;
          _tripStarted = true;
        });
      } else {
        // Logic for ending trip can be added here
        setState(() {
          _tripStarted = false;
          _tripId = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'ACTIVE TRIP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const Spacer(),
                if (!_tripStarted)
                  _buildIdleState()
                else
                  _buildActiveState(),
                const Spacer(),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  ElevatedButton(
                    onPressed: _toggleTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tripStarted ? Colors.redAccent.withValues(alpha: 0.2) : AppTheme.purpleLight,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: _tripStarted ? const BorderSide(color: Colors.redAccent) : null,
                    ),
                    child: Text(_tripStarted ? 'END TRIP SESSION' : 'START NEW TRIP'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        Icon(Icons.qr_code_scanner, size: 100, color: Colors.white.withValues(alpha: 0.1)),
        const SizedBox(height: 24),
        const Text(
          'Ready to Start?',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Starting a trip will generate a unique QR code for passengers to scan for boarding and dropping.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildActiveState() {
    // Generate the unique QR data
    final qrData = 'trip:$_tripId:bus:${widget.busId}';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.purpleLight.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 240.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'UNIQUE TRIP QR',
          style: TextStyle(color: AppTheme.purpleLight, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Trip ID: ${_tripId?.substring(_tripId!.length - 8)}',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        // Live counters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem('Boarded', '0', Icons.people_outline),
            _statItem('Revenue', 'LKR 0', Icons.account_balance_wallet_outlined),
          ],
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: AppTheme.glassCard(),
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
