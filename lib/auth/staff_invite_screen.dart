import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/invite_service.dart';
import '../../core/auth/role_router.dart';

class StaffInviteScreen extends StatefulWidget {
  final Map<String, dynamic> inviteData;

  const StaffInviteScreen({super.key, required this.inviteData});

  @override
  State<StaffInviteScreen> createState() => _StaffInviteScreenState();
}

class _StaffInviteScreenState extends State<StaffInviteScreen> {
  bool _isLoading = false;

  Future<void> _respond(bool accept) async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await InviteService.respondToInvite(
        widget.inviteData['inviteId'],
        user.uid,
        accept,
      );

      if (!mounted) return;
      if (accept) {
        // Go to RoleRouter which will now see the new role
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouter()),
          (route) => false,
        );
      } else {
        // Just go to their existing role
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouter()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = widget.inviteData['businessName'] ?? 'a Transport Owner';
    final role = widget.inviteData['role'] ?? 'Staff';
    final busId = widget.inviteData['busId'] ?? 'Unassigned Bus';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.purpleLight, width: 2),
                  ),
                  child: const Icon(Icons.mail_outline, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Join Staff Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    children: [
                      const TextSpan(text: 'You have been invited by '),
                      TextSpan(
                        text: businessName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' to join as a '),
                      TextSpan(
                        text: role.toUpperCase(),
                        style: const TextStyle(color: AppTheme.purpleLight, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' for bus '),
                      TextSpan(
                        text: busId,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => _respond(true),
                        style: AppTheme.primaryButton(),
                        child: const Text('Accept Invitation'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _respond(false),
                        child: const Text('Decline', style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
                const Spacer(),
                const Text(
                  'Note: Once accepted, an Admin must approve your assignment before you can start trips.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
