import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/setting/domain.dart';
import 'package:conavi_message/setting/user_setting.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

final authProvider = StateProvider<Auth>((ref) {

  Member account = ref.watch(userProvider);
  Domain domain = ref.read(domainProvider);
  UserSetting userSetting = ref.watch(userSettingProvider);
  userSetting.currentBottomNavigationIndex = ref.watch(selectedBottomMenuIndexProvider);
  userSetting.currentMessageTabIndex = ref.watch(selectedMessageTabIndexProvider);
  userSetting.currentMessageRoom = ref.watch(selectedMessageRoomProvider);
  userSetting.currentGroupMessageRoom = ref.watch(selectedGroupMessageRoomProvider);
  userSetting.currentFilePreviewFlag = ref.watch(isFilePreviewFlagProvider);
  userSetting.localNotificationFlag = ref.watch(isLocalNotificationProvider);
  userSetting.currentMessageSort = ref.watch(selectedMessageSortProvider);
  // print('userSetting.currentMessageRoom:${userSetting.currentMessageRoom}');
  // print('userSetting.currentFilePreviewFlag:${userSetting.currentFilePreviewFlag}');

  DateTime now = DateTime.now();
  DateFormat outputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  String date = outputFormat.format(now);
  print('authProvider:$date');

  return Auth(
    domain: domain,
    member: account,
    userSetting: userSetting,
  );
});

final userProvider = StateProvider<Member>((ref) {
  return Member(id: '', name: '', imagePath: '', selfIntroduction: '');
});

final domainProvider = StateProvider((ref) {
  return Domain(id: '',url: '');
});

final userSettingProvider = StateProvider((ref) {
  return UserSetting();
});

final todoListNotifierProvider = StateNotifierProvider<MenuSelectedIndexNotifier,UserSetting>((ref) => MenuSelectedIndexNotifier(UserSetting()));

class MenuSelectedIndexNotifier extends StateNotifier<UserSetting>{
  MenuSelectedIndexNotifier(super.state);
  //MenuSelectedIndex(UserSetting setting): super(setting);

  void test(){
    state.currentBottomNavigationIndex = 2;
  }

  void increment() => state.currentBottomNavigationIndex + 1;
}


final userSettingProvider2 = StateProvider((ref) {
  return UserSetting();
});