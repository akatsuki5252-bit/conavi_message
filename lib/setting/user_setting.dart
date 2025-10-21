import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/model/talk_room.dart';

class UserSetting {
  int currentBottomNavigationIndex = 0; //メニュー番号
  int currentMessageTabIndex = 1; //メッセージ画面タブ番号
  bool currentFilePreviewFlag = false; //ファイル閲覧フラグ
  TalkRoom? currentMessageRoom; //現在表示中のメッセージルーム情報
  TalkGroupRoom? currentGroupMessageRoom; //現在表示中のグループメッセージルーム情報
  bool localNotificationFlag = true;
  MessageSort currentMessageSort = MessageSort.time;
  bool isAppUpdate = false; //アプリ強制アップデート

  UserSetting();
}