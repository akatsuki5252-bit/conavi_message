import 'dart:convert';
import 'dart:io';

import 'package:conavi_message/api/api_domains.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/setting/domain.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/firebase_cloud_messaging.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/local_notifications.dart';
import 'package:conavi_message/utils/shared_prefs.dart';
import 'package:conavi_message/setting/user_setting.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class Authentication {
  static Auth? myAccount;
  //認証
  static Future<Result?> signIn({
    required String conaviId, //コナビID
    required String email,    //メールアドレス
    required String password, //パスワード
    required String appToken //認証トークン
  }) async {
    //戻り値
    Result result = Result();
    //初期化
    await SharedPrefs.setInstance();
    // 1. ドメイン取得
    String? domainUrl = await domainSignIn(domainId: conaviId);
    if (domainUrl == null || domainUrl.isEmpty) {
      result.error = 'コナビIDが無効です';
      return result; // isSuccess = false のまま
    }
    // 2. メンバー認証
    var member = await emailSignIn(
      domain: domainUrl,
      email: email,
      password: password,
      appToken: appToken,
      conaviId: conaviId,
    );
    if (member is! Member) {
      result.error = 'メールアドレスまたはパスワードが正しくありません';
      return result;
    }
    // 3. 認証用アカウント生成
    Auth account = Auth(
      domain: Domain(id: conaviId, url: domainUrl),
      member: member,
      userSetting: UserSetting(),
    );
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    FunctionUtils.log('アプリバージョン：${packageInfo.version}');
    //初回ログインのみ更新
    if(appToken.isEmpty) {
      //FCMトークンを更新
      account.member.fcmToken = await FirebaseCloudMessaging.updateToken(domain: domainUrl, mid: member.id);
      //端末情報を更新
      final deviceInfo = DeviceInfoPlugin();
      String deviceInfoText = '';
      if(Platform.isAndroid){
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceInfoText = 'Android/${androidInfo.model}/${androidInfo.version.sdkInt}/${androidInfo.manufacturer}';
        FunctionUtils.log('Model: ${androidInfo.model}');
        FunctionUtils.log('Android Version: ${androidInfo.version.sdkInt}');
        FunctionUtils.log('Manufacturer: ${androidInfo.manufacturer}');
      }else if(Platform.isIOS){
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceInfoText = 'IOS/${iosInfo.systemName}/${iosInfo.systemVersion}/${iosInfo.model}/${iosInfo.utsname.machine}';
        FunctionUtils.log('Device: ${iosInfo.utsname.machine}');
      }else {
        deviceInfoText = 'Unknown/${Platform.operatingSystem}'; // ← 空送信対策
      }
      await ApiMembers.updateDeviceInfo(
        domain: domainUrl,
        mid: member.id,
        deviceInfo: deviceInfoText,
        appVersion: packageInfo.version,
      );
    }
    //アプリバージョンチェック
    account.userSetting.isAppUpdate = await ApiDomains.checkAppVersion(version: packageInfo.version);
    FunctionUtils.log('アプリ強制更新：${account.userSetting.isAppUpdate}');
    //プリファレンスに保存
    await SharedPrefs.setAuth(domainId: conaviId, appToken: member.appToken!);
    FunctionUtils.log('appToken:${member.appToken!}');
    FunctionUtils.log('認証完了');

    result.isSuccess = true;
    result.account = account;
    return result;
  }

  static Future<String?> domainSignIn({required String domainId}) async {
    try {
      var url = Uri.parse('https://aps.conavi.net/api/auth/auth_domain.php');
      var response = await http.post(url, body: {
        'domain_id': domainId,
      });
      if (response.statusCode == 200) {
        FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if(data.containsKey('domain') && !data.containsKey('error')){
          return data['domain'];
        }else{
          FunctionUtils.log('domainSignIn error ===== ${data['error']}');
        }
      }else{
        FunctionUtils.log('domainSignIn statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('domainSignIn try catch error ===== $e');
    }
    return null;
  }

  static Future<Member?> emailSignIn({
    required String domain,
    required String email,
    required String password,
    required String appToken,
    required String conaviId }) async {
    try {
      var url = Uri.parse('$domain/api/auth/auth_user.php');
      var response = await http.post(url, body: {
        'email': email,
        'password': password,
        'app_token': appToken,
        'conavi_id': conaviId,
      });
      if (response.statusCode == 200) {
        FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if(data.containsKey('member') && !data.containsKey('error')) {
          Member member = Member(
            id: data['member']['id'],
            name: data['member']['member_nm'],
            imagePath: data['member']['member_image_base'] ?? '',
            selfIntroduction: data['member']['member_naiyo'] ?? '',
            notifyEmailFlag: data['member']['mailsend_message_flg'] ?? '',
            appToken: data['member']['app_token'] ?? '',
            fcmToken: data['member']['fcm_token'] ?? '',
          );
          return member;
        }else{
          FunctionUtils.log('emailSignIn error ===== ${data['error']}');
        }
      }else{
        FunctionUtils.log('emailSignIn statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('emailSignIn try catch error ===== $e');
    }

    return null;
  }

  static Future<Auth?> autoLogin() async {

    //プリファレンスから取得
    await SharedPrefs.setInstance();
    String conaviId = SharedPrefs.fetchDomainId();
    String appToken = SharedPrefs.fetchAppToken();
    FunctionUtils.log("domain:$conaviId");
    FunctionUtils.log("appToken:$appToken");

    //ドメインId、アプリトークンが空で無ければアカウント情報を取得
    if(conaviId.isNotEmpty && appToken.isNotEmpty) {
      FunctionUtils.showToast(
        message: '認証中...',
        toastLength: Toast.LENGTH_LONG,
        toastGravity: ToastGravity.BOTTOM ,
        time: 10,
        backgroundColor: const Color(0xff3166f7),
        textColor: Colors.white,
        textSize: 16.0,
      );
      Result? result = await signIn(
        conaviId: conaviId,
        email: '',
        password: '',
        appToken: appToken,
      );
      return result?.account;
      // if (account is Auth) {
      //   //Auth myAccount = ref.watch(userProvider);
      //   //ref.read(authProvider.notifier).state  = account;
      //   /*final member = Member(name: 'aaa', imagePath: '', selfIntroduction: '');
      //   myAccount.member = member;
      //   FunctionUtils.logmyAccount.member);*/
      //   //FunctionUtils.log('UserSetting:${account.userSetting.selectedBottomMenuIndex}');
      //   ref.read(userProvider.notifier).state  = account.member;
      //   ref.read(domainProvider.notifier).state  = account.domain;
      //   ref.read(userSettingProvider.notifier).state = account.userSetting;
      //
      //   Authentication.myAccount = account;
      //   return true;
      // }
    }
    return null;
  }

  static Future<void> signOut({
    required String? mid,
    required String domain}) async {
    //FCMトークンの削除
    FirebaseCloudMessaging.deleteToken(domain: domain,mid: mid);
    //通知を全てキャンセル
    await LocalNotifications.cancelAllNotifications();
    //プリファレンスを削除
    await SharedPrefs.removeAuth();
    await SharedPrefs.clear();
  }

  static Future<dynamic> createAuthCode({
    required String email
  }) async {
    Result result = Result();
    try {
      var url = Uri.parse('https://aps.conavi.net/api/auth/auth_code.php');
      var response = await http.post(url, body: {
        'email': email,
      });
      if (response.statusCode == 200) {
        FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if(data.containsKey('result')) result.isSuccess = data['result'];
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('createAuthCode error ===== ${data['error']}');
        }
        return result;
      }else{
        FunctionUtils.log('createAuthCode statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('createAuthCode try catch error ===== $e');
    }
    return null;
  }

  static Future<bool> checkAuthCode({
    required String email,
    required String code,
  }) async {
    try {
      var url = Uri.parse('https://aps.conavi.net/api/auth/auth_check_code.php');
      var response = await http.post(url, body: {
        'email': email,
        'code': code,
      });
      if (response.statusCode == 200) {
        FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if(data.containsKey('result') && !data.containsKey('error')){
          return true;
        }else{
          FunctionUtils.log('createAuthCode error ===== ${data['error']}');
        }
      }else{
        FunctionUtils.log('createAuthCode statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('createAuthCode try catch error ===== $e');
    }
    return false;
  }
}
