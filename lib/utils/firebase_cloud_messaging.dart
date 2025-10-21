import 'dart:io';

import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseCloudMessaging {
  static Future<void> setup() async {
    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
  }

  static Future<String> updateToken({
    required String domain,
    required String? mid}) async {
    //トークンを取得
    final fcmToken = await FirebaseMessaging.instance.getToken();
    //アカウントのトークンを更新
    await ApiMembers.updateFcmToken(
        mid: mid,
        token: fcmToken,
        domain:domain
    );
    print('updateToken:$fcmToken');
    //リフレッシュ時にアカウントのトークンを更新
    FirebaseMessaging.instance.onTokenRefresh.listen((String newFcmToken) async {
      await ApiMembers.updateFcmToken(
        mid: mid,
        token: newFcmToken,
        domain: domain,
      );
      Authentication.myAccount?.member.fcmToken = newFcmToken;
      print('refreshToken:$newFcmToken');
    });

    return fcmToken!;
  }

  static Future<void> deleteToken({
    required String? mid,
    required String domain}) async {
    ///FCMトークンを削除
    await ApiMembers.updateFcmToken(
      domain: domain,
      mid: mid,
      token: '',
    );
    await FirebaseMessaging.instance.deleteToken();
    print('deleteToken');
  }

  static void receiveNotification(RemoteMessage message, String type) {
    RemoteNotification? notification = message.notification;
    //AndroidNotification? android = message.notification?.android;
    if (!kIsWeb) {
      // print('setNotification:$type');
      // print('Message ID:${message.messageId}');
      // print('Sender ID:${message.senderId}');
      // print('Category:${message.category}');
      // print('Collapse Key:${message.collapseKey}');
      // print('Content Available:${message.contentAvailable.toString()}');
      // print('Data:${message.data.toString()}');
      // print('From:${message.from}');
      // print('Message ID:${message.messageId}');
      // print('Sent Time:${message.sentTime?.toString()}');
      // print('Thread ID:${message.threadId}');
      // print('Time to Live (TTL):${message.ttl?.toString()}');

      LocalNotifications.showNotify(message);

      /*
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            // TODO add a proper drawable resource to android, for now using
            //      one that already exists in example app.
            icon: 'launch_background',
          ),
        ),
      );*/
    }
  }
}
