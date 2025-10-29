import 'dart:convert';

import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/function_utils.dart';
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

      FunctionUtils.log('community_name:$communityName');
      FunctionUtils.log('email:$email');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
          if(data.containsKey('conavi_id')){
            result.set('conaviId',data['conavi_id']);
          }
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('createCommunity error ===== ${data['error']}');
        }
        FunctionUtils.log(result.isSuccess);
        FunctionUtils.log(result.data['conaviId']);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('createCommunity statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('createCommunity try catch error ===== $e');
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

      FunctionUtils.log('name:$name');
      FunctionUtils.log('email:$email');
      FunctionUtils.log('password:$password');
      FunctionUtils.log('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('createCommunityMember error ===== ${data['error']}');
        }
        FunctionUtils.log(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('createCommunityMember statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('createCommunityMember try catch error ===== $e');
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

      FunctionUtils.log('email:$email');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('checkEmail error ===== ${data['error']}');
        }
        FunctionUtils.log(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('checkEmail statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('checkEmail try catch error ===== $e');
    }
    return null;
  }
}