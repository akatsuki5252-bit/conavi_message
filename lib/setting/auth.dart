import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/setting/domain.dart';
import 'package:conavi_message/setting/user_setting.dart';

class Auth {
  // String domain;
  // String domainId;
  Domain domain;
  Member member;
  UserSetting userSetting;

  Auth({
    required this.domain,
    required this.member,
    required this.userSetting,
  });
}