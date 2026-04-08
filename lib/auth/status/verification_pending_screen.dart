import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Pulsing animation or static clock icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.purpleLight, width: 2),
                  ),
                  child: const Icon(Icons.timer_outlined, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Verification in Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We are currently reviewing your documents. This usually takes 24-48 hours. We\'ll notify you once approved!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                // Status checklist
                _buildStatusItem('Personal Information', true),
                _buildStatusItem('Document Uploads', true),
                _buildStatusItem('Selfie Verification', true),
                _buildStatusItem('Admin Approval', false),
                const Spacer(),
                const Text(
                  'Need help? Contact PayRoute Support',
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Sign Out', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.greenAccent : Colors.white24,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDone ? Colors.white : Colors.white30,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
