import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _isLoading = false;

  void _showTopUpDialog(int? initialAmountCents) {
    final TextEditingController controller = TextEditingController(
      text: initialAmountCents != null ? (initialAmountCents / 100).toStringAsFixed(0) : ''
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text('Add Credits', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to transfer from your bank account:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixText: 'LKR ',
                prefixStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.purpleLight)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(context);
                _topUp((val * 100).toInt());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.purpleLight,
              minimumSize: const Size(120, 40),
            ),
            child: const Text('Transfer Now'),
          ),
        ],
      ),
    );
  }

  void _topUp(int amountCents) async {
    setState(() => _isLoading = true);
    await ref.read(walletBalanceProvider.notifier).topUp(amountCents);
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transferred LKR ${(amountCents / 100).toStringAsFixed(2)} successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passengerAsync = ref.watch(passengerStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: passengerAsync.when(
            data: (passenger) {
              if (passenger == null) return _buildEmptyState();
              final NumberFormat currencyFormat = NumberFormat('#,##0.00', 'en_US');
              final balanceStr = currencyFormat.format(passenger.walletBalance / 100);

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        decoration: AppTheme.glassCard(),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('Available Balance', style: TextStyle(color: Colors.white60, fontSize: 16)),
                            const SizedBox(height: 12),
                            Text('LKR $balanceStr', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Text('Updated: ${DateFormat("hh:mm a").format(DateTime.now())}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Quick Top Up', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildAmountChip(10000), // LKR 100
                          _buildAmountChip(50000), // LKR 500
                          _buildAmountChip(100000), // LKR 1000
                          _buildAmountChip(200000), // LKR 2000
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      ElevatedButton.icon(
                        onPressed: () => _showTopUpDialog(null),
                        style: AppTheme.primaryButton(),
                        icon: const Icon(Icons.account_balance_outlined),
                        label: const Text('Transfer from Bank', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 12),
                      const Center(child: Text('Secure transaction via PayRoute Gateway', style: TextStyle(color: Colors.white70, fontSize: 11))),

                      const SizedBox(height: 32),
                      const Text('Recent Trip Deductions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      _buildRealTransactionHistory(passenger.userId),
                    ],
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text('Processing Transfer...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
          )
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          const Text('Profile Details Missing', style: TextStyle(color: Colors.white, fontSize: 18)),
          const Text('Please complete your passenger registration.', style: TextStyle(color: Colors.white54)),
        ],
      )
    );
  }

  Widget _buildAmountChip(int cents) {
    return ActionChip(
      label: Text('+ LKR ${(cents / 100).toStringAsFixed(0)}'),
      backgroundColor: AppTheme.surfaceGlass,
      labelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderGlass),
      ),
      onPressed: () => _showTopUpDialog(cents),
    );
  }

  Widget _buildRealTransactionHistory(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .orderBy('boardedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.white54)));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final currencyFormat = NumberFormat('#,##0.00', 'en_US');
            final fareCents = data['fareCents'] as int? ?? 0;
            final dateStr = DateFormat("MMM d, h:mm a").format((data['boardedAt'] as Timestamp).toDate());
            final title = 'Trip: ' + (data['boardingStopName'] ?? 'Unknown');
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    '-LKR ${currencyFormat.format(fareCents / 100)}', 
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
