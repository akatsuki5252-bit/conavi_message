import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/message/message_room_page.dart';
import 'package:conavi_message/view/message/message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberPage extends ConsumerStatefulWidget {
  final Member member;
  const MemberPage(this.member, {super.key});

  @override
  ConsumerState<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends ConsumerState<MemberPage> {

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        //戻るボタン押下時にtrueを返す
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(title: Text(widget.member.name)),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    ///メンバー画像
                    Padding(
                      padding: const EdgeInsets.only(top: 20,bottom: 20),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey,
                        foregroundImage:widget.member.imagePath.isNotEmpty
                            ? NetworkImage('${myAccount.domain.url}/api/upload/file.php?member_id=${widget.member.id}&app_token=${myAccount.member.appToken}')
                            : null,
                        child: widget.member.imagePath.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    ///自己紹介
                    Material(
                      color: Colors.white,
                      shape: const Border(
                        top: BorderSide(color: Color(0xffC0C0C0),width: 1),
                        bottom: BorderSide(color: Color(0xffC0C0C0),width: 1),
                      ),
                      child: ListTile(
                        title: const Text('自己紹介',style: TextStyle(color: Colors.grey,fontSize: 13)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(widget.member.selfIntroduction,style: const TextStyle(color:Colors.black,fontSize: 17)),
                        ),
                      ),
                    ),
                    ///メッセージを送る
                    Material(
                      color: Colors.white,
                      shape: const Border(
                        bottom: BorderSide(color: Color(0xffC0C0C0),width: 1),
                      ),
                      child: InkWell(
                        highlightColor: Colors.amber.shade100,
                        splashColor: Colors.amber.shade100,
                        onTap: () async{
                          Future.delayed(const Duration(milliseconds: 300), () async {
                            //ローディング
                            Loading.show(message: '処理中', isDismissOnTap: false);
                            //ルームidを作成
                            final List<String> memberIds = [myAccount.member.id, widget.member.id];
                            memberIds.sort((a, b) => a.compareTo(b));
                            String listAsString = FunctionUtils.listToString(memberIds);
                            //ルーム情報を作成・取得
                            final talkRoom = await ApiMessages.createRoom(
                              joinedMemberIds: listAsString,
                              myAccount: myAccount,
                            );
                            if(talkRoom is TalkRoom){
                              //ローディング終了
                              Loading.dismiss();
                              if (!context.mounted) return;
                              //メッセージルームへ遷移
                              Navigator.pushReplacement(context,
                                MaterialPageRoute(
                                  builder: (context) => MessageRoomPage(talkRoom),
                                ),
                              );
                            }else{
                              //エラーメッセージ表示
                              Loading.error(message: 'エラーが発生しました');
                            }
                          });
                        },
                        //splashColor: Colors.pink,
                        child: const ListTile(
                          title: Text('メッセージを送る',style: TextStyle(color: Colors.black,fontSize: 17)),
                          leading: Icon(Icons.mail,color:Color(0xff3166f7)),
                          trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
