import 'package:bubble/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conavi_message/firestore/room_firestore.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/message.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/utils/upload_file.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/push_notifications.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class ChatRoomPage extends StatefulWidget {
  final TalkRoom talkRoom;
  const ChatRoomPage(this.talkRoom, {super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  Auth myAccount = Authentication.myAccount!;
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text(
            widget.talkRoom.roomName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
          centerTitle: false,
        ),
        body: SafeArea(
          child: Stack(
            /*alignment: Alignment.bottomCenter,*/
            children: [
              StreamBuilder<QuerySnapshot>(
                  stream: RoomFirestore.fetchMessageSnapshot(widget.talkRoom.roomId),
                  builder: (context, snapshot) {
                    /*if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.grey,
                        ),
                      );
                    } else*/
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Scrollbar(
                          child: ListView.builder(
                              //画面幅を超える時にスクロールする
                              physics: const RangeMaintainingScrollPhysics(),
                              //容量が少ない時は上から
                              shrinkWrap: true,
                              //上にスクロール
                              reverse: true,
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                //メッセージ成形
                                final Message message = getMessage(
                                    snapshot.data!.docs[index],
                                    widget.talkRoom.talkMembers);
                                //自分のメッセージか判定
                                if (myAccount.member.id == message.member!.id) {
                                  message.isMe = true;
                                }
                                //表示日付
                                String sendDay =
                                    intl.DateFormat('yyyy-MM-dd(E)')
                                        .format(message.sendTime);
                                //最後のメッセージ以外
                                if ((index + 1) < snapshot.data!.docs.length) {
                                  Message nextMessage = getMessage(
                                      snapshot.data!.docs[(index + 1)],
                                      widget.talkRoom.talkMembers);
                                  //print(message.message);
                                  //print(nextMessage.message);
                                  //次のメッセージ日付と同じ場合は空
                                  String nextDay =
                                      intl.DateFormat('yyyy-MM-dd(E)')
                                          .format(nextMessage.sendTime);
                                  if (sendDay == nextDay) {
                                    sendDay = '';
                                  }
                                }
                                return Padding(
                                  padding: EdgeInsets.only(
                                      top: 10,
                                      left: 10,
                                      right: 10,
                                      bottom: index == 0 ? 10 : 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Visibility(
                                        visible: sendDay.isEmpty ? false : true,
                                        child: Center(
                                          child: Text(sendDay),
                                        ),
                                      ),
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          textDirection: message.isMe
                                              ? TextDirection.rtl
                                              : TextDirection.ltr,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Visibility(
                                              visible: message.isMe == false,
                                              child: Container(
                                                alignment: Alignment.topCenter,
                                                padding: const EdgeInsets.only(
                                                    right: 5),
                                                child: CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor:
                                                      Colors.amberAccent,
                                                  foregroundImage: message.member!.imagePath.isNotEmpty
                                                      ? NetworkImage(message.member!.imagePath)
                                                      : null,
                                                  child: message.member!.imagePath.isEmpty
                                                      ? const Icon(Icons.person,
                                                          size: 20,
                                                          color: Colors.black)
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            Bubble(
                                              color: message.isMe
                                                  ? Colors.orange
                                                  : const Color(0xffd1d8e0),
                                              radius: const Radius.circular(15),
                                              nip: message.isMe
                                                  ? BubbleNip.rightBottom
                                                  : BubbleNip.leftTop,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 1,
                                                    left: 1,
                                                    right: 1,
                                                    bottom: 1),
                                                child: Stack(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  children: [
                                                    Container(
                                                      //表示可能領域の7割まで横サイズ
                                                      constraints: BoxConstraints(
                                                          maxWidth: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.6,
                                                          minWidth: 30),
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 20),
                                                      child: Text(
                                                        message.message,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            height: 1.2,
                                                            color: message.isMe
                                                                ? Colors.white
                                                                : Colors.black),
                                                      ),
                                                    ),
                                                    Text(
                                                      intl.DateFormat('HH:mm')
                                                          .format(
                                                              message.sendTime),
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.black),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              alignment: Alignment.bottomCenter,
                                              child: const Text('未読',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                        ),
                      );
                    } else {
                      return Container();
                    }
                  }),
              Column(
                /*mainAxisSize: MainAxisSize.min,*/
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {},
                          icon: const Icon(Icons.photo_camera, color: Colors.grey),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              minLines: 1,
                              cursorColor: Colors.grey,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.only(left: 0),
                                /*border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                  ),
                                ),*/
                                border: InputBorder.none,
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (controller.text.isNotEmpty) {
                              FocusScope.of(context).unfocus();
                              var sendText = controller.text;
                              controller.clear();
                              await RoomFirestore.sendMessage(
                                  roomId: widget.talkRoom.roomId,
                                  senderId: myAccount.member.id,
                                  message: sendText,
                              );
                              //プッシュ通知
                              List<String?> pushMemberIds = [];
                              for (var member in widget.talkRoom.talkMembers) {
                                if (myAccount.member.id != member.id){
                                  pushMemberIds.add(member.id);
                                }
                              }
                              await PushNotifications.sendPushMessage(
                                domain: myAccount.domain.url,
                                title: widget.talkRoom.roomName,
                                body: sendText,
                                memberIds: pushMemberIds,
                                type: 'chat',
                                roomId: widget.talkRoom.roomId,
                                uniqueKey: intl.DateFormat('yyyyMMddHHmm').format(widget.talkRoom.createdTime),
                                imageUrl: ''
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.send,
                            color: Colors.grey,
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    height: MediaQuery.of(context).padding.bottom,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Message getMessage(QueryDocumentSnapshot doc, List<Member> members) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    late Member? chatMember;
    for (var member in members) {
      if (data['sender_id'] == member.id) {
        chatMember = member;
      }
    }
    final Message message = Message(
      id:'',
      message: data['message'],
      widgetMessage: WidgetUtils.textWithUrl(data['message'] ?? '',Colors.black,15),
      fileUrl: '',
      member: chatMember,
      isMe: false,
      readFlag: false,
      sendTime: data['send_time'] is Timestamp
          ? data['send_time'].toDate()
          : data['send_time'], fileName: '', fileExt: '',
      file: UploadFile(id:'',fileName:'',fileUrl: '',fileExt: '')
    );
    return message;
  }
}
