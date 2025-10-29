import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/talk_group_member.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/message.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/utils/upload_file.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiMessages {
  static String error = ''; //エラー
  //ルーム作成
  static Future<dynamic> createRoom({
    required String joinedMemberIds, //メンバーidをカンマ区切りした文字列
    required Auth myAccount //アカウント情報
  }) async {
    try {
      //取得先URL
      var url = Uri.parse('${myAccount.domain.url}/api/message/create_room.php');
      //POST送信
      var response = await http.post(url, body: {
        'joined_member_ids': joinedMemberIds,
      });
      //200:成功
      if (response.statusCode == 200) {
        //jsonをデコード
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        //キーの存在チェック
        if (data.containsKey('rooms') && !data.containsKey('error')) {
          //カンマ区切り文字列をList<String>に変換
          List<String> memberIds = FunctionUtils.stringToList(data['rooms']['joined_member_ids']);
          //メンバーリスト
          List<Member> talkMembers = [];
          String roomName = '';
          //メンバーid単位でループ
          for (var id in memberIds) {
            Member? talkMember;
            //アカウントと異なる場合はメンバー情報を取得
            if(id != myAccount.member.id) {
              talkMember = await ApiMembers.fetchProfile(
                domain: myAccount.domain.url,
                memberId: id,
              );
            }else{
              talkMember = myAccount.member;
            }
            if (talkMember is Member) {
              //トーク相手のメンバー名がルーム名となる
              if(id != myAccount.member.id) roomName = talkMember.name;
              //メンバーリストに追加
              talkMembers.add(talkMember);
            }
          }
          var talkDateTime = DateTime.now(); //ルームの更新時刻を現在の時刻に設定（仮）
          //取得したルーム情報の作成・更新時刻を挿入
          if(data['rooms']['created'] != null) talkDateTime = DateTime.parse(data['rooms']['created']);
          if(data['rooms']['modified'] != null) talkDateTime = DateTime.parse(data['rooms']['modified']);
          final talkRoom = TalkRoom(
            roomId: data['rooms']['id'], //ルームid
            roomName: roomName, //ルーム名
            talkMembers: talkMembers, //メンバーリスト（※自身の情報を含む）
            createdTime: data['rooms']['created'] != null ? DateTime.parse(data['rooms']['created']) : DateTime.now(),
            modifiedTime: talkDateTime, //ルームの最新更新日付
          );
          FunctionUtils.log('メンバールーム作成・取得完了');
          return talkRoom;
        } else {
          //キーの存在チェックでエラー
          error = data['error'];
          FunctionUtils.log('createRoom error ===== ${data['error']}');
        }
      } else {
        //リクエスト失敗（※送信は成功）
        FunctionUtils.log('createRoom statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      FunctionUtils.log('createRoom try catch error ===== $e');
    }
    return null;
  }
  //メッセージ一覧
  static Future<List<TalkRoom>?> fetchJoinedRooms({
    required Auth myAccount,
    required List<Member>? members
  }) async {
    try {
      var url = Uri.parse('${myAccount.domain.url}/api/message/get_rooms.php');
      var response = await http.post(url, body: {
        'member_id': myAccount.member.id,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //FunctionUtils.log(response.body);
        if (data.containsKey('rooms') && !data.containsKey('error')) {
          List<TalkRoom> talkRooms = [];
          bool isContinue = false;
          for (var room in data['rooms']) {
            //FunctionUtils.log(json.encode(room));
            if(room['modified'] == null || room['last_message'] == null) continue;
            List<String> memberIds = FunctionUtils.stringToList(room['joined_member_ids']);
            List<Member> talkMembers = [];
            String roomName = ''; //ルーム名
            String imagePath = ''; //ルーム画像
            for (var id in memberIds) {
              Member? talkMember; //ルームメンバー
              if(id != myAccount.member.id) {
                if (members != null) {
                  for (var member in members) {
                    if (id == member.id) talkMember = member;
                  }
                  //相手の情報が無い場合はループを抜ける
                  talkMember ??= Member(
                    id: '',
                    name: '削除されたユーザー',
                    imagePath: '',
                    selfIntroduction: ''
                  );
                }
              }else{
                talkMember = myAccount.member;
              }
              // else {
              //   talkMember = await ApiMembers.fetchProfile(
              //     mid: id,
              //     domain: myAccount.domain,
              //   );
              // }
              if (talkMember is Member) {
                if(myAccount.member.id != talkMember.id) {
                  roomName = talkMember.name;
                  if(talkMember.imagePath.isNotEmpty) {
                    imagePath = '${myAccount.domain.url}/api/upload/file.php?member_id=${talkMember.id}&app_token=${myAccount.member.appToken}';
                  }
                }
                talkMembers.add(talkMember);
              }
            }
            //相手のメンバー情報が無い場合はループを抜ける
            //if(isContinue) continue;
            try {
              final talkRoom = TalkRoom(
                roomId: room['id'],
                talkMembers: talkMembers,
                lastMessage: room['last_message'] ?? '',
                lastSendFileFromMemberId: room['last_file_from_member_id'] ?? '',
                roomName: roomName,
                imagePath: imagePath,
                createdTime: room['created'] != null ? DateTime.parse(room['created']) : DateTime.now(),
                modifiedTime: DateTime.parse(room['modified']),
                lastSendTime: FunctionUtils.createLastSendTime(room['modified']),
                countUnRead: int.parse(room['unread_count']),
              );
              //相手がファイルを送信した時のメッセージ
              if(talkRoom.lastSendFileFromMemberId.isNotEmpty){
                for(var member in talkRoom.talkMembers){
                  if(member.id == talkRoom.lastSendFileFromMemberId && myAccount.member.id != talkRoom.lastSendFileFromMemberId){
                    talkRoom.lastMessage = '${member.name}が${talkRoom.lastMessage}';
                  }
                }
              }

              talkRooms.add(talkRoom);
            }catch(e){
              FunctionUtils.log('fetchJoinedRooms room try catch error ===== $e');
            }
          }
          //並び順
          //FunctionUtils.log(myAccount.userSetting.currentMessageSort);
          if(myAccount.userSetting.currentMessageSort == MessageSort.time) {
            talkRooms.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
          }else if(myAccount.userSetting.currentMessageSort == MessageSort.unRead) {
            talkRooms.sort((a, b) => b.countUnRead.compareTo(a.countUnRead));
          }
          return talkRooms;
        } else {
          error = data['error'];
          FunctionUtils.log('fetchJoinedRooms error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('fetchJoinedRooms statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('fetchJoinedRooms try catch error ===== $e');
    }
    return null;
  }



  static Future<TalkRoom?> fetchRoom({
    required String domain,
    required String roomId,
    required String mid,
  }) async {
    try {
      var url = Uri.parse('$domain/api/message/get_room.php');
      var response = await http.post(url, body: {
        'room_id': roomId,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //FunctionUtils.log(response.body);
        if (data.containsKey('rooms') && !data.containsKey('error')) {
          var room = data['rooms'];
          List<String> memberIds = FunctionUtils.stringToList(room['joined_member_ids']);
          List<Member> talkMembers = [];
          String roomName = '';
          String imagePath = '';
          for (var id in memberIds) {
            Member? talkMember = await ApiMembers.fetchProfile(
              domain: domain,
              memberId:id,
            );
            if (talkMember is Member) {
              if(mid != talkMember.id) {
                roomName = talkMember.name;
                imagePath = talkMember.imagePath;
              }
              talkMembers.add(talkMember);
            }
          }
          try {
            final talkRoom = TalkRoom(
                roomId: room['id'],
                talkMembers: talkMembers,
                lastMessage: room['last_message'] ?? '',
                roomName: roomName,
                imagePath: imagePath,
                createdTime: room['created'] != null ? DateTime.parse(room['created']) : DateTime.now(),
                modifiedTime: DateTime.parse(room['modified']),
                lastSendTime: FunctionUtils.createLastSendTime(room['modified']),
                countUnRead: int.parse(room['unread_count'])
            );
            //FunctionUtils.log(talkRoom);
            return talkRoom;
          }catch(e){
            FunctionUtils.log('fetchRoom room try catch error ===== $e');
          }
        } else {
          FunctionUtils.log('fetchRoom error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('fetchRoom statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('fetchRoom try catch error ===== $e');
    }
    return null;
  }

  static Future<List<Message>?> fetchMessages({
    required TalkRoom talkRoom,
    required Auth myAccount}) async {
    try {
      var url = Uri.parse('${myAccount.domain.url}/api/message/get_message.php');
      var response = await http.post(url, body: {
        'room_id': talkRoom.roomId,
        'member_id': myAccount.member.id
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        FunctionUtils.log(response.body);
        if (data.containsKey('room_messages') && !data.containsKey('error')) {
          List<Message> messages = [];
          for (var roomMessage in data['room_messages']) {
            Member? talkMember;
            //FunctionUtils.log(talkRoom.talkMembers.length);
            for(var member in talkRoom.talkMembers){
              //FunctionUtils.log(member.name);
              //FunctionUtils.log(member.id);
              if(roomMessage['member_id_from'] == member.id){
                talkMember = member;
              }
            }
            FunctionUtils.log(talkMember);
            talkMember ??= Member(
              id: '',
              name: '削除されたユーザー',
              imagePath: '',
              selfIntroduction: '',
            );
            // Member? talkMember = await ApiMembers.fetchProfile(
            //     domain: account.domain,
            //     mid: roomMessage['member_id_from']
            // );
            //アップロードファイル
            final uploadFile = UploadFile(
              id: roomMessage['id'] ?? '',
              fileUrl: roomMessage['id'] != null
                  ? '${myAccount.domain.url}/api/upload/file.php?message_id=${roomMessage['id']}&app_token=${myAccount.member.appToken}'
                  : '',
              fileName: roomMessage['file_nm'] ?? '',
              fileExt: roomMessage['file_kbn'] ?? '',
            );
            //メッセージに格納
            final Message message = Message(
              id: roomMessage['id'] ?? '',
              message: roomMessage['message'] ?? '',
              widgetMessage: WidgetUtils.textWithUrl(roomMessage['message'] ?? '',Colors.black,15),
              fileUrl: roomMessage['file'] ?? '',
              fileName: roomMessage['file_nm'] ?? '',
              fileExt: roomMessage['file_kbn'] ?? '',
              file: uploadFile,
              member: talkMember,
              isMe: talkMember.id == myAccount.member.id ? true : false,
              readFlag: roomMessage['read_flg'] == '1' ? true : false,
              sendTime: DateTime.parse(roomMessage['created']),
            );
            messages.add(message);
          }
          return messages;
        } else if(data.containsKey('error')){
          FunctionUtils.log('fetchMessages error ===== ${data['error']}');
        } else{
          FunctionUtils.log('fetchMessages empty');
        }
      } else {
        FunctionUtils.log('fetchMessages statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('fetchMessages try catch error ===== $e');
    }
    return null;
  }



  static Future<bool> sendMessage({
    required String roomId,
    required String senderFromId,
    required String senderToId,
    required String message,
    required String domain}) async {

    try {
      var url = Uri.parse('$domain/api/message/send_message.php');
      var response = await http.post(url, body: {
        'room_id': roomId,
        'sender_from_id': senderFromId,
        'sender_to_id': senderToId,
        'message': message,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //FunctionUtils.log(response.body);
        if (!data.containsKey('error')) {
          FunctionUtils.log('メッセージの送信成功');
          return true;
        } else {
          FunctionUtils.log('sendMessage error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('sendMessage statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('sendMessage try catch error ===== $e');
    }
    return false;
  }

  static Future<bool> deleteMessage({
    required String messageId,
    required String domain}) async {

    try {
      var url = Uri.parse('$domain/api/message/delete_message.php');
      var response = await http.post(url, body: {
        'message_id': messageId,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //FunctionUtils.log(response.body);
        if (!data.containsKey('error')) {
          FunctionUtils.log('メッセージの削除成功');
          return true;
        } else {
          FunctionUtils.log('deleteMessage error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('deleteMessage statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('deleteMessage try catch error ===== $e');
    }
    return false;
  }

  static Future<bool> sendUploadFile(
      {required String roomId,
        required String sendFromId,
        required String sendToId,
        required List<dynamic> files,
        required String domain}) async {

    try {
      var url = Uri.parse('$domain/api/upload/upload_message.php');
      var request = http.MultipartRequest('POST', url);
      //$_POST
      request.fields['room_id'] = roomId;
      request.fields['sender_from_id'] = sendFromId;
      request.fields['sender_to_id'] = sendToId;
      request.fields['file_length'] = files.length.toString();

      // FunctionUtils.log('room_id:${request.fields['room_id']}');
      // FunctionUtils.log('sender_from_id:${request.fields['sender_from_id']}');
      // FunctionUtils.log('sender_to_id:${request.fields['sender_to_id']}');
      // FunctionUtils.log('file_length:${request.fields['file_length']}');

      if (files is List<File>) {
        //$_FILES
        int count = 1;
        for (var file in files) {
          var fileName = path.basename(file.path);
          request.fields['file${count}_name'] = fileName;
          //FunctionUtils.log('file${count}_name:${request.fields['file${count}_name']}');
          var picture = http.MultipartFile.fromBytes(
            'file$count',
            file.readAsBytesSync(),
            filename: fileName,
            //contentType: MediaType.parse('image/jpeg'),
          );
          request.files.add(picture);
          count++;
        }

        var response = await request.send();
        FunctionUtils.log(response.statusCode);
        if(response.statusCode == 200){
          var responseData = await response.stream.toBytes();
          var body = String.fromCharCodes(responseData);
          FunctionUtils.log(body);
          Map<String, dynamic> data = jsonDecode(body);
          if(!data.containsKey('error')) {
            return true;
          }else{
            error = data['error'];
            return false;
          }
        }else{
          error = 'statusCode ${response.statusCode}';
          return false;
        }
      }else{
        error = 'no List<File>';
        return false;
      }
    } catch (e) {
      FunctionUtils.log('sendUploadFile try catch error ===== $e');
    }
    return false;
  }

  ///メッセージ・グループメッセージ共通
  ///メッセージを全て既読
  static Future<bool> updateAllRead({
    required String domain,
    required String memberId,
  }) async {
    try {
      var url = Uri.parse('$domain/api/message/update_message_all_read.php');
      var response = await http.post(url, body: {
        'member_id': memberId,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if (data.containsKey('result')) {
          if(data['result'] == true) {
            FunctionUtils.log('すべて既読');
            return true;
          }else{
            FunctionUtils.log('すべて既読失敗');
          }
        } else {
          FunctionUtils.log('updateAllRead error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('updateAllRead statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('updateAllRead try catch error ===== $e');
    }
    return false;
  }
}
