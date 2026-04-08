import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';
import 'role_selection_screen.dart';
import '../core/auth/role_router.dart';

class RoleSwitchScreen extends StatelessWidget {
  final List<String> availableRoles;

  const RoleSwitchScreen({super.key, required this.availableRoles});

  Future<void> _switchRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'activeRole': role,
    });

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleRouter()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Switch Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose which role you want to use right now.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      ...availableRoles.map((role) => _buildRoleCard(context, role)),
                      _buildAddRoleCard(context),
                    ],
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign Out', style: TextStyle(color: Colors.white54)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String role) {
    IconData icon;
    String label;
    Color color;

    switch (role) {
      case 'passenger':
        icon = Icons.person_outline;
        label = 'Passenger';
        color = Colors.blueAccent;
        break;
      case 'driver':
        icon = Icons.drive_eta_outlined;
        label = 'Driver';
        color = Colors.amber;
        break;
      case 'conductor':
        icon = Icons.badge_outlined;
        label = 'Conductor';
        color = AppTheme.purpleLight;
        break;
      case 'owner':
        icon = Icons.business_outlined;
        label = 'Owner';
        color = Colors.greenAccent;
        break;
      default:
        icon = Icons.help_outline;
        label = role.toUpperCase();
        color = Colors.white24;
    }

    return InkWell(
      onTap: () => _switchRole(context, role),
      child: Container(
        decoration: AppTheme.glassCard(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRoleCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              'Add Role',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
