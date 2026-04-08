import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class MyQRScreen extends ConsumerStatefulWidget {
  const MyQRScreen({super.key});

  @override
  ConsumerState<MyQRScreen> createState() => _MyQRScreenState();
}

class _MyQRScreenState extends ConsumerState<MyQRScreen> {
  bool _nfcActive = false;
  bool _nfcSupported = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      setState(() => _nfcSupported = isAvailable);
    } catch (e) {
      setState(() => _nfcSupported = false);
    }
  }

  void _toggleNfc(bool value, String qrPayload) async {
    if (!_nfcSupported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC not available on this device')));
      return;
    }

    setState(() => _nfcActive = value);

    if (value) {
      try {
        NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
          // NDEF encoding logic would go here for real implementation
          // For coursework, we indicate we are listening and handle callbacks.
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NFC active - ready to tap')));
      } catch (e) {
        setState(() => _nfcActive = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error starting NFC session')));
      }
    } else {
      NfcManager.instance.stopSession();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    if (_nfcActive) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: userAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: Text('Please log in.', style: TextStyle(color: Colors.white)));
              }

              final qrData = jsonEncode({
                "conductorId": user.userId,
                "busId": "bus_123", // Static fallback until Phase 5
                "type": "payroute_checkin_v1"
              });

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Show this QR or let passengers tap your phone', 
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 280.0,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: AppTheme.glassCard(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NFC Active', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Switch(
                          value: _nfcActive,
                          activeThumbColor: AppTheme.purpleLight,
                          onChanged: (val) => _toggleNfc(val, qrData),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
          ),
        ),
      ),
    );
  }
}
