import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

/// Global navigator key used for FCM deep-linking.
final GlobalKey<NavigatorState> payRouteNavigatorKey = GlobalKey<NavigatorState>();

/// Must be called once from main() before runApp().
Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await _localNotifications.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: (details) {
      // Tapping a local notification (foreground) — payload contains the FCM type
      _routeFromPayload(details.payload);
    },
  );
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> init() async {
    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Refresh token on rotation — subscription stored for cleanup
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // Show a local notification banner when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // App opened from a background notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _routeFromMessage(message);
      });
    }

    // App launched from a terminated-state notification tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay routing until the widget tree is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _routeFromMessage(initialMessage);
      });
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }

  /// Routes the user to the appropriate screen based on FCM [data] payload.
  static void _routeFromMessage(RemoteMessage message) {
    _routeFromPayload(message.data['type']);
  }

  static void _routeFromPayload(String? type) {
    final navigator = payRouteNavigatorKey.currentState;
    if (navigator == null || type == null) return;

    switch (type) {
      case 'TRIP_COMPLETED':
        // Navigate to trip history so the user can tap the latest receipt
        navigator.pushNamedAndRemoveUntil('/trip-history', (route) => route.isFirst);
        break;
      case 'BOARDING':
        // Navigate to active trip screen (home will show the HUD)
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        break;
      case 'TOP_UP':
        navigator.pushNamedAndRemoveUntil('/wallet', (route) => route.isFirst);
        break;
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'payroute_channel',
      'PayRoute',
      channelDescription: 'PayRoute trip and payment notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotifications.show(
      message.hashCode,
      notification.title ?? 'PayRoute',
      notification.body,
      details,
      payload: message.data['type'],
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()});
    } catch (_) {
      // Non-critical: silently ignore if user doc doesn't exist yet
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
