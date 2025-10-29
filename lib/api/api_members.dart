import 'dart:convert';
import 'dart:io';

import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiMembers {

  static String error = '';

  static Future<dynamic> setMember(Member newMember) async {
    try {
      var url = Uri.parse('https://...conavi.net/member_insert.php');
      var result = await http.post(url, body: {
        'email': newMember.email,
        'password': newMember.password,
        'name': newMember.name,
        'image_path': newMember.imagePath,
        'self_introduction': newMember.selfIntroduction,
      });
      Map<String, dynamic> data = jsonDecode(result.body);
      Member member = Member(
        id: data['member']['id'],
        email: data['member']['email'],
        password: data['member']['password'],
        name: data['member']['name'],
        selfIntroduction: data['member']['self_introduction'],
        imagePath: data['member']['image_path'],
      );
      //FunctionUtils.log(data);
      FunctionUtils.log('新規ユーザー作成完了');
      return member;
    } catch (e) {
      FunctionUtils.log('新規ユーザー作成エラー ===== $e');
      return null;
    }
  }

  static Future<Member?> updateMember({
    required Member updateAccount,
    required String domain}) async {

    try {
      var url = Uri.parse('$domain/api/user/update_user.php');
      var response = await http.post(url, body: {
        'id': updateAccount.id,
        'name': updateAccount.name,
        'self_introduction': updateAccount.selfIntroduction,
        'email_message_flg':updateAccount.notifyEmailFlag
      });

      if (response.statusCode == 200) {
        //FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('member') && !data.containsKey('error')) {
          Member member = Member(
              id: data['member']['id'],
              name: data['member']['member_nm'],
              imagePath: data['member']['member_image_base'],
              selfIntroduction: data['member']['member_naiyo'],
              notifyEmailFlag: data['member']['mailsend_message_flg'],
              fcmToken: data['member']['fcm_token'],
              appToken: data['member']['app_token']
          );
          FunctionUtils.log('ユーザー情報の更新完了');
          return member;
        } else {
          FunctionUtils.log('updateMember error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('updateMember statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('updateMember try catch error ===== $e');
    }
    return null;
  }

  static Future<bool> uploadMemberFile({
    required String uid,
    required File? uploadFile,
    required String domain,
  }) async {
    try {
      var url = Uri.parse('$domain/api/upload/upload_user.php');
      var request = http.MultipartRequest('POST', url);
      //$_POST
      request.fields['user_id'] = uid;
      if (uploadFile is File) {
        //$_FILES
        var fileName = path.basename(uploadFile.path);
        request.fields['file_name'] = fileName;
        var picture = http.MultipartFile.fromBytes(
          'file',
          uploadFile.readAsBytesSync(),
          filename: fileName,
          //contentType: MediaType.parse('image/jpeg'),
        );
        request.files.add(picture);
        var response = await request.send();
        //FunctionUtils.log(response.statusCode);
        if(response.statusCode == 200){
          var responseData = await response.stream.toBytes();
          var body = String.fromCharCodes(responseData);
          //FunctionUtils.log(body);
          Map<String, dynamic> data = jsonDecode(body);
          if(!data.containsKey('error')) {
            return true;
          }else{
            FunctionUtils.log('uploadMemberFile error ===== ${data['error']}');
          }
        }else{
          FunctionUtils.log('uploadMemberFile statusCode error ===== ${response.statusCode}');
        }
      }else{
        FunctionUtils.log('uploadMemberFile error ===== no List<File>');
      }
    } catch (e) {
      FunctionUtils.log('uploadMemberFile try catch error ===== $e');
    }
    return false;
  }

  static Future<List<Member>?> fetchMembers({
    required String domain,
    required String domainId,
    required String mid,
  }) async {
    List<Member> list = [];
    try {
      var url = Uri.parse('$domain/api/user/get_user.php?action=all');
      var response = await http.post(url, body: {
        'domain_id': domainId,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //FunctionUtils.log(response.body);
        if (data.containsKey('member') && !data.containsKey('error')) {
          for (var member in data['member']) {
            //if (mid == member['id']) continue;
            //FunctionUtils.log(json.encode(member));
            list.add(
              Member(
                id: member['id'],
                name: member['member_nm'] ?? '',
                imagePath: member['member_image_base']?.replaceFirst('./uploads', '$domain/uploads') ?? '',
                selfIntroduction: member['member_naiyo'] ?? '',
              ),
            );
          }
          //member['member_image_base'].replaceFirst('./uploads', '$domain/uploads')
          //FunctionUtils.log('ユーザー取得完了');
        } else {
          FunctionUtils.log('fetchMembers error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('fetchMembers statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('fetchMembers try catch error ===== $e');
    }
    return list;
  }

  static Future<Member?> fetchProfile({
    required String domain,
    required String memberId,
  }) async {
    try {
      var url = Uri.parse('$domain/api/user/get_user.php');
      var response = await http.post(url, body: {
        'id': memberId,
      });
      if (response.statusCode == 200) {
        //FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('member') && !data.containsKey('error')){
          Member member = Member(
            id: data['member']['id'],
            email: data['member']['mail'],
            name: data['member']['member_nm'] ?? '',
            imagePath: data['member']['member_image_base'] ?? '',
            selfIntroduction: data['member']['member_naiyo'] ?? '',
            fcmToken: data['member']['fcm_token'],
            appToken: data['member']['app_token'],
          );
          //FunctionUtils.log(member.toJson());
          return member;
        } else {
          FunctionUtils.log('fetchProfile error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('fetchProfile statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('fetchProfile try catch error ===== $e');
    }
    return null;
  }

  static Future<bool> updateProfile({
    required String domain,
    required String memberId,
    required String name,
    required String selfIntroduction,
  }) async {
    try {
      var url = Uri.parse('$domain/api/user/update_user.php');
      var response = await http.post(url, body: {
        'id': memberId,
        'name': name,
        'self_introduction': selfIntroduction,
      });
      if (response.statusCode == 200) {
        //FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('result')) {
          if(data['result'] == true) {
            FunctionUtils.log('メンバー情報更新：成功');
            return true;
          }else{
            FunctionUtils.log('メンバー情報更新：失敗');
          }
        } else {
          FunctionUtils.log('updateProfile error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('updateProfile statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('updateProfile try catch error ===== $e');
    }
    return false;
  }

  // static Future<dynamic> getMember(String mid) async {
  //   try {
  //     var url = Uri.parse('https://.conavi.net/index.php');
  //     var result = await http.get(url);
  //     Map<String, dynamic> data = jsonDecode(result.body);
  //     //FunctionUtils.log(data);
  //     //Member member = Member(id: id, name: name, userId: userId, selfIntroduction: selfIntroduction, imagePath: imagePath)
  //     //await http.get(url);
  //     /*DocumentSnapshot documentSnapshot = await users.doc(uid).get();
  //     Map<String, dynamic> data =
  //     documentSnapshot.data() as Map<String, dynamic>;
  //     Account myAccount = Account(
  //         id: uid,
  //         name: data['name'],
  //         userId: data['user_id'],
  //         selfIntroduction: data['self_introduction'],
  //         imagePath: data['image_path'],
  //         createTime: data['created_time'],
  //         updateTime: data['updated_time']);
  //     Authentication.myAccount = myAccount;*/
  //     FunctionUtils.log('ユーザー取得完了');
  //     return true;
  //   } catch (e) {
  //     FunctionUtils.log('ユーザー取得エラー ===== $e');
  //     return false;
  //   }
  // }

  static Future<void> updateFcmToken({
    required String domain,
    required String? mid,
    required String? token,
  }) async {
    try {
      var url = Uri.parse('$domain/api/user/update_fcm_token.php');
      var response = await http.post(url, body: {
        'id': mid,
        'token': token,
      });
      if (response.statusCode == 200) {
        //FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (!data.containsKey('error')) {
          FunctionUtils.log('FCMトークン情報の更新完了');
        } else {
          FunctionUtils.log('updateFcmToken error ===== ${data['error']}');
        }
      }else{
        FunctionUtils.log('updateFcmToken statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('updateFcmToken try catch error ===== $e');
    }
  }

  static Future<void> updateDeviceInfo({
    required String domain,
    required String mid,
    required String deviceInfo,
    required String appVersion,
  }) async {
    try {
      var url = Uri.parse('$domain/api/user/update_device_info.php');
      var response = await http.post(url, body: {
        'id': mid,
        'device_info': deviceInfo,
        'app_version' : appVersion,
      });
      if (response.statusCode == 200) {
        //FunctionUtils.log(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (!data.containsKey('error')) {
          FunctionUtils.log('デバイス情報の更新完了');
        } else {
          FunctionUtils.log('updateDeviceInfo error ===== ${data['error']}');
        }
      }else{
        FunctionUtils.log('updateDeviceInfo statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('updateDeviceInfo try catch error ===== $e');
    }
  }

  static Future<dynamic> createMember({
    required String domain, //ドメインURL
    required String name, //名前
    required String email, //メールアドレス
    required String password, //パスワード
    required String conaviId, //コナビID
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('$domain/api/user/create_user.php');
      //セット
      var response = await http.post(url, body: {
        'user_name': name,
        'email': email,
        'password': password,
        'conavi_id': conaviId,
      });

      FunctionUtils.log('----------ApiMember.createMember-----------');
      FunctionUtils.log('name:$name');
      FunctionUtils.log('email:$email');
      FunctionUtils.log('password:$password');
      FunctionUtils.log('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('createMember error ===== ${data['error']}');
        }
        //FunctionUtils.log(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('createMember statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('createMember try catch error ===== $e');
    }
    return null;
  }

  ///メールアドレスチェック
  static Future<dynamic> checkEmail({
    required String domain, //ドメインURL
    required String email, //メールアドレス
    required String conaviId, //コナビID
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('$domain/api/user/check_user_email.php');
      //セット
      var response = await http.post(url, body: {
        'email': email,
        'conavi_id': conaviId,
      });

      FunctionUtils.log('domain:$domain');
      FunctionUtils.log('email:$email');
      FunctionUtils.log('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
          if(data.containsKey('member')){
            result.set('memberId',data['member']['id']);
          }
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('checkEmail error ===== ${data['error']}');
        }
        FunctionUtils.log(result.isSuccess);
        FunctionUtils.log(result.data);
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

  ///パスワードチェック
  static Future<dynamic> checkPassword({
    required String domain, //ドメインURL
    required String memberId, //メンバーid
    required String password, //パスワード
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('$domain/api/user/check_user_password.php');
      //セット
      var response = await http.post(url, body: {
        'member_id': memberId,
        'password': password,
      });
      FunctionUtils.log('member_id:$memberId');
      FunctionUtils.log('password:$password');
      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('checkPassword error ===== ${data['error']}');
        }
        FunctionUtils.log(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('checkPassword statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('checkPassword try catch error ===== $e');
    }
    return null;
  }

  ///パスワード変更
  static Future<dynamic> changePassword({
    required String domain, //ドメインURL
    required String memberId, //メンバーid
    required String password, //パスワード
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('$domain/api/user/update_user_password.php');
      //セット
      var response = await http.post(url, body: {
        'member_id': memberId,
        'password': password,
      });
      FunctionUtils.log('member_id:$memberId');
      FunctionUtils.log('password:$password');
      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('changePassword error ===== ${data['error']}');
        }
        FunctionUtils.log(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('changePassword statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('changePassword try catch error ===== $e');
    }
    return null;
  }

  ///メンバー削除
  static Future<dynamic> delete({
    required String domain, //ドメインURL
    required String memberId, //メンバーID
  }) async {
    Result result = Result();
    try {
      //取得先URL
      var url = Uri.parse('$domain/api/user/delete_user.php');
      //セット
      var response = await http.post(url, body: {
        'member_id': memberId,
      });
      FunctionUtils.log('domain:$domain');
      FunctionUtils.log('member_id:$memberId');
      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          FunctionUtils.log('delete error ===== ${data['error']}');
        }
        FunctionUtils.log(result.isSuccess);
        FunctionUtils.log(result.data);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('delete statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('delete try catch error ===== $e');
    }
    return null;
  }
}
