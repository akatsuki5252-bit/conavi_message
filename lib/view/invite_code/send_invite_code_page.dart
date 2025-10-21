import 'package:conavi_message/api/api_domains.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SendInviteCodePage extends StatefulWidget {
  final String inviteCode;
  const SendInviteCodePage(this.inviteCode, {super.key});

  @override
  State<SendInviteCodePage> createState() => _SendInviteCodePageState();
}

class _SendInviteCodePageState extends State<SendInviteCodePage> {

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

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
            title: const Text('招待コードを送信'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
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
                                //メールアドレスチェック
                                RegExp regExp = RegExp(
                                  r"^[\w-+.!#$%&'*/=?^`{|}~]+@[\w-]+(\.[\w-]+)+$",
                                  caseSensitive: false, //大文字と小文字を区別するか
                                  multiLine: false, //複数行に対応するか
                                );
                                //メールアドレス確認
                                if(_emailController.text.isEmpty){
                                  Loading.error(message: 'メールアドレスを入力してください',);
                                }else if(regExp.hasMatch(_emailController.text)){
                                  //ローディングを表示
                                  Loading.show(message: '送信中...', isDismissOnTap: false);
                                  //指定メールアドレスに招待コードを送信
                                  var result = await ApiDomains.sendInviteCode(
                                    email: _emailController.text,
                                    inviteCode: widget.inviteCode,
                                  );
                                  if(result is Result && result.isSuccess){
                                    Loading.dismiss();
                                    FunctionUtils.showToast(
                                        message: '送信しました',
                                        toastLength: Toast.LENGTH_LONG,
                                        toastGravity: ToastGravity.BOTTOM,
                                        time: 10,
                                        backgroundColor: const Color(0xff3166f7),
                                        textColor: Colors.white,
                                        textSize: 16.0
                                    );
                                  }else{
                                    Loading.error(message: '招待コードの送信に失敗しました');
                                  }
                                }else{
                                  Loading.error(message: '正しいメールアドレスを入力してください',);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xfff8b500), //ボタンの背景色
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)
                                ),
                              ),
                              child: const Text('招待コードを送信する', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
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
    );
  }
}
