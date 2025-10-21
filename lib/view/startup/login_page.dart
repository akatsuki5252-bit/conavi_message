import 'package:conavi_message/api/api_communitys.dart';
import 'package:conavi_message/api/api_domains.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/setting/create_member.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/invite_code/create_member_page.dart';
import 'package:conavi_message/view/screen.dart';
import 'package:conavi_message/view/community/create_community_page.dart';
import 'package:conavi_message/view/startup/password_reset_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _conaviIdController = TextEditingController(); //コナビId
  final TextEditingController _emailController = TextEditingController(); //メールアドレス
  final TextEditingController _passController = TextEditingController(); //パスワード
  final TextEditingController _inviteCodeController = TextEditingController(); //招待コード
  final FocusNode _conaviIdFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _inviteCodeFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true; //パスワード非表示
  String _version = ''; //バージョン

  Future getVer() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'Ver.${packageInfo.version}';
    });
  }

  @override
  void initState() {
    super.initState();
    getVer();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(membersFutureProvider);
    ref.read(talkRoomsFutureProvider);
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width > 600 ? 600 : double.infinity,
                  height: MediaQuery.of(context).size.height,
                  padding: const EdgeInsets.only(left: 20,right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 150,
                            height: 70,
                            padding: const EdgeInsets.only(bottom:20),
                            child: Image.asset('assets/logo.png',fit: BoxFit.contain),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff3166f7),
                              border: Border.all(color: const Color(0xffc6d3f7),width: 3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.only(left: 15,top: 10,right: 15,bottom: 10),
                            child: Column(
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: const Text('Conavi ID',style: TextStyle(fontSize:13,color: Colors.white)),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 42,
                                      child: TextFormField(
                                        focusNode: _conaviIdFocusNode,
                                        controller: _conaviIdController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(5), //5文字制限
                                          FilteringTextInputFormatter.digitsOnly, //数字のみ
                                        ],
                                        //maxLength: 5,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        textInputAction: TextInputAction.next,
                                        cursorColor: const Color(0xff0043f8),
                                        validator: (String? value) {
                                          // if (value == null || value.isEmpty) {
                                          //   return 'コナビIDを入力してください';
                                          // }
                                          // if (value.length < 5) {
                                          //   return '5桁のコナビIDを入力してください';
                                          // }
                                          return null;
                                        },
                                        decoration: WidgetUtils.inputDecoration(icon: Icons.home_outlined, hintTxt: 'コナビID',color: const Color(0xff0043f8)),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 7.0),
                                  child: Column(
                                    children: [
                                      Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(bottom: 3),
                                        child: const Text('Email',style: TextStyle(fontSize:13,color: Colors.white)),
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 42,
                                        child: TextFormField(
                                          focusNode: _emailFocusNode,
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          autovalidateMode: AutovalidateMode.onUserInteraction,
                                          textInputAction: TextInputAction.next,
                                          cursorColor: const Color(0xff0043f8),
                                          validator: (String? value) {
                                            // if (value == null || value.isEmpty) {
                                            //   return 'メールアドレスを入力してください';
                                            // }
                                            return null;
                                          },
                                          decoration: WidgetUtils.inputDecoration(icon: Icons.mail_outline, hintTxt: 'メールアドレス',color: const Color(0xff0043f8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: const Text('Password',style: TextStyle(fontSize:13,color: Colors.white)),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 42,
                                      child: TextFormField(
                                        focusNode: _passFocusNode,
                                        obscureText: _isObscure,
                                        controller: _passController,
                                        keyboardType: TextInputType.visiblePassword,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        cursorColor: const Color(0xff0043f8),
                                        validator: (String? value) {
                                          // if (value == null || value.isEmpty) {
                                          //   return 'パスワードを入力してください';
                                          // }
                                          return null;
                                        },
                                        decoration: WidgetUtils.inputDecoration(
                                          icon: Icons.lock_outline,
                                          hintTxt: 'パスワード',
                                          color: const Color(0xff0043f8),
                                          isSuffix : true,
                                          isObscure: _isObscure,
                                          actionSuffix: () async {
                                            setState(() {
                                              _isObscure = !_isObscure;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(top: 10,bottom: 15),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'パスワードを忘れた方はこちら',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          try {
                                            //パスワード再設定画面へ移動
                                            Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => const PasswordResetPage()),
                                            );
                                          } catch (e) {
                                            print('error url_launch:$e');
                                          }
                                        },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      //フォーカスを外す
                                      _conaviIdFocusNode.unfocus();
                                      _emailFocusNode.unfocus();
                                      _passFocusNode.unfocus();
                                      //入力チェック
                                      if (_formKey.currentState!.validate()) {
                                        //ローディングを表示
                                        Loading.show(message: '認証中...', isDismissOnTap: false);
                                        //入力エラーチェック
                                        if(_conaviIdController.text.isEmpty){
                                          Loading.error(message: 'コナビIDを入力してください');
                                          return;
                                        }
                                        if(_conaviIdController.text.length < 5){
                                          Loading.error(message: '5桁のコナビIDを入力してください');
                                          return;
                                        }
                                        if(_emailController.text.isEmpty){
                                          Loading.error(message: 'メールアドレスを入力してください');
                                          return;
                                        }
                                        if(_passController.text.isEmpty){
                                          Loading.error(message: 'パスワードを入力してください');
                                          return;
                                        }
                                        //認証
                                        Result? result = await Authentication.signIn(
                                          conaviId: _conaviIdController.text,
                                          email: _emailController.text,
                                          password: _passController.text,
                                          appToken: '',
                                        );
                                        //認証チェック
                                        if (result != null && result.isSuccess) {
                                          Auth? account = result.account!;
                                          //初期化
                                          ref.invalidate(membersFutureProvider);
                                          ref.invalidate(talkRoomsFutureProvider);
                                          ref.invalidate(talkGroupRoomsFutureProvider);
                                          ref.read(userProvider.notifier).state  = account.member;
                                          ref.read(domainProvider.notifier).state  = account.domain;
                                          ref.read(userSettingProvider.notifier).state = account.userSetting;
                                          ref.read(selectedBottomMenuIndexProvider.notifier).state = account.userSetting.currentBottomNavigationIndex;
                                          ref.read(bottomNavigationMessageBadgeProvider.notifier).state = 0;
                                          //Authentication.myAccount = account;
                                          //ローディングを終了
                                          Loading.dismiss();
                                          if (!context.mounted) return;
                                          while (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          }
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const Screen(),
                                            ),
                                          );
                                        } else {
                                          Loading.error(message:result?.error ?? '認証に失敗しました');
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xfff8b500), //ボタンの背景色
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                    ),
                                    child: const Text('ログイン', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      //招待コードをクリア
                                      _inviteCodeController.clear();
                                      //フォーカスを外す
                                      _conaviIdFocusNode.unfocus();
                                      _emailFocusNode.unfocus();
                                      _passFocusNode.unfocus();
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => CustomAlertDialog(
                                          title: '招待コードを入力',
                                          contentWidget: SizedBox(
                                            height: 36,
                                            child: TextFormField(
                                              autofocus: false,
                                              controller: _inviteCodeController,
                                              keyboardType: TextInputType.emailAddress,
                                              autovalidateMode: AutovalidateMode.onUserInteraction,
                                              textInputAction: TextInputAction.done,
                                              cursorColor: Colors.black,
                                              decoration: WidgetUtils.inputDecoration(icon: null, hintTxt: '',color: Colors.black),
                                            ),
                                          ),
                                          cancelActionText: 'キャンセル',
                                          cancelAction: () {},
                                          defaultActionText: 'OK',
                                          action: () async {
                                            if(_inviteCodeController.text.isNotEmpty){
                                              //ローディングを表示
                                              Loading.show(message: '招待コードを確認中...', isDismissOnTap: false);
                                              //招待コードを確認
                                              var resultInviteCode = await ApiDomains.checkInviteCode(inviteCode: _inviteCodeController.text,checked: '');
                                              if(resultInviteCode is Result && resultInviteCode.isSuccess && resultInviteCode.data.containsKey('conaviId')){
                                                String conaviId = resultInviteCode.data['conaviId'].toString();
                                                //ローディング終了
                                                Loading.dismiss();
                                                if (!context.mounted) return;
                                                //新規メンバー登録画面へ移動
                                                var resultMember = await Navigator.push(context,
                                                  MaterialPageRoute(builder: (context) => CreateMemberPage(
                                                    conaviId: conaviId,
                                                    inviteCode: _inviteCodeController.text,
                                                  ),),
                                                );
                                                if(resultMember is CreateMember) {
                                                  print(resultMember.conaviId);
                                                  print(resultMember.userName);
                                                  print(resultMember.email);
                                                  print(resultMember.password);
                                                  print(resultMember.inviteCode);
                                                  //ローディングを表示
                                                  Loading.show(message: '新規メンバーを作成中...', isDismissOnTap: false);
                                                  //ドメイン情報を取得
                                                  var resultDomain = await ApiDomains.getUrl(conaviId: conaviId);
                                                  //ドメイン情報をチェック
                                                  if (resultDomain is Result && resultDomain.isSuccess && resultDomain.data.containsKey('domainUrl')) {
                                                    String domainUrl = resultDomain.data['domainUrl'].toString();
                                                    //メンバー情報を新規作成
                                                    var result = await ApiMembers.createMember(
                                                      domain: domainUrl,
                                                      name: resultMember.userName,
                                                      email: resultMember.email,
                                                      password: resultMember.password,
                                                      conaviId: resultMember.conaviId,
                                                    );
                                                    if (result is Result && result.isSuccess) {
                                                      //招待コードを使用済みに更新
                                                      var resultCheckInviteCode = await ApiDomains.checkInviteCode(inviteCode: resultMember.inviteCode,checked: '1');
                                                      print(resultCheckInviteCode);
                                                      if(resultCheckInviteCode is Result && resultCheckInviteCode.isSuccess){
                                                        _conaviIdController.text = resultMember.conaviId;
                                                        _emailController.text = resultMember.email;
                                                        Loading.dismiss();
                                                      }else{
                                                        print('招待コード更新に失敗');
                                                      }
                                                    } else {
                                                      Loading.error(message: '新規メンバーの作成に失敗しました');
                                                    }
                                                  } else {
                                                    Loading.error(message: 'ドメイン情報の取得に失敗しました');
                                                  }
                                                }
                                              }else{
                                                Loading.error(message: '招待コードが正しくありません');
                                              }
                                            }else{
                                              Loading.error(message: '招待コードを入力してください');
                                            }
                                          },
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xfff8b500),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                    ),
                                    child: const Text('招待コード', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              top: BorderSide(color: Colors.white,width: 0.5),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        child: Text('Demo',style: TextStyle(color: Colors.white,fontSize: 13),),
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              top: BorderSide(color: Colors.white,width: 0.5),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (!context.mounted) return;
                                      var resultCommunityMember = await Navigator.push(context,
                                        MaterialPageRoute(
                                          builder: (context) => const CreateCommunityPage(),
                                        ),
                                      );
                                      print(resultCommunityMember);
                                      if(resultCommunityMember is CreateMember){
                                        print(resultCommunityMember.communityName);
                                        print(resultCommunityMember.userName);
                                        print(resultCommunityMember.email);
                                        print(resultCommunityMember.password);
                                        //ローディングを表示
                                        Loading.show(message: 'コミュニティを作成中...', isDismissOnTap: false);
                                        //コミュニティの作成
                                        var resultCommunity = await ApiCommunitys.createCommunity(communityName: resultCommunityMember.communityName, email: resultCommunityMember.email);
                                        print(resultCommunity);
                                        if(resultCommunity is Result && resultCommunity.isSuccess){
                                          if(resultCommunity.data.containsKey('conaviId')){
                                            print(resultCommunity.data);
                                            var result = await ApiCommunitys.createMember(
                                              name: resultCommunityMember.userName,
                                              email: resultCommunityMember.email,
                                              password: resultCommunityMember.password,
                                              conaviId: resultCommunity.data['conaviId'].toString(),
                                            );
                                            if(result is Result && result.isSuccess){
                                              _conaviIdController.text = resultCommunity.data['conaviId'].toString();
                                              _emailController.text = resultCommunityMember.email;
                                              Loading.dismiss();
                                            }else{
                                              Loading.error(message: 'コミュニティの作成に失敗しました');
                                            }
                                          }else{
                                            Loading.error(message: 'コナビIDの取得に失敗しました');
                                          }
                                        }else{
                                          Loading.error(message: 'コミュニティの作成に失敗しました');
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xfff8b500),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)
                                      ),
                                    ),
                                    child: const Text('コミュニティを作成', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(_version,style: const TextStyle(color: Colors.white,fontSize: 12)),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // RichText(
                      //     text: TextSpan(
                      //       style: const TextStyle(color: Colors.black),
                      //       children: [
                      //         const TextSpan(text: 'アカウントを作成していない方は'),
                      //         TextSpan(
                      //         text: 'こちら',
                      //         style: const TextStyle(color: Colors.blue),
                      //         recognizer: TapGestureRecognizer()
                      //           ..onTap = () {
                      //             Navigator.push(
                      //               context,
                      //               MaterialPageRoute(
                      //                 builder: (context) => const CreateAccountPage(),
                      //               ),
                      //             );
                      //           },
                      //       )
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
