///メッセージ：オプション
enum MessageOption{
  copy,
  delete
}
///メッセージ：タブ
enum MessageTab{
  member,
  message,
  groupMessage
}
///メッセージ：設定
enum MessageSetting{
  sort,
  allRead
}
///メッセージ：設定
enum MessageSort{
  time,
  unRead,
}
///メッセージ：ファイルタイプ
enum MessageFileType{
  image,
  file
}
///下部メニュー
enum BottomNavigationMenu{
  message,
  profile
}
///メッセージ種別
enum MessageType{
  message,
  group
}
///グループメッセージ操作ダイアログ用
enum GroupMessageAction{
  member, //メンバー
  invite, //招待
  withdrawal, //退会
  setting, //設定
}
///グループメンバー状態
enum GroupMessageMemberState{
  invite, //招待：1
  approval, //承認：2
  reject, //拒否：3
  withdrawal, //退会：4
  delete, //削除：5
}
enum UserEdit{
  delete, //アカウント削除：1
}