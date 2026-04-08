import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class ConductorQrScreen extends StatelessWidget {
  const ConductorQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conductorId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    // In production this would include busId from the conductor's assignment
    final qrData = 'conductor:$conductorId:bus:bus_123';

    return Container(
      decoration: AppTheme.gradientBackground(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Show this QR to passengers',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.purpleLight.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Bus: bus_123  •  Conductor: ${conductorId.substring(0, 8)}...',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
