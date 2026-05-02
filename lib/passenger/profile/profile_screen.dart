#profilenew
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';
import '../complaint/complaint_screen.dart';
import '../help/help_faq_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../legal/privacy_policy_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passengerAsync = ref.watch(passengerStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: passengerAsync.when(
          data: (passenger) {
            if (passenger == null) {
              return const Center(child: Text('Complete your profile to view details', style: TextStyle(color: Colors.white)));
            }
            final currency = NumberFormat('#,##0.00', 'en_US');

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar + name
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppTheme.purpleLight.withValues(alpha: 0.3),
                            backgroundImage: passenger.profilePhotoUrl.isNotEmpty
                                ? NetworkImage(passenger.profilePhotoUrl)
                                : null,
                            child: passenger.profilePhotoUrl.isEmpty
                                ? Text(
                                    passenger.fullName.isNotEmpty ? passenger.fullName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.purpleLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.backgroundDark, width: 2),
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(passenger.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Passenger ID: ${passenger.passengerId}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.purpleLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.purpleLight.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'PASSENGER',
                          style: TextStyle(color: AppTheme.purpleLight, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Balance card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCard(),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: AppTheme.purpleLight, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Wallet Balance', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          Text(
                            'LKR ${currency.format(passenger.walletBalance / 100)}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Info section
                _sectionTitle('Account Information'),
                _infoTile(Icons.person_outline, 'Full Name', passenger.fullName),
                _infoTile(Icons.badge_outlined, 'Role', 'Passenger'),
                _infoTile(Icons.fingerprint, 'User ID', '${passenger.userId.substring(0, 12)}...'),

                const SizedBox(height: 24),
                _sectionTitle('My Rides'),
                _actionTile(
                  context,
                  Icons.calendar_month_outlined,
                  'My Bookings',
                  'View and manage advance seat reservations',
                  Colors.tealAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Support'),
                _actionTile(
                  context,
                  Icons.report_problem_outlined,
                  'File a Complaint',
                  'Report an issue with a trip',
                  Colors.orangeAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen())),
                ),
                _actionTile(
                  context,
                  Icons.help_outline,
                  'Help & FAQ',
                  'Get answers to common questions',
                  Colors.blueAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpFaqScreen())),
                ),
                _actionTile(
                  context,
                  Icons.privacy_tip_outlined,
                  'Privacy Policy & Terms',
                  'Read our data and usage policies',
                  Colors.white54,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),

                const SizedBox(height: 24),
                _sectionTitle('Account'),
                _actionTile(
                  context,
                  Icons.edit_outlined,
                  'Edit Profile',
                  'Update your name, address and contacts',
                  AppTheme.purpleLight,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                _actionTile(
                  context,
                  Icons.logout,
                  'Sign Out',
                  'You will need to log in again',
                  Colors.redAccent,
                  () => FirebaseAuth.instance.signOut(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.glassCard(),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.glassCard(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
#profiledone
