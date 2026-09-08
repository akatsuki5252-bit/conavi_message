import 'dart:io';

import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/view/mypage/edit_profile_introduction_page.dart';
import 'package:conavi_message/view/mypage/edit_profile_name_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:conavi_message/utils/file_piker_helper.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends ConsumerStatefulWidget {
  final ImageProvider? profileImage;

  const EditProfilePage({
    super.key,
    this.profileImage,
  });

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {

  ImageProvider? _profileImage; //メンバー画像
  String _profileName = ''; //メンバー名
  String _profileSelfIntroduction = ''; //自己紹介
  bool _isChanged = false; //変更フラグ

  @override
  void initState() {
    super.initState();

    final myAccount = ref.read(authProvider);

    _profileName = myAccount.member.name;
    _profileSelfIntroduction = myAccount.member.selfIntroduction;

    // マイページからプロフィール画像を受け取る
    _profileImage = widget.profileImage;

    loadProfile();
    // マイページ側で画像を取得できていない場合のみ取得
    if (_profileImage == null) {
      loadProfileImage();
    }
  }

  //プロフィール情報読み込み
  Future<void> loadProfile() async {
    final myAccount = ref.read(authProvider);
    final member = await ApiMembers.fetchProfile(domain:myAccount.domain.url,memberId:myAccount.member.id);
    if(member is Member && mounted){
      ref.read(userProvider.notifier).state = member;
      setState(() {
        _profileName = member.name;
        _profileSelfIntroduction = member.selfIntroduction;
      });
    }
  }

  //プロフィール画像
  Future<void> loadProfileImage() async {
    final myAccount = ref.read(authProvider);

    if (myAccount.member.imagePath.isEmpty) {
      return;
    }

    final url = '${myAccount.domain.url}/api/upload/file.php?member_id=${myAccount.member.id}&app_token=${myAccount.member.appToken}';
    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      setState(() {
        _profileImage = response.bodyBytes.isNotEmpty ? MemoryImage(response.bodyBytes) : null;
      });
    } catch (e) {
      FunctionUtils.log('プロフィール画像取得エラー: $e');
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
                            final files = await FilePickerHelper.pickFilesWithSizeCheck(
                              context: context,
                              type: MessageFileType.image,
                              allowMultiple: false
                            );

                            if (files.isEmpty) return;
                            if (!mounted) return;

                            final imageFile = files.first;
                            FunctionUtils.log(imageFile);

                            //ローディングメッセージを表示
                            Loading.show(
                              message: '処理中...',
                              isDismissOnTap: false,
                            );
                            try {
                              bool result = await ApiMembers.uploadMemberFile(
                                domain: myAccount.domain.url,
                                uid: myAccount.member.id,
                                uploadFile: imageFile,
                              );

                              FunctionUtils.log(result);

                              if(result){
                                await loadProfileImage();
                                _isChanged = true;
                              }
                            } catch (e) {
                              FunctionUtils.log('プロフィール画像更新エラー: $e');
                            } finally {
                              Loading.dismiss();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20,bottom: 20),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  foregroundImage: _profileImage,
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
                                  await loadProfile();
                                  _isChanged = true;
                                }
                              });
                            },
                            //splashColor: Colors.pink,
                            child: ListTile(
                              title: const Text('名前',style: TextStyle(color: Colors.grey,fontSize: 13)),
                              subtitle: Text(_profileName,style: const TextStyle(color:Colors.black,fontSize: 17),),
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
                                await loadProfile();
                                _isChanged = true;
                              }
                            },
                            //splashColor: Colors.pink,
                            child: ListTile(
                              title: const Text('自己紹介',style: TextStyle(color: Colors.grey,fontSize: 13)),
                              subtitle: Text(_profileSelfIntroduction,style: const TextStyle(color:Colors.black,fontSize: 17),),
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
