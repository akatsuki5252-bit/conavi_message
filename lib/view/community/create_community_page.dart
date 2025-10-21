import 'package:conavi_message/api/api_communitys.dart';
import 'package:conavi_message/setting/create_member.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/util/authentication_code_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateCommunityPage extends ConsumerStatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  ConsumerState<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends ConsumerState<CreateCommunityPage> {

  final TextEditingController _communityNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true; //パスワード非表示

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
            title: const Text('コミュニティ'),
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
                          ///コミュニティ
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: const Text('コミュニティ',style: TextStyle(fontSize:13,color: Colors.black)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: TextFormField(
                                    controller: _communityNameController,
                                    keyboardType: TextInputType.text,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    textInputAction: TextInputAction.next,
                                    cursorColor: Colors.black,
                                    validator: (String? value) {
                                      // if (value == null || value.isEmpty) {
                                      //   return 'メールアドレスを入力してください';
                                      // }
                                      return null;
                                    },
                                    decoration: WidgetUtils.inputDecoration(icon: Icons.diversity_3, hintTxt: 'コナビグループ',color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ///名前
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: const Text('名前',style: TextStyle(fontSize:13,color: Colors.black)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: TextFormField(
                                    controller: _userNameController,
                                    keyboardType: TextInputType.text,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    textInputAction: TextInputAction.next,
                                    cursorColor: Colors.black,
                                    validator: (String? value) {
                                      // if (value == null || value.isEmpty) {
                                      //   return 'メールアドレスを入力してください';
                                      // }
                                      return null;
                                    },
                                    decoration: WidgetUtils.inputDecoration(icon: Icons.person, hintTxt: 'コナビ太郎',color: Colors.black),
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
                                    textInputAction: TextInputAction.next,
                                    cursorColor: Colors.black,
                                    validator: (String? value) {
                                      // if (value == null || value.isEmpty) {
                                      //   return 'メールアドレスを入力してください';
                                      // }
                                      return null;
                                    },
                                    decoration: WidgetUtils.inputDecoration(icon: Icons.mail_outline, hintTxt: 'メールアドレス',color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ///パスワード
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: const Text('パスワード',style: TextStyle(fontSize:13,color: Colors.black)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 62,
                                  child: TextFormField(
                                    obscureText: _isObscure,
                                    controller: _passController,
                                    keyboardType: TextInputType.visiblePassword,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    cursorColor: Colors.black,
                                    maxLength: 16,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(16),
                                    ],
                                    validator: (String? value) {
                                      // if (value == null || value.isEmpty) {
                                      //   return 'パスワードを入力してください';
                                      // }
                                      return null;
                                    },
                                    decoration: WidgetUtils.inputDecoration(
                                      icon: Icons.lock_outline,
                                      hintTxt: 'パスワード',
                                      color: Colors.black,
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
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                //フォーカスを外す
                                FocusScope.of(context).unfocus();
                                //入力チェック
                                if (_formKey.currentState!.validate()) {
                                  //入力エラーチェック
                                  if(_communityNameController.text.isEmpty){
                                    Loading.error(message: 'コミュニティを入力してください');
                                    return;
                                  }
                                  if(_userNameController.text.isEmpty){
                                    Loading.error(message: '名前を入力してください');
                                    return;
                                  }
                                  if(_emailController.text.isEmpty){
                                    Loading.error(message: 'メールアドレスを入力してください');
                                    return;
                                  }else{
                                    ///メールアドレスをチェック
                                    var resultCheckEmail = await ApiCommunitys.checkEmail(email: _emailController.text);
                                    if(resultCheckEmail is Result && resultCheckEmail.isSuccess == false){
                                      Loading.error(message: '複数のコミュニティを作成する事はできません');
                                      return;
                                    }
                                  }
                                  if(_passController.text.isEmpty){
                                    Loading.error(message: 'パスワードを入力してください');
                                    return;
                                  }else{
                                    if(_passController.text.length < 8){
                                      Loading.error(message: 'パスワードは8～16文字以内で入力してください');
                                      return;
                                    }
                                  }
                                  //ローディングを表示
                                  Loading.show(message: '認証コード送信中...', isDismissOnTap: false);
                                  //認証コード作成
                                  var result = await Authentication.createAuthCode(email: _emailController.text);
                                  if(result is Result && result.isSuccess){
                                    //ローディングを終了
                                    Loading.dismiss();
                                    if (!context.mounted) return;
                                    bool resultAuth = await Navigator.push(context,
                                      MaterialPageRoute(
                                        builder: (context) => AuthenticationCodePage(email: _emailController.text),
                                      ),
                                    );
                                    if(resultAuth){
                                      if (!context.mounted) return;
                                      CreateMember member = CreateMember(
                                        userName: _userNameController.text,
                                        email: _emailController.text,
                                        password: _passController.text,
                                        communityName: _communityNameController.text,
                                      );
                                      Navigator.pop(context,member);
                                    }
                                  } else {
                                    Loading.error(message: result.error);
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
