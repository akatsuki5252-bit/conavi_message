import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthenticationCodePage extends StatefulWidget {
  final String email;
  const AuthenticationCodePage({super.key,required this.email});

  @override
  State<AuthenticationCodePage> createState() => _AuthenticationCodePageState();
}

class _AuthenticationCodePageState extends State<AuthenticationCodePage> {

  final TextEditingController _authenticationCodeController = TextEditingController();

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
            title: const Text('認証コード'),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('メールアドレスを認証するため、以下にコードを入力してください。${widget.email}',style: const TextStyle(fontSize: 13),),
                        ),
                        ///認証コード
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            children: [
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(bottom: 4),
                                child: const Text('認証コード',style: TextStyle(fontSize:13,color: Colors.black)),
                              ),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: TextFormField(
                                  controller: _authenticationCodeController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: Colors.black,
                                  validator: (String? value) {

                                    return null;
                                  },
                                  decoration: WidgetUtils.inputDecoration(icon: null, hintTxt: '', color: Colors.black),
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
                              if (_authenticationCodeController.text.isNotEmpty) {
                                //ローディングを表示
                                Loading.show(message: '認証中...', isDismissOnTap: false);
                                //入力エラーチェック
                                if(_authenticationCodeController.text.length < 6){
                                  Loading.error(message: '6桁の認証コードを入力してください');
                                  return;
                                }
                                //認証
                                bool result = await Authentication.checkAuthCode(
                                  email: widget.email,
                                  code: _authenticationCodeController.text,
                                );
                                if(result){
                                  //ローディングを終了
                                  Loading.dismiss();
                                  if (!context.mounted) return;
                                  Navigator.pop(context,true);
                                }else{
                                  Loading.error(message: '認証に失敗しました',);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xfff8b500), //ボタンの背景色
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)
                              ),
                            ),
                            child: const Text('認証する', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
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
