import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/passenger_provider.dart';
import '../../core/services/azure_functions_service.dart';

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
            const Text('Enter amount to top up via PayHere:', style: TextStyle(color: Colors.white70)),
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
              if (val != null && val >= 100) {
                Navigator.pop(context);
                _startPayHereCheckout((val * 100).toInt());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Minimum top-up is LKR 100')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.purpleLight,
              minimumSize: const Size(120, 40),
            ),
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPayHereCheckout(int amountCents) async {
    setState(() => _isLoading = true);

    try {
      final azureService = AzureFunctionsService();
      final session = await azureService.createPaymentSession(amountCents: amountCents);

      if (session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create payment session. Please try again.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
      }

      final paymentObject = {
        "sandbox": session['isSandbox'] ?? true,
        "merchant_id": session['merchantId'],
        "notify_url": session['notifyUrl'],
        "order_id": session['orderId'],
        "items": "PayRoute Wallet Top-Up",
        "amount": session['amountLKR'],
        "currency": session['currency'] ?? 'LKR',
        "first_name": session['firstName'] ?? 'Customer',
        "last_name": session['lastName'] ?? '',
        "email": "passenger@payroute.lk",
        "phone": session['phone'] ?? '',
        "address": "Sri Lanka",
        "city": "Colombo",
        "country": "Sri Lanka",
        "hash": session['hash'],
      };

      if (!mounted) return;
      setState(() => _isLoading = false);

      PayHere.startPayment(
        paymentObject,
        (paymentId) {
          // Payment success — wallet will be credited via the payhereNotify webhook
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Wallet will be updated shortly.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed: $error'), backgroundColor: Colors.red),
            );
          }
        },
        () {
          // Dismissed by user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment cancelled.')),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final passengerAsync = ref.watch(passengerStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      // Glowing balance card
                      GestureDetector(
                        onTap: () => _showTopUpDialog(null),
                        child: Stack(
                          children: [
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.purpleLight.withValues(alpha: 0.4),
                                    blurRadius: 44,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.purplePrimary.withValues(alpha: 0.65),
                                        AppTheme.purpleDim.withValues(alpha: 0.5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: const Color(0x55FFFFFF), width: 0.8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.account_balance_wallet_rounded,
                                              color: Colors.white70, size: 16),
                                          const SizedBox(width: 6),
                                          const Text('AVAILABLE BALANCE',
                                              style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 11,
                                                  letterSpacing: 1.2,
                                                  fontWeight: FontWeight.w600)),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white24),
                                            ),
                                            child: const Text('Tap to Top Up',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'LKR $balanceStr',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Updated: ${DateFormat("hh:mm a").format(DateTime.now())}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Quick Top Up',
                          style: TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildAmountChip(10000),
                          _buildAmountChip(50000),
                          _buildAmountChip(100000),
                          _buildAmountChip(200000),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      ElevatedButton.icon(
                        onPressed: () => _showTopUpDialog(null),
                        style: AppTheme.primaryButton(),
                        icon: const Icon(Icons.payment),
                        label: const Text('Top Up via PayHere', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 12),
                      const Center(child: Text('Secure payment via PayHere', style: TextStyle(color: Colors.white70, fontSize: 11))),

                      const SizedBox(height: 32),
                      const Text('Recent Trip Deductions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      _buildRealTransactionHistory(passenger.passengerId),
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

  Widget _buildRealTransactionHistory(String passengerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('passengerTrips')
          .where('passengerId', isEqualTo: passengerId)
          .where('status', isEqualTo: 'COMPLETED')
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
            final fareCents = (data['fareCents'] as int?) ?? 0;
            final boardedAtTs = data['boardedAt'] as Timestamp?;
            final dateStr = boardedAtTs != null
                ? DateFormat("MMM d, h:mm a").format(boardedAtTs.toDate())
                : '—';
            final title = 'Bus: ${data['busId'] ?? 'Unknown'}';
            
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
