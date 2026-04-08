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

class _PassengerDashboardState extends State<PassengerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PassengerHomeTab(),
    const TripHistoryScreen(),
    const CheckInScreen(),
    const RouteFinderScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.backgroundDark,
        selectedItemColor: AppTheme.purpleLight,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Rides'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Check In'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
