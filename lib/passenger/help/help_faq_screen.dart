import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final List<_FaqItem> _faqs = const [
    _FaqItem(
      question: 'How do I board a bus?',
      answer: 'Open the Check In tab, scan the QR code on the conductor\'s phone. Your wallet will be checked for a minimum balance of LKR 100. Once scanned, your trip begins automatically.',
    ),
    _FaqItem(
      question: 'How do I pay for my trip?',
      answer: 'Payment is automatic. When you scan the QR code to exit the bus, the exact fare is calculated based on the distance you travelled and deducted from your PayRoute wallet instantly.',
    ),
    _FaqItem(
      question: 'How do I top up my wallet?',
      answer: 'Go to the Wallet tab and tap "Top Up". You can top up using the PayHere gateway via card, bank transfer, or other supported methods. Funds appear instantly.',
    ),
    _FaqItem(
      question: 'What if I forget to scan when I exit?',
      answer: 'The conductor can manually check you out from their screen. If neither happens, contact support through the Profile > File a Complaint option with your trip details.',
    ),
    _FaqItem(
      question: 'How is the fare calculated?',
      answer: 'The fare is based on a base rate plus the GPS distance travelled (using the Haversine formula). Companions you registered are included in the total deduction.',
    ),
    _FaqItem(
      question: 'Can I edit my NIC after registration?',
      answer: 'No. Your NIC number is locked once submitted to prevent identity fraud. If you entered it incorrectly, please contact support to raise a correction request.',
    ),
    _FaqItem(
      question: 'Can I change my phone number?',
      answer: 'Phone numbers are tied to your Firebase Authentication account for security. Contact PayRoute support to initiate an official phone number change process.',
    ),
    _FaqItem(
      question: 'What happens if my wallet balance is too low?',
      answer: 'You need a minimum balance of LKR 100 to board. If you have insufficient balance after boarding, the system will still process the trip but flag the shortfall for review.',
    ),
    _FaqItem(
      question: 'How do I report a problem with a trip?',
      answer: 'Go to Profile > File a Complaint, or tap the help icon on the active journey screen. Select the category and describe the issue. Our team will review it within 48 hours.',
    ),
    _FaqItem(
      question: 'How do I track my bus in real time?',
      answer: 'Use the Routes tab to find your bus line, then tap it to open the live tracking map. When you\'re on a trip, you can also tap VIEW MAP on your home screen.',
    ),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: AppTheme.purpleLight, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Need more help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('File a complaint from the Profile tab and our team will respond within 48 hours.',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(_faqs.length, (i) {
              final isOpen = _expanded.contains(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppTheme.glassCard(),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey(i),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    iconColor: AppTheme.purpleLight,
                    collapsedIconColor: Colors.white54,
                    onExpansionChanged: (v) => setState(() => v ? _expanded.add(i) : _expanded.remove(i)),
                    title: Text(
                      _faqs[i].question,
                      style: TextStyle(
                        color: isOpen ? AppTheme.purpleLight : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Text(
                        _faqs[i].answer,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
