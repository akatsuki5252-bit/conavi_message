import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conavi_message/firestore/room_firestore.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/view/chat/chat_room_page.dart';
import 'package:conavi_message/view/chat/select_account_page.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Auth myAccount = Authentication.myAccount!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('チャット')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SelectAccountPage(),
                ),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: RoomFirestore.fetchJoinedRoomSnapshot(myAccount.member.id),
          builder: (context, streamSnapshot) {
            if (streamSnapshot.hasData) {
              FunctionUtils.log(streamSnapshot.data);
              return FutureBuilder<List<TalkRoom>?>(
                  future: RoomFirestore.fetchJoinedRooms(
                      snapshot: streamSnapshot.data!,
                      domain: myAccount.domain.url,
                  ),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      if (futureSnapshot.hasData) {
                        List<TalkRoom> talkRooms = futureSnapshot.data!;
                        return ListView.builder(
                            itemCount: talkRooms.length,
                            itemBuilder: (context, index) {
                              talkRooms[index].roomName =
                                  FunctionUtils.getTalkRoomName(
                                      myAccount.member, talkRooms[index].talkMembers);
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatRoomPage(talkRooms[index]),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: index == 0
                                          ? const Border(
                                              top: BorderSide(
                                                  color: Colors.grey, width: 0),
                                              bottom: BorderSide(
                                                  color: Colors.grey, width: 0),
                                            )
                                          : const Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey, width: 0),
                                            )),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 15),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.amberAccent,
                                          child: Icon(
                                            Icons.textsms_outlined,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              talkRooms[index].roomName,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Visibility(
                                              visible: talkRooms[index]
                                                              .lastMessage !=
                                                          null &&
                                                      talkRooms[index]
                                                          .lastMessage
                                                          .isNotEmpty
                                                  ? true
                                                  : false,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 5),
                                                child: Text(
                                                  talkRooms[index]
                                                              .lastMessage !=
                                                          null
                                                      ? talkRooms[index]
                                                          .lastMessage
                                                      : '',
                                                  maxLines: 2,
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      height: 1.2),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                      } else {
                        return const Center(child: Text('チャットルームの取得に失敗しました'));
                      }
                    }
                  });
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
