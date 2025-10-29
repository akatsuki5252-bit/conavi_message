import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/shared_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditNotificationPage extends ConsumerStatefulWidget {
  const EditNotificationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EditNotificationPage> createState() => _EditNotificationPageState();
}

class _EditNotificationPageState extends ConsumerState<EditNotificationPage> {

  bool _active = false;

  @override
  void initState() {
    super.initState();
    Auth myAccount = ref.read(authProvider);
    FunctionUtils.log(myAccount.userSetting.localNotificationFlag);
    FunctionUtils.log(SharedPrefs.fetch(name: 'localNotificationFlag'));
    _active = myAccount.userSetting.localNotificationFlag == true ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    Auth myAccount = ref.watch(authProvider);
    return Scaffold(
        appBar: AppBar(
          title: const Text('通知設定', style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
          centerTitle: false,
        ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Material(
                color: Colors.white,
                shape: const Border(
                  bottom: BorderSide(color: Color(0xffC0C0C0),width: 1),
                ),
                child: SwitchListTile(
                  title: const Text('メッセージを通知する'),
                  value: _active,
                  activeColor: const Color(0xff3166f7),
                  onChanged: _switchLocalNotification,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchLocalNotification(bool flag){
    setState(() => _active = flag);
    ref.read(isLocalNotificationProvider.notifier).state = flag;
    //プリファレンスに保存
    SharedPrefs.set(name: 'localNotificationFlag', value: flag == true ? '1' : '');
  }

  void _changeSwitch(bool e) async{
    setState(() => _active = e);
    //ローディング
    EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
    EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
    EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
    await EasyLoading.show(
      status: '処理中...',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.black,
    );
    var account = await updateAccount(_active);
    if (account is Member) {
      ref.read(userProvider.notifier).state = account;
      EasyLoading.dismiss();
    } else {
      EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
      EasyLoading.showError(
        '保存に失敗しました',
        dismissOnTap: true,
        maskType: EasyLoadingMaskType.black,
      );
    }
  }

  Future<Member?> updateAccount(bool notifyEmailFlag) async {
    Auth myAccount = ref.watch(authProvider);
    Member updateAccount = Member(
      id: myAccount.member.id,
      name: myAccount.member.name,
      selfIntroduction:myAccount.member.selfIntroduction,
      imagePath: myAccount.member.imagePath,
      notifyEmailFlag: notifyEmailFlag == true ? '1' : '0',
    );
    return await ApiMembers.updateMember(
        updateAccount: updateAccount,
        domain: myAccount.domain.url
    );
  }
}
