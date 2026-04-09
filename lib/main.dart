import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/config/mapbox_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'core/services/fcm_service.dart' show FCMService, initLocalNotifications, payRouteNavigatorKey;
import 'core/auth/phone_entry_screen.dart';
import 'core/auth/role_router.dart';
import 'core/widgets/connectivity_wrapper.dart';
import 'passenger/history/trip_history_screen.dart';
import 'passenger/wallet/wallet_screen.dart';
import 'passenger/home/passenger_dashboard.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  MapboxOptions.setAccessToken(kMapboxPublicToken);
  
  // Initialize local notification display
  await initLocalNotifications();

  // Initialize Push Notifications (also wires onMessageOpenedApp / getInitialMessage)
  await FCMService().init();
  
  runApp(const ProviderScope(child: PayRouteApp()));
}

class PayRouteApp extends StatefulWidget {
  const PayRouteApp({super.key});

  @override
  State<PayRouteApp> createState() => _PayRouteAppState();
}

class _PayRouteAppState extends State<PayRouteApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _initialUri;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _initialUri = await _appLinks.getInitialLink();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (mounted) setState(() => _initialUri = uri);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(currentUserStreamProvider);
        final isOnboarding = ref.watch(onboardingStateProvider);

        return MaterialApp(
          title: 'PayRoute',
          theme: AppTheme.themeData,
          // Navigator key enables FCMService to push routes without a BuildContext
          navigatorKey: payRouteNavigatorKey,
          // Named routes used by FCM deep-link handler
          routes: {
            '/home': (_) => const PassengerDashboard(),
            '/trip-history': (_) => const TripHistoryScreen(),
            '/wallet': (_) => const WalletScreen(),
          },
          home: authState.when(
            data: (user) {
              if (user == null || isOnboarding) {
                return const PhoneEntryScreen();
              }
              return ConnectivityWrapper(child: RoleRouter(initialUri: _initialUri));
            },
            loading: () => Scaffold(
              body: Container(
                decoration: AppTheme.gradientBackground(),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
            error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
          ),
        );
      },
    );
  }
}

