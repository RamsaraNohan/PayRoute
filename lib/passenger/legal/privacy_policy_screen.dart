import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Privacy Policy & Terms'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              'Privacy Policy',
              'Last updated: January 2025',
              Colors.blueAccent,
              Icons.privacy_tip_outlined,
            ),
            _buildParagraph(
              'Information We Collect',
              'PayRoute collects the following information to provide our bus payment and tracking service:\n'
              '• Mobile phone number (for account verification)\n'
              '• Full name and National Identity Card (NIC) number\n'
              '• Home/work address\n'
              '• Emergency contact details\n'
              '• Profile photo\n'
              '• GPS location (only during active trips)\n'
              '• Payment transaction history',
            ),
            _buildParagraph(
              'How We Use Your Information',
              '• To verify your identity and prevent fraud\n'
              '• To process bus fare payments from your wallet\n'
              '• To track your active trip in real time\n'
              '• To generate your trip history and receipts\n'
              '• To send you trip and payment notifications\n'
              '• To respond to complaints and support requests',
            ),
            _buildParagraph(
              'Data Storage & Security',
              'Your data is stored securely on Google Firebase servers. We use Firebase Authentication for secure phone-number-based sign-in. Payment data is processed through PayHere — a PCI-DSS compliant payment gateway. We do not store your card or bank details.',
            ),
            _buildParagraph(
              'Data Sharing',
              'We share your data with:\n'
              '• Bus operators (name, trip details) to manage services\n'
              '• PayHere (payment processing only)\n'
              'We do NOT sell your personal data to any third party.',
            ),
            _buildParagraph(
              'Your Rights',
              'You may request deletion of your account and data by contacting support@payroute.lk. Location data is only collected while a trip is active and is not stored after trip completion.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Terms of Service',
              'By using PayRoute you agree to the following',
              Colors.purpleAccent,
              Icons.gavel_outlined,
            ),
            _buildParagraph(
              '1. Wallet & Payments',
              '• You must maintain a minimum balance of LKR 100 to board a bus.\n'
              '• Fares are deducted automatically when you scan the exit QR code.\n'
              '• Wallet top-ups are processed via PayHere and are non-refundable once credited.\n'
              '• PayRoute is not liable for bank-side delays in wallet funding.',
            ),
            _buildParagraph(
              '2. QR Check-In / Check-Out',
              '• You must scan the conductor\'s QR code to begin a trip.\n'
              '• You must scan again at your destination to end the trip.\n'
              '• Failure to scan at exit will keep your trip marked ONGOING until manually resolved by support.\n'
              '• Attempting to board without sufficient balance will be refused.',
            ),
            _buildParagraph(
              '3. Acceptable Use',
              '• You may not share your account or QR token with another person.\n'
              '• Using fake GPS or manipulated tokens to evade fares is a criminal offense.\n'
              '• PayRoute reserves the right to suspend accounts found in violation.',
            ),
            _buildParagraph(
              '4. Liability',
              'PayRoute provides a digital payment and tracking platform. We are not a bus operator and are not liable for delays, accidents, or service quality of bus operators. In the event of a technical failure preventing fare collection, contact support within 24 hours.',
            ),
            _buildParagraph(
              '5. Account Security',
              'You are responsible for keeping your phone and OTP confidential. PayRoute will never ask for your OTP. If your phone is lost, contact support immediately to freeze your wallet.',
            ),
            _buildParagraph(
              'Contact Us',
              'For questions about this policy:\n'
              'Email: support@payroute.lk\n'
              'Phone: +94 11 000 0000\n'
              'Hours: Monday–Friday, 9 AM – 6 PM',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String heading, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
