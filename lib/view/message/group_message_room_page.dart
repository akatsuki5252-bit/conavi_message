import 'dart:io';

import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/group_message.dart';
import 'package:conavi_message/model/message.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/push_notifications.dart';
import 'package:conavi_message/utils/shared_prefs.dart';
import 'package:conavi_message/utils/widget_dialogs.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/message/invite_group_message_member_page.dart';
import 'package:conavi_message/view/message/participate_group_member_page.dart';
import 'package:conavi_message/view/message/setting_group_page.dart';
import 'package:conavi_message/view/util/file_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;


class GroupMessageRoomPage extends ConsumerStatefulWidget {
  final TalkGroupRoom talkRoom;
  const GroupMessageRoomPage(this.talkRoom, {super.key});

  @override
  ConsumerState<GroupMessageRoomPage> createState() => _GroupMessageRoomPageState();
}

class _GroupMessageRoomPageState extends ConsumerState<GroupMessageRoomPage> {

  bool _isEntry = false;
  bool _isInputOptionIcons = true;
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEntry = widget.talkRoom.isEntry;
  }

  //メッセージタップ時のダイアログ
  Widget showMessageOptionDialog(Message message,bool isMe){
    return SimpleDialog(
      children: [
        if(message.message.isNotEmpty)
          SimpleDialogOption(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('コピー'),
                Icon(Icons.content_copy,color: Colors.amber)
              ],
            ),
            onPressed: () {
              Navigator.pop(context, MessageOption.copy);
            },
          ),
        //自分のメッセージのみ削除可
        if(isMe)
          SimpleDialogOption(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('削除'),
                Icon(Icons.delete_outline,color: Colors.amber),
              ],
            ),
            onPressed: () {
              Navigator.pop(context, MessageOption.delete);
            },
          )
      ],
    );
  }

  //参加・拒否タブボタン
  PreferredSizeWidget? widgetMessageParticipateButtons(){
    if(!_isEntry) {
      final myAccount = ref.read(authProvider);
      return PreferredSize(
        preferredSize: const Size.fromHeight(45.0),
        child: TabBar(
          indicatorColor: Colors.white,
          tabs: [
            InkWell(
              onTap: () async{
                //ローディングメッセージを表示
                Loading.show(message: '処理中...', isDismissOnTap: false);
                //参加状態を更新（参加）
                var result = await ApiGroupMessages.updateRoomMemberState(
                  domain: myAccount.domain.url,
                  roomId: widget.talkRoom.roomId,
                  memberId: myAccount.member.id,
                  state: (GroupMessageMemberState.approval.index+1).toString(),
                  deleteMemberId: '',
                );
                //ローディングメッセージを破棄
                Loading.dismiss();
                FunctionUtils.log(result);
                if(result != null){
                  if(result){
                    ref.refresh(talkGroupMessagesFutureProvider(widget.talkRoom));
                    setState(() {
                      _isEntry = result;
                    });
                  }
                }
              },
              child: const SizedBox(
                height: 45.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.black),
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text('参加', style: TextStyle(fontSize: 13, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                //ローディングメッセージを表示
                Loading.show(message: '処理中...', isDismissOnTap: false);
                //参加状態を更新（拒否）
                var result = await ApiGroupMessages.updateRoomMemberState(
                  domain: myAccount.domain.url,
                  roomId: widget.talkRoom.roomId,
                  memberId: myAccount.member.id,
                  state: (GroupMessageMemberState.reject.index+1).toString(),
                  deleteMemberId: '',
                );
                //ローディングメッセージを破棄
                Loading.dismiss();
                FunctionUtils.log(result);
                if(result != null){
                  if(result){
                    if (!context.mounted) return;
                    Navigator.pop(context,true);
                  }
                }
              },
              child: const SizedBox(
                height: 45.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.not_interested, color: Colors.black),
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text('拒否', style: TextStyle(fontSize: 13, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    //build完了後
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //ルームidをセット
      ref.read(selectedGroupMessageRoomProvider.notifier).state = widget.talkRoom;
      final talkRoom = ref.read(selectedGroupMessageRoomProvider);
      if(talkRoom is TalkGroupRoom) {
        FunctionUtils.log('currentTalkRoomId:${talkRoom.roomId}');
      }
    });
    final myAccount = ref.read(authProvider);
    final talkGroupMessageList = ref.watch(talkGroupMessagesFutureProvider(widget.talkRoom));
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          //ルームidを初期化
          ref.read(selectedGroupMessageRoomProvider.notifier).state = null;
          Navigator.pop(context,true);
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                widget.talkRoom.roomName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              bottom: widgetMessageParticipateButtons(),
              centerTitle: false,
              elevation: 0,
              actions: [
                ///メンバー・招待・退会
                Visibility(
                  visible: _isEntry,
                  child: PopupMenuButton<GroupMessageAction>(
                    onSelected: (GroupMessageAction result) async{
                      switch(result){
                        case GroupMessageAction.member: //メンバー
                          var result = await Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => ParticipateGroupMemberPage(widget.talkRoom),
                            ),
                          );
                          // //メンバー情報を更新
                          // if (result is List<TalkGroupMember>) {
                          //   widget.talkRoom.talkMembers = result;
                          // }
                          //メッセージを更新
                          ref.refresh(talkGroupMessagesFutureProvider(widget.talkRoom));
                          break;
                        case GroupMessageAction.invite: //招待
                          var result = await Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => InviteGroupMessageMemberPage(widget.talkRoom),
                            ),
                          );
                          // //メンバー情報を更新
                          // if (result is List<TalkGroupMember>) {
                          //   widget.talkRoom.talkMembers = result;
                          // }
                          //メッセージを更新
                          ref.refresh(talkGroupMessagesFutureProvider(widget.talkRoom));
                          break;
                        case GroupMessageAction.setting:
                          var result = await Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => SettingGroupPage(widget.talkRoom),
                            ),
                          );
                          FunctionUtils.log(result);
                          if(result is bool){
                            if(result) {
                              final newTalkGroupRoom = await ApiGroupMessages.fetchGroupRoom(myAccount: myAccount, roomId: widget.talkRoom.roomId);
                              if (newTalkGroupRoom is TalkGroupRoom) {
                                setState(() {
                                  widget.talkRoom.imagePath = newTalkGroupRoom.imagePath;
                                  widget.talkRoom.roomName = newTalkGroupRoom.roomName;
                                });
                              }
                            }
                            //メッセージを更新
                            ref.refresh(talkGroupMessagesFutureProvider(widget.talkRoom));
                          }
                          break;
                        case GroupMessageAction.withdrawal:
                          // TODO: Handle this case.
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<GroupMessageAction>>[
                      const PopupMenuItem<GroupMessageAction>(
                        value: GroupMessageAction.member,
                        child: Text('メンバー',style: TextStyle(fontSize: 16)),
                      ),
                      const PopupMenuItem<GroupMessageAction>(
                        value: GroupMessageAction.invite,
                        child: Text('招待',style: TextStyle(fontSize: 16)),
                      ),
                      // const PopupMenuItem<GroupMessageAction>(
                      //   value: GroupMessageAction.withdrawal,
                      //   child: Text('退会',style: TextStyle(fontSize: 16)),
                      // ),
                      const PopupMenuItem<GroupMessageAction>(
                        value: GroupMessageAction.setting,
                        child: Text('設定',style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: talkGroupMessageList.when(
              data: (talkGroupMessageList){
                return SafeArea(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: talkGroupMessageList != null && talkGroupMessageList.isNotEmpty ? Scrollbar(
                          child: ListView.builder(
                            //画面幅を超える時にスクロールする
                            physics: const RangeMaintainingScrollPhysics(),
                            //容量が少ない時は上から
                            shrinkWrap: true,
                            //上にスクロール
                            reverse: true,
                            itemCount: talkGroupMessageList.length,
                            itemBuilder: (BuildContext context, index) {
                              //メッセージ成形
                              final GroupMessage message = talkGroupMessageList[index];
                              //日付：日本語対応
                              initializeDateFormatting('ja');
                              //送信日付
                              String sendDay = FunctionUtils.createMessageSendDayString(message, talkGroupMessageList, index);
                              return Padding(
                                padding: EdgeInsets.only(top: 15, left: 10, right: 10, bottom: index == 0 ? 10 : 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    //日付表示
                                    Visibility(
                                      visible: sendDay.isEmpty ? false : true,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Container(
                                              width: 125,
                                              height: 24,
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.only(bottom: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xffb8b8b8),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(sendDay,style: const TextStyle(fontSize:11,color:Colors.white))
                                          ),
                                        ),
                                      ),
                                    ),
                                    //メッセージ
                                    Visibility(
                                      visible: true,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 0),
                                        child: WidgetUtils.widgetMessage(myAccount,context,message)
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ) : const Center(child: Text('メッセージがありません')),
                      ),
                      //下部Widget
                      Visibility(
                        visible: _isEntry,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Material(
                              color: Colors.white,
                              shape: const Border(
                                top: BorderSide(color: Color(0xffC0C0C0),width: 1), //シルバー
                              ),
                              child: Row(
                                children: [
                                  Visibility(
                                    visible: !_isInputOptionIcons,
                                    //アイコン：収納
                                    child: Container(
                                      //color: Colors.blue,
                                      child: IconButton(
                                        padding: const EdgeInsets.only(left: 10,top: 5,right: 5,bottom: 5),
                                        constraints: const BoxConstraints(
                                          maxWidth: 40,
                                        ),
                                        onPressed: () async {
                                          if(!_isInputOptionIcons){
                                            setState(() {
                                              _isInputOptionIcons = true;
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: _isInputOptionIcons,
                                    child: Row(
                                      children: [
                                        //アイコン：カメラ
                                        IconButton(
                                          padding: const EdgeInsets.only(left: 10,top: 5,right: 0,bottom: 5),
                                          constraints: const BoxConstraints(
                                            maxWidth: 40,
                                          ),
                                          onPressed: () async {
                                            FocusScope.of(context).unfocus(); //フォーカスを外す
                                            final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                                            if (pickedFile == null) return;
                                            List<File> files = [File(pickedFile.path)];
                                            FunctionUtils.log(files);
                                            //ローディングメッセージを表示
                                            Loading.show(message: 'アップロード中...', isDismissOnTap: false,);
                                            //アップロード処理
                                            var result = await ApiGroupMessages.sendUploadFile(
                                              domain: myAccount.domain.url,
                                              roomId: widget.talkRoom.roomId,
                                              sendMemberFromId: myAccount.member.id,
                                              files: files,
                                            );
                                            if(result){
                                              //画面リロード
                                              ref.refresh(talkGroupMessagesFutureProvider(widget.talkRoom));
                                              //プッシュ通知
                                              bool result = await PushNotifications.sendPushGroupMessage(
                                                domain: myAccount.domain.url,
                                                roomId: widget.talkRoom.roomId,
                                                type: 'groupMessage',
                                                sendFromMemberId: myAccount.member.id,
                                                uniqueKey: FunctionUtils.createUniqueKeyFromDate(widget.talkRoom.createdTime),
                                                title: myAccount.member.name,
                                                body: '${myAccount.member.name}がファイルを送信しました',
                                                imageUrl: widget.talkRoom.imagePath
                                              );
                                              if(!result){
                                                FunctionUtils.log('プッシュ通知でエラーが発生');
                                              }
                                              Loading.dismiss();
                                            } else {
                                              Loading.error(message: 'アップロードに失敗しました');
                                            }
                                          },
                                          icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                                        ),
                                        //アイコン：画像
                                        IconButton(
                                          padding: const EdgeInsets.only(left: 10,top: 5,right: 5,bottom: 5),
                                          constraints: const BoxConstraints(
                                            maxWidth: 40,
                                          ),
                                          onPressed: () async {
                                            FocusScope.of(context).unfocus(); //フォーカスを外す
                                            final selectedFileType = await showDialog<MessageFileType>(
                                                context: context,
                                                builder: (_) {
                                                  return WidgetDialogs.showFileTypeDialog(context);
                                                });
                                            if(selectedFileType == null) return;
                                            FunctionUtils.log(selectedFileType);
                                            if (!context.mounted) return;
                                            var resultPickerFile = await Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => FilePickerPage(
                                                fileType: selectedFileType,
                                                multipleType: true,
                                                limitImageFileSize: 10.0,
                                                limitFileSize: 100.0,),
                                              ),
                                            );
                                            FunctionUtils.log("result: $resultPickerFile");
                                            if (resultPickerFile is List<PickerFile>) {
                                              List<File> files = [];
                                              for(var pickerFile in resultPickerFile){
                                                files.add(File(pickerFile.file.path));
                                              }
                                              //ローディングメッセージを表示
                                              Loading.show(message: 'アップロード中...', isDismissOnTap: false,);
                                              //アップロード処理
                                              var result = await ApiGroupMessages.sendUploadFile(
                                                domain: myAccount.domain.url,
                                                roomId: widget.talkRoom.roomId,
                                                sendMemberFromId: myAccount.member.id,
                                                files: files,
                                              );
                                              if(result){
                                                //画面リロード
                                                ref.refresh(talkGroupMessagesFutureProvider(widget.talkRoom));
                                                //プッシュ通知
                                                bool result = await PushNotifications.sendPushGroupMessage(
                                                  domain: myAccount.domain.url,
                                                  roomId: widget.talkRoom.roomId,
                                                  type: 'groupMessage',
                                                  sendFromMemberId: myAccount.member.id,
                                                  uniqueKey: FunctionUtils.createUniqueKeyFromDate(widget.talkRoom.createdTime),
                                                  title: myAccount.member.name,
                                                  body: '${myAccount.member.name}がファイルを送信しました',
                                                  imageUrl: widget.talkRoom.imagePath
                                                );
                                                if(!result){
                                                  FunctionUtils.log('プッシュ通知でエラーが発生');
                                                }
                                                Loading.dismiss();
                                              } else {
                                                Loading.error(message: 'アップロードに失敗しました');
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.image_outlined, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  //メッセージ入力欄
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left:0,top:7,right:0,bottom:7),
                                      child: TextField(
                                        controller: textController,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        minLines: 1,
                                        cursorColor: Colors.grey,
                                        onTap: () {
                                          if(_isInputOptionIcons){
                                            setState(() {
                                              _isInputOptionIcons = false;
                                            });
                                          }
                                        },
                                        onChanged: (value) async {
                                          //入力中の文字を端末に保存
                                          await SharedPrefs.setGroupMessage(roomId: widget.talkRoom.roomId, message: value);
                                        },
                                        decoration: InputDecoration(
                                          fillColor: const Color(0xffefefef), //シルバーホワイト
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(color: Colors.white),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(color: Colors.white),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      if (textController.text.isNotEmpty) {
                                        //フォーカスを外す
                                        FocusScope.of(context).unfocus();
                                        //入力テキスト
                                        var sendText = textController.text;
                                        //クリア
                                        textController.clear();
                                        await SharedPrefs.setGroupMessage(roomId: widget.talkRoom.roomId, message: '');
                                        // //メッセージ送信
                                        var result = await ApiGroupMessages.sendMessage(
                                            roomId: widget.talkRoom.roomId,
                                            sendMemberFromId: myAccount.member.id,
                                            message: sendText,
                                            domain: myAccount.domain.url);
                                        FunctionUtils.log(result);
                                        if (result) {
                                          //画面リロード
                                          // 状態を更新する
                                          ref.refresh(talkGroupMessagesFutureProvider(widget.talkRoom));
                                          //プッシュ通知
                                          bool result = await PushNotifications.sendPushGroupMessage(
                                            domain: myAccount.domain.url,
                                            roomId: widget.talkRoom.roomId,
                                            type: 'groupMessage',
                                            sendFromMemberId: myAccount.member.id,
                                            uniqueKey: FunctionUtils.createUniqueKeyFromDate(widget.talkRoom.createdTime),
                                            title: widget.talkRoom.roomName,
                                            body: sendText,
                                            imageUrl: widget.talkRoom.imagePath,
                                          );
                                          if(!result){
                                            FunctionUtils.log('プッシュ通知でエラーが発生');
                                          }
                                        }else{
                                          Loading.error(message: 'メッセージの送信に失敗しました');
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.send,
                                      color: Colors.amber,
                                    ),
                                    splashColor: Colors.transparent,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber),
              ),
            )
          ),
        )
      ),
    );
  }
}
