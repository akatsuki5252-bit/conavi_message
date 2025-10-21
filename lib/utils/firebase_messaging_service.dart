import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// webとiOS向け設定
  void setting() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
  }

  Future<String?> getFcmToken() async {
    final fcmToken = await messaging.getToken();
    print(fcmToken);
    return fcmToken;
  }

  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
  }

  //メッセージのリッスン
  static void foregroundHandler(RemoteMessage message) {
    print('Got a message whilst in the foreground!');

    if (message.notification != null) {
      print('onForegroundMessage Title: ${message.notification?.title}');
      print('onForegroundMessage Body: ${message.notification?.body}');
    }
  }
}
