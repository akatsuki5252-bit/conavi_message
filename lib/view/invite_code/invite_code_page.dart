import 'package:conavi_message/api/api_domains.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/invite_code/send_invite_code_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

class InviteCodePage extends ConsumerStatefulWidget {
  const InviteCodePage({super.key});

  @override
  ConsumerState<InviteCodePage> createState() => _InviteCodePageState();
}

class _InviteCodePageState extends ConsumerState<InviteCodePage> {

  final TextEditingController _invitationCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final myAccount = ref.read(authProvider);
    _crateInviteCode(myAccount);
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('招待コード'),
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
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text('招待コードを発行して共有、またはメールアドレスに送信してください。',style: TextStyle(fontSize: 13),),
                      ),
                      ///招待コード
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(bottom: 4),
                              child: const Text('招待コード',style: TextStyle(fontSize:13,color: Colors.black)),
                            ),
                            Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: TextFormField(
                                    enabled: false,
                                    controller: _invitationCodeController,
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
                                    decoration: WidgetUtils.inputDecoration(icon: null, hintTxt: '',color: Colors.black),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: () async {
                                      if(_invitationCodeController.text.isNotEmpty) {
                                        Clipboard.setData(ClipboardData(text: _invitationCodeController.text));
                                        FunctionUtils.showToast(
                                            message: 'コピーしました',
                                            toastLength: Toast.LENGTH_LONG,
                                            toastGravity: ToastGravity.BOTTOM,
                                            time: 10,
                                            backgroundColor: const Color(0xff3166f7),
                                            textColor: Colors.white,
                                            textSize: 16.0
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.copy, color: Colors.black,size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text('※招待コードは発行から24時間以内に使用してください。',style: TextStyle(fontSize: 13),),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:(){
                              _crateInviteCode(myAccount);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xfff8b500), //ボタンの背景色
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)
                              ),
                            ),
                            child: const Text('招待コードを再発行する', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 9,
                            child: SizedBox(
                              child: ElevatedButton(
                                onPressed: () async {
                                  //フォーカスを外す
                                  FocusScope.of(context).unfocus();
                                  //入力チェック
                                  if (_invitationCodeController.text.isNotEmpty) {
                                    SharePlus.instance.share(
                                        ShareParams(
                                          text: _invitationCodeController.text,
                                          subject: 'コナビ招待コード',
                                        )
                                    );
                                  }else{
                                    Loading.error(message: '招待コードを発行してください');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, //ボタンの背景色
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: Color(0xfff8b500),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  splashFactory: InkRipple.splashFactory,
                                  foregroundColor: const Color(0xfff8b500),
                                ),
                                child: const Text('共有', style: TextStyle(color: Color(0xfff8b500),fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 9,
                            child: SizedBox(
                              child: ElevatedButton(
                                onPressed: () async {
                                  //フォーカスを外す
                                  FocusScope.of(context).unfocus();
                                  //入力チェック
                                  if (_invitationCodeController.text.isNotEmpty) {
                                    var result = await Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => SendInviteCodePage(_invitationCodeController.text)),
                                    );
                                    if(result is bool && result){
                                      _invitationCodeController.clear();
                                      print('send!!');
                                    }
                                  }else{
                                    Loading.error(message: '招待コードを発行してください');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, //ボタンの背景色
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: Color(0xfff8b500),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  splashFactory: InkRipple.splashFactory,
                                  foregroundColor: const Color(0xfff8b500),
                                ),
                                child: const Text('送信', style: TextStyle(color: Color(0xfff8b500),fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future _crateInviteCode(Auth myAccount) async {
    //ローディングを表示
    Loading.show(message: '発行中...', isDismissOnTap: false);
    //招待コードを発行
    var result = await ApiDomains.createInviteCode(
      conaviId: myAccount.domain.id,
    );
    if(result is Result && result.isSuccess){
      //ローディング終了
      Loading.dismiss();
      if(result.data.containsKey('inviteCode')){
        _invitationCodeController.text = result.data['inviteCode'].toString();
      }else{
        Loading.error(message: '招待コードの取得に失敗しました');
      }
    }else{
      Loading.error(message: '招待コードの発行に失敗しました');
    }
  }
}
