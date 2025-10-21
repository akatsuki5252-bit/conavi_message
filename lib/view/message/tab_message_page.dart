import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/view/message/message_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabMessagePage extends ConsumerStatefulWidget {
  const TabMessagePage({Key? key}) : super(key: key);

  @override
  ConsumerState<TabMessagePage> createState() => _TabMessagePageState();
}

class _TabMessagePageState extends ConsumerState<TabMessagePage> {

  @override
  Widget build(BuildContext context) {
    final Auth myAccount = ref.read(authProvider);
    final talkRoomsList = ref.watch(talkRoomsFutureProvider);
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.refresh),
      //   onPressed: () async {
      //     if (await FlutterAppBadger.isAppBadgeSupported()) {
      //       print('batch');
      //       FlutterAppBadger.updateBadgeCount(5); // <-引数の`number`が`null`だった場合は`0`
      //     }
      //   },
      // ),
      body: talkRoomsList.when(
        data: (talkRoomsList) {
          //キャッシュをクリア
          PaintingBinding.instance.imageCache.clear();
          return talkRoomsList != null && talkRoomsList.isNotEmpty ? RefreshIndicator(
            onRefresh: () async {
              // 状態を更新する
              ref.refresh(talkRoomsFutureProvider);
            },
            child: ListView.builder(
              itemCount: talkRoomsList.length,
              itemBuilder: (BuildContext context, int index) {
                final talkRoom = talkRoomsList[index];
                //talkRoom.roomName = FunctionUtils.getTalkRoomName(myAccount.member, talkRoom.talkMembers);
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xffC0C0C0), width: 1),
                    ),
                  ),
                  child: InkWell(
                    highlightColor: Colors.amber.shade100,
                    splashColor: Colors.amber.shade100,
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 300), () async {
                        var result = await Navigator.push(context,
                          MaterialPageRoute(
                            builder: (context) => MessageRoomPage(talkRoom),
                          ),
                        );
                        print('result:$result');
                        if (result is bool && result) {
                          // 状態を更新する
                          ref.refresh(talkRoomsFutureProvider);
                        }
                      });
                    },
                    child: ListTile(
                      tileColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      title: Text(talkRoom.roomName, style: const TextStyle(fontSize: 16)),
                      subtitle: talkRoom.lastMessage != '' ? Text(
                        talkRoom.lastMessage,
                        overflow: TextOverflow.ellipsis, //はみ出した文字を「…」にする
                        maxLines: 2, //表示する最大行数
                      ) : null,
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey,
                        foregroundImage: talkRoom.imagePath.isNotEmpty ? NetworkImage(talkRoom.imagePath) : null,
                        child: talkRoom.imagePath.isEmpty ? const Icon(Icons.person, size: 35, color: Colors.white) : null,
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            talkRoom.lastSendTime,
                            style: const TextStyle(color:Colors.grey,fontSize: 10),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Visibility(
                                  visible: 0 < talkRoom.countUnRead ? true : false,
                                  child: CircleAvatar(
                                    maxRadius: 12,
                                    backgroundColor: const Color(0xfff8b500),
                                    child: Center(
                                      child: Text(
                                        '${talkRoom.countUnRead}',
                                        style: const TextStyle(color: Colors.white,fontSize: 12,fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: false,
                      dense: true,
                      // onTap: () => {},
                      //onLongPress: () => {},
                      //trailing: Icon(Icons.more_vert),
                    ),
                  ),
                );
              },
            ),
          ) : const Center(child: Text('メッセージ情報がありません'));
          // }else{
          //   return const Center(child: Text('メンバー情報がありません'));
          // }
        },
        error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),

      // body: FutureBuilder<List<TalkRoom>?>(
      //   future: ApiMessages.fetchJoinedRooms(
      //     mid: myAccount.member.id,
      //     domain: myAccount.domain
      //   ),
      //   builder: (context, futureSnapshot) {
      //     if (futureSnapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator());
      //     } else {
      //       if (futureSnapshot.hasData) {
      //         List<TalkRoom> talkRooms = futureSnapshot.data!;
      //         return ListView.builder(
      //             itemCount: talkRooms.length,
      //             itemBuilder: (context, index) {
      //               talkRooms[index].roomName = FunctionUtils.getTalkRoomName(myAccount.member, talkRooms[index].talkMembers);
      //               String? imagePath = '';
      //               for (var member in talkRooms[index].talkMembers) {
      //                 if (myAccount.member.id != member.id) {
      //                   imagePath = member.imagePath;
      //                 }
      //               }
      //               return InkWell(
      //                 onTap: () async {
      //                   var result = await Navigator.push(
      //                     context,
      //                     MaterialPageRoute(
      //                       builder: (context) =>
      //                           MemberRoomPage(talkRooms[index]),
      //                     ),
      //                   );
      //                   if (result == true) {
      //                     print('bbb');
      //                     setState(() {});
      //                   }
      //                 },
      //                 child: Container(
      //                   decoration: BoxDecoration(
      //                       border: index == 0
      //                           ? const Border(
      //                               top: BorderSide(
      //                                   color: Colors.grey, width: 0),
      //                               bottom: BorderSide(
      //                                   color: Colors.grey, width: 0),
      //                             )
      //                           : const Border(
      //                               bottom: BorderSide(
      //                                   color: Colors.grey, width: 0),
      //                             )),
      //                   padding: const EdgeInsets.symmetric(
      //                       horizontal: 10, vertical: 15),
      //                   child: Row(
      //                     children: [
      //                       Padding(
      //                         padding:
      //                             const EdgeInsets.symmetric(horizontal: 8.0),
      //                         child: WidgetUtils.getCircleAvatar(imagePath, 22),
      //                       ),
      //                       Expanded(
      //                         child: Column(
      //                           crossAxisAlignment: CrossAxisAlignment.start,
      //                           mainAxisAlignment: MainAxisAlignment.center,
      //                           children: [
      //                             Text(
      //                               talkRooms[index].roomName!,
      //                               style: const TextStyle(
      //                                   fontSize: 16,
      //                                   fontWeight: FontWeight.bold),
      //                             ),
      //                             Visibility(
      //                               visible:
      //                                   talkRooms[index].lastMessage != null &&
      //                                           talkRooms[index]
      //                                               .lastMessage!
      //                                               .isNotEmpty
      //                                       ? true
      //                                       : false,
      //                               child: Padding(
      //                                 padding: const EdgeInsets.only(top: 5),
      //                                 child: Text(
      //                                   talkRooms[index].lastMessage != null
      //                                       ? talkRooms[index].lastMessage!
      //                                       : '',
      //                                   maxLines: 2,
      //                                   style: const TextStyle(
      //                                       color: Colors.grey, height: 1.2),
      //                                 ),
      //                               ),
      //                             ),
      //                           ],
      //                         ),
      //                       ),
      //                     ],
      //                   ),
      //                 ),
      //               );
      //             });
      //       } else {
      //         return const Center(child: Text('メッセージルームの取得に失敗しました'));
      //       }
      //     }
      //   },
      // ),
    );
  }
}
