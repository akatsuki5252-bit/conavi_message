import 'package:conavi_message/api/api_domains.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/setting/create_member.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/util/authentication_code_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditProfilePasswordPage extends ConsumerStatefulWidget {
  String domainUrl; //接続先URL
  String memberId; //メンバーid
  bool isOldPassword; //現在のパスワード表示判定
  EditProfilePasswordPage({super.key,required this.domainUrl,required this.memberId,required this.isOldPassword});

  @override
  ConsumerState<EditProfilePasswordPage> createState() => _EditProfilePasswordPageState();
}

class _EditProfilePasswordPageState extends ConsumerState<EditProfilePasswordPage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController(); //現在のパスワード
  final TextEditingController _newPasswordController = TextEditingController(); //新しいパスワード
  final TextEditingController _confPasswordController = TextEditingController(); //確認用パスワード
  bool _isOldObscure = true; //現在のパスワード非表示フラグ
  bool _isNewObscure = true; //新しいパスワード非表示フラグ
  bool _isConfObscure = true; //確認用パスワード非表示フラグ

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
            title: const Text('パスワード変更'),
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
                          ///現在のパスワード
                          Visibility(
                            visible: widget.isOldPassword,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Column(
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: const Text('現在のパスワード',style: TextStyle(fontSize:13,color: Colors.black)),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 62,
                                    child: TextFormField(
                                      obscureText: _isOldObscure,
                                      controller: _oldPasswordController,
                                      keyboardType: TextInputType.visiblePassword,
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      textInputAction: TextInputAction.next,
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
                                        hintTxt: '',
                                        color: Colors.black,
                                        isSuffix : true,
                                        isObscure: _isOldObscure,
                                        actionSuffix: () async {
                                          setState(() {
                                            _isOldObscure = !_isOldObscure;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ///新しいパスワード
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: const Text('新しいパスワード',style: TextStyle(fontSize:13,color: Colors.black)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 62,
                                  child: TextFormField(
                                    obscureText: _isNewObscure,
                                    controller: _newPasswordController,
                                    keyboardType: TextInputType.visiblePassword,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    textInputAction: TextInputAction.next,
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
                                      hintTxt: '',
                                      color: Colors.black,
                                      isSuffix : true,
                                      isObscure: _isNewObscure,
                                      actionSuffix: () async {
                                        setState(() {
                                          _isNewObscure = !_isNewObscure;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ///確認用パスワード
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: const Text('新しいパスワード(確認)',style: TextStyle(fontSize:13,color: Colors.black)),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 62,
                                  child: TextFormField(
                                    obscureText: _isConfObscure,
                                    controller: _confPasswordController,
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
                                      hintTxt: '',
                                      color: Colors.black,
                                      isSuffix : true,
                                      isObscure: _isConfObscure,
                                      actionSuffix: () async {
                                        setState(() {
                                          _isConfObscure = !_isConfObscure;
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
                                  if(widget.isOldPassword) {
                                    if (_oldPasswordController.text.isEmpty) {
                                      Loading.error(message: 'パスワードを入力してください');
                                      return;
                                    }
                                  }
                                  if (_newPasswordController.text.isEmpty || _confPasswordController.text.isEmpty) {
                                    Loading.error(message: 'パスワードを入力してください');
                                    return;
                                  }
                                  if(widget.isOldPassword) {
                                    if(_oldPasswordController.text.length < 8){
                                      Loading.error(message: 'パスワードは8～16文字以内で入力してください');
                                      return;
                                    }
                                  }
                                  if(_newPasswordController.text.length < 8 || _confPasswordController.text.length < 8 ){
                                    Loading.error(message: 'パスワードは8～16文字以内で入力してください');
                                    return;
                                  }
                                  if(_newPasswordController.text.compareTo(_confPasswordController.text) != 0){
                                    Loading.error(message: '新しいパスワードが一致しません');
                                    return;
                                  }
                                  //ローディングを表示
                                  Loading.show(message: 'パスワード変更中...', isDismissOnTap: false);
                                  if(widget.isOldPassword) {
                                    //現在のパスワードをチェック
                                    var resultCheckOldPassword = await ApiMembers.checkPassword(
                                      domain: widget.domainUrl,
                                      memberId: widget.memberId,
                                      password: _oldPasswordController.text,
                                    );
                                    if(resultCheckOldPassword is Null || (resultCheckOldPassword is Result && resultCheckOldPassword.isSuccess == false)) {
                                      Loading.error(message: '現在のパスワードが一致しません');
                                      return;
                                    }
                                  }
                                  //新しいパスワードに変更
                                  var resultChangePassword = await ApiMembers.changePassword(
                                    domain: widget.domainUrl,
                                    memberId: widget.memberId,
                                    password: _newPasswordController.text,
                                  );
                                  if(resultChangePassword is Result && resultChangePassword.isSuccess) {
                                    //ローディングを終了
                                    Loading.dismiss();
                                    //トースト表示
                                    FunctionUtils.showToast(
                                      message: 'パスワードを再設定しました',
                                      toastLength: Toast.LENGTH_SHORT,
                                      toastGravity: ToastGravity.BOTTOM ,
                                      time: 1,
                                      backgroundColor: const Color(0xff3166f7),
                                      textColor: Colors.white,
                                      textSize: 16.0,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pop(context,true);
                                  }else{
                                    Loading.error(message: 'パスワードの変更に失敗しました');
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xfff8b500), //ボタンの背景色
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)
                                ),
                              ),
                              child: const Text('パスワードを変更する', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
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
