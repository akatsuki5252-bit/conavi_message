import 'package:conavi_message/model/member.dart';

class TalkGroupMember {
  Member? member;
  String state = '';
  bool isAdmin = false;
  DateTime? createTime;
  DateTime? updateTime;

  TalkGroupMember({
    required this.member,
    required this.state,
    required this.isAdmin,
    this.createTime,
    this.updateTime,
  });
}
