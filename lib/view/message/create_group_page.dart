import 'dart:io';

import 'package:conavi_message/api/api_group_message.dart';
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

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {

  TextEditingController _groupNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final groupName = ref.read(createGroupNameProvider);
    _groupNameController = TextEditingController(text: groupName);
  }

  ImageProvider? getImage() {
    final selectedGroupImageFile = ref.watch(createGroupImagePathProvider);
    if (selectedGroupImageFile != null) {
      return FileImage(selectedGroupImageFile);
    }else{
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    final selectedGroupImageFile = ref.watch(createGroupImagePathProvider);
    final selectedMembers = ref.watch(createGroupMembersProvider);
    //FunctionUtils.log(selectedMembers);
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('グループ設定'),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: () async{
                //フォーカスを外す
                primaryFocus?.unfocus();
                //入力値チェック
                if (_formKey.currentState!.validate()) {
                  //ローディングメッセージを表示
                  Loading.show(message: '処理中...', isDismissOnTap: false);
                  //招待メンバー
                  List<Member> inviteMembers = [];
                  for(Member selectMember in selectedMembers){
                    inviteMembers.add(selectMember);
                  }
                  //ルームメンバー(招待メンバー + 自分)
                  List<Member> roomMembers = [];
                  for(Member inviteMember in inviteMembers){
                    roomMembers.add(inviteMember);
                  }
                  roomMembers.add(myAccount.member);
                  // //ルーム情報を作成・取得
                  final talkGroupRoom = await ApiGroupMessages.createGroupRoom(
                    domain: myAccount.domain.url,
                    joinedMemberIds: FunctionUtils.createJoinedMemberIds(roomMembers),
                    groupName: _groupNameController.text,
                    adminMemberId: myAccount.member.id,
                    uploadFile: selectedGroupImageFile,
                  );
                  if(talkGroupRoom is TalkGroupRoom) {
                    //プッシュ通知
                    bool result = await PushNotifications.sendPushMessage(
                      domain: myAccount.domain.url,
                      roomId: talkGroupRoom.roomId,
                      type: 'groupMessage',
                      title: talkGroupRoom.roomName,
                      body: 'グループに招待されました',
                      memberIds: FunctionUtils.createArrayMemberIds(inviteMembers),
                      uniqueKey: FunctionUtils.createUniqueKeyFromDate(DateTime.now()),
                      imageUrl: talkGroupRoom.imagePath
                    );
                    if(!result){
                      FunctionUtils.log('プッシュ通知でエラーが発生');
                    }
                    //ローディングを終了
                    Loading.dismiss();
                    if (!context.mounted) return;
                    Navigator.pop(context, talkGroupRoom);
                  }else{
                    //エラーメッセージ表示
                    Loading.error(message: 'グループルームの作成に失敗しました');
                  }
                }
              },
              child: const Text('作成', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(right: 15, left: 15, top: 20),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          primaryFocus?.unfocus();
                          var resultFiles = await Navigator.push(context,
                            MaterialPageRoute(builder: (context) => const ChoiceImagePage(
                                fileName: 'group',
                                multipleType: false,
                                limitFileSize: 5.0),
                            ),
                          );
                          if (resultFiles is List<ImageFile>) {
                            for (var image in resultFiles) {
                              setState((){
                                ref.read(createGroupImagePathProvider.notifier).state = image.file;
                              });
                            }
                          }
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              foregroundImage: getImage(),
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
                              child: const Icon(Icons.photo_camera,size: 16,color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                        child: TextFormField(
                          controller: _groupNameController,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50), //50文字制限
                          ],
                          maxLines: 1,
                          maxLength: 50,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textInputAction: TextInputAction.done,
                          cursorColor: const Color(0xfff8b500),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'グループ名を入力してください';
                            }
                            return null;
                          },
                          onChanged: (value) async {
                            //入力中の文字を端末に保存
                            ref.read(createGroupNameProvider.notifier).state = value;
                          },
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(0),
                            labelText: 'グループ名',
                            labelStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            floatingLabelStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
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
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 0,left: 10,bottom: 20,right: 10),
                        child: Text(
                          '参加メンバー${selectedMembers.length.toString()}人',
                          style: const TextStyle(fontSize: 12,fontWeight: FontWeight.bold),
                        )
                      ),
                      Flexible(
                        // child: Container(
                        //   color: Colors.grey,
                        //   alignment: Alignment.bottomCenter,
                        //   child: Text('aa'),
                        // ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0,left: 10,bottom: 0,right: 10),
                          child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, //カラム数
                                mainAxisSpacing: 5,
                              ),
                              itemCount: selectedMembers.length,
                              itemBuilder: (BuildContext context, int index) {
                                Member member = selectedMembers[index];
                                String imagePath = member.imagePath.isNotEmpty ? '${myAccount.domain.url}/api/upload/file.php?member_id=${member.id}&app_token=${myAccount.member.appToken}' : '';
                                return Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      child: WidgetUtils.getCircleAvatar(imagePath)
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4,left: 2,bottom: 0,right: 2),
                                      child: Text(
                                        member.name,
                                        style: const TextStyle(fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  ],
                                );
                              }
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
