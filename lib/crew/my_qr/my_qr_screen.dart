import 'dart:convert';
import 'dart:ui';
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
  bool _nfcWriting = false;
  bool _nfcSupported = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      if (mounted) setState(() => _nfcSupported = available);
    } catch (_) {
      if (mounted) setState(() => _nfcSupported = false);
    }
  }

  /// Writes the QR payload as an NDEF Text record to a physical NFC tag.
  Future<void> _writeNfcTag(String payload) async {
    if (!_nfcSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC not available on this device')),
      );
      return;
    }
    setState(() => _nfcWriting = true);
    final scaffoldMsg = ScaffoldMessenger.of(context);
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              await NfcManager.instance.stopSession(errorMessage: 'Tag not writable');
              if (mounted) setState(() => _nfcWriting = false);
              return;
            }
            await ndef.write(NdefMessage([NdefRecord.createText(payload)]));
            await NfcManager.instance.stopSession();
            if (mounted) {
              setState(() => _nfcWriting = false);
              scaffoldMsg.showSnackBar(const SnackBar(
                content: Text('NFC tag written — passengers can tap to board!'),
                backgroundColor: Colors.green,
              ));
            }
          } catch (e) {
            await NfcManager.instance.stopSession(errorMessage: e.toString());
            if (mounted) setState(() => _nfcWriting = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _nfcWriting = false);
        scaffoldMsg.showSnackBar(SnackBar(content: Text('NFC error: $e')));
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: SafeArea(
          child: userAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: Text('Please log in.', style: TextStyle(color: Colors.white)));
              }

              final qrData = jsonEncode({
                'conductorId': user.userId,
                'type': 'payroute_identity_v1',
              });

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Your Identity QR',
                      style: TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the Active Trip screen to generate\nthe passenger boarding QR & NFC tag.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.purpleLight.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 260.0,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_nfcSupported)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0x14FFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.nfc, color: AppTheme.purpleLight, size: 28),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Write identity to NFC tag',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                _nfcWriting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: AppTheme.purpleLight),
                                      )
                                    : ElevatedButton(
                                        onPressed: () => _writeNfcTag(qrData),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.purplePrimary,
                                          foregroundColor: Colors.white,
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        child: const Text('Write', style: TextStyle(fontSize: 13)),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, st) => Center(
                child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
          ),
        ),
      ),
    );
  }
}
