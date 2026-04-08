import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
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
