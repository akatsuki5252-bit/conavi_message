import 'dart:async';
import 'dart:convert';

import 'package:badges/badges.dart' as badges;
import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/main.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/utils/firebase_cloud_messaging.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/local_notifications.dart';
import 'package:conavi_message/utils/received_notification.dart';
import 'package:conavi_message/view/invite_code/invite_code_page.dart';
import 'package:conavi_message/view/message/group_message_room_page.dart';
import 'package:conavi_message/view/mypage/my_page.dart';
import 'package:conavi_message/view/message/message_room_page.dart';
import 'package:conavi_message/view/message/message_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
class Screen extends ConsumerStatefulWidget {
  const Screen({super.key});

  @override
  ConsumerState<Screen> createState() => ScreenState();
}

class ScreenState extends ConsumerState<Screen> with WidgetsBindingObserver {
  // 通知用Streamのリスナー管理（dispose時にcancelするため保持）
  StreamSubscription? _didReceiveSub;
  StreamSubscription? _selectSub;
  Timer? _refreshDebounce; // 連続でrefreshが呼ばれた時に無駄な再取得を防ぐためのデバウンス用タイマー

  ///フッターメニューページ
  final List<Widget> _footerPageList = const [
    //ChatPage(),
    MessageScreen(),
    MyPage(),
    InviteCodePage(),
  ];
  ///アクション通知
  void _configureDidReceiveLocalNotificationSubject() {
    FunctionUtils.log('_configureDidReceiveLocalNotificationSubject');
    _didReceiveSub = didReceiveLocalNotificationStream.stream.listen((ReceivedNotification receivedNotification) async {
      FunctionUtils.log('_configureDidReceiveLocalNotificationSubject');
    });
  }
  ///通常通知
  void _configureSelectNotificationSubject() {
    FunctionUtils.log('_configureSelectNotificationSubject');
    _selectSub = selectNotificationStream.stream.listen((String? payload) async {
      FunctionUtils.log('selectNotificationStream.stream.listen');
      //通知をクリックしてメッセージルームのトーク画面に遷移
      await _pushNotification(payload);
    });
  }
  ///通知クリック時の挙動
  Future<void> _pushNotification(String? payload) async{
    FunctionUtils.log('payload:${payload}');
    //通知をクリックしてメッセージルームのトーク画面に遷移
    if (payload != null) {
      Auth myAccount = ref.read(authProvider); //アカウント情報
      final mapPayload = jsonDecode(payload);
      //ルームid
      String roomId = mapPayload.containsKey('room_id') == true ? mapPayload['room_id'] : '';
      //メッセージタイプ
      String messageType = mapPayload.containsKey('type') == true ? mapPayload['type'] : '';
      if(roomId.isNotEmpty && messageType.isNotEmpty){
        //Bottomメニュー画面設定
        ref.read(selectedBottomMenuIndexProvider.notifier).state = BottomNavigationMenu.message.index;
        //メッセージ画面タブ設定
        if(messageType == 'message') {
          ref.read(selectedMessageTabIndexProvider.notifier).state = MessageTab.message.index;
        }else if(messageType == 'groupMessage'){
          ref.read(selectedMessageTabIndexProvider.notifier).state = MessageTab.groupMessage.index;
        }
        //通知を全てキャンセル
        await LocalNotifications.cancelAllNotifications();
        if (!mounted) return;
        //初期画面に戻る
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        //ルーム画面を表示
        if(messageType == 'message') {
          //ルーム情報を取得
          final talkRoom = await ApiMessages.fetchRoom(
            domain: myAccount.domain.url,
            roomId: roomId,
            mid: myAccount.member.id,
          );
          FunctionUtils.log(talkRoom);
          //型チェック
          if (talkRoom is TalkRoom) {
            if (!mounted) return;
            //画面遷移 & 戻り値
            var result = await Navigator.push(context,
              MaterialPageRoute(
                builder: (context) => MessageRoomPage(talkRoom),
              ),
            );
            FunctionUtils.log("result: $result");
            //戻り値がbool & true
            if (result is bool && result) {
              //画面を更新する
              ref.refresh(talkRoomsFutureProvider);
            }
          }
        }else if(messageType == 'groupMessage') {
          //ルーム情報を取得
          final talkRoom = await ApiGroupMessages.fetchGroupRoom(
            myAccount: myAccount,
            roomId: roomId,
          );
          FunctionUtils.log(talkRoom);
          if(talkRoom is TalkGroupRoom){
            if (!mounted) return;
            //画面遷移 & 戻り値
            var result = await Navigator.push(context,
              MaterialPageRoute(
                  builder: (context) => GroupMessageRoomPage(talkRoom)
              ),
            );
            FunctionUtils.log("result: $result");
            //戻り値がbool & true
            if (result is bool && result) {
              //画面を更新する
              ref.refresh(talkGroupRoomsFutureProvider);
            }
          }
        }
      }
    }
  }

