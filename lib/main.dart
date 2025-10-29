import 'dart:async';
import 'dart:io';

import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/firebase_cloud_messaging.dart';
import 'package:conavi_message/utils/firebase_options.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/local_notifications.dart';
import 'package:conavi_message/utils/received_notification.dart';
import 'package:conavi_message/utils/shared_prefs.dart';
import 'package:conavi_message/view/test/test.dart';
import 'package:conavi_message/view/screen.dart';
import 'package:conavi_message/view/startup/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ローカル通知を管理するためのプラグインインスタンスを用意（アプリ全体で1つ）
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 通知をタップした時のイベントをStreamで伝える（複数リスナー対応のbroadcast）
final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

// 通知に含まれるpayload（画面遷移に使用）をStreamで通知する
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

Auth? myAccount; //認証アカウント
String? selectedNotificationPayload; // 通知タップ時に渡される引数（payload文字列）
String initialRoute = MyApp.routeName; // 最初に表示するルートを指定（"/" = MyApp）

// アプリが破棄された状態で通知をタップして起動された場合に呼ばれる関数（バックグラウンドエントリポイント）
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  FunctionUtils.log('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    FunctionUtils.log(
        'notification action tapped with input: ${notificationResponse.input}');
  }
  selectedNotificationPayload = notificationResponse.payload; // payloadを保持して後から利用
  //initialRoute = NotificationTapBackground.routeName;
}

// Firebase Messagingのバックグラウンド処理（アプリが閉じてる時の通知受信）用ハンドラ
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase初期化（BGでも必要）
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //ローカル通知設定
  LocalNotifications.setupNotifications(flutterLocalNotificationsPlugin);
  //FCM設定
  FirebaseCloudMessaging.setup();
  //通知（ios）
  /*RemoteNotification? notification = message.notification;
  AppleNotification? ios = message.notification?.apple;
  if (notification != null && ios != null && !kIsWeb) {
    FirebaseCloudMessaging.setNotification(message, 'BackgroundHandler');
  }*/
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  FunctionUtils.log('Handling a background message ${message.messageId}');
}

void main() async {
  // FlutterエンジンとUIの連携を初期化（プラグイン使用前には必須））
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-Edge（画面端まで描画）を有効化
  // これによりステータスバー/ナビゲーションバーの後ろまでUIが描画される。
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Firebaseの初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // バックグラウンド通知を受けた時の処理を登録
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ステータスバーのカラー適用
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xfff8b500),
  ));

  runApp(
    ProviderScope( // Riverpodを全体に提供
      // //複数解像度対応
      // child: ScreenUtilInit(
      //   //ターゲットデバイスの設定
      //   designSize: const Size(1080,2160),
      //   //幅と高さの最小値に応じてテキストサイズを可変させるか
      //   minTextAdapt: false,
      //   //split screenに対応するかどうか？
      //   splitScreenMode: false,
      //   builder: (BuildContext context,child) =>
        child: MaterialApp(
          //showPerformanceOverlay: true,
          debugShowCheckedModeBanner: false, // 右上のdebugラベルを消す
          title: '', // アプリのタイトル
          theme: ThemeData( // 全体のテーマ設定
            useMaterial3: false, // Material3を使用しない（既存デザイン維持）
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent, // Material3の影響を消すための指定
              iconTheme: IconThemeData(color: Colors.black), // 戻るボタンなどのアイコン色
              titleTextStyle: TextStyle(color: Colors.black), // タイトルの文字色
              // systemOverlayStyle: SystemUiOverlayStyle(
              //   statusBarColor: Color(0xfff8b500),
              // ),
              centerTitle: true, // タイトルを中央寄せ
              elevation: 0,
              shape: Border( // AppBar下にボーダー線
                bottom: BorderSide(
                  color: Color(0xffC0C0C0),
                  width: 1,
                ),
              ),
            ),
            primarySwatch: Colors.amber, // プライマリカラー（ボタンなど）
            //colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.yellow[100])
          ),
          //home: const MyApp(),
          initialRoute: initialRoute,
          routes: {
            MyApp.routeName: (_) => const MyApp(),
            NotificationTapBackground.routeName: (_) => // 通知タップ時の遷移ルート
                NotificationTapBackground(selectedNotificationPayload),
            GetNotificationAppLaunchDetails.routeName: (_) => // 通知詳細確認画面用ルート
                GetNotificationAppLaunchDetails(selectedNotificationPayload)
          },
          builder: EasyLoading.init(), // EasyLoading（ローディングインジケーター）を初期化
          localizationsDelegates: const [ // 多言語対応用（Flutter標準）
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja', 'JP')], // 日本語を有効化
        ),
      ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  static const String routeName = '/';
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  void initState() {
    super.initState();
    // UIに関係する処理（Navigatorや権限ダイアログ） → UI描画後
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      try {
        // 通知タップで起動されたかチェック
        final NotificationAppLaunchDetails? notificationAppLaunchDetails = !kIsWeb && Platform.isLinux
            ? null
            : await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

        //ローカル通知設定
        LocalNotifications.setupNotifications(flutterLocalNotificationsPlugin);
        //FCM設定
        FirebaseCloudMessaging.setup();

        // 通知経由起動判定
        if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
          selectedNotificationPayload = notificationAppLaunchDetails!.notificationResponse?.payload;
        }

        // 初期処理（認証/通知セットアップ/画面遷移）
        if (mounted) {
          await _initializeAppLogic(context);
        }
      } catch (e) {
        FunctionUtils.log('initState error: $e');
      }
    });
  }

  // 初期化処理（非同期）
  Future<void> _initializeAppLogic(BuildContext context) async {
    //認証
    myAccount = await Authentication.autoLogin();
    if(myAccount is Auth){
      //通知を全てキャンセル
      await LocalNotifications.cancelAllNotifications();
      //認証トースト
      FunctionUtils.showToast(
          message: '認証完了',
          toastLength: Toast.LENGTH_SHORT,
          toastGravity: ToastGravity.BOTTOM ,
          time: 1,
          backgroundColor: const Color(0xff3166f7),
          textColor: Colors.white,
          textSize: 16.0,
          cancelFlg: true
      );
      //ログイン情報をセット
      ref.read(userProvider.notifier).state  = myAccount!.member;
      ref.read(domainProvider.notifier).state  = myAccount!.domain;
      ref.read(userSettingProvider.notifier).state = myAccount!.userSetting;
      ref.read(selectedBottomMenuIndexProvider.notifier).state = myAccount!.userSetting.currentBottomNavigationIndex;
      ref.read(isLocalNotificationProvider.notifier).state = SharedPrefs.fetch(name: 'localNotificationFlag') == '1' ? true : false;
      //ref.refresh(membersFutureProvider);
      //ref.refresh(talkRoomsFutureProvider);
      Authentication.myAccount = myAccount;
      if (!mounted) return;
      // ログイン済 → Screen() へ画面遷移
      Navigator.pushReplacement(this.context,
        MaterialPageRoute(
          builder: (context) => const Screen(),
        ),
      );
    }else{
      if (!mounted) return;
      //ログインなし
      Navigator.pushReplacement(
        this.context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.amber)
      ),
    );
  }
}
