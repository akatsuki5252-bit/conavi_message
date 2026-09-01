import 'dart:io';

import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
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
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        FunctionUtils.log(
            '🔕 通知が許可されていないため、FCMトークンを取得しません'
        );
        return '';
      }

      String? apnsToken;
      int retry = 0;
      while (apnsToken == null && retry < 5) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          FunctionUtils.log('✅ APNsトークン取得成功: $apnsToken');
          break;
        }
        retry++;
        FunctionUtils.log('⚠️ まだAPNsトークンがnull、再試行 ($retry/5)');
        await Future.delayed(const Duration(seconds: 1)); // ←ここで1秒待つ
      }
      if (apnsToken == null) {
        FunctionUtils.log('⚠️ APNsトークンが未取得');
      }
    }

    // 🔹 FCMトークンの取得をtry-catchで安全化
    String? fcmToken;
    try {
      fcmToken = await messaging.getToken();
    } catch (e) {
      if (e.toString().contains('apns-token-not-set')) {
        FunctionUtils.log('⚠️ APNsトークン未取得のためFCMトークン生成失敗');
        fcmToken = null;
      } else {
        FunctionUtils.log('❌ FCMトークン取得中に予期せぬエラー: $e');
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
        FunctionUtils.log('✅ updateToken: $fcmToken');
      } catch (e) {
        FunctionUtils.log('⚠️ サーバー更新中にエラー: $e');
      }
    } else {
      FunctionUtils.log('⚠️ FCMトークンがnullまたは空のため登録スキップ');
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
        FunctionUtils.log('refreshToken:$newFcmToken');
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
    FunctionUtils.log('deleteToken');
  }

  static void receiveNotification(RemoteMessage message, String type) {
    RemoteNotification? notification = message.notification;
    //AndroidNotification? android = message.notification?.android;
    if (!kIsWeb) {
      // FunctionUtils.log('setNotification:$type');
      // FunctionUtils.log('Message ID:${message.messageId}');
      // FunctionUtils.log('Sender ID:${message.senderId}');
      // FunctionUtils.log('Category:${message.category}');
      // FunctionUtils.log('Collapse Key:${message.collapseKey}');
      // FunctionUtils.log('Content Available:${message.contentAvailable.toString()}');
      // FunctionUtils.log('Data:${message.data.toString()}');
      // FunctionUtils.log('From:${message.from}');
      // FunctionUtils.log('Message ID:${message.messageId}');
      // FunctionUtils.log('Sent Time:${message.sentTime?.toString()}');
      // FunctionUtils.log('Thread ID:${message.threadId}');
      // FunctionUtils.log('Time to Live (TTL):${message.ttl?.toString()}');

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
