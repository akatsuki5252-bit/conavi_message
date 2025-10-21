import 'package:conavi_message/model/talk_group_member.dart';

class TalkGroupRoom {
  String roomId;
  String roomName;
  String lastMessage;
  String imagePath;
  String lastSendTime;
  DateTime createdTime;
  DateTime modifiedTime;
  int countUnRead;
  bool isEntry;

  List<TalkGroupMember> talkMembers;

  TalkGroupRoom({
    required this.roomId,
    required this.talkMembers,
    required this.createdTime,
    required this.modifiedTime,
    this.roomName = '',
    this.lastMessage = '',
    this.imagePath = '',
    this.lastSendTime = '',
    this.countUnRead = 0,
    this.isEntry = false});
}
