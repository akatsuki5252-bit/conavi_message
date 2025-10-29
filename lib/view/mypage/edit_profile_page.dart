import 'dart:io';

import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/create_group_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/push_notifications.dart';
import 'package:conavi_message/view/message/edit_group_name_page.dart';
import 'package:conavi_message/view/message/invite_group_message_member_page.dart';
import 'package:conavi_message/view/message/participate_group_member_page.dart';
import 'package:conavi_message/view/message/select_message_member_page.dart';
import 'package:conavi_message/view/mypage/edit_profile_introduction_page.dart';
import 'package:conavi_message/view/mypage/edit_profile_name_page.dart';
import 'package:conavi_message/view/util/choice_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {

  Image? _image; //メンバー画像
  String _name = ''; //メンバー名
  String _selfIntroduction = ''; //自己紹介
  bool _isChanged = false; //変更フラグ

  @override
  void initState() {
    super.initState();
    final myAccount = ref.read(authProvider);
    _name = myAccount.member.name;
    _selfIntroduction = myAccount.member.selfIntroduction;
    setProfile();
  }

  //グループ画像を更新
  Future<void> setProfile() async {
    final myAccount = ref.read(authProvider);
    final member = await ApiMembers.fetchProfile(domain:myAccount.domain.url,memberId:myAccount.member.id);
    if(member is Member){
      ref.read(userProvider.notifier).state = member;
      String url = '${myAccount.domain.url}/api/upload/file.php?member_id=${myAccount.member.id}&app_token=${myAccount.member.appToken}';
      final http.Response response = await http.get(Uri.parse(url));
      if(mounted) {
        setState(() {
          _image = response.bodyBytes.isNotEmpty ? Image.memory(response.bodyBytes, fit: BoxFit.contain) : null;
          _name = member.name;
          _selfIntroduction = member.selfIntroduction;
        });
      }
    }
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
          Navigator.pop(context,_isChanged);
        },
        child: Scaffold(
          backgroundColor: const Color(0xfff5f5f5),
          appBar: AppBar(
            title: const Text('プロフィール編集',style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        ///メンバー画像
                        GestureDetector(
                          onTap: () async {
                            var resultFiles = await Navigator.push(context,
                              MaterialPageRoute(builder: (context) =>
                                const ChoiceImagePage(
                                  fileName: 'member',
                                  multipleType: false,
                                  limitFileSize: 5.0),
                              ),
                            );
                            File? imageFile;
                            if (resultFiles is List<ImageFile>) {
                              for (var image in resultFiles) {
                                imageFile = image.file;
                              }
                            }
                            if(imageFile != null){
                              FunctionUtils.log(imageFile);
                              //ローディングメッセージを表示
                              Loading.show(message: '処理中...', isDismissOnTap: false);
                              bool result = await ApiMembers.uploadMemberFile(
                                domain: myAccount.domain.url,
                                uid: myAccount.member.id,
                                uploadFile: imageFile,
                              );
                              FunctionUtils.log(result);
                              if(result){
                                setProfile();
                                _isChanged = true;
                              }
                              //ローディングを終了
                              Loading.dismiss();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20,bottom: 20),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  foregroundImage: _image?.image,
                                  backgroundColor: Colors.grey,
                                  radius: 32,
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle, //形を丸に//枠線をつける
                                    ),
                                    child: const Icon(Icons.photo_camera,size: 16,color: Colors.white)
                                ),
                              ],
                            ),
                          ),
                        ),
                        ///コナビID
                        Material(
                          color: Colors.white,
                          shape: const Border(
                            top: BorderSide(color: Color(0xffC0C0C0),width: 1),
                          ),
                          child: ListTile(
                            title: const Text('コナビID',style: TextStyle(color: Colors.grey,fontSize: 13)),
                            subtitle: Text(myAccount.domain.id,style: const TextStyle(color:Colors.black,fontSize: 17),),
                          ),
                        ),
                        ///名前
                        Material(
                          color: Colors.white,
                          shape: const Border(
                            top: BorderSide(color: Color(0xffC0C0C0),width: 1),
                            bottom: BorderSide(color: Color(0xffC0C0C0),width: 1),
                          ),
                          child: InkWell(
                            highlightColor: Colors.amber.shade100,
                            splashColor: Colors.amber.shade100,
                            onTap: () async{
                              Future.delayed(const Duration(milliseconds: 300), () async {
                                var result = await Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => const EditProfileNamePage()),
                                );
                                if(result is bool && result){
                                  setProfile();
                                  _isChanged = true;
                                }
                              });
                            },
                            //splashColor: Colors.pink,
                            child: ListTile(
                              title: const Text('名前',style: TextStyle(color: Colors.grey,fontSize: 13)),
                              subtitle: Text(_name,style: const TextStyle(color:Colors.black,fontSize: 17),),
                              trailing: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ///自己紹介
                        Material(
                          color: Colors.white,
                          shape: const Border(
                            bottom: BorderSide(color: Color(0xffC0C0C0),width: 1),
                          ),
                          child: InkWell(
                            highlightColor: Colors.amber.shade100,
                            splashColor: Colors.amber.shade100,
                            onTap: () async{
                              var result = await Navigator.push(context,
                                MaterialPageRoute(builder: (context) => const EditProfileIntroductionPage()),
                              );
                              if(result is bool && result){
                                setProfile();
                                _isChanged = true;
                              }
                            },
                            //splashColor: Colors.pink,
                            child: ListTile(
                              title: const Text('自己紹介',style: TextStyle(color: Colors.grey,fontSize: 13)),
                              subtitle: Text(_selfIntroduction,style: const TextStyle(color:Colors.black,fontSize: 17),),
                              trailing: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                                ],
                              ),
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
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {
          //     setState(() {});
          //   },
          //   child: Icon(Icons.add),
          // ),
        ),
      ),
    );
  }
}
