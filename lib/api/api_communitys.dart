import 'dart:convert';

import 'package:conavi_message/setting/result.dart';
import 'package:http/http.dart' as http;

class ApiCommunitys {

  ///コミュニティを作成
  static Future<dynamic> createCommunity({
    required String communityName, //コミュニティ名
    required String email, //メールアドレス
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://aps.conavi.net/api/community/create_community.php');
      //セット
      var response = await http.post(url, body: {
        'community_name': communityName,
        'email': email,
      });

      print('community_name:$communityName');
      print('email:$email');

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
          print('createCommunity error ===== ${data['error']}');
        }
        print(result.isSuccess);
        print(result.data['conaviId']);
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

  static Future<dynamic> createMember({
    required String name, //名前
    required String email, //メールアドレス
    required String password, //パスワード
    required String conaviId, //コナビID
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://light.conavi.net/api/user/create_user.php');
      //セット
      var response = await http.post(url, body: {
        'user_name': name,
        'email': email,
        'password': password,
        'conavi_id': conaviId,
      });

      print('name:$name');
      print('email:$email');
      print('password:$password');
      print('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('createCommunityMember error ===== ${data['error']}');
        }
        print(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('createCommunityMember statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('createCommunityMember try catch error ===== $e');
    }
    return null;
  }

  ///メールアドレスチェック
  static Future<dynamic> checkEmail({
    required String email, //メールアドレス
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('https://aps.conavi.net/api/community/check_community_email.php');
      //セット
      var response = await http.post(url, body: {
        'email': email,
      });

      print('email:$email');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('checkEmail error ===== ${data['error']}');
        }
        print(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('checkEmail statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('checkEmail try catch error ===== $e');
    }
    return null;
  }
}