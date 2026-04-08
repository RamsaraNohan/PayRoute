import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';
import '../wallet/wallet_screen.dart';
import '../booking/advance_booking_screen.dart';
import '../check_in/check_in_screen.dart';
import '../../providers/active_trip_provider.dart';
import '../active_trip/active_trip_screen.dart';
import '../history/trip_history_screen.dart';
import '../../auth/role_selection_screen.dart';

class PassengerHomeTab extends StatefulWidget {
  const PassengerHomeTab({super.key});

  @override
  State<PassengerHomeTab> createState() => _PassengerHomeTabState();
}

class _PassengerHomeTabState extends State<PassengerHomeTab> {

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final passengerAsync = ref.watch(passengerStreamProvider);

        return Scaffold(
          body: Container(
            decoration: AppTheme.gradientBackground(),
            child: SafeArea(
              child: passengerAsync.when(
                data: (passenger) {
                  if (passenger == null) {
                    return _buildCompleteProfileState();
                  }
                  
                  final currencyFormat = NumberFormat('#,##0.00', 'en_US');
                  final balanceStr = currencyFormat.format(passenger.walletBalance / 100);

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeader(passenger),
                      const SizedBox(height: 24),
                      
                      // LIVE TRIP HUD
                      _buildActiveTripHUD(context, ref),
                      
                      const SizedBox(height: 16),
                      // Wallet Card
                      Container(
                        decoration: AppTheme.glassCard(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wallet Balance', style: TextStyle(color: Colors.white60, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text('LKR $balanceStr',
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Updated: ${DateFormat("hh:mm a").format(DateTime.now())}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.purplePrimary,
                                    shape: const StadiumBorder(),
                                    minimumSize: const Size(100, 36),
                                  ),
                                  child: const Text('Top Up'),
                                )
                              ],
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildQuickAction(context, Icons.calendar_month, 'Book Ride',
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvanceBookingScreen()))),
                          _buildQuickAction(context, Icons.history, 'My Trips',
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()))),
                          _buildQuickAction(context, Icons.qr_code_scanner, 'Check In', 
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen()))),
                          _buildQuickAction(context, Icons.account_balance_wallet, 'Wallet',
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
                        ],
                      ),

                      const SizedBox(height: 32),
                      const Text('Recent Activity',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      _buildRealRecentTrips(passenger.passengerId),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(dynamic passenger) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, ${passenger.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
              const Text('Good day', style: TextStyle(color: Colors.white60, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
            CircleAvatar(
              backgroundColor: AppTheme.purpleLight,
              backgroundImage: passenger.profilePhotoUrl.isNotEmpty ? NetworkImage(passenger.profilePhotoUrl) : null,
              child: passenger.profilePhotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveTripHUD(BuildContext context, WidgetRef ref) {
    final activeTripAsync = ref.watch(currentActiveTripProvider);

    return activeTripAsync.when(
      data: (trip) {
        if (trip == null) return const SizedBox();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.purpleLight.withValues(alpha: 0.9), AppTheme.purplePrimary.withValues(alpha: 0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppTheme.purpleLight.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.radar, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('LIVE JOURNEY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('ON BUS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Bus ID', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        Text(trip['busId'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveTripScreen(tripData: trip))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.purplePrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('VIEW MAP'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppTheme.glassCard(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.purpleLight, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteProfileState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 64, color: Colors.white30),
            const SizedBox(height: 16),
            const Text('Profile Details Missing', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Please complete your passenger registration.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              ),
              style: AppTheme.primaryButton(),
              child: const Text('Complete Info')
            )
          ],
        ),
      )
    );
  }

  Widget _buildRealRecentTrips(String passengerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('passengerId', isEqualTo: passengerId)
          .orderBy('boardingTime', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassCard(),
            child: const Column(
              children: [
                Icon(Icons.directions_bus_outlined, size: 48, color: Colors.white30),
                SizedBox(height: 12),
                Text('No recent trips', style: TextStyle(color: Colors.white60)),
                Text('Board a bus using Check In to get started',
                     style: TextStyle(color: Colors.white38, fontSize: 12)),
              ]
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final currencyFormat = NumberFormat('#,##0.00', 'en_US');
            final fareCents = (data['fareCents'] as int?) ?? (data['finalFare'] as int?) ?? 0;
            final rawTime = data['boardingTime'] as String?;
            final dateStr = rawTime != null
                ? DateFormat("MMM d, h:mm a").format(DateTime.parse(rawTime))
                : '—';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.purpleLight.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.directions_bus, color: AppTheme.purpleLight),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data['boardingStopName'] ?? 'Start'} → ${data['destinationStopId'] ?? 'End'}', 
                             maxLines: 1, overflow: TextOverflow.ellipsis,
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('LKR ${currencyFormat.format(fareCents / 100)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
