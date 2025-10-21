import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/setting/user_setting.dart';
import 'package:flutter_riverpod/legacy.dart';

//下部メニュー番号
final selectedBottomMenuIndexProvider = StateProvider((ref) => UserSetting().currentBottomNavigationIndex);
//選択中メッセージ画面タブ番号
final selectedMessageTabIndexProvider = StateProvider((ref) => UserSetting().currentMessageTabIndex);
//選択中メッセージルーム情報
final selectedMessageRoomProvider = StateProvider((ref) => UserSetting().currentMessageRoom);
//選択中グループメッセージルーム情報
final selectedGroupMessageRoomProvider = StateProvider((ref) => UserSetting().currentGroupMessageRoom);
//下部メニューメッセージ通知バッチ
final bottomNavigationMessageBadgeProvider = StateProvider((ref){
  int countMessageUnRead = ref.watch(countMessageUnReadProvider);
  int countGroupMessageUnRead = ref.watch(countGroupMessageUnReadProvider);
  return countMessageUnRead + countGroupMessageUnRead;
});
//アプリ通知バッチ
final appBadgeProvider = StateProvider((ref) => 0);
//ファイル閲覧フラグ
final isFilePreviewFlagProvider = StateProvider((ref) => UserSetting().currentFilePreviewFlag);
//通知設定
final isLocalNotificationProvider = StateProvider((ref) => UserSetting().localNotificationFlag);
//メッセージルーム並び順
final selectedMessageSortProvider = StateProvider((ref) => UserSetting().currentMessageSort);