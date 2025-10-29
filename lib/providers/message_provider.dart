import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/model/group_message.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/message.dart' as ms;
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

final membersFutureProvider = FutureProvider<List<Member>?>((ref) async {
  Auth myAccount = ref.read(authProvider);
  List<Member>? membersList = [];
  if(myAccount.domain.url.isNotEmpty) {
    membersList = await ApiMembers.fetchMembers(
      domain: myAccount.domain.url,
      domainId: myAccount.domain.id,
      mid: myAccount.member.id,
    );
  }
  DateTime now = DateTime.now();
  DateFormat outputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String date = outputFormat.format(now);
  FunctionUtils.log('membersFutureProvider:$date');
  return membersList;
});

//未読メッセージカウント
final countMessageUnReadProvider = StateProvider((ref) => 0);

final talkRoomsFutureProvider = FutureProvider<List<TalkRoom>?>((ref) async {
  Auth myAccount = ref.read(authProvider);
  List<Member>? membersList = [];
  List<TalkRoom>? talkRoomsList = [];
  if(myAccount.domain.url.isNotEmpty) {
    membersList = await ApiMembers.fetchMembers(
      domain: myAccount.domain.url,
      domainId: myAccount.domain.id,
      mid: myAccount.member.id,
    );
    if(membersList != null) {
      talkRoomsList = await ApiMessages.fetchJoinedRooms(
          myAccount: myAccount,
          members: membersList
      );
      if (talkRoomsList != null) {
        int countUnRead = 0;
        for (var talkRoom in talkRoomsList) {
          countUnRead += talkRoom.countUnRead;
        }
        ref.read(countMessageUnReadProvider.notifier).state = countUnRead;
      }
    }
  }
  DateTime now = DateTime.now();
  DateFormat outputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String date = outputFormat.format(now);
  FunctionUtils.log('talkRoomsFutureProvider:$date');
  return talkRoomsList;
});

final talkMessagesFutureProvider = FutureProvider.autoDispose.family<List<ms.Message>?,TalkRoom>((ref,talkRoom) async {
  Auth myAccount = ref.read(authProvider);
  final talkMessageList = await ApiMessages.fetchMessages(
      talkRoom: talkRoom,
      myAccount: myAccount,
  );
  DateTime now = DateTime.now();
  DateFormat outputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String date = outputFormat.format(now);
  FunctionUtils.log('talkMessagesFutureProvider:$date');
  return talkMessageList;
});

//未読グループメッセージカウント
final countGroupMessageUnReadProvider = StateProvider((ref) => 0);

final talkGroupRoomsFutureProvider = FutureProvider<List<TalkGroupRoom>?>((ref) async {
  Auth myAccount = ref.read(authProvider);
  List<Member>? membersList = [];
  List<TalkGroupRoom>? talkRoomsList = [];
  if(myAccount.domain.url.isNotEmpty) {
    membersList = await ApiMembers.fetchMembers(
      domain: myAccount.domain.url,
      domainId: myAccount.domain.id,
      mid: myAccount.member.id,
    );
    if(membersList != null) {
      talkRoomsList = await ApiGroupMessages.fetchJoinedGroupRooms(
          myAccount: myAccount,
          members: membersList
      );
      if (talkRoomsList != null) {
        int countUnRead = 0;
        for (var talkRoom in talkRoomsList) {
          countUnRead += talkRoom.countUnRead;
        }
        ref.read(countGroupMessageUnReadProvider.notifier).state = countUnRead;
      }
    }
  }
  DateTime now = DateTime.now();
  DateFormat outputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String date = outputFormat.format(now);
  FunctionUtils.log('talkGroupRoomsFutureProvider:$date');
  return talkRoomsList;
});

final talkGroupMessagesFutureProvider = FutureProvider.autoDispose.family<List<GroupMessage>?,TalkGroupRoom>((ref,talkRoom) async {
  Auth myAccount = ref.read(authProvider);
  final talkMessageList = await ApiGroupMessages.fetchGroupMessages(
    talkRoom: talkRoom,
    myAccount: myAccount,
  );
  DateTime now = DateTime.now();
  DateFormat outputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String date = outputFormat.format(now);
  FunctionUtils.log('talkGroupMessagesFutureProvider:$date');
  return talkMessageList;
});