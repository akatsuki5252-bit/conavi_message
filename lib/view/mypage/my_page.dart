import 'dart:io';

import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/setting/result.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/view/invite_code/invite_code_page.dart';
import 'package:conavi_message/view/mypage/edit_notification_page.dart';
import 'package:conavi_message/view/mypage/edit_profile_page_backup.dart';
import 'package:conavi_message/view/mypage/edit_profile_page.dart';
import 'package:conavi_message/view/mypage/edit_profile_password_page.dart';
import 'package:conavi_message/view/startup/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
//**import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class MyPage extends ConsumerStatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {

  Image? _image; //メンバー画像

  @override
  void initState(){
    super.initState();
    setImage();
  }

  //画像を更新
  Future<void> setImage() async {
    final myAccount = ref.read(authProvider);
    if(myAccount.member.imagePath.isNotEmpty) {
      String url = '${myAccount.domain.url}/api/upload/file.php?member_id=${myAccount.member.id}&app_token=${myAccount.member.appToken}';
      print(url);
      final http.Response response = await http.get(Uri.parse(url));
      if(mounted) {
        setState(() {
          _image = Image.memory(response.bodyBytes, fit: BoxFit.contain);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Auth myAccount = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          PopupMenuButton<UserEdit>(
            onSelected: (UserEdit result) async{
              switch(result){
                ///アカウント削除
                case UserEdit.delete:
                  showDialog(
                    context: context,
                    builder: (dialogContext) => CustomAlertDialog(
                      title: '確認',
                      contentWidget: const Text('本当にアカウントを削除しますか？', style: TextStyle(fontSize: 15)),
                      cancelActionText: 'いいえ',
                      cancelAction: () {},
                      defaultActionText: 'アカウント削除',
                      action: () async {
                        //ローディングを表示
                        Loading.show(message: '削除中...', isDismissOnTap: false);
                        //アカウントを削除
                        var results = await ApiMembers.delete(
                            domain:myAccount.domain.url,
                            memberId:myAccount.member.id
                        );
                        if(results is Result && results.isSuccess){
                          //ログイン情報を削除
                          await Authentication.signOut(mid: myAccount.member.id, domain: myAccount.domain.url);
                          //ローディングを終了
                          Loading.dismiss();
                          //トースト
                          FunctionUtils.showToast(
                              message: 'アカウントを削除しました',
                              toastLength: Toast.LENGTH_LONG,
                              toastGravity: ToastGravity.BOTTOM,
                              time: 10,
                              backgroundColor: const Color(0xff3166f7),
                              textColor: Colors.white,
                              textSize: 16.0
                          );
                          //ログインページへ
                          if (!context.mounted) return;
                          Navigator.pushReplacement(context,
                            MaterialPageRoute(
                              builder: (dialogContext) =>
                              const LoginPage(),
                            ),
                          );
                        }else{
                          Loading.error(message: 'アカウントの削除に失敗しました');
                          return;
                        }
                      },
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<UserEdit>>[
              const PopupMenuItem<UserEdit>(
                value: UserEdit.delete,
                child: Text('アカウント削除'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey,
                          foregroundImage: _image?.image,
                          child: myAccount.member.imagePath.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 10,bottom: 20),
                        child: Text(myAccount.member.name)
                      ),
                      ///プロフィール編集
                      Material(
                        color: Colors.white,
                        shape: const Border(
                          top: BorderSide(width: 0.2),
                          bottom: BorderSide(width: 0.2),
                        ),
                        child: InkWell(
                          highlightColor: Colors.amber.shade100,
                          splashColor: Colors.amber.shade100,
                          onTap: () async{
                            Future.delayed(const Duration(milliseconds: 300), () async {
                              var result = await Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfilePage()
                                ),
                              );
                              print(result);
                              if(result is bool && result){
                                setImage();
                              }
                            });
                          },
                          //splashColor: Colors.pink,
                          child: const ListTile(
                            title: Text('プロフィール編集'),
                            leading: Icon(Icons.person,color:Color(0xff3166f7)),
                            trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                          ),
                        ),
                      ),
                      ///通知設定
                      Visibility(
                        visible: false,
                        child: Material(
                          color: Colors.white,
                          shape: const Border(
                            bottom: BorderSide(width: 0.2),
                          ),
                          child: InkWell(
                            highlightColor: Colors.amber.shade100,
                            splashColor: Colors.amber.shade100,
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditNotificationPage(),
                                  ),
                                ).then((value) {
                                  print('ok');
                                });
                              });
                            },
                            //splashColor: Colors.pink,
                            child: const ListTile(
                              title: Text('通知設定'),
                              leading: Icon(Icons.notifications,color:Color(0xff3166f7)),
                              trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                            ),
                          ),
                        ),
                      ),
                      ///パスワード変更
                      Material(
                        color: Colors.white,
                        shape: const Border(
                          bottom: BorderSide(width: 0.2),
                        ),
                        child: InkWell(
                          highlightColor: Colors.amber.shade100,
                          splashColor: Colors.amber.shade100,
                          onTap: (){
                            Future.delayed(const Duration(milliseconds: 300), () async {
                              Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfilePasswordPage(
                                    domainUrl: myAccount.domain.url,
                                    memberId: myAccount.member.id,
                                    isOldPassword: true,
                                  ),
                                ),
                              );
                            });
                          },
                          //splashColor: Colors.pink,
                          child: const ListTile(
                            title: Text('パスワード変更'),
                            leading: Icon(Icons.lock,color:Color(0xff3166f7)),
                            trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                          ),
                        ),
                      ),
                      ///招待コード
                      Material(
                        color: Colors.white,
                        shape: const Border(
                          bottom: BorderSide(width: 0.2),
                        ),
                        child: InkWell(
                          highlightColor: Colors.amber.shade100,
                          splashColor: Colors.amber.shade100,
                          onTap: () async{
                            Future.delayed(const Duration(milliseconds: 300), () async {
                              Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (context) => const InviteCodePage(),
                                ),
                              );
                            });
                          },
                          //splashColor: Colors.pink,
                          child: const ListTile(
                            title: Text('招待コード'),
                            leading: Icon(Icons.account_box,color:Color(0xff3166f7)),
                            trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                          ),
                        ),
                      ),
                      ///ログアウト
                      Material(
                        color: Colors.white,
                        shape: const Border(
                          bottom: BorderSide(width: 0.2),
                        ),
                        child: InkWell(
                          highlightColor: Colors.amber.shade100,
                          splashColor: Colors.amber.shade100,
                          onTap: (){
                            Future.delayed(const Duration(milliseconds: 300), () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => CustomAlertDialog(
                                  title: '確認',
                                  contentWidget: const Text('ログアウトしますか？', style: TextStyle(fontSize: 15)),
                                  cancelActionText: 'いいえ',
                                  cancelAction: () {

                                  },
                                  defaultActionText: 'はい',
                                  action: () async {
                                    //ローディングを表示
                                    Loading.show(message: 'ログアウト中...', isDismissOnTap: false);
                                    //ログイン情報を削除
                                    await Authentication.signOut(mid: myAccount.member.id, domain: myAccount.domain.url);
                                    //ローディングを終了
                                    Loading.dismiss();
                                    //ログインページへ
                                    if (!context.mounted) return;
                                    Navigator.pushReplacement(context,
                                      MaterialPageRoute(
                                        builder: (dialogContext) =>
                                        const LoginPage(),
                                      ),
                                    );
                                  },
                                ),
                              );
                            });
                          },
                          //splashColor: Colors.pink,
                          child: const ListTile(
                            title: Text('ログアウト'),
                            leading: Icon(Icons.logout,color:Color(0xff3166f7)),
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
      ),
    );
  }
}
