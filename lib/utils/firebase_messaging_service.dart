import 'package:conavi_message/utils/function_utils.dart';
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

    FunctionUtils.log('User granted permission: ${settings.authorizationStatus}');

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
  }

  Future<String?> getFcmToken() async {
    final fcmToken = await messaging.getToken();
    FunctionUtils.log(fcmToken);
    return fcmToken;
  }

  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    FunctionUtils.log('Handling a background message: ${message.messageId}');
  }

  //メッセージのリッスン
  static void foregroundHandler(RemoteMessage message) {
    FunctionUtils.log('Got a message whilst in the foreground!');

    if (message.notification != null) {
      FunctionUtils.log('onForegroundMessage Title: ${message.notification?.title}');
      FunctionUtils.log('onForegroundMessage Body: ${message.notification?.body}');
    }
  }
}
