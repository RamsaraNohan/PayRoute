import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../crew/driver/driver_trip_screen.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Driver Portal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('drivers')
                .where('userId', isEqualTo: user?.uid)
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.purpleLight));
              }

              final driverDocs = snapshot.data?.docs ?? [];
              if (driverDocs.isEmpty) {
                return _buildErrorState('Driver profile not found.');
              }

              final driverData = driverDocs.first.data() as Map<String, dynamic>;
              final busId = driverData['assignedBusId'] as String?;
              final fullName = driverData['fullName'] as String? ?? 'Driver';
              final isPending = busId == null || busId == 'Pending Assignment';

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _buildDriverHeader(fullName),
                  const SizedBox(height: 28),
                  isPending ? _buildWaitingState() : _buildBusCard(context, busId),
                  const SizedBox(height: 32),
                  if (!isPending) ...[
                    _buildSectionTitle('Shift History'),
                    const SizedBox(height: 16),
                    _buildShiftHistory(busId),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDriverHeader(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting,', style: const TextStyle(color: Colors.white60, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        AppTheme.statusBadge('DRIVER', AppTheme.cyanAccent),
      ],
    );
  }

  Widget _buildBusCard(BuildContext context, String busId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('buses').doc(busId).snapshots(),
      builder: (context, snapshot) {
        final busData = snapshot.data?.data() as Map<String, dynamic>?;
        final routeId = busData?['routeId'] as String? ?? 'Unassigned';
        final regNum = busData?['registrationNumber'] as String? ?? busId;
        final capacity = busData?['capacity'] as int? ?? 0;

        return Column(
          children: [
            // Bus info card
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.purplePrimary.withValues(alpha: 0.5),
                        AppTheme.blueAccent.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x44FFFFFF), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.purpleLight.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.directions_bus_rounded,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ASSIGNED BUS',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(regNum,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _statChip(Icons.route_rounded, 'Route $routeId'),
                          const SizedBox(width: 12),
                          if (capacity > 0) _statChip(Icons.people_alt_rounded, '$capacity seats'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverTripScreen(busId: busId, routeId: routeId),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('START JOURNEY',
                            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        style: AppTheme.glowButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildShiftHistory(String busId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'COMPLETED')
          .orderBy('boardingTime', descending: true)
          .limit(15)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.purpleLight));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.glassCard(),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                const Text('No shift history yet',
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          );
        }
        final currencyFormat = NumberFormat('#,##0.00', 'en_US');
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fare = (data['finalFare'] as int?) ?? 0;
            final rawTime = data['boardingTime'] as String?;
            final dateStr = rawTime != null
                ? DateFormat('MMM d, h:mm a').format(DateTime.parse(rawTime))
                : '—';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: AppTheme.glassCard(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.purpleLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppTheme.purpleLight, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['boardingStopName'] as String? ?? 'Completed Trip',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(dateStr,
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(
                    'LKR ${currencyFormat.format(fare / 100)}',
                    style: const TextStyle(
                        color: AppTheme.purpleLight, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWaitingState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: const Color(0x15FFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 48, color: Colors.amber),
              ),
              const SizedBox(height: 24),
              const Text(
                'Waiting for Assignment',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Once your owner assigns you to a bus and an admin approves it, your dashboard will activate.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Text(msg, style: const TextStyle(color: Colors.redAccent)),
    );
  }
}

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: AppTheme.gradientBackground(),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('drivers')
              .where('userId', isEqualTo: user?.uid)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final driverDocs = snapshot.data?.docs ?? [];
            if (driverDocs.isEmpty) {
              return _buildErrorState('Driver profile not found.');
            }

            final driverData = driverDocs.first.data() as Map<String, dynamic>;
            final busId = driverData['assignedBusId'];

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Driver Portal',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: const Icon(Icons.logout, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (busId == null || busId == 'Pending Assignment')
                    _buildWaitingState()
                  else
                    _buildBusCard(context, busId),
                  
                  const Spacer(),
                  const Text(
                    'Recent Shift History',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: busId == null || busId == 'Pending Assignment'
                        ? Container(
                            width: double.infinity,
                            decoration: AppTheme.glassCard(),
                            child: const Center(
                              child: Text('No shift history available.', style: TextStyle(color: Colors.white24)),
                            ),
                          )
                        : _buildShiftHistory(busId),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShiftHistory(String busId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'COMPLETED')
          .orderBy('boardingTime', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            decoration: AppTheme.glassCard(),
            child: const Center(
              child: Text('No recent trips recorded.', style: TextStyle(color: Colors.white24)),
            ),
          );
        }
        final currencyFormat = NumberFormat('#,##0.00', 'en_US');
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final fare = (data['finalFare'] as int?) ?? 0;
            final rawTime = data['boardingTime'] as String?;
            final dateStr = rawTime != null
                ? DateFormat('MMM d, h:mm a').format(DateTime.parse(rawTime))
                : '—';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppTheme.glassCard(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['boardingStopName'] ?? 'Trip',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                  Text(
                    'LKR ${currencyFormat.format(fare / 100)}',
                    style: const TextStyle(color: AppTheme.purpleLight, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBusCard(BuildContext context, String busId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('buses').doc(busId).snapshots(),
      builder: (context, snapshot) {
        final busData = snapshot.data?.data() as Map<String, dynamic>?;
        if (busData == null) return const SizedBox();

        final routeId = busData['routeId'] ?? 'Unassigned Route';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassCard(),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: AppTheme.purpleLight, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Fleet', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(busData['registrationNumber'] ?? busId, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              _infoRow(Icons.pin_drop_outlined, 'Route $routeId'),
              const SizedBox(height: 12),
              _infoRow(Icons.confirmation_number_outlined, busData['registrationNumber'] ?? busId),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverTripScreen(busId: busId, routeId: routeId),
                    ),
                  );
                },
                style: AppTheme.primaryButton(),
                child: const Text('START JOURNEY'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15)),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassCard(),
      child: const Column(
        children: [
          Icon(Icons.hourglass_empty, size: 64, color: Colors.amber),
          SizedBox(height: 24),
          Text(
            'Waiting for Assignment',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Once your owner assigns you to a bus and it\'s approved by an admin, you can start your shift.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(child: Text(msg, style: const TextStyle(color: Colors.redAccent)));
  }
}
