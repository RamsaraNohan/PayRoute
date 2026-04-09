import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

/// Displays the passenger's recent in-app activity from the `activityLogs` collection.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const int _maxNotifications = 40;

  static const Map<String, _NotifMeta> _actionMeta = {
    'LOGIN': _NotifMeta('Signed In', Icons.login_rounded, Colors.blueAccent),
    'REGISTER_PASSENGER': _NotifMeta('Account Created', Icons.person_add_rounded, Colors.green),
    'TOP_UP': _NotifMeta('Wallet Topped Up', Icons.account_balance_wallet_rounded, Colors.green),
    'BOARD_BUS': _NotifMeta('Boarded Bus', Icons.directions_bus_rounded, Colors.purple),
    'SIGNAL_DROP': _NotifMeta('Trip Completed', Icons.check_circle_rounded, Colors.teal),
    'FILE_COMPLAINT': _NotifMeta('Complaint Filed', Icons.report_problem_rounded, Colors.orange),
    'UPDATE_PROFILE': _NotifMeta('Profile Updated', Icons.edit_rounded, Colors.blueAccent),
    'ACCEPT_STAFF_INVITE': _NotifMeta('Invite Accepted', Icons.handshake_rounded, Colors.amber),
    'ROLE_SWITCH': _NotifMeta('Role Switched', Icons.swap_horiz_rounded, Colors.cyan),
  };

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('activityLogs')
              .where('userId', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .limit(_maxNotifications)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.purpleLight));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 72, color: Colors.white24),
                    SizedBox(height: 16),
                    Text('No activity yet', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Your recent actions will appear here.', style: TextStyle(color: Colors.white30, fontSize: 13)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final action = data['action'] as String? ?? 'Unknown';
                final meta = _actionMeta[action] ?? const _NotifMeta('Activity', Icons.info_outline, Colors.white54);
                final ts = (data['timestamp'] as Timestamp?)?.toDate();
                final timeStr = ts != null ? _formatTime(ts) : '—';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: AppTheme.glassCard(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meta.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _NotifMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _NotifMeta(this.label, this.icon, this.color);
}
