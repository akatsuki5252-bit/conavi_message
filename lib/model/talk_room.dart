import 'package:conavi_message/model/member.dart';

class TalkRoom {
  String roomId;
  List<Member> talkMembers;
  String roomName;
  String lastMessage;
  String lastSendFileFromMemberId;
  String imagePath;
  DateTime createdTime;
  DateTime modifiedTime;
  String lastSendTime;
  int countUnRead;

  TalkRoom({
    required this.roomId,
    required this.talkMembers,
    this.roomName = '',
    this.lastMessage = '',
    this.lastSendFileFromMemberId = '',
    this.imagePath = '',
    required this.createdTime,
    required this.modifiedTime,
    this.lastSendTime = '',
    this.countUnRead = 0});
}
