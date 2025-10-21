import 'dart:convert';
import 'dart:io';

import 'package:conavi_message/main.dart';
import 'package:conavi_message/utils/received_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class LocalNotifications {
  /// A notification action which triggers a App navigation event
  static String navigationActionId = 'id_3';

  /// Defines a iOS/MacOS notification category for text input actions.
  static String darwinNotificationCategoryText = 'textCategory';

  /// Defines a iOS/MacOS notification category for plain actions.
  static String darwinNotificationCategoryPlain = 'plainCategory';

  static bool isFlutterLocalNotificationsInitialized = false;
  static late AndroidNotificationChannel chatChannel;
  static late AndroidNotificationChannel messageChannel;
  static late AndroidNotificationChannel groupMessageChannel;

  static Future<void> setupNotifications(FlutterLocalNotificationsPlugin fLocalNotificationsPlugin) async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }
    //チャンネル（Android）
    messageChannel = const AndroidNotificationChannel(
      'conavi_message_channel', // id
      'メッセージ', // title
      description: 'this message channel is used for important notifications.', // description
      importance: Importance.high,
    );
    groupMessageChannel = const AndroidNotificationChannel(
      'conavi_group_message_channel', // id
      'グループメッセージ', // title
      description: 'this group message channel is used for important notifications.', // description
      importance: Importance.high,
    );
    //チャンネル作成
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(messageChannel);
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(groupMessageChannel);
    //通知アイコン
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_conavi_logo');

    //iosの通知アクション設定
    final List<DarwinNotificationCategory> darwinNotificationCategories = <DarwinNotificationCategory>[
      DarwinNotificationCategory(darwinNotificationCategoryText,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.text(
            'text_1',
            'Action 1',
            buttonTitle: 'Send',
            placeholder: 'Placeholder',
          ),
        ],
      ),
      DarwinNotificationCategory(darwinNotificationCategoryPlain,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain('id_1', 'Action 1'),
          DarwinNotificationAction.plain(
            'id_2',
            'Action 2 (destructive)',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
          DarwinNotificationAction.plain(navigationActionId,
            'Action 3 (foreground)',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            'id_4',
            'Action 4 (auth required)',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.authenticationRequired,
            },
          ),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      )
    ];

    // iOS 初期化
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: darwinNotificationCategories,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    //タップ設定（iOS/Android 共通）
    await fLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          //通常通知
          case NotificationResponseType.selectedNotification:
            print('case:NotificationResponseType.selectedNotification');
            selectNotificationStream.add(notificationResponse.payload);
            break;
          //アクション通知
          case NotificationResponseType.selectedNotificationAction:
            print('case:NotificationResponseType.selectedNotificationAction');
            if (notificationResponse.actionId == navigationActionId) {
              selectNotificationStream.add(notificationResponse.payload);
            }
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    isFlutterLocalNotificationsInitialized = true;
  }

  static Future<void> showNotification(
      String type,
      int roomId,
      String? title,
      String body,
      String imagePath,
      Map<String, String> payload) async {

    //Android
    final String? largeIconPath = await downloadAndSaveFile(imagePath, 'largeIcon');
    final channelName = type == 'chat' ? 'チャット' : 'メッセージ';
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      type, channelName,
      largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
      channelDescription: '$channelName通知',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
      //ticker: 'ticker',
      //additionalFlags: Int32List.fromList(<int>[insistentFlag])
      //styleInformation: inboxStyleInformation,
      // ticker: 'ticker', //補助サービス？
    );
    //iOS
    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'iOSCategory',
    );
    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
      roomId,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(payload),
    );
  }

  static Future<Uint8List> getImageBytes(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    return response.bodyBytes;
  }

  static Future<ByteArrayAndroidBitmap?> getAndroidBitmap(String imageUrl) async {
    try {
      final bodyBytes = await getImageBytes(imageUrl);
      return ByteArrayAndroidBitmap.fromBase64String(base64.encode(bodyBytes));
    } on Exception catch (e) {
      print(e);
      return null;
    }
  }

  static Future<void> showNotify(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if(notification != null) {
      //アイコン画像
      String imagePath = message.data.containsKey('image_url') ? message.data['image_url'] : '';
      print('image:$imagePath');
      final bitmapData = imagePath.isNotEmpty ? await getAndroidBitmap(imagePath) : null;
      //メッセージタイプ
      String type = message.data.containsKey('type') && message.data['type'] != null ? message.data['type'] : 'message';
      late AndroidNotificationDetails androidNotificationDetails;
      if(type == 'message') {
        androidNotificationDetails = AndroidNotificationDetails(
          messageChannel.id,
          messageChannel.name,
          channelDescription: messageChannel.description,
          largeIcon: bitmapData,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );
      }else if(type == 'groupMessage'){
        androidNotificationDetails = AndroidNotificationDetails(
          groupMessageChannel.id,
          groupMessageChannel.name,
          channelDescription: messageChannel.description,
          largeIcon: bitmapData,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );
      }

      //iOS
      // final http.Response response = await http.get(Uri.parse(imagePath));
      // // Get temporary directory
      // final dir = await getTemporaryDirectory();
      // // Create an image name
      // var filename = '${dir.path}/image.png';
      // // Save to filesystem
      // final file = File(filename);
      // await file.writeAsBytes(response.bodyBytes);
      DarwinNotificationDetails iosNotificationDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'iOSCategory',
        //attachments: imagePath.isNotEmpty ? [DarwinNotificationAttachment(filename)] : null,
      );
      NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);

      //ルーム作成時間を通知識別IDとして使用
      int pushId = message.data.containsKey('unique_key') && message.data['unique_key'] != null ? int.parse(message.data['unique_key']) : notification.hashCode;
      print('pushId:$pushId');

      //ローカル通知
      await flutterLocalNotificationsPlugin.show(
        pushId,
        notification.title,
        '${notification.body}',
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  static Future<void> showTestNotification(String? imagePath) async {
    // const List<String> lines = <String>[
    //   'Alex Faarborg  Check this out',
    //   'Jeff Chang    Launch Party'
    // ];
    // const InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
    //     lines,
    //     contentTitle: '2 messages',
    //     summaryText: 'janedoe@example.com');

    //Android
    final String? largeIconPath =
        await downloadAndSaveFile(imagePath, 'largeIcon');
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      largeIcon:
          largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      //styleInformation: inboxStyleInformation,
      // ticker: 'ticker', //補助サービス？
    );
    //iOS
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'iOSCategory',
    );
    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(1, 'title', 'body', notificationDetails, payload: 'item x');
  }

  static Future<String?> downloadAndSaveFile(
      String? url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    if (url != null) {
      final http.Response response = await http.get(Uri.parse(url));
      print(response.statusCode);
      if (response.statusCode != 404) {
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        return null;
      }
    }
    return null;
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;
      if (!granted) {
        print('LocalNotifications:isAndroidPermissionGranted');
      }
    }
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      if (granted == null || !granted) {
        print('requestNotificationsPermission:not requestPermission');
      }else{
        print('requestNotificationsPermission:clear');
      }

      final bool? granted2 = await androidImplementation?.requestExactAlarmsPermission();
      if (granted2 == null || !granted2) {
        print('requestExactAlarmsPermission:not requestPermission');
      }else{
        print('requestExactAlarmsPermission:clear');
      }
    }
  }
}
