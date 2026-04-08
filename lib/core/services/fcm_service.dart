import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Refresh token on rotation
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Handle foreground notifications (e.g. show local notification banner)
      });
    }
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