  void _launchURL(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        final launched = await launchUrlString(url, mode: LaunchMode.externalApplication); // ストア/外部ブラウザ想定なら明示
        if (!launched) {
          await launchUrlString(url);
        }
      } else {
        FunctionUtils.log('Cannot launch: $url');
      }
    } catch (e) {
      FunctionUtils.log('launch error: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   final settings = await FirebaseMessaging.instance.getNotificationSettings();
    //   // まだ聞いてなかったら（= 初回）
    //   if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    //     await LocalNotifications.requestPermissions();
    //     await FirebaseCloudMessaging.requestPermissions();
    //   }
    // });


    final myAccount = ref.read(authProvider);
    WidgetsBinding.instance.addObserver(this);
    FunctionUtils.log('isAppUpdate:${myAccount.userSetting.isAppUpdate}');
    //バージョンチェック（build完了後）
    WidgetsBinding.instance.addPostFrameCallback((_){
      //強制アップデートならアップデートダイアログを表示
      if(myAccount.userSetting.isAppUpdate) {
        const playStoreUrl = 'https://play.google.com/store/apps/details?id=net.conavi.aps.conavimessage&hl=ja';
        const appStoreUrl = 'https://apps.apple.com/jp/app/%E3%82%B3%E3%83%8A%E3%83%93-%E3%83%A1%E3%83%83%E3%82%BB%E3%83%B3%E3%82%B8%E3%83%A3%E3%83%BC/id6446796159';
        showDialog(
          context: context,
          //barrierDismissibleをfalseにすると、戻るボタン以外をクリックしても反応しません
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              title: const Text('アップデートのお願い'),
              content: const Text('最新バージョンのアプリを公開しました。恐れ入りますが、アップデートをお願いします。', style: TextStyle(fontSize: 15)),
              actions: [
                PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (bool didPop, Object? result) async {
                    if (didPop) return;
                  },
                  child: ElevatedButton(
                    onPressed: () {
                      TargetPlatform platform = Theme.of(context).platform;
                      if (platform.name == 'android') {
                        _launchURL(playStoreUrl);
                      } else {
                        _launchURL(appStoreUrl);
                      }
                    },
                    child: const Text('アップデートする'),
                  ),
                ),
              ],
            );
          },
        );
      }
    });
    //FCM：ターミネイト時の通知トレイタップ
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        await _pushNotification(jsonEncode(message.data));
        // selectMenuIndex(jsonEncode(message.data));
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     backgroundColor: Colors.grey,
        //     content: Text('FirebaseMessaging.instance.getInitialMessage${message.data}'),
        //   ),
        // );
      }
    });

    //FCM：フォアグラウンド
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //下部メッセージメニューを選択中 + メッセージ画面を表示 + 受信した通知がメッセージ画面の相手の場合、ローカル通知を通知しない
      FunctionUtils.log('FirebaseMessaging.onMessage.listen');
      if (message.notification != null) {
        FunctionUtils.log('currentMessageRoom:${myAccount.userSetting.currentMessageRoom}');
        FunctionUtils.log('currentGroupMessageRoom:${myAccount.userSetting.currentGroupMessageRoom}');
        ///メッセージ画面表示中に相手からメッセージが来た場合
        if (myAccount.userSetting.currentBottomNavigationIndex == BottomNavigationMenu.message.index &&
            myAccount.userSetting.currentMessageRoom != null &&
            message.data.containsKey('room_id') &&
            message.data['room_id'] == myAccount.userSetting.currentMessageRoom!.roomId) {
          //通知ペイロードのルームidと現在表示しているルームidを比較
          ref.refresh(talkMessagesFutureProvider(myAccount.userSetting.currentMessageRoom!));
          FunctionUtils.log('メッセージ通知自動更新');
        }
        ///グループメッセージ画面表示中に相手からメッセージが来た場合
        else if (myAccount.userSetting.currentBottomNavigationIndex == BottomNavigationMenu.message.index &&
            myAccount.userSetting.currentGroupMessageRoom != null &&
            message.data.containsKey('room_id') &&
            message.data['room_id'] == myAccount.userSetting.currentGroupMessageRoom!.roomId) {
          //通知ペイロードのルームidと現在表示しているルームidを比較
          ref.refresh(talkGroupMessagesFutureProvider(myAccount.userSetting.currentGroupMessageRoom!));
          FunctionUtils.log('グループメッセージ通知自動更新');
        } else {
          //メッセージの通知がONの場合ローカル通知作成
          //if(myAccount.userSetting.localNotificationFlag) {
          RemoteNotification? notification = message.notification;
          AndroidNotification? android = message.notification?.android;
          if (notification != null && android != null) {
            FunctionUtils.log('ローカルメッセージ通知');
            FirebaseCloudMessaging.receiveNotification(message, 'onMessage');
          }
          //}
          //最新情報を更新
          if(myAccount.userSetting.currentBottomNavigationIndex == BottomNavigationMenu.message.index) {

            // 直近のrefresh予約があればキャンセルして再セット（＝通知が連続で来た場合、1回にまとめる）
            _refreshDebounce?.cancel(); // Timerが存在していればキャンセルして「連続実行を抑える」

            // 400msの遅延を設定（通知が続いてきてもこの間はリロードは発生しない）
            _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
              FunctionUtils.log('タブ一覧情報更新');
              // invalidate() は「今すぐ取得」ではなく「次に参照された時に再取得」を指示する
              ref.invalidate(membersFutureProvider); // → メンバー一覧の次回使用時に自動リロードする
              ref.invalidate(talkRoomsFutureProvider); // → 1対1トークルーム一覧も「次回参照で再取得」に切り替える
              ref.invalidate(talkGroupRoomsFutureProvider); // → グループルーム一覧も同じく「遅延再取得」する設定
            });
          }
        }
        //count++;
      }
    });

    //FCM：バックグラウンド時の通知トレイタップ
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async{
      //FirebaseCloudMessaging.setNotification(message, 'onMessageOpenedApp');
      await _pushNotification(jsonEncode(message.data));
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     backgroundColor: Colors.grey,
      //     content: Text('FirebaseMessaging.onMessageOpenedApp.listen'),
      //   ),
      // );
    });

    //アクション通知
    _configureDidReceiveLocalNotificationSubject();
    //通常通知
    _configureSelectNotificationSubject();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    //didReceiveLocalNotificationStream.close();
    //selectNotificationStream.close();
    _didReceiveSub?.cancel();
    _selectSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    FunctionUtils.log("stete = $state");
    switch (state) {
      case AppLifecycleState.inactive:
        FunctionUtils.log('非アクティブになったときの処理');
        break;
      case AppLifecycleState.paused:
        FunctionUtils.log('停止されたときの処理');
        break;
      case AppLifecycleState.resumed:
        FunctionUtils.log('再開されたときの処理');
        final myAccount = ref.read(authProvider);
        //メッセージメニュー画面選択
        if(myAccount.userSetting.currentBottomNavigationIndex == BottomNavigationMenu.message.index) {
          //メッセージのメッセージ画面を表示中はメッセージを更新
          if(myAccount.userSetting.currentMessageRoom != null){
            ref.refresh(talkMessagesFutureProvider(myAccount.userSetting.currentMessageRoom!));
          }else if(myAccount.userSetting.currentGroupMessageRoom != null){
            //グループメッセージのメッセージ画面を表示中はグループメッセージを更新
            ref.refresh(talkGroupMessagesFutureProvider(myAccount.userSetting.currentGroupMessageRoom!));
          }else{
            //一覧を全て更新
            ref.refresh(membersFutureProvider);
            ref.refresh(talkRoomsFutureProvider);
            ref.refresh(talkGroupRoomsFutureProvider);
          }
        }
        break;
      case AppLifecycleState.detached:
        FunctionUtils.log('破棄されたときの処理');
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
    }
  }

  @override
  Widget build(BuildContext context) {
    Auth myAccount = ref.watch(authProvider);
    int countBottomNavigationMessageBadge = ref.watch(bottomNavigationMessageBadgeProvider);
    return Scaffold(
      body: SafeArea(child: _footerPageList[myAccount.userSetting.currentBottomNavigationIndex]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              width: 1, //太さ
              color: Color(0xffC0C0C0), //シルバー
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,//Color(0xffefebe0),
          items: [
            BottomNavigationBarItem(
              label: 'メッセージ',
              icon: badges.Badge(
                showBadge: 0 < countBottomNavigationMessageBadge ? true : false,
                badgeContent: Text(
                  '$countBottomNavigationMessageBadge',
                  style: const TextStyle(color: Colors.white),
                ),
                badgeStyle: const badges.BadgeStyle(badgeColor: Color(0xfff8b500)),
                child: const Icon(Icons.mail_outlined),
              ),
              activeIcon: badges.Badge(
                showBadge: 0 < countBottomNavigationMessageBadge ? true : false,
                badgeContent: Text(
                  '$countBottomNavigationMessageBadge',
                  style: const TextStyle(color: Colors.white),
                ),
                badgeStyle: const badges.BadgeStyle(badgeColor: Color(0xfff8b500)),
                child: const Icon(Icons.mail),
              ),
            ),
            const BottomNavigationBarItem(
              label: 'マイページ',
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
            ),
            // const BottomNavigationBarItem(
            //   label: '招待コード',
            //   icon: Icon(Icons.account_box_outlined),
            //   activeIcon: Icon(Icons.account_box),
            // ),
          ],
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          selectedItemColor: const Color(0xff3166f7),
          selectedIconTheme: const IconThemeData(color: Color(0xff3166f7),size: 28),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedItemColor: const Color(0xffC0C0C0),
          unselectedIconTheme: const IconThemeData(color: Color(0xffC0C0C0),size: 28),
          type: BottomNavigationBarType.fixed,
          currentIndex: myAccount.userSetting.currentBottomNavigationIndex,
          onTap: (index) {
            ref.read(selectedBottomMenuIndexProvider.notifier).state = index;
            if(BottomNavigationMenu.message.index == index){
              ref.refresh(membersFutureProvider);
              ref.refresh(talkRoomsFutureProvider);
              ref.refresh(talkGroupRoomsFutureProvider);
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          bool isSupported =
              await FlutterAppBadgeControl.isAppBadgeSupported();
          // ignore: avoid_print
          FunctionUtils.log('isSupported: $isSupported');
          await FlutterAppBadgeControl.updateBadgeCount(1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
