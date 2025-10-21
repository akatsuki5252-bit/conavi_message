import 'dart:convert';
import 'dart:io';

import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/setting/result.dart';
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
      //print(data);
      print('新規ユーザー作成完了');
      return member;
    } catch (e) {
      print('新規ユーザー作成エラー ===== $e');
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
        //print(response.body);
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
          print('ユーザー情報の更新完了');
          return member;
        } else {
          print('updateMember error ===== ${data['error']}');
        }
      } else {
        print('updateMember statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('updateMember try catch error ===== $e');
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
        //print(response.statusCode);
        if(response.statusCode == 200){
          var responseData = await response.stream.toBytes();
          var body = String.fromCharCodes(responseData);
          //print(body);
          Map<String, dynamic> data = jsonDecode(body);
          if(!data.containsKey('error')) {
            return true;
          }else{
            print('uploadMemberFile error ===== ${data['error']}');
          }
        }else{
          print('uploadMemberFile statusCode error ===== ${response.statusCode}');
        }
      }else{
        print('uploadMemberFile error ===== no List<File>');
      }
    } catch (e) {
      print('uploadMemberFile try catch error ===== $e');
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
        //print(response.body);
        if (data.containsKey('member') && !data.containsKey('error')) {
          for (var member in data['member']) {
            //if (mid == member['id']) continue;
            //print(json.encode(member));
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
          //print('ユーザー取得完了');
        } else {
          print('fetchMembers error ===== ${data['error']}');
        }
      } else {
        print('fetchMembers statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('fetchMembers try catch error ===== $e');
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
        //print(response.body);
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
          //print(member.toJson());
          return member;
        } else {
          print('fetchProfile error ===== ${data['error']}');
        }
      } else {
        print('fetchProfile statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('fetchProfile try catch error ===== $e');
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
        //print(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('result')) {
          if(data['result'] == true) {
            print('メンバー情報更新：成功');
            return true;
          }else{
            print('メンバー情報更新：失敗');
          }
        } else {
          print('updateProfile error ===== ${data['error']}');
        }
      } else {
        print('updateProfile statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('updateProfile try catch error ===== $e');
    }
    return false;
  }

  // static Future<dynamic> getMember(String mid) async {
  //   try {
  //     var url = Uri.parse('https://.conavi.net/index.php');
  //     var result = await http.get(url);
  //     Map<String, dynamic> data = jsonDecode(result.body);
  //     //print(data);
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
  //     print('ユーザー取得完了');
  //     return true;
  //   } catch (e) {
  //     print('ユーザー取得エラー ===== $e');
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
        //print(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (!data.containsKey('error')) {
          print('FCMトークン情報の更新完了');
        } else {
          print('updateFcmToken error ===== ${data['error']}');
        }
      }else{
        print('updateFcmToken statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('updateFcmToken try catch error ===== $e');
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
        //print(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (!data.containsKey('error')) {
          print('デバイス情報の更新完了');
        } else {
          print('updateDeviceInfo error ===== ${data['error']}');
        }
      }else{
        print('updateDeviceInfo statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('updateDeviceInfo try catch error ===== $e');
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

      print('----------ApiMember.createMember-----------');
      print('name:$name');
      print('email:$email');
      print('password:$password');
      print('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('createMember error ===== ${data['error']}');
        }
        //print(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('createMember statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('createMember try catch error ===== $e');
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

      print('domain:$domain');
      print('email:$email');
      print('conavi_id:$conaviId');

      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
          if(data.containsKey('member')){
            result.set('memberId',data['member']['id']);
          }
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('checkEmail error ===== ${data['error']}');
        }
        print(result.isSuccess);
        print(result.data);
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
      print('member_id:$memberId');
      print('password:$password');
      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('checkPassword error ===== ${data['error']}');
        }
        print(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('checkPassword statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('checkPassword try catch error ===== $e');
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
      print('member_id:$memberId');
      print('password:$password');
      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('changePassword error ===== ${data['error']}');
        }
        print(result.isSuccess);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('changePassword statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('changePassword try catch error ===== $e');
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
      print('domain:$domain');
      print('member_id:$memberId');
      //取得
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if(data.containsKey('result')){
          result.isSuccess = data['result'];
        }
        if(data.containsKey('error')){
          result.error = data['error'];
          print('delete error ===== ${data['error']}');
        }
        print(result.isSuccess);
        print(result.data);
        return result;
      } else {
        //リクエスト失敗（※送信は成功）
        print('delete statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('delete try catch error ===== $e');
    }
    return null;
  }
}
