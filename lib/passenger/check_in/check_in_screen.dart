import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';
import '../../core/services/trip_service.dart';
import 'package:intl/intl.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  late final MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _processing = false;
  bool _nfcMode = false;
  bool _nfcSupported = false;
  bool _nfcListening = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      if (mounted) setState(() => _nfcSupported = available);
    } catch (_) {}
  }

  void _switchMode(bool toNfc) {
    if (toNfc && !_nfcSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC not supported on this device'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_nfcMode && !toNfc) {
      NfcManager.instance.stopSession();
      setState(() {
        _nfcMode = false;
        _nfcListening = false;
      });
      return;
    }
    if (toNfc && !_nfcMode) {
      setState(() {
        _nfcMode = true;
        _nfcListening = true;
      });
      _startNfcSession();
    }
  }

  Future<void> _startNfcSession() async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) throw Exception('Not an NDEF tag');
            final message = await ndef.read();
            for (final record in message.records) {
              final payload = record.payload;
              if (payload.isEmpty) continue;
              // NDEF Text record: byte[0] = status (bit7=UTF-16, bits[5:0]=lang length)
              final langLen = payload[0] & 0x3F;
              if (payload.length <= 1 + langLen) continue;
              final text = String.fromCharCodes(payload.sublist(1 + langLen));
              if (text.startsWith('trip:')) {
                await NfcManager.instance.stopSession();
                if (mounted) {
                  setState(() => _nfcListening = false);
                  await _processPayload(text);
                }
                return;
              }
            }
            throw Exception('Invalid tag: no trip payload found');
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: 'Invalid tag');
            if (mounted) {
              _showToast('NFC Error: $e', Colors.red);
              setState(() { _nfcListening = false; _nfcMode = false; });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _showToast('Cannot start NFC: $e', Colors.red);
        setState(() { _nfcListening = false; _nfcMode = false; });
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (!_isScanning || _processing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      await _processPayload(barcodes.first.rawValue!);
    }
  }

  Future<void> _processPayload(String code) async {
    // Expected Format: trip:TRIP_ID:bus:BUS_ID
      if (!code.startsWith('trip:')) return;
      final parts = code.split(':');
      if (parts.length < 4) return;

      setState(() {
        _isScanning = false;
        _processing = true;
      });

      try {
        final tripId = parts[1];
        final busId = parts[3];
        
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
            busId: busId,
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
        title: Text(
          _nfcMode ? 'NFC Check-In' : 'Scan Bus QR',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: _nfcSupported
            ? [
                IconButton(
                  tooltip: _nfcMode ? 'Switch to QR' : 'Switch to NFC',
                  icon: Icon(_nfcMode ? Icons.qr_code_scanner : Icons.nfc, color: Colors.white),
                  onPressed: () => _switchMode(!_nfcMode),
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          // SCANNER LAYER (hidden when NFC mode active)
          if (!_nfcMode)
            MobileScanner(
              controller: _scannerController,
              onDetect: _handleScan,
            )
          else
            Container(decoration: AppTheme.gradientBackground()),

          // NFC LISTENING STATE
          if (_nfcMode)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _nfcListening ? AppTheme.purpleLight : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.nfc,
                      size: 72,
                      color: _nfcListening ? AppTheme.purpleLight : Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _nfcListening ? 'Hold phone near the bus NFC tag' : 'NFC ready',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (_nfcListening) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the NFC sticker on the bus seat or door',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

          if (!_nfcMode)
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
                  Icon(_nfcMode ? Icons.nfc : Icons.info_outline, color: AppTheme.purpleLight),
                  const SizedBox(height: 12),
                  Text(
                    _nfcMode ? 'NFC Tap Check-In' : 'Entry & Exit Scan',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nfcMode
                        ? 'Tap the NFC tag on the bus to board. Tap again when you exit.'
                        : 'Scan the unique QR code on the conductor\'s phone when you board and again when you drop.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  passengerAsync.when(
                    data: (p) => Text(
                      'Balance: LKR ${NumberFormat('#,##0.00').format((p?.walletBalance ?? 0) / 100)}',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, _) => const SizedBox(),
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
  void dispose() {
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
