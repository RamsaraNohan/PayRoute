import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../conductor/conductor_trip_screen.dart';

/// Static QR helper shown on the conductor dashboard home tab.
/// The actual boarding QR (trip:TRIP_ID:bus:BUS_ID) is generated inside
/// [ConductorTripScreen] once the conductor starts an active trip session.
class ConductorQrScreen extends StatelessWidget {
  const ConductorQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conductorUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      decoration: AppTheme.gradientBackground(),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conductors')
            .where('userId', isEqualTo: conductorUid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          final conductorDocs = snapshot.data?.docs ?? [];
          final conductorData =
              conductorDocs.isNotEmpty ? conductorDocs.first.data() as Map<String, dynamic> : null;
          final busId = conductorData?['assignedBusId'] as String?;
          final routeId = conductorData?['routeId'] as String? ?? '';

          if (busId == null || busId == 'Pending Assignment') {
            return const Center(
              child: Text(
                'Not yet assigned to a bus.\nAsk your admin to assign you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: AppTheme.glassCard(),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_2, size: 64, color: AppTheme.purpleLight),
                        const SizedBox(height: 20),
                        const Text(
                          'Start a Trip to Show QR',
                          style: TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'The unique boarding QR code (trip:…:bus:…) is generated when you start an active trip session. Tap the button below to begin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ConductorTripScreen(busId: busId, routeId: routeId),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('START TRIP SESSION'),
                          style: AppTheme.glowButton(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
