#passUI
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'passenger_home_tab.dart';
import '../history/trip_history_screen.dart';
import '../check_in/check_in_screen.dart';
import '../profile/profile_screen.dart';
import '../route_finder/route_finder_screen.dart';
import '../wallet/wallet_screen.dart';

class PassengerDashboard extends StatefulWidget {
  const PassengerDashboard({super.key});

  @override
  State<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == 2) {
      // Check-In: push as full-screen modal, don't switch tab
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen()));
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Pages excluding the modal check-in page
    final displayPages = [
      const PassengerHomeTab(),
      const TripHistoryScreen(),
      const RouteFinderScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];
    final displayIndex = _currentIndex > 1 ? _currentIndex - 1 : _currentIndex;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: displayIndex.clamp(0, displayPages.length - 1),
        children: displayPages,
      ),
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,              label: 'Home'),
    _NavItem(icon: Icons.history_outlined,        activeIcon: Icons.history,                   label: 'Rides'),
    _NavItem(icon: Icons.qr_code_scanner,         activeIcon: Icons.qr_code_scanner,           label: 'Check In'),
    _NavItem(icon: Icons.map_outlined,            activeIcon: Icons.map_rounded,               label: 'Routes'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Wallet'),
    _NavItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,            label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0x44FFFFFF), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i == 2) // Check-In FAB-style
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.purpleLight, AppTheme.purplePrimary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.purpleLight.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                          )
                        else ...[
                          Icon(
                            selected ? _items[i].activeIcon : _items[i].icon,
                            color: selected ? AppTheme.purpleLight : Colors.white54,
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].label,
                            style: TextStyle(
                              color: selected ? AppTheme.purpleLight : Colors.white38,
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
#newUI
