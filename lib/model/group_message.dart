import 'package:conavi_message/model/group_message_file.dart';
import 'package:conavi_message/model/member.dart';

//グループメッセージ用メッセージ
class GroupMessage {
  String id; //id
  String type; //1.ユーザーメッセージ、2.システムメッセージ
  String message; //メッセージ
  Member? member; //送信者メンバー情報
  bool isFile; //ファイル判定フラグ
  List<GroupMessageFile>? files;
  bool isMe; //投稿者判定フラグ
  int readCount; //既読カウント
  DateTime sendTime; //送信時間
  //コンストラクタ
  GroupMessage({
    required this.id,
    required this.type,
    required this.message,
    required this.member,
    required this.isFile,
    required this.files,
    required this.isMe,
    required this.readCount,
    required this.sendTime,
  });
}
