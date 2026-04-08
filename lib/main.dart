import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/auth/phone_entry_screen.dart';
import 'core/auth/role_router.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Push Notifications
  await FCMService().init();
  
  // await SentryFlutter.init(
  //   (options) {
  //     options.dsn = 'YOUR_SENTRY_DSN_HERE';
  //     options.tracesSampleRate = 1.0;
  //   },
  //   appRunner: () => runApp(
  //     const ProviderScope(child: PayRouteApp()),
  //   ),
  // );
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
      builder: (context, ref, child) {
        final authState = ref.watch(currentUserStreamProvider);
        final isOnboarding = ref.watch(onboardingStateProvider);

        return MaterialApp(
          title: 'PayRoute',
          theme: AppTheme.themeData,
          home: authState.when(
            data: (user) {
              if (user == null || isOnboarding) {
                return const PhoneEntryScreen();
              }
              return RoleRouter(initialUri: _initialUri);
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


