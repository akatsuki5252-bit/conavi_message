import 'package:conavi_message/api/api_domains.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/mypage/edit_profile_password_page.dart';
import 'package:conavi_message/view/util/authentication_code_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {

  final TextEditingController _conaviIdController = TextEditingController(); //コナビId
  final TextEditingController _emailController = TextEditingController(); //メールアドレス
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          Navigator.pop(context, false);
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('パスワード再設定'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          ///コナビID
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: const Text('コナビID',style: TextStyle(fontSize:13,color: Colors.black)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: TextFormField(
                                    controller: _conaviIdController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(5), //5文字制限
                                      FilteringTextInputFormatter.digitsOnly, //数字のみ
                                    ],
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    textInputAction: TextInputAction.next,
                                    cursorColor: Colors.black,
                                    decoration: WidgetUtils.inputDecoration(icon: null, hintTxt: '',color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ///メールアドレス
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: const Text('メールアドレス',style: TextStyle(fontSize:13,color: Colors.black)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    textInputAction: TextInputAction.done,
                                    cursorColor: Colors.black,
                                    decoration: WidgetUtils.inputDecoration(icon: null, hintTxt: '',color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  //フォーカスを外す
                                  FocusScope.of(context).unfocus();
                                  //入力チェック
                                  if (_formKey.currentState!.validate()) {
                                    //コナビID確認
                                    if (_conaviIdController.text.isEmpty) {
                                      Loading.error(message: 'コナビIDを入力してください',);
                                      return;
                                    }
                                    //メールアドレス確認
                                    if (_emailController.text.isEmpty) {
                                      Loading.error(message: 'メールアドレスを入力してください',);
                                      return;
                                    }
                                    //メールアドレスチェック
                                    RegExp regExp = RegExp(
                                      r"^[\w-+.!#$%&'*/=?^`{|}~]+@[\w-]+(\.[\w-]+)+$",
                                      caseSensitive: false, //大文字と小文字を区別するか
                                      multiLine: false, //複数行に対応するか
                                    );
                                    if (regExp.hasMatch(_emailController.text)) {
                                      FunctionUtils.log(_conaviIdController.text);
                                      FunctionUtils.log(_emailController.text);
                                      //ローディングを表示
                                      Loading.show(message: '確認中...', isDismissOnTap: false);
                                      //ドメインを取得
                                      var resultDomainUrl = await ApiDomains.getUrl(conaviId: _conaviIdController.text);
                                      if(resultDomainUrl is Result && resultDomainUrl.isSuccess && resultDomainUrl.data.containsKey('domainUrl')){
                                        //接続先URL
                                        String domainUrl = resultDomainUrl.data['domainUrl'].toString();
                                        //メールアドレスをチェック
                                        var resultCheckEmail = await ApiMembers.checkEmail(
                                          domain: domainUrl,
                                          email: _emailController.text,
                                          conaviId: _conaviIdController.text,
                                        );
                                        if(resultCheckEmail is Result && resultCheckEmail.isSuccess && resultCheckEmail.data.containsKey('memberId')){
                                          //メールアドレスからメンバーidを取得
                                          String memberId = resultCheckEmail.data['memberId'].toString();
                                          //ローディング終了
                                          Loading.dismiss();
                                          //ローディングを表示
                                          Loading.show(message: '認証コード送信中...', isDismissOnTap: false);
                                          //認証コード作成
                                          var result = await Authentication.createAuthCode(email: _emailController.text);
                                          if(result is Result && result.isSuccess) {
                                            //ローディングを終了
                                            Loading.dismiss();
                                            if (!context.mounted) return;
                                            //認証コード入力画面へ移動
                                            bool resultAuth = await Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => AuthenticationCodePage(
                                                email: _emailController.text,
                                              )),
                                            );
                                            //認証成功
                                            if(resultAuth){
                                              if (!context.mounted) return;
                                              //新しいパスワード設定画面
                                              var resultNewPassword = await Navigator.push(context,
                                                MaterialPageRoute(builder: (context) => EditProfilePasswordPage(
                                                  domainUrl: domainUrl,
                                                  memberId: memberId,
                                                  isOldPassword: false,
                                                )),
                                              );
                                              if(resultNewPassword is bool && resultNewPassword){
                                                if (!context.mounted) return;
                                                Navigator.pop(context,true);
                                              }
                                            }
                                          }else {
                                            Loading.error(message: '認証コードの送信に失敗しました');
                                          }
                                        }else{
                                          Loading.error(message: 'コナビID、またはメールアドレスが一致しません',);
                                        }
                                      }else{
                                        Loading.error(message: 'コナビID、またはメールアドレスが一致しません',);
                                      }
                                    } else {
                                      Loading.error(message: '正しいメールアドレスを入力してください',);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xfff8b500), //ボタンの背景色
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                ),
                                child: const Text('メールアドレスを認証する', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
