import 'dart:io';

import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseCloudMessaging {
  // Firebase Messaging のトークン更新リスナーが重複登録されないように制御するフラグ
  // Flutter アプリでは、画面の再構築や再起動時に updateToken() が複数回呼ばれる可能性がある。
  // そのたびに onTokenRefresh.listen(...) を登録すると、同じリスナーが何重にも実行されてしまうため、
  // 一度だけ登録したら true にして再登録を防ぐ。
  static bool _isTokenListenerAttached = false;
  /// Firebase Messagingの基本セットアップ
  static Future<void> setup() async {
    // iOSフォアグラウンド通知設定（アラート・バッジ・サウンドを有効）
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// iOS 通知権限をリクエスト
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

  /// FCMトークンを取得してサーバーに登録
  static Future<String> updateToken({
    required String domain,
    required String? mid}) async {
    final messaging = FirebaseMessaging.instance;

    // 🔹 iOSの場合はAPNsトークンが得られるまで少し待つ
    if (Platform.isIOS) {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('🔕 通知が拒否されているため、FCMトークンを取得しません');
        return '';
      }
      String? apnsToken;
      int retry = 0;
      while (apnsToken == null && retry < 5) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          debugPrint('✅ APNsトークン取得成功: $apnsToken');
          break;
        }
        retry++;
        debugPrint('⚠️ まだAPNsトークンがnull、再試行 ($retry/10)');
        await Future.delayed(const Duration(seconds: 1)); // ←ここで1秒待つ
      }
      if (apnsToken == null) {
        debugPrint('⚠️ APNsトークンが未取得');
      }
    }

    // 🔹 FCMトークンの取得をtry-catchで安全化
    String? fcmToken;
    try {
      fcmToken = await messaging.getToken();
    } catch (e) {
      if (e.toString().contains('apns-token-not-set')) {
        debugPrint('⚠️ APNsトークン未取得のためFCMトークン生成失敗');
        fcmToken = null;
      } else {
        debugPrint('❌ FCMトークン取得中に予期せぬエラー: $e');
        return '';
      }
    }

    // 🔹 成功時のみサーバーに登録
    if (fcmToken != null && fcmToken.isNotEmpty) {
      try {
        await ApiMembers.updateFcmToken(
          mid: mid,
          token: fcmToken,
          domain: domain,
        );
        Authentication.myAccount?.member.fcmToken = fcmToken;
        debugPrint('✅ updateToken: $fcmToken');
      } catch (e) {
        debugPrint('⚠️ サーバー更新中にエラー: $e');
      }
    } else {
      debugPrint('⚠️ FCMトークンがnullまたは空のため登録スキップ');
    }

    // 二重登録防止付き onTokenRefresh
    if (!_isTokenListenerAttached) {
      _isTokenListenerAttached = true;
      //リフレッシュ時にアカウントのトークンを更新
      FirebaseMessaging.instance.onTokenRefresh.listen((
          String newFcmToken) async {
        await ApiMembers.updateFcmToken(
          mid: mid,
          token: newFcmToken,
          domain: domain,
        );
        Authentication.myAccount?.member.fcmToken = newFcmToken;
        print('refreshToken:$newFcmToken');
      });
    }

    return fcmToken ?? '';
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
