import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      if (token != null) {
        // Optionally save this to Firestore user profile in a real app
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Handle foreground notifications (e.g. show local notification banner)
      });
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
