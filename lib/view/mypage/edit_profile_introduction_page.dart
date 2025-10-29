import 'dart:io';

import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/create_group_provider.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/push_notifications.dart';
import 'package:conavi_message/view/message/select_message_member_page.dart';
import 'package:conavi_message/view/util/choice_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:http/http.dart' as http;

class EditProfileIntroductionPage extends ConsumerStatefulWidget {
  const EditProfileIntroductionPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileIntroductionPage> createState() => _EditProfileIntroductionPageState();
}

class _EditProfileIntroductionPageState extends ConsumerState<EditProfileIntroductionPage> {

  final TextEditingController _selfIntroductionController = TextEditingController(); //グループ名コントローラー
  bool _isSave = false; //保存判定

  @override
  void initState() {
    super.initState();
    //セット
    final myAccount = ref.read(authProvider);
    _selfIntroductionController.text = myAccount.member.selfIntroduction;
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          Navigator.pop(context,_isSave);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('自己紹介',style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: false,
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20,top: 20,right: 20,bottom: 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _selfIntroductionController,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(200), //50文字制限
                        //FilteringTextInputFormatter.digitsOnly, //数字のみ
                      ],
                      maxLines: null,
                      maxLength: 200,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      cursorColor: const Color(0xfff8b500),
                      validator: (String? value) {
                        // if (value == null || value.isEmpty) {
                        //   return 'コナビIDを入力してください';
                        // }
                        return null;
                      },
                      decoration: const InputDecoration(
                        fillColor: Colors.white,//背景色
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 0,vertical: 0),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xfff8b500),
                          )
                        ),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                            )
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20,top: 0,right: 20,bottom: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        //フォーカスを外す
                        FocusScope.of(context).unfocus();
                        //名前入力値確認
                        if (_selfIntroductionController.text.isNotEmpty) {
                          //ローディングメッセージを表示
                          Loading.show(message: '処理中...', isDismissOnTap: false);
                          bool result = await ApiMembers.updateProfile(
                            domain: myAccount.domain.url,
                            memberId: myAccount.member.id,
                            name: '',
                            selfIntroduction: _selfIntroductionController.text,
                          );
                          FunctionUtils.log(result);
                          if(result){
                            _isSave = true;
                            //ローディングを終了
                            Loading.dismiss();
                            if (!context.mounted) return;
                            Navigator.pop(context,_isSave);
                          }else{
                            Loading.error(message: '保存に失敗しました');
                          }
                        }else{
                          Loading.error(message: '自己紹介を入力してください');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xfff8b500), //ボタンの背景色
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text('保存', style: TextStyle(color:Colors.white,fontSize: 16,fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
