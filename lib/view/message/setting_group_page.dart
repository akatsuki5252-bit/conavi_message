import 'dart:io';
import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/view/message/edit_group_name_page.dart';
import 'package:conavi_message/view/message/invite_group_message_member_page.dart';
import 'package:conavi_message/view/message/participate_group_member_page.dart';
import 'package:conavi_message/view/util/choice_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class SettingGroupPage extends ConsumerStatefulWidget {
  final TalkGroupRoom talkRoom;
  const SettingGroupPage(this.talkRoom, {super.key});

  @override
  ConsumerState<SettingGroupPage> createState() => _SettingGroupPageState();
}

class _SettingGroupPageState extends ConsumerState<SettingGroupPage> {

  Image? _groupImage; //グループ画像
  String _groupName = ''; //グループ名
  bool _isChanged = false; //変更フラグ

  @override
  void initState() {
    super.initState();
    //グループ名
    _groupName = widget.talkRoom.roomName;
    //グループ情報を更新
    initializeGroup();
  }

  //グループ画像を更新
  Future<void> initializeGroup() async {
    final myAccount = ref.read(authProvider);
    final newTalkGroupRoom = await ApiGroupMessages.fetchGroupRoom(myAccount: myAccount, roomId: widget.talkRoom.roomId);
    if(newTalkGroupRoom is TalkGroupRoom){
      FunctionUtils.log(newTalkGroupRoom.imagePath);
      final http.Response? response = newTalkGroupRoom.imagePath.isNotEmpty ? await http.get(Uri.parse(newTalkGroupRoom.imagePath)) : null;
      if(mounted) {
        setState(() {
          _groupImage = response != null ? Image.memory(response.bodyBytes, fit: BoxFit.contain) : null;
          _groupName = newTalkGroupRoom.roomName;
        });
      }
      widget.talkRoom.imagePath = newTalkGroupRoom.imagePath;
      widget.talkRoom.roomName = newTalkGroupRoom.roomName;
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
            title: const Text('設定',style: TextStyle(fontWeight: FontWeight.bold)),
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
                        ///グループ画像
                        GestureDetector(
                          onTap: () async {
                            var resultFiles = await Navigator.push(context,
                              MaterialPageRoute(builder: (context) =>
                                const ChoiceImagePage(
                                  fileName: 'group',
                                  multipleType: false,
                                  limitFileSize: 5.0),
                              ),
                            );
                            File? groupImageFile;
                            if (resultFiles is List<ImageFile>) {
                              for (var image in resultFiles) {
                                groupImageFile = image.file;
                              }
                            }
                            if(groupImageFile != null){
                              FunctionUtils.log(groupImageFile);
                              //ローディングメッセージを表示
                              Loading.show(message: '処理中...', isDismissOnTap: false);
                              bool result = await ApiGroupMessages.updateGroupRoom(
                                domain: myAccount.domain.url,
                                roomId: widget.talkRoom.roomId,
                                roomName: '',
                                uploadFile: groupImageFile,
                              );
                              FunctionUtils.log(result);
                              if(result){
                                initializeGroup();
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
                                  foregroundImage: _groupImage != null ? _groupImage!.image : null,
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
                        ///グループ名
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
                              var result = await Navigator.push(context,
                                MaterialPageRoute(builder: (context) => EditGroupNamePage(widget.talkRoom)),
                              );
                              if(result is bool && result){
                                initializeGroup();
                                _isChanged = true;
                              }
                            },
                            //splashColor: Colors.pink,
                            child: ListTile(
                              title: const Text('グループ名',style: TextStyle(color: Colors.grey,fontSize: 13)),
                              subtitle: Text(_groupName,style: const TextStyle(color:Colors.black,fontSize: 17),),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ///メンバー一覧・編集
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
                                var result = await Navigator.push(context,
                                  MaterialPageRoute(
                                    builder: (context) => ParticipateGroupMemberPage(widget.talkRoom),
                                  ),
                                );
                              });
                            },
                            //splashColor: Colors.pink,
                            child: const ListTile(
                              title: Text('メンバー',style: TextStyle(color: Colors.black,fontSize: 17)),
                              trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                            ),
                          ),
                        ),
                        ///招待
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
                                var result = await Navigator.push(context,
                                  MaterialPageRoute(
                                    builder: (context) => InviteGroupMessageMemberPage(widget.talkRoom),
                                  ),
                                );
                              });
                            },
                            //splashColor: Colors.pink,
                            child: const ListTile(
                              title: Text('招待',style: TextStyle(color: Colors.black,fontSize: 17)),
                              trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                            ),
                          ),
                        ),
                        ///退会
                        Material(
                          color: Colors.white,
                          shape: const Border(
                            bottom: BorderSide(color: Color(0xffC0C0C0),width: 1),
                          ),
                          child: InkWell(
                            highlightColor: Colors.amber.shade100,
                            splashColor: Colors.amber.shade100,
                            onTap: () async{
                              Future.delayed(const Duration(milliseconds: 300), () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => CustomAlertDialog(
                                    title: '',
                                    contentWidget: const Text('グループを退会しますか？', style: TextStyle(fontSize: 15)),
                                    cancelActionText: 'いいえ',
                                    cancelAction: () {},
                                    defaultActionText: 'はい',
                                    action: () async {
                                      //ローディングメッセージを表示
                                      Loading.show(message: '処理中...', isDismissOnTap: false);
                                      //退会
                                      var result = await ApiGroupMessages.updateRoomMemberState(
                                          domain: myAccount.domain.url,
                                          roomId: widget.talkRoom.roomId,
                                          memberId: myAccount.member.id,
                                          state: (GroupMessageMemberState.withdrawal.index+1).toString(),
                                          deleteMemberId: myAccount.member.id);
                                      //ローディングメッセージを破棄
                                      Loading.dismiss();
                                      FunctionUtils.log(result);
                                      if(result is bool && result){
                                        //ルームidを初期化
                                        ref.read(selectedGroupMessageRoomProvider.notifier).state = null;
                                        if (!context.mounted) return;
                                        //2つ戻る
                                        int count = 0;
                                        Navigator.popUntil(context, (_) => count++ >= 2);
                                      }
                                    },
                                  ),
                                );
                              });
                            },
                            //splashColor: Colors.pink,
                            child: const ListTile(
                              title: Text('グループを退会',style: TextStyle(color: Colors.black,fontSize: 17)),
                              trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                            ),
                          ),
                        ),
                        // Material(
                        //   color: Colors.white,
                        //   shape: const Border(
                        //     bottom: BorderSide(width: 0.2),
                        //   ),
                        //   child: InkWell(
                        //     highlightColor: Colors.amber.shade100,
                        //     splashColor: Colors.amber.shade100,
                        //     onTap: () async{
                        //       Future.delayed(const Duration(milliseconds: 300), () {
                        //         if (!mounted) return;
                        //         //2つ戻る
                        //         int count = 0;
                        //         Navigator.popUntil(context, (_) => count++ >= 2);
                        //       });
                        //     },
                        //     //splashColor: Colors.pink,
                        //     child: const ListTile(
                        //       title: Text('テスト',style: TextStyle(color: Colors.black,fontSize: 17)),
                        //       trailing: Icon(Icons.chevron_right,color:Color(0xff3166f7)),
                        //     ),
                        //   ),
                        // ),
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
