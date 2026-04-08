import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'registration/passenger_registration.dart';
import 'registration/driver_registration.dart';
import 'registration/conductor_registration.dart';
import 'registration/owner_registration.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Join PayRoute as...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your primary role to get started',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildRoleCard(
                        context: context,
                        title: 'Passenger',
                        subtitle: 'Tap to ride',
                        icon: Icons.person_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PassengerRegistration()),
                        ),
                      ),
                      _buildRoleCard(
                        context: context,
                        title: 'Driver',
                        subtitle: 'Drive & earn',
                        icon: Icons.drive_eta_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverRegistration()),
                        ),
                      ),
                      _buildRoleCard(
                        context: context,
                        title: 'Conductor',
                        subtitle: 'Manage bus',
                        icon: Icons.badge_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConductorRegistration()),
                        ),
                      ),
                      _buildRoleCard(
                        context: context,
                        title: 'Owner',
                        subtitle: 'Fleet manager',
                        icon: Icons.business_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OwnerRegistration()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCard(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
