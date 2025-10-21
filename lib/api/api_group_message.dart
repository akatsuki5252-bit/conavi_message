import 'dart:convert';
import 'dart:io';

import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/model/group_message.dart';
import 'package:conavi_message/model/group_message_file.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/message.dart';
import 'package:conavi_message/model/talk_group_member.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/upload_file.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiGroupMessages{

  ///グループメッセージルーム新規作成
  static Future<dynamic> createGroupRoom({
    required String domain, //ドメイン
    required String joinedMemberIds, //参加メンバーidをカンマ区切りした文字列
    required String groupName, //グループ名
    required String adminMemberId, //管理者メンバーid
    required File? uploadFile, //グループ画像
  }) async {
    try {
      //取得先URL
      var url = Uri.parse('$domain/api/message/create_group_room.php');
      //セット
      var request = http.MultipartRequest('POST', url);
      request.fields['joined_member_ids'] = joinedMemberIds;
      request.fields['group_name'] = groupName;
      request.fields['admin_member_id'] = adminMemberId;

      // print('createGroupRoom-joined_member_ids:'+joinedMemberIds);
      // print('createGroupRoom-group_name:'+groupName);
      // print('createGroupRoom-admin_member_id:'+adminMemberId);

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
      }
      //取得
      var response = await request.send();
      if(response.statusCode == 200){
        var responseData = await response.stream.toBytes();
        var body = utf8.decode(responseData);
        print(body);
        Map<String, dynamic> data = jsonDecode(body);
        //キーの存在チェック
        if (data.containsKey('rooms') && !data.containsKey('error')) {
          //参加メンバー
          List<TalkGroupMember> talkMembers = [];
          for (var member in data['rooms']['members']) {
            final talkMember = await ApiMembers.fetchProfile(
              domain: domain,
              memberId: member['member_id'],
            );
            if (talkMember is Member) {
              talkMembers.add(
                  TalkGroupMember(
                    member: talkMember,
                    state: member['state'],
                    isAdmin: member['is_admin'] == '1' ? true : false,
                    createTime: DateTime.parse(member['created']),
                    updateTime: DateTime.parse(member['modified']),
                  )
              );
            }
          }
          // for (var roomMember in roomMembers) {
          //   print(roomMember.id);
          //   print(roomMember.state);
          //   print(roomMember.isAdmin);
          //   print(roomMember.createTime);
          //   print(roomMember.updateTime);
          // }
          var talkDateTime = DateTime.now(); //ルームの更新時刻を現在の時刻に設定（仮）
          //取得したルーム情報の作成・更新時刻を挿入
          if(data['rooms']['room']['created'] != null) talkDateTime = DateTime.parse(data['rooms']['room']['created']);
          if(data['rooms']['room']['modified'] != null) talkDateTime = DateTime.parse(data['rooms']['room']['modified']);

          final talkGroupRoom = TalkGroupRoom(
            roomId: data['rooms']['room']['id'], //ルームid
            roomName: data['rooms']['group']['name'] ?? '', //ルーム名
            imagePath: data['rooms']['group']['image_path'] ?? '', //ルーム画像
            talkMembers: talkMembers, //メンバーリスト（※自身の情報を含む）
            createdTime: data['rooms']['room']['created'] != null ? DateTime.parse(data['rooms']['room']['created']) : DateTime.now(),
            modifiedTime: talkDateTime, //ルームの最新更新日付
          );

          print('グループルーム作成・取得完了');
          return talkGroupRoom;
        }
      }else{
        //リクエスト失敗（※送信は成功）
        print('createRoom statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('createRoom try catch error ===== $e');
    }
    return null;
  }

  ///グループ一覧情報を取得
  static Future<List<TalkGroupRoom>?> fetchJoinedGroupRooms({
    required Auth myAccount,
    required List<Member>? members,
  }) async {
    try {
      var url = Uri.parse('${myAccount.domain.url}/api/message/get_group_rooms.php');
      var response = await http.post(url, body: {
        'member_id': myAccount.member.id,
      });
      //print('fetchJoinedGroupRooms-member_id:'+myAccount.member.id);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //print(response.body);
        if (data.containsKey('rooms') && !data.containsKey('error')) {
          List<TalkGroupRoom> talkRooms = [];
          //int count = 0;
          for (var room in data['rooms']) {
            //print('count:'+count.toString());
            //print(room);
            if(room['room']['modified'] == null) continue;
            //参加メンバー
            List<TalkGroupMember> talkMembers = [];
            for (var member in room['members']) {
              Member? talkMember;
              String id = member['member_id'];
              if(id != myAccount.member.id) {
                if (members != null) {
                  for (var member in members) {
                    if (id == member.id) talkMember = member;
                  }
                }else{
                  talkMember = await ApiMembers.fetchProfile(
                    memberId: id,
                    domain: myAccount.domain.url,
                  );
                }
              }else{
                talkMember = myAccount.member;
              }
              if (talkMember is Member) {
                talkMembers.add(
                    TalkGroupMember(
                      member: talkMember,
                      state: member['state'],
                      isAdmin: member['is_admin'] == '1' ? true : false,
                      createTime: DateTime.parse(member['created']),
                      updateTime: member['modified'] != null ? DateTime.parse(member['modified']) : null,
                    )
                );
              }else{
                //メンバー情報が存在しない場合
                talkMembers.add(
                    TalkGroupMember(
                      member: Member(id: '', name: '削除されたユーザー', imagePath: '', selfIntroduction: ''),
                      state: '0',
                      isAdmin: false,
                      createTime: null,
                      updateTime: null,
                    )
                );
              }
            }
            try {
              final talkRoom = TalkGroupRoom(
                  roomId: room['room']['id'],
                  roomName: room['room']['name'] ?? '',
                  imagePath: room['room']['image_path'] != null && room['room']['image_path'] != '' ? '${myAccount.domain.url}/api/upload/file.php?group_room_id=${room['room']['id']}&app_token=${myAccount.member.appToken}' : '',
                  lastMessage: room['room']['last_message'] ?? '',
                  talkMembers: talkMembers,
                  createdTime: room['room']['created'] != null ? DateTime.parse(room['room']['created']) : DateTime.now(),
                  modifiedTime: DateTime.parse(room['room']['modified']),
                  lastSendTime: FunctionUtils.createLastSendTime(room['room']['modified']),
                  countUnRead: room['room']['unread_count'] != null ? int.parse(room['room']['unread_count']) : 0,
                  isEntry : room['room']['state'] == '2' ? true : false
              );
              talkRooms.add(talkRoom);
            }catch(e){
              print('fetchJoinedGroupRooms room try catch error ===== $e');
            }
            //count++;
          }

          //並び順
          talkRooms.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));

          //print('talkRooms-length'+talkRooms.length.toString());

          return talkRooms;
        } else {
          print('fetchJoinedGroupRooms error ===== ${data['error']}');
        }
      } else {
        print('fetchJoinedGroupRooms statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('fetchJoinedGroupRooms try catch error ===== $e');
    }
    return null;
  }

  ///グループ単体情報を取得
  static Future<TalkGroupRoom?> fetchGroupRoom({
    required Auth myAccount,
    required String roomId,
  }) async {
    try {
      var url = Uri.parse('${myAccount.domain.url}/api/message/get_group_room.php');
      var response = await http.post(url, body: {
        'room_id': roomId,
        'member_id' : myAccount.member.id,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if (data.containsKey('rooms') && !data.containsKey('error')) {
          var room = data['rooms'];
          print(room);

          //参加メンバー
          List<TalkGroupMember> talkMembers = [];
          for (var member in room['members']) {
            Member? talkMember;
            String memberId = member['member_id'];
            if (memberId != myAccount.member.id) {
              talkMember = await ApiMembers.fetchProfile(
                domain: myAccount.domain.url,
                memberId: memberId,
              );
            } else {
              talkMember = myAccount.member;
            }
            if (talkMember is Member) {
              talkMembers.add(
                TalkGroupMember(
                  member: talkMember,
                  state: member['state'],
                  isAdmin: member['is_admin'] == '1' ? true : false,
                  createTime: DateTime.parse(member['created']),
                  updateTime: member['modified'] != null ? DateTime.parse(member['modified']) : null,
                ),
              );
            } else {
              //メンバー情報が存在しない場合
              talkMembers.add(
                TalkGroupMember(
                  member: Member(id: '', name: '削除されたユーザー', imagePath: '', selfIntroduction: ''),
                  state: '0',
                  isAdmin: false,
                  createTime: null,
                  updateTime: null,
                ),
              );
            }
          }

          final talkRoom = TalkGroupRoom(
            roomId: room['room']['id'],
            roomName: room['room']['name'] ?? '',
            imagePath: room['room']['image_path'] != null && room['room']['image_path'] != '' ? '${myAccount.domain.url}/api/upload/file.php?group_room_id=${room['room']['id']}&app_token=${myAccount.member.appToken}' : '',
            lastMessage: room['room']['last_message'] ?? '',
            talkMembers: talkMembers,
            createdTime: room['room']['created'] != null ? DateTime.parse(room['room']['created']) : DateTime.now(),
            modifiedTime: DateTime.parse(room['room']['modified']),
            lastSendTime: FunctionUtils.createLastSendTime(room['room']['modified']),
            countUnRead: 0,
            isEntry : room['room']['state'] == '2' ? true : false,
          );
          return talkRoom;

        } else {
          print('fetchGroupRoom error ===== ${data['error']}');
        }
      } else {
        print('fetchGroupRoom statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('fetchGroupRoom try catch error ===== $e');
    }
    return null;
  }

  //グループメッセージ一覧
  static Future<List<GroupMessage>?> fetchGroupMessages({
    required Auth myAccount,
    required TalkGroupRoom talkRoom,
  }) async {
    try {
      var url = Uri.parse('${myAccount.domain.url}/api/message/get_group_messages.php');
      var response = await http.post(url, body: {
        'room_id': talkRoom.roomId,
        'member_id': myAccount.member.id
      });
      //print('room_id:'+talkRoom.roomId);
      //print('member_id:'+myAccount.member.id);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        print(response.body);
        if (data.containsKey('room_messages') && !data.containsKey('error')) {
          List<GroupMessage> messages = [];
          for (var roomMessage in data['room_messages']) {
            Member? talkMember;
            //print(talkRoom.talkMembers);
            //print(roomMessage);
            for(var roomMember in talkRoom.talkMembers){
              if(roomMember.member != null) {
                if (roomMessage['from_member_id'] == roomMember.member!.id) {
                  talkMember = roomMember.member;
                }
              }
            }
            //print(talkMember);
            talkMember ??= Member(
              id: '',
              name: '削除されたユーザー',
              imagePath: '',
              selfIntroduction: '',
            );

            List<GroupMessageFile> groupMessageFiles = [];
            if(roomMessage['files'] != null) {
              for (var groupMessageFile in roomMessage['files']) {
                groupMessageFiles.add(
                  GroupMessageFile(
                    id: groupMessageFile['id'],
                    name: groupMessageFile['file_name'],
                    url: '${myAccount.domain.url}/api/upload/file.php?group_message_file_id=${groupMessageFile['id']}&app_token=${myAccount.member.appToken}',
                    extension: groupMessageFile['file_ext'],
                    createTime: DateTime.parse(roomMessage['created']),
                    updateTime: groupMessageFile['modified'] != null ? DateTime.parse(groupMessageFile['modified']) : null,
                  )
                );
              }
            }

            final GroupMessage message = GroupMessage(
              id: roomMessage['id'] ?? '',
              type: roomMessage['message_type'] ?? '',
              message: roomMessage['message'] ?? '',
              member: talkMember,
              isFile: roomMessage['is_file'] == '1' ? true : false,
              files: groupMessageFiles,
              isMe: talkMember != null && talkMember.id == myAccount.member.id ? true : false,
              readCount: roomMessage['read_count'] != null && int.tryParse(roomMessage['read_count']) != null ? int.parse(roomMessage['read_count']) : 0,
              sendTime: DateTime.parse(roomMessage['created']),
            );
            messages.add(message);
          }
          return messages;
        } else if(data.containsKey('error')){
          print('fetchGroupMessages error ===== ${data['error']}');
        } else{
          print('fetchGroupMessages empty');
        }
      } else {
        print('fetchGroupMessages statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('fetchGroupMessages try catch error ===== $e');
    }
    return null;
  }

  ///グループメンバー一覧
  static Future<List<TalkGroupMember>?> fetchGroupMembers({
    required Auth myAccount,
    required String roomId,
  }) async {
    try {
      var url = Uri.parse('${myAccount.domain.url}/api/message/get_group_members.php');
      var response = await http.post(url, body: {
        'room_id': roomId,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        print(response.body);
        if (data.containsKey('rooms') && !data.containsKey('error')) {
          //参加メンバー
          List<TalkGroupMember> talkMembers = [];
          //参加人数分ループ
          for (var roomMember in data['rooms']['members']) {
            Member? talkMember;
            if(roomMember['member_id'] != myAccount.member.id) {
              talkMember = await ApiMembers.fetchProfile(
                memberId: roomMember['member_id'],
                domain: myAccount.domain.url,
              );
            }else{
              talkMember = myAccount.member;
            }
            if (talkMember is Member) {
              talkMembers.add(
                  TalkGroupMember(
                    member: talkMember,
                    state: roomMember['state'],
                    isAdmin: roomMember['is_admin'] == '1' ? true : false,
                    createTime: DateTime.parse(roomMember['created']),
                    updateTime: roomMember['modified'] != null ? DateTime.parse(roomMember['modified']) : null,
                  )
              );
            }else{
              //メンバー情報が存在しない場合
              talkMembers.add(
                  TalkGroupMember(
                    member: Member(id: '', name: '削除されたユーザー', imagePath: '', selfIntroduction: ''),
                    state: '0',
                    isAdmin: false,
                    createTime: null,
                    updateTime: null,
                  )
              );
            }
          }
          return talkMembers;
        } else {
          print('fetchGroupMembers error ===== ${data['error']}');
        }
      } else {
        print('fetchGroupMembers statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('fetchGroupMembers try catch error ===== $e');
    }
    return null;
  }

  //グループに参加・拒否
  static Future<dynamic> updateRoomMemberState({
    required String domain, //ドメイン
    required String roomId, //ルームid
    required String memberId, //ルームメンバーid
    required String state, //状態
    required String deleteMemberId, //削除実行するルームメンバーid
    }) async {
    try {
      var url = Uri.parse('$domain/api/message/update_group_member_state.php');
      var response = await http.post(url, body: {
        'room_id': roomId,
        'member_id': memberId,
        'state': state,
        'delete_member_id': deleteMemberId,
      });
      if (response.statusCode == 200) {
        print(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('result')) {
          print('グループ参加・拒否更新');
          if(data['result'] == true) {
            return true;
          }else{
            return false;
          }
        } else {
          print('updateRoomMemberState error ===== ${data['error']}');
        }
      }else{
        print('updateRoomMemberState statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('updateRoomMemberState try catch error ===== $e');
    }
    return null;
  }

  //グループから削除
  static Future<dynamic> deleteRoomMember({
    required String domain, //ドメイン
    required String roomId, //ルームid
    required String memberId, //ルームメンバーid
    required String deleteMemberId, //削除するメンバーid
  }) async {
    try {
      var url = Uri.parse('$domain/api/message/delete_group_member.php');
      var response = await http.post(url, body: {
        'room_id': roomId,
        'member_id': memberId,
        'delete_member_id': deleteMemberId,
      });
      print('member_id:$memberId');
      print('delete_member_id:$deleteMemberId');
      if (response.statusCode == 200) {
        print(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('result')) {
          print('グループから退会');
          if(data['result'] == true) {
            return true;
          }else{
            return false;
          }
        } else {
          print('updateRoomMemberState error ===== ${data['error']}');
        }
      }else{
        print('updateRoomMemberState statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('updateRoomMemberState try catch error ===== $e');
    }
    return null;
  }

  //グループにメンバーを招待
  static Future<dynamic> inviteGroupMembers({
    required String domain, //ドメイン
    required String roomId, //ルームid
    required String inviteJoinedMemberIds, //招待メンバーidをカンマ区切りした文字列
    required String inviteMemberId, //招待したメンバーid
  }) async {
    try {
      //接続先URL
      var url = Uri.parse('$domain/api/message/invite_group_members.php');
      //print(url);
      var response = await http.post(url, body: {
        'room_id': roomId,
        'invite_joined_member_ids': inviteJoinedMemberIds,
        'invite_member_id': inviteMemberId,
      });

      //print(response);

      if (response.statusCode == 200) {
        print(response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('result')) {
          print('グループに招待');
          if(data['result'] == true) {
            return true;
          }else{
            return false;
          }
        } else {
          print('inviteGroupMembers error ===== ${data['error']}');
        }
      }else{
        print('inviteGroupMembers statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      //リクエスト送信失敗
      print('inviteGroupMembers try catch error ===== $e');
    }
    return null;
  }

  static Future<bool> sendMessage({
    required String domain,
    required String roomId,
    required String message,
    required String sendMemberFromId,
  }) async {

    try {
      var url = Uri.parse('$domain/api/message/send_group_message.php');
      var response = await http.post(url, body: {
        'room_id': roomId,
        'message': message,
        'send_from_id': sendMemberFromId,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        //print(response.body);
        if (!data.containsKey('error')) {
          print('メッセージの送信成功');
          return true;
        } else {
          print('sendMessage error ===== ${data['error']}');
        }
      } else {
        print('sendMessage statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('sendMessage try catch error ===== $e');
    }
    return false;
  }

  static Future<bool> sendUploadFile({
    required String domain,
    required String roomId,
    required String sendMemberFromId,
    required List<dynamic> files,
  }) async {

    try {
      var url = Uri.parse('$domain/api/upload/upload_group_message.php');
      var request = http.MultipartRequest('POST', url);
      //$_POST
      request.fields['room_id'] = roomId;
      request.fields['send_from_id'] = sendMemberFromId;
      request.fields['file_length'] = files.length.toString();

      // print('room_id:${request.fields['room_id']}');
      // print('sender_from_id:${request.fields['sender_from_id']}');
      // print('sender_to_id:${request.fields['sender_to_id']}');
      // print('file_length:${request.fields['file_length']}');

      if (files is List<File>) {
        //$_FILES
        int count = 1;
        for (var file in files) {
          var fileName = path.basename(file.path);
          request.fields['file${count}_name'] = fileName;
          //print('file${count}_name:${request.fields['file${count}_name']}');
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
        print(response.statusCode);
        if(response.statusCode == 200){
          var responseData = await response.stream.toBytes();
          var body = String.fromCharCodes(responseData);
          print(body);
          Map<String, dynamic> data = jsonDecode(body);
          if(!data.containsKey('error')) {
            return true;
          }else{
            print('sendUploadFile error ===== ${data['error']}');
            return false;
          }
        }else{
          print('sendUploadFile statusCode error ===== ${response.statusCode}');
          return false;
        }
      }else{
        print('sendUploadFile error ===== no List<File>');
        return false;
      }
    } catch (e) {
      print('sendUploadFile try catch error ===== $e');
    }
    return false;
  }

  ///グループ設定を更新
  static Future<bool> updateGroupRoom({
    required String domain,
    required String roomId,
    required String roomName,
    required File? uploadFile,
  }) async {
    try {
      var url = Uri.parse('$domain/api/message/update_group_room.php');
      var request = http.MultipartRequest('POST', url);
      //$_POST
      request.fields['room_id'] = roomId;
      //グループ名
      if(roomName.isNotEmpty){
        request.fields['room_name'] = roomName;
      }
      //$_FILES（グループ画像）
      if (uploadFile is File) {
        var fileName = path.basename(uploadFile.path);
        request.fields['file_name'] = fileName;
        var picture = http.MultipartFile.fromBytes(
          'file',
          uploadFile.readAsBytesSync(),
          filename: fileName,
          //contentType: MediaType.parse('image/jpeg'),
        );
        request.files.add(picture);
      }
      var response = await request.send();
      //print(response.statusCode);
      if(response.statusCode == 200){
        var responseData = await response.stream.toBytes();
        var body = String.fromCharCodes(responseData);
        print(body);
        Map<String, dynamic> data = jsonDecode(body);
        if(!data.containsKey('error')) {
          return true;
        }else{
          print('updateGroupImageFile error ===== ${data['error']}');
        }
      }else{
        print('updateGroupImageFile statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      print('updateGroupImageFile try catch error ===== $e');
    }
    return false;
  }
}