import 'dart:io';

import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/view/mypage/my_page.dart';
import 'package:conavi_message/view/util/choice_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfilePage2 extends ConsumerStatefulWidget {
  const EditProfilePage2({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfilePage2> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends ConsumerState<EditProfilePage2> {
  TextEditingController nameController = TextEditingController();
  TextEditingController selfIntroductionController = TextEditingController();
  File? _imageFile;
  String _imagePath = '';
  final _formKey = GlobalKey<FormState>();

  ImageProvider? getImage(Auth myAccount) {
    if (_imageFile == null) {
      if (myAccount.member.imagePath.isNotEmpty) {
        return NetworkImage('${myAccount.domain.url}/api/upload/file.php?member_id=${myAccount.member.id}&app_token=${myAccount.member.appToken}');
      } else {
        return null;
      }
    } else {
      return FileImage(_imageFile!);
    }
  }

  @override
  void initState() {
    super.initState();
    Auth myAccount = ref.read(authProvider);
    nameController = TextEditingController(text: myAccount.member.name);
    selfIntroductionController = TextEditingController(text: myAccount.member.selfIntroduction);
  }

  @override
  Widget build(BuildContext context) {
    Auth myAccount = ref.watch(authProvider);
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'マイページ編集',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: false,
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                primaryFocus?.unfocus();
                if (_formKey.currentState!.validate()) {
                  //ローディング
                  EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
                  EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
                  EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                  await EasyLoading.show(
                    status: '処理中...',
                    dismissOnTap: false,
                    maskType: EasyLoadingMaskType.black,
                  );
                  //ファイル更新
                  if (_imageFile is File) {
                    var result = await ApiMembers.uploadMemberFile(
                        uid: myAccount.member.id,
                        uploadFile: _imageFile,
                        domain: myAccount.domain.url);
                    if (!result) {
                      print(ApiMembers.error);
                    }
                  }
                  var account = await updateAccount(myAccount);
                  if (account is Member) {
                    ref.read(userProvider.notifier).state = account;
                    EasyLoading.dismiss();
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } else {
                    EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                    EasyLoading.showError(
                      '保存に失敗しました',
                      dismissOnTap: true,
                      maskType: EasyLoadingMaskType.black,
                    );
                  }
                }
              },
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                  return Colors.transparent; //通常時の色（透明色）
                }),
              ),
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Container(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () async {
                      var resultFiles = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChoiceImagePage(
                              fileName: 'member${myAccount.member.id}',
                              multipleType: false,
                              limitFileSize: 5.0),
                        ),
                      );
                      print("result: $resultFiles");
                      if (resultFiles is List<ImageFile>) {
                        for (var image in resultFiles) {
                          setState((){
                            _imageFile = image.file;
                          });
                        }
                      }
                      // var result = await FunctionUtils.getImageFromGallery();
                      // if (result != null) {
                      //   setState((){
                      //     _image = File(result.path);
                      //   });
                      // }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          foregroundImage: getImage(myAccount),
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
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    child: TextFormField(
                      controller: nameController,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return '名前を入力してください';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(10),
                        labelText: '名前',
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        floatingLabelStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '名前を入力してください',
                        hintStyle: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.amberAccent,
                            width: 2.0,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.amberAccent,
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextFormField(
                      controller: selfIntroductionController,
                      maxLines: 4,
                      minLines: 4,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: '自己紹介',
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        floatingLabelStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '自己紹介を入力してください',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        fillColor: Colors.white,
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            width: 2,
                            color: Colors.amberAccent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            width: 2,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(
                  //   height: 20,
                  // ),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: Padding(
                  //         padding:
                  //             const EdgeInsets.only(left: 10, right: 5),
                  //         child: ElevatedButton(
                  //           onPressed: () async {
                  //             Navigator.pop(context);
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             primary: Colors.white,
                  //             onPrimary: Colors.grey,
                  //             shape: const StadiumBorder(),
                  //             side: const BorderSide(color: Colors.grey),
                  //           ),
                  //           child: const Text('キャンセル'),
                  //         ),
                  //       ),
                  //     ),
                  //     Expanded(
                  //       child: Padding(
                  //         padding:
                  //             const EdgeInsets.only(left: 5, right: 10),
                  //         child: ElevatedButton(
                  //           onPressed: () async {
                  //             if (_formKey.currentState!.validate()) {
                  //               FocusScope.of(context).unfocus();
                  //               //ローディング
                  //               EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
                  //               EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
                  //               EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                  //               await EasyLoading.show(
                  //                 status: '更新中...',
                  //                 dismissOnTap: false,
                  //                 maskType: EasyLoadingMaskType.black,
                  //               );
                  //               //ファイル更新
                  //               if(_imageFile is File){
                  //                 var result = await ApiMembers.uploadMemberFile(
                  //                     uid: myAccount.member.id,
                  //                     uploadFile: _imageFile,
                  //                     domain: myAccount.domain);
                  //                 if(!result) {
                  //                   print(ApiMembers.error);
                  //                 }
                  //               }
                  //               var account = await updateAccount(myAccount);
                  //               if (account is Member) {
                  //                 ref.read(userProvider.notifier).state  = account;
                  //                 EasyLoading.dismiss();
                  //                 if (!mounted) return;
                  //                 Navigator.pop(context, true);
                  //               }else{
                  //                 EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                  //                 EasyLoading.showError(
                  //                   '更新に失敗しました',
                  //                   dismissOnTap: true,
                  //                   maskType: EasyLoadingMaskType.black,
                  //                 );
                  //               }
                  //             }
                  //           },
                  //           style: ElevatedButton.styleFrom(
                  //             primary: Colors.blue,
                  //             onPrimary: Colors.white,
                  //             shape: const StadiumBorder(),
                  //             side: const BorderSide(color: Colors.blue),
                  //           ),
                  //           child: const Text('更新'),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Member?> updateAccount(Auth myAccount) async {
    // if (_imageFile != null) {
    //   _imagePath = await FunctionUtils.uploadImage(_imageFile!);
    // } else if (myAccount.member.imagePath.isNotEmpty) {
    //   _imagePath = myAccount.member.imagePath;
    // }
    Member updateAccount = Member(
      id: myAccount.member.id,
      name: nameController.text,
      selfIntroduction: selfIntroductionController.text,
      imagePath: myAccount.member.imagePath,
      notifyEmailFlag: myAccount.member.notifyEmailFlag,
    );
    return await ApiMembers.updateMember(
      updateAccount: updateAccount,
      domain: myAccount.domain.url,
    );
  }
}
