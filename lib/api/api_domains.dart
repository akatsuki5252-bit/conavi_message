import 'dart:convert';

import 'package:conavi_message/setting/result.dart';
import 'package:http/http.dart' as http;

class ApiDomains {

  ///ドメインURLを取得
  static Future<dynamic> getUrl({
    required String conaviId, //コナビId
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://aps.conavi.net/api/domain/get_domain.php');
      //セット
      var response = await http.post(url, body: {
        'conavi_id': conaviId,
      });

      print('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
          if(data.containsKey('domain_url')){
            result.set('domainUrl',data['domain_url']);
          }
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('createCommunity error ===== ${data['error']}');
        }
        print(result.isSuccess);
        print(result.data);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('createCommunity statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('createCommunity try catch error ===== $e');
    }
    return null;
  }

  ///招待コードを作成
  static Future<dynamic> createInviteCode({
    required String conaviId, //コナビID
  }) async {
    //結果
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://aps.conavi.net/api/invite/create_invite_code.php');
      //セット
      var response = await http.post(url, body: {
        'conavi_id': conaviId,
      });

      print('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
          if(data.containsKey('invite_code')){
            result.set('inviteCode',data['invite_code']);
          }
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('createInviteCode error ===== ${data['error']}');
        }
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('createInviteCode statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('createInviteCode try catch error ===== $e');
    }
    return null;
  }

  ///招待コードをチェック
  static Future<dynamic> checkInviteCode({
    required String inviteCode, //認証コード
    required String checked, //チェック
  }) async {
    //結果
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://aps.conavi.net/api/invite/check_invite_code.php');
      //セット
      var response = await http.post(url, body: {
        'invite_code': inviteCode,
        'checked': checked,
      });

      print('invite_code:$inviteCode');
      print('checked:$checked');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
          if(data.containsKey('conavi_id')){
            result.set('conaviId',data['conavi_id']);
          }
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('checkInviteCode error ===== ${data['error']}');
        }
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('checkInviteCode statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('checkInviteCode try catch error ===== $e');
    }
    return null;
  }

  ///招待コードを送信
  static Future<dynamic> sendInviteCode({
    required String email, //メールアドレス
    required String inviteCode, //認証コード
  }) async {
    //結果
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://aps.conavi.net/api/invite/send_invite_code.php');
      //セット
      var response = await http.post(url, body: {
        'email': email,
        'invite_code': inviteCode,
      });

      print('email:$email');
      print('invite_code:$inviteCode');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('sendInviteCode error ===== ${data['error']}');
        }
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('sendInviteCode statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('sendInviteCode try catch error ===== $e');
    }
    return null;
  }

  //アップデートが必要ならtrue
  static Future<bool> checkAppVersion({
    required String version //バージョン
  }) async {
    //結果
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://aps.conavi.net/api/version/check_version.php');
      //セット
      var response = await http.post(url, body: {
        'version': version,
      });

      print('version:$version');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          print('checkAppVersion error ===== ${data['error']}');
        }
        return result.isSuccess;
      } else {
        //リクエスト失敗（※送信は成功）
        print('checkAppVersion statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('checkAppVersion try catch error ===== $e');
    }
    return false;
  }
}