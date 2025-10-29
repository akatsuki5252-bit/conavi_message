import 'dart:convert';
import 'dart:io';

import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/main.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/message.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/upload_file.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/push_notifications.dart';
import 'package:conavi_message/utils/shared_prefs.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/util/audio_view_page.dart';
import 'package:conavi_message/view/util/file_picker_page.dart';
import 'package:conavi_message/view/util/image_view_page.dart';
import 'package:conavi_message/view/util/pdf_view_page.dart';
import 'package:conavi_message/view/util/video_view_page.dart';
//**import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
//**import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;

class MessageRoomPage extends ConsumerStatefulWidget {
  final TalkRoom talkRoom;
  const MessageRoomPage(this.talkRoom, {super.key});

  @override
  ConsumerState<MessageRoomPage> createState() => _MessageRoomPageState();
}

class _MessageRoomPageState extends ConsumerState<MessageRoomPage> with WidgetsBindingObserver{

  final TextEditingController controller = TextEditingController();
  final List<String?> _pushMemberIds = []; //通知メンバーid
  String _sendFromId = ''; //送信メンバーid
  String _sendToId = ''; //受信メンバーid
  bool _isInputOptionIcons = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final myAccount = ref.read(authProvider);
    _sendFromId = myAccount.member.id;
    for (var member in widget.talkRoom.talkMembers) {
      if (_sendFromId != member.id) {
        _sendToId = member.id;
        _pushMemberIds.add(member.id);
      }
    }

    //build完了後
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //ルームidをセット
      ref.read(selectedMessageRoomProvider.notifier).state = widget.talkRoom;
    });
    //ルームidの通知を削除
    flutterLocalNotificationsPlugin.cancel(int.parse(widget.talkRoom.roomId));
    //過去の入力値をセット
    controller.text = SharedPrefs.getRoomMessage(roomId: widget.talkRoom.roomId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        FunctionUtils.log('room-message:非アクティブになったときの処理');
        break;
      case AppLifecycleState.paused:
        FunctionUtils.log('room-message:停止されたときの処理');
        break;
      case AppLifecycleState.resumed:
        FunctionUtils.log('room-message:再開されたときの処理');
        break;
      case AppLifecycleState.detached:
        FunctionUtils.log('room-message:破棄されたときの処理');
        break;
      case AppLifecycleState.hidden:
        FunctionUtils.log('room-message:hidden');
        break;
    }
  }

  //メッセージタップ時のダイアログ
  Widget showMessageOptionDialog(Message message,bool isMe){
    FunctionUtils.log(message.message);
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

  //ファイル選択時のダイアログ
  Widget showFileTypeDialog(){
    return SimpleDialog(
      children: [
        SimpleDialogOption(
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('画像'),
              Icon(Icons.image_outlined,color: Colors.amber)
            ],
          ),
          onPressed: () {
            Navigator.pop(context, MessageFileType.image);
          },
        ),
        SimpleDialogOption(
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('ファイル'),
              Icon(Icons.insert_drive_file_outlined,color: Colors.amber)
            ],
          ),
          onPressed: () {
            Navigator.pop(context, MessageFileType.file);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    final talkMessageList = ref.watch(talkMessagesFutureProvider(widget.talkRoom));
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) return;
          //ルームidを初期化
          ref.read(selectedMessageRoomProvider.notifier).state = null;
          //戻るボタン押下時にtrueを返す
          Navigator.pop(context,true);
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              widget.talkRoom.roomName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: false,
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.refresh),
            //     onPressed: () => {_reload()},
            //   ),
            // ],
          ),
          body: talkMessageList.when(
            data: (talkMessageList) {
              return SafeArea(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: talkMessageList != null && talkMessageList.isNotEmpty ? Scrollbar(
                        child: ListView.builder(
                        //画面幅を超える時にスクロールする
                        physics: const RangeMaintainingScrollPhysics(),
                        //容量が少ない時は上から
                        shrinkWrap: true,
                        //上にスクロール
                        reverse: true,
                        itemCount: talkMessageList.length,
                        itemBuilder: (BuildContext context, index) {
                          //メッセージ成形
                          final Message message = talkMessageList[index];
                          //日付：日本語対応
                          initializeDateFormatting('ja');
                          //送信日付
                          String sendDay = '${intl.DateFormat('yyyy年MM月dd日').format(message.sendTime)}(${intl.DateFormat.E('ja').format(message.sendTime)})';
                          //次の送信日付（※最後のメッセージは除外）
                          if ((index + 1) < talkMessageList.length) {
                            Message nextMessage = talkMessageList[(index + 1)];
                            //次の送信日付と同じ場合は表示しない
                            String nextDay = '${intl.DateFormat('yyyy年MM月dd日').format(nextMessage.sendTime)}(${intl.DateFormat.E('ja').format(nextMessage.sendTime)})';
                            if (sendDay == nextDay) sendDay = '';
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              top: 10,
                              left: 10,
                              right: 10,
                              bottom: index == 0 ? 10 : 0,),
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
                                        width: 140,
                                        height: 25,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.only(bottom: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(color: Colors.grey),
                                        ),
                                        child: Text(sendDay,style: const TextStyle(fontSize:12,color:Colors.white))
                                      ),
                                    ),
                                  ),
                                ),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    textDirection: message.isMe
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      //相手メンバーアイコン
                                      Visibility(
                                        visible: message.isMe == false,
                                        child: Container(
                                          width: 35,
                                          alignment: Alignment.topCenter,
                                          padding: const EdgeInsets.only(right: 0),
                                          // child: CachedNetworkImage(
                                          //   imageUrl: 'https://dev.conavi.net/api/upload/test.php',//message.member!.imagePath,
                                          //   imageBuilder: (context, imageProvider) => Container(
                                          //     width: 35,
                                          //     height: 35,
                                          //     decoration: BoxDecoration(
                                          //       borderRadius: const BorderRadius.all(Radius.circular(50)),
                                          //       image: DecorationImage(
                                          //         image: imageProvider,
                                          //         fit: BoxFit.cover,
                                          //       ),
                                          //     ),
                                          //   ),
                                          //   placeholder: (context, url) => const CircularProgressIndicator(color: Colors.amber),
                                          //   errorWidget: (context, url, error) => const Icon(Icons.error,color: Colors.amber),
                                          // ),
                                          child:CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.grey,
                                            foregroundImage: message.member!.imagePath.isNotEmpty
                                                ? NetworkImage('${myAccount.domain.url}/api/upload/file.php?member_id=${message.member!.id}&app_token=${myAccount.member.appToken}')
                                                : null,
                                            child: message.member!.imagePath.isEmpty
                                                ? const Icon(Icons.person,
                                                size: 35, color: Colors.white)
                                                : null,
                                          ),

                                          // CircleAvatar(
                                          //   radius: 20,
                                          //   backgroundColor: Colors.amberAccent,
                                          //   foregroundImage: message.member!.imagePath.isNotEmpty
                                          //       ? NetworkImage(message.member!.imagePath)
                                          //       : null,
                                          //   child: message.member!.imagePath.isEmpty
                                          //       ? const Icon(
                                          //           Icons.person,
                                          //           size: 20,
                                          //           color: Colors.black)
                                          //       : null,
                                          // ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          //メッセージ
                                          if(message.message.isNotEmpty) Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
                                            children: [
                                              InkWell(
                                                onLongPress: () async {
                                                  showMessageOption(myAccount, message);
                                                },
                                                highlightColor: Colors.transparent,
                                                child: Bubble(
                                                  color: message.isMe ? const Color(0xffFCD997) : const Color(0xffd1d8e0),
                                                  radius: const Radius.circular(15),
                                                  nip: message.isMe ? BubbleNip.rightBottom : BubbleNip.leftTop,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                                    child: Container(
                                                      //表示可能領域の6割まで横サイズ
                                                      constraints: BoxConstraints(
                                                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                                                        minWidth: 10,
                                                      ),
                                                      child: message.widgetMessage
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              //既読・時間
                                              Container(
                                                alignment: Alignment.bottomCenter,
                                                //color: Colors.blue,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Visibility(
                                                      visible: message.isMe,
                                                      child: Text(message.readFlag ? '既読' : '未読', style: const TextStyle(fontSize: 11, color: Colors.black)),
                                                    ),
                                                    Text(intl.DateFormat('HH:mm').format(message.sendTime),style: const TextStyle(fontSize: 11, color: Colors.black)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          //ファイル
                                          Visibility(
                                            visible: message.fileUrl.isNotEmpty,
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
                                              children: [
                                                //ファイル表示
                                                WidgetUtils.showMessageFile(
                                                  context: context,
                                                  fileUrl: message.file.fileUrl,
                                                  fileName: message.file.fileName,
                                                  fileExtension: message.file.fileExt,
                                                  isMe: message.isMe,
                                                  isLast: true,
                                                ),
                                                //既読・時間
                                                Container(
                                                  alignment: Alignment.bottomCenter,
                                                  //color: Colors.blue,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      Visibility(
                                                        visible: message.isMe,
                                                        child: Text(message.readFlag ? '既読' : '未読', style: const TextStyle(fontSize: 11, color: Colors.black)),
                                                      ),
                                                      Text(intl.DateFormat('HH:mm').format(message.sendTime),style: const TextStyle(fontSize: 11, color: Colors.black)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },),
                      ) : const Center(child: Text('メッセージがありません'),),
                    ),
                    //下部Widget
                    Column(
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
                                        try {
                                          final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
                                          if (pickedFile == null) throw Exception('file:null');
                                          List<File> files = [File(pickedFile.path)];
                                          FunctionUtils.log(files);
                                          sendUploads(
                                              talkRoom: widget.talkRoom,
                                              myAccount: myAccount,
                                              sendFromId: _sendFromId,
                                              sendToId: _sendToId,
                                              message: '写真を送信しました',
                                              files: files,
                                              pushMemberIds: _pushMemberIds,
                                          );
                                        } catch (e) {
                                          FunctionUtils.log('Failed to pick file: $e');
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
                                        final selectedFileType = await showDialog<MessageFileType>(
                                            context: context,
                                            builder: (_) {
                                              return showFileTypeDialog();
                                            });
                                        if(selectedFileType == null) return;
                                        if (!context.mounted) return;
                                        // //フォーカスを外す
                                        FocusScope.of(context).unfocus();
                                        var result = await Navigator.push(context,
                                          MaterialPageRoute(
                                            builder: (context) => FilePickerPage(
                                                fileType: selectedFileType,
                                                multipleType: true,
                                                limitImageFileSize: 10.0,
                                                limitFileSize: 100.0),
                                          ),
                                        );
                                        FunctionUtils.log("result: $result");
                                        if (result is List<PickerFile>) {
                                          List<File> files = [];
                                          for(var pickerFile in result){
                                            files.add(File(pickerFile.file.path));
                                          }
                                          sendUploads(
                                            talkRoom: widget.talkRoom,
                                            myAccount: myAccount,
                                            sendFromId: _sendFromId,
                                            sendToId: _sendToId,
                                            message: 'ファイルを送信しました',
                                            files: files,
                                            pushMemberIds: _pushMemberIds,
                                          );
                                        }


                                        // if(result is List<ImageFile>){
                                        //   List<File> files = [];
                                        //   for(var image in result){
                                        //     files.add(File(image.file.path));
                                        //   }
                                        //   sendUploads(
                                        //       talkRoom: widget.talkRoom,
                                        //       myAccount: myAccount,
                                        //       sendFromId: _sendFromId,
                                        //       sendToId: _sendToId,
                                        //       message: '画像を送信しました',
                                        //       files: files,
                                        //       pushMemberIds: _pushMemberIds,
                                        //       limitSize: 5.0);
                                        // }
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
                                    controller: controller,
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
                                      await SharedPrefs.setRoomMessage(roomId: widget.talkRoom.roomId, message: value);
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
                                  if (controller.text.isNotEmpty) {
                                    var sendText = controller.text;
                                    //フォーカスを外す
                                    FocusScope.of(context).unfocus();
                                    //入力テキストクリア
                                    controller.clear();
                                    //保存している入力文字をクリア
                                    await SharedPrefs.setRoomMessage(roomId: widget.talkRoom.roomId, message: '');
                                    //メッセージ送信
                                    var result = await ApiMessages.sendMessage(
                                        roomId: widget.talkRoom.roomId,
                                        senderFromId: _sendFromId,
                                        senderToId: _sendToId,
                                        message: sendText,
                                        domain: myAccount.domain.url);
                                    if (result) {
                                      //画面リロード
                                      _reload();
                                      //プッシュ通知
                                      await sendPushNotification(
                                        account: myAccount,
                                        roomId: widget.talkRoom.roomId,
                                        title: myAccount.member.name,
                                        body: sendText,
                                        memberIds: _pushMemberIds,
                                        imageUrl: myAccount.member.imagePath.isNotEmpty ? '${myAccount.domain.url}/api/upload/file.php?member_id=${myAccount.member.id}&app_token=${myAccount.member.appToken}' : ''
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.amber,
                                ),
                              )
                            ],
                          ),
                        ),
                        // Container(
                        //   color: Colors.white,
                        //   height: MediaQuery.of(context).padding.bottom,
                        // ),
                      ],
                    ),
                    // MessageBar(
                    //   replyCloseColor: Colors.black,
                    //   onTapCloseReply: (){FunctionUtils.log('aa');},
                    //   replying: true,
                    //   replyingTo: 'aaa',
                    //   sendButtonColor: Colors.amber,
                    //   onSend: (_) => FunctionUtils.log(_),
                    //   actions: [
                    //     InkWell(
                    //       child: Icon(
                    //         Icons.add,
                    //         color: Colors.black,
                    //         size: 24,
                    //       ),
                    //       onTap: () {},
                    //     ),
                    //     Padding(
                    //       padding: EdgeInsets.only(left: 0, right: 8),
                    //       child: InkWell(
                    //         child: Icon(
                    //           Icons.image,
                    //           color: Colors.green,
                    //           size: 24,
                    //         ),
                    //         onTap: () {},
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              );
            },
            error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
          ),
        ),
      ),
    );
  }

  //画面更新
  void _reload() {
    // 状態を更新する
    ref.refresh(talkMessagesFutureProvider(widget.talkRoom));
  }

  //メッセージ長押しオプション
  void showMessageOption(Auth myAccount,Message message) async{
    final selectedOption = await showDialog<MessageOption>(
        context: context,
        builder: (_) {
          return showMessageOptionDialog(message,message.isMe);
        });
    switch(selectedOption){
      case MessageOption.copy:
        FunctionUtils.log('copy');
        Clipboard.setData(ClipboardData(text: message.message));
        break;
      case MessageOption.delete:
        showDialog(
          context: context,
          builder: (dialogContext) =>
            CustomAlertDialog(
              title: '削除',
              contentWidget: Text(message.fileUrl.isNotEmpty
                  ? 'ファイルを削除しますか？'
                  : 'メッセージを削除しますか？',
                  style: const TextStyle(fontSize: 15)),
              cancelActionText: 'Cancel',
              defaultActionText: 'OK',
              action: () async {
                FunctionUtils.log('delete:${message.id}');
                //ローディングメッセージを表示
                Loading.show(message: '削除中...', isDismissOnTap: false,);
                var result = await ApiMessages.deleteMessage(
                    messageId: message.id,
                    domain: myAccount.domain.url);
                if(result){
                  //画面更新
                  _reload();
                  //ローディング終了
                  Loading.dismiss();
                }else{
                  //エラーダイアログ
                  Loading.error(message: '削除に失敗しました');
                }
              },
            ),);
        break;
      case null:
        // TODO: Handle this case.
    }
  }

  //ファイルメッセージ
  Widget showFile(Auth myAccount,TalkRoom talkRoom,Message message){
    if(message.file.isImageFlag){
      FunctionUtils.log(message.file.fileUrl);
      //画像
      return Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            maxHeight: 320,
            minHeight: 20.0,
            minWidth: 20.0,
          ),
          padding: message.isMe
              ? const EdgeInsets.only(left: 5,right: 5,top: 10,bottom: 0)
              : const EdgeInsets.only(left: 5,right: 5,top: 10,bottom: 0),
          child: InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewPage(message.file.fileUrl, message.file.fileName),
                ),
              );
            },
            onLongPress: () {
              if(message.isMe) showMessageOption(myAccount, message);
            },
            child: CachedNetworkImage(
              maxHeightDiskCache: 1000,
              imageUrl: message.file.fileUrl,
              placeholder: (context, url) => const CircularProgressIndicator(color: Colors.amber),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
              fit: BoxFit.contain,
            ),
          )
          //child: Image.network('https://dev.conavi.net/api/upload/test.php'),
      );
    }else if(message.file.isPdfFlag) {
      //pdf
      return InkWell(
        onTap: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => PdfViewPage(message.file.fileUrl, message.file.fileName)),
          );
        },
        child: IgnorePointer(
          child: Container(
              width: 320,
              height: 320,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
                maxHeight: 320,
              ),
              alignment: Alignment.center,
              padding: message.isMe
                  ? const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 0)
                  : const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 0),
              child: const PDF(
                swipeHorizontal: false,
                defaultPage: 0,
                // pageFling: true,
                // fitEachPage: true,
                // pageSnap: true,
                // preventLinkNavigation: true
              ).cachedFromUrl(
                message.file.fileUrl,
                placeholder: (progress) =>
                const CircularProgressIndicator(color: Colors.amber),
                errorWidget: (error) =>
                const Icon(Icons.error, color: Colors.red),
              )
          ),
        ),
      );
    } if(message.file.isVideoFlag || message.file.isAudioFlag){
      //video or audio
      return InkWell(
        onTap: () async{
          //ファイル閲覧フラグ
          ref.read(isFilePreviewFlagProvider.notifier).state = true;
          //専用ビューア
          bool? result;
          if(message.file.isVideoFlag) {
            result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => VideoViewPage(message.file.fileUrl, message.file.fileName))
            );
          }else if(message.file.isAudioFlag){
            result = await Navigator.push(context,
                MaterialPageRoute(builder: (context) => AudioViewPage(message.file.fileUrl, message.file.fileName))
                //MaterialPageRoute(builder: (context) => TestAudioPage())
            );
          }
          FunctionUtils.log("result: $result");
          if(result is bool && result){
            //ファイル閲覧フラグ
            ref.read(isFilePreviewFlagProvider.notifier).state = false;
          }
        },
        child: Bubble(
          margin: const BubbleEdges.only(top: 10),
          color: message.isMe ? const Color(0xFFFCD997) : const Color(0xffd1d8e0),
          radius: const Radius.circular(15),
          nip: message.isMe ? BubbleNip.rightBottom : BubbleNip.leftTop,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            //表示可能領域の6割まで横サイズ
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
              minWidth: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: message.file.isVideoFlag == true ? const Icon(Icons.video_file_outlined)
                      : message.file.isAudioFlag == true ? const Icon(Icons.audio_file_outlined)
                      : const Icon(Icons.description_outlined),
                ),
                Flexible(
                  child: Text(
                    message.fileName,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 15, color: Colors.blue),
                  ),
                  // child: RichText(
                  //     text: TextSpan(
                  //     text: message.fileName,
                  //     style: const TextStyle(
                  //       fontSize: 15,
                  //       color: Colors.blue,
                  //       decoration: TextDecoration.underline,
                  //     ),
                  //     recognizer: TapGestureRecognizer()
                  //       ..onTap = () async {
                  //         try {
                  //           final uri = Uri.parse(message.file.fileUrl);
                  //           if (await canLaunchUrl(uri)) {
                  //             await launchUrl(uri);
                  //           } else {
                  //             FunctionUtils.log('Could not launch $uri');
                  //           }
                  //         } catch (e) {
                  //           FunctionUtils.log('error url_launch:$e');
                  //         }
                  //       },
                  //   )
                  // )
                ),
              ],
            ),
          ),
        )
      );

      //   child: Container(
      //     width: 225,
      //     constraints: BoxConstraints(
      //       maxWidth: MediaQuery.of(context).size.width * 0.6,
      //       minHeight: 125,
      //     ),
      //     alignment: Alignment.center,
      //     padding: message.isMe
      //         ? const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 0)
      //         : const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 0),
      //     child: AspectRatio(
      //       aspectRatio: message.file.videoPlayerController!.value.aspectRatio,
      //       child: Stack(
      //         alignment: Alignment.bottomCenter,
      //         children: <Widget>[
      //           VideoPlayer(
      //               message.file.videoPlayerController!
      //                 //..setLooping(false)
      //                 //..initialize()
      //                 ..addListener(() {})
      //                 ..setLooping(false)
      //                 ..initialize()
      //                     .then((value) => VideoPlayerController.network(message.file.fileUrl).play())
      //           ),
      //           const AnimatedSwitcher(
      //             duration: Duration(milliseconds: 50),
      //             reverseDuration: Duration(milliseconds: 200),
      //             child: Center(
      //                 child: Icon(
      //                   Icons.play_arrow,
      //                   color: Colors.white,
      //                   size: 100.0,
      //                   semanticLabel: 'Play',
      //                 ),
      //               ),
      //             ),
      //         ],
      //       ),
      //     ),
      //   ),
      // );
    }else{
      return Bubble(
        margin: const BubbleEdges.only(top: 10),
        color: message.isMe ? const Color(0xFFFCD997) : const Color(0xffd1d8e0),
        radius: const Radius.circular(15),
        nip: message.isMe ? BubbleNip.rightBottom : BubbleNip.leftTop,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          //表示可能領域の6割まで横サイズ
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
            minWidth: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 2),
                child: Icon(Icons.description_outlined),
              ),
              Flexible(
                child: Text(
                  message.fileName,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 15,
                      color: message.isMe ? Colors.black : Colors.black),
                ),
                // child: RichText(
                //     text: TextSpan(
                //     text: message.fileName,
                //     style: const TextStyle(
                //       fontSize: 15,
                //       color: Colors.blue,
                //       decoration: TextDecoration.underline,
                //     ),
                //     recognizer: TapGestureRecognizer()
                //       ..onTap = () async {
                //         try {
                //           final uri = Uri.parse(message.file.fileUrl);
                //           if (await canLaunchUrl(uri)) {
                //             await launchUrl(uri);
                //           } else {
                //             FunctionUtils.log('Could not launch $uri');
                //           }
                //         } catch (e) {
                //           FunctionUtils.log('error url_launch:$e');
                //         }
                //       },
                //   )
                // )
              ),
            ],
          ),
        ),
      );
    }
  }

  //プッシュ通信
  Future<void> sendPushNotification({
      required Auth account,
      required String roomId,
      required String title,
      required String body,
      required List<String?> memberIds,
      required String imageUrl}) async {
    bool result = await PushNotifications.sendPushMessage(
      domain: account.domain.url,
      roomId: widget.talkRoom.roomId,
      type: 'message',
      title: account.member.name,
      body: body,
      memberIds: memberIds,
      uniqueKey: FunctionUtils.createUniqueKeyFromDate(widget.talkRoom.createdTime),
      imageUrl: imageUrl
    );
    if(!result){
      FunctionUtils.log('プッシュ通知でエラーが発生');
    }
  }

  //ファイル送信
  Future<void> sendUploads({
    required TalkRoom talkRoom,
    required Auth myAccount,
    required String sendFromId,
    required String sendToId,
    required String message,
    required List<File> files,
    required List<String?> pushMemberIds}) async{

    //ローディングメッセージを表示
    Loading.show(message: 'アップロード中...', isDismissOnTap: false);

    //アップロード処理
    var result = await ApiMessages.sendUploadFile(
        roomId: talkRoom.roomId,
        sendFromId: sendFromId,
        sendToId: sendToId,
        files: files,
        domain: myAccount.domain.url);
    if (result) {
      //画面リロード
      _reload();
      //プッシュ通知
      await sendPushNotification(
        account: myAccount,
        roomId: talkRoom.roomId,
        title: myAccount.member.name,
        body: message,
        //controller.text,
        memberIds: pushMemberIds,
        imageUrl: myAccount.member.imagePath.isNotEmpty ? '${myAccount.domain.url}/api/upload/file.php?member_id=${myAccount.member.id}&app_token=${myAccount.member.appToken}' : ''
      );
      //ローディングを終了
      Loading.dismiss();
    } else {
      //エラーメッセージダイアログ
      Loading.error(message: ApiMessages.error);
    }

    // bool isEmptyExtension = false;
    // bool isFileSizeOver = false;
    // for(var file in files){
    //   //拡張子チェック
    //   // if(path.extension(file.path).isEmpty){
    //   //   isEmptyExtension = true;
    //   // }
    //   //ファイルサイズチェック
    //   // if(FunctionUtils.checkFileSize(file.readAsBytesSync().lengthInBytes.toDouble(),limitSize)){
    //   //   isFileSizeOver = true;
    //   // }
    // }
    //
    // if(!isEmptyExtension && !isFileSizeOver) {
    //
    //
    // }else{
    //   if(isEmptyExtension) {
    //     EasyLoading.showError(
    //       '拡張子がありません',
    //       dismissOnTap: true,
    //       maskType: EasyLoadingMaskType.black,
    //     );
    //   }else if(isFileSizeOver){
    //     EasyLoading.showError(
    //       '最大アップロードサイズを超過しています:$limitSize MB',
    //       dismissOnTap: true,
    //       maskType: EasyLoadingMaskType.black,
    //     );
    //   }
    // }
  }

}
