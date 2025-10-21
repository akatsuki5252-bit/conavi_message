import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/view/message/group_message_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabGroupMessagePage extends ConsumerStatefulWidget {
  const TabGroupMessagePage({super.key});

  @override
  ConsumerState<TabGroupMessagePage> createState() => _TabGroupMessagePageState();
}

class _TabGroupMessagePageState extends ConsumerState<TabGroupMessagePage> {

  @override
  Widget build(BuildContext context) {
    final Auth myAccount = ref.read(authProvider);
    final talkGroupRoomsList = ref.watch(talkGroupRoomsFutureProvider);
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      body: talkGroupRoomsList.when(
        data: (talkGroupRoomsList) {
          //キャッシュをクリア
          PaintingBinding.instance.imageCache.clear();
          return talkGroupRoomsList != null && talkGroupRoomsList.isNotEmpty ? RefreshIndicator(
            onRefresh: () async {
              // 状態を更新する
              ref.refresh(talkGroupRoomsFutureProvider);
            },
            child: ListView.builder(
              itemCount: talkGroupRoomsList.length,
              itemBuilder: (BuildContext context, int index) {
                final talkRoom = talkGroupRoomsList[index];
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xffC0C0C0), width: 1),
                    ),
                  ),
                  child: InkWell(
                    highlightColor: Colors.amber.shade100,
                    splashColor: Colors.amber.shade100,
                    onTap: () async{
                      Future.delayed(const Duration(milliseconds: 300), () async {
                        //グループメッセージ
                        var result = await Navigator.push(context,
                          MaterialPageRoute(
                            builder: (context) => GroupMessageRoomPage(talkRoom),
                          ),
                        );
                        //if (result is bool && result) {
                        ref.refresh(talkGroupRoomsFutureProvider);
                        //}
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
                                //招待
                                Visibility(
                                  visible: !talkRoom.isEntry,
                                  child: const CircleAvatar(
                                    maxRadius: 12,
                                    backgroundColor: Colors.red,
                                    child: Center(
                                      child: Text(
                                        '!',
                                        style: TextStyle(color: Colors.white,fontSize: 13,fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                //未読件数
                                Visibility(
                                  visible: talkRoom.isEntry && 0 < talkRoom.countUnRead ? true : false,
                                  child: CircleAvatar(
                                    maxRadius: 12,
                                    backgroundColor: const Color(0xfff8b500),
                                    child: Center(
                                      child: Text(
                                        '${talkRoom.countUnRead}',
                                        style: const TextStyle(color: Colors.white,fontSize: 13,fontWeight: FontWeight.bold),
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
          ) : const Center(child: Text('グループ情報がありません'),);
          // }else{
          //   return const Center(child: Text('メンバー情報がありません'));
          // }
        },
        error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
