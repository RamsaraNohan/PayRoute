import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';
import '../../core/services/trip_service.dart';
import '../active_trip/active_trip_screen.dart';
import 'package:intl/intl.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _isScanning = true;
  bool _processing = false;
  int _companions = 0;

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (!_isScanning || _processing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      
      // Expected Format: trip:TRIP_ID:bus:BUS_ID
      if (!code.startsWith('trip:')) return;

      setState(() {
        _isScanning = false;
        _processing = true;
      });

      try {
        final parts = code.split(':');
        final tripId = parts[1];
        
        final passenger = ref.read(passengerStreamProvider).value;
        if (passenger == null) throw Exception('Passenger profile not found.');

        // 1. Get current location for fare/entry accuracy
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final location = cf.GeoPoint(position.latitude, position.longitude);

        // 2. Check for active trip to determine entry/exit
        final activeTripQuery = await cf.FirebaseFirestore.instance
            .collection('passengerTrips')
            .where('passengerId', isEqualTo: passenger.passengerId)
            .where('status', isEqualTo: 'BOARDED')
            .limit(1)
            .get();

        if (activeTripQuery.docs.isEmpty) {
          // ENTRY SCAN (BOARDING)
          if (passenger.walletBalance < 10000) {
            throw Exception('Insufficient balance. Minimum 100.00 LKR required to board.');
          }
          await TripService.processBoarding(
            tripId: tripId,
            passengerId: passenger.passengerId,
            location: location,
          );
          if (!mounted) return;
          _showToast('Successfully Boarded!', Colors.green);
        } else {
          // EXIT SCAN (DROPPING)
          await TripService.processDropping(
            tripId: tripId,
            passengerId: passenger.passengerId,
            exitLocation: location,
          );
          if (!mounted) return;
          _showToast('Trip Completed. Fare Deducted.', Colors.blueAccent);
        }

        if (!mounted) return;
        Navigator.pop(context); // Go back to dashboard which will show active trip or history
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isScanning = true;
          _processing = false;
        });
      }
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passengerAsync = ref.watch(passengerStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Bus QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // SCANNER LAYER
          MobileScanner(
            onDetect: _handleScan,
          ),
          
          // SCANNER OVERLAY
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.purpleLight, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                   _ScannerLineAnimation(),
                ],
              ),
            ),
          ),

          // INSTRUCTIONS LAYER
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassCard(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.purpleLight),
                  const SizedBox(height: 12),
                  const Text(
                    'Entry & Exit Scan',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan the unique QR code on the conductor\'s phone when you board and again when you drop.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  passengerAsync.when(
                    data: (p) => Text(
                      'Balance: LKR ${NumberFormat('#,##0.00').format((p?.walletBalance ?? 0) / 100)}',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),

          // PROCESSING OVERLAY
          if (_processing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.purpleLight),
                    SizedBox(height: 24),
                    Text(
                      'Verifying Trip Session...',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerLineAnimation extends StatefulWidget {
  @override
  State<_ScannerLineAnimation> createState() => _ScannerLineAnimationState();
}

class _ScannerLineAnimationState extends State<_ScannerLineAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 250 * _controller.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: AppTheme.purpleLight.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
              ],
              color: AppTheme.purpleLight,
            ),
          ),
        );
      },
    );
  }
}
