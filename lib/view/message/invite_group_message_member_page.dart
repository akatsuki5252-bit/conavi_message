import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/talk_group_member.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/push_notifications.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///グループメッセージ：メンバー招待ページ
class InviteGroupMessageMemberPage extends ConsumerStatefulWidget {
  final TalkGroupRoom talkRoom;
  const InviteGroupMessageMemberPage(this.talkRoom, {super.key});

  @override
  ConsumerState<InviteGroupMessageMemberPage> createState() => _InviteGroupMessageMemberPageState();
}

class _InviteGroupMessageMemberPageState extends ConsumerState<InviteGroupMessageMemberPage> {
  ///招待メンバー
  final List<Member> _inviteMembers = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future initialize() async{
    Loading.show(message: '取得中...', isDismissOnTap: false);
    final myAccount = ref.read(authProvider);
    final talkMembers = await ApiGroupMessages.fetchGroupMembers(myAccount: myAccount, roomId: widget.talkRoom.roomId);
    if(talkMembers is List<TalkGroupMember>) {
      setState(() {
        widget.talkRoom.talkMembers = talkMembers;
      });
    }
    Loading.dismiss();
  }

  ///戻るボタン
  Future<bool> _willPopCallback() async{
    Navigator.pop(context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    final membersList = ref.watch(membersFutureProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(
          title: const Text('メンバーを選択',style: TextStyle(fontWeight: FontWeight.bold),),
          centerTitle: false,
          actions: [
            TextButton(
              onPressed: () async {
                //選択チェック
                if(_inviteMembers.isEmpty) {
                  Loading.error(message: 'メンバーを選択してください');
                  return;
                }else{
                  //ローディングメッセージを表示
                  Loading.show(message: '処理中...', isDismissOnTap: false);
                  //招待メンバーをグループに追加
                  var result = await ApiGroupMessages.inviteGroupMembers(
                    domain: myAccount.domain.url,
                    roomId: widget.talkRoom.roomId,
                    inviteJoinedMemberIds: FunctionUtils.createJoinedMemberIds(_inviteMembers),
                    inviteMemberId: myAccount.member.id
                  );
                  Loading.dismiss();
                  if(result is bool && result) {
                    //プッシュ通知
                    bool result = await PushNotifications.sendPushMessage(
                      domain: myAccount.domain.url,
                      roomId: widget.talkRoom.roomId,
                      type: 'groupMessage',
                      title: widget.talkRoom.roomName,
                      body: 'グループに招待されました',
                      memberIds: FunctionUtils.createArrayMemberIds(_inviteMembers),
                      uniqueKey: FunctionUtils.createUniqueKeyFromDate(widget.talkRoom.createdTime),
                      imageUrl: widget.talkRoom.imagePath
                    );
                    if(!result){
                      FunctionUtils.log('プッシュ通知でエラーが発生');
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context,true);
                  }else{
                    Loading.error(message: '招待に失敗しました');
                  }
                }
              },
              child: const Text('招待',style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
        body: SafeArea(
          child: membersList.when(
            data: (membersList) {
              return membersList != null && membersList.isNotEmpty ? ListView.builder(
                itemCount: membersList.length,
                itemBuilder: (BuildContext context, int index) {
                  final member = membersList[index];
                  //チェックボックス
                  member.isChecked = false;
                  for (var inviteMember in _inviteMembers) {
                    if(member.id == inviteMember.id){
                      member.isChecked = true;
                    }
                  }
                  //画像パス
                  String imagePath = member.imagePath.isNotEmpty ? '${myAccount.domain.url}/api/upload/file.php?member_id=${member.id}&app_token=${myAccount.member.appToken}' : '';
                  //状態
                  String state = '';
                  for (var talkMember in widget.talkRoom.talkMembers) {
                    if(talkMember.member != null) {
                      if (member.id == talkMember.member!.id) {
                        state = talkMember.state;
                      }
                    }
                  }
                  return Visibility(
                    ///自分のアカウントは表示しない
                    visible: member.id != myAccount.member.id ? true : false,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xffC0C0C0), width: 1),
                        ),
                      ),
                      child: ListTile(
                        tileColor: Colors.white,
                        contentPadding: const EdgeInsets.only(top:7.5,bottom:7.5,left:10,right:20),
                        title: Text(member.name, style: const TextStyle(fontSize: 16)),
                        leading: WidgetUtils.getCircleAvatar(imagePath),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ///未選択、状態が拒否、削除のメンバーは選択可
                            state.isEmpty || state == '3' || state == '4' || state == '5' ? SizedBox(
                              width: 20,
                              height: 20,
                              child : Checkbox(
                                value: member.isChecked,
                                onChanged: (bool? value) {
                                  if (value == null) return;
                                  if(value){
                                    _inviteMembers.add(member);
                                  }else{
                                    _inviteMembers.remove(member);
                                  }
                                  setState(() {
                                    member.isChecked = value;
                                  });
                                  FunctionUtils.log(_inviteMembers);
                                },
                              ),
                            ) :
                            ///招待済み
                            state == '1' ? const Text('招待中', style: TextStyle(fontSize: 12)) :
                            ///参加済み
                            const Spacer(),
                          ]
                        ),
                        onTap: () => {

                        },
                        dense: true,
                      ),
                    ),
                  );
                },
              ) : const Center(child: Text('メンバー情報がありません'));
              // }else{
              //   return const Center(child: Text('メンバー情報がありません'));
              // }
            },
            error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
  //   final myAccount = ref.read(authProvider);
  //   final membersList = ref.watch(membersFutureProvider);
  //   final selectedMemberId = ref.watch(selectMemberIdProvider);
  //   final selectedMembers = ref.read(createGroupMembersProvider);
  //   //build完了後
  //   // WidgetsBinding.instance.addPostFrameCallback((_){
  //   //   ref.read(selectMembersProvider.notifier).state = [];
  //   // });
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('メンバーを選択'),
  //       centerTitle: false,
  //       actions: <Widget>[
  //         TextButton(
  //           onPressed: () async {
  //             //選択チェック
  //             if (selectedMemberId.isEmpty && selectedMembers.isEmpty) {
  //               EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
  //               EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
  //               EasyLoading.showError(
  //                 'メンバーを選択してください',
  //                 dismissOnTap: true,
  //                 maskType: EasyLoadingMaskType.black,
  //               );
  //               return;
  //             }
  //             //メッセージ
  //             if (widget.messageType == MessageType.message) {
  //               //ローディング
  //               EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
  //               EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
  //               EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
  //               await EasyLoading.show(
  //                 dismissOnTap: false,
  //                 maskType: EasyLoadingMaskType.black,
  //               );
  //               //ルームidを作成
  //               final List<String> memberIds = [
  //                 myAccount.member.id,
  //                 selectedMemberId
  //               ];
  //               memberIds.sort((a, b) => a.compareTo(b));
  //               String listAsString = FunctionUtils.listToString(memberIds);
  //               //FunctionUtils.log(listAsString);
  //               //ルーム情報を作成・取得
  //               final talkRoom = await ApiMessages.createRoom(
  //                 joinedMemberIds: listAsString,
  //                 myAccount: myAccount,
  //               );
  //               if (talkRoom is TalkRoom) {
  //                 //ローディング終了
  //                 EasyLoading.dismiss();
  //                 if (!mounted) return;
  //                 //メッセージルームへ遷移
  //                 Navigator.pushReplacement(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => MessageRoomPage(talkRoom),
  //                   ),
  //                 );
  //               } else {
  //                 //エラーメッセージ表示
  //                 EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
  //                 EasyLoading.showError(
  //                   'ルームの作成に失敗しました',
  //                   dismissOnTap: true,
  //                   maskType: EasyLoadingMaskType.black,
  //                 );
  //               }
  //             } else if (widget.messageType == MessageType.group) {
  //               //グループメッセージ
  //               var result = await Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => const CreateGroupPage(),
  //                 ),
  //               );
  //               if (result is TalkGroupRoom) {
  //                 if (!mounted) return;
  //                 Navigator.pop(context, result);
  //               }
  //             }
  //           },
  //           child: Text(
  //             widget.messageType == MessageType.message ? '作成' :
  //             widget.messageType == MessageType.group ? '選択' : '',
  //             style: const TextStyle(color: Colors.black),
  //           ),
  //         ),
  //       ],
  //     ),
  //     body: SafeArea(
  //       child: membersList.when(
  //         data: (membersList) {
  //           return membersList != null && membersList.isNotEmpty
  //               ? RefreshIndicator(
  //             onRefresh: () async {
  //               // 状態を更新する
  //               ref.refresh(membersFutureProvider);
  //             },
  //             child: ListView.builder(
  //               itemCount: membersList.length,
  //               itemBuilder: (BuildContext context, int index) {
  //                 final member = membersList[index];
  //                 return Visibility(
  //                   visible: member.id != myAccount.member.id ? true : false,
  //                   child: Container(
  //                     decoration: const BoxDecoration(
  //                       border: Border(
  //                         bottom: BorderSide(color: Colors.grey, width: 0),
  //                       ),
  //                     ),
  //                     padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
  //                     child: ListTile(
  //                       title: Text(member.name, style: const TextStyle(fontSize: 16)),
  //                       leading: CircleAvatar(
  //                         radius: 22,
  //                         backgroundColor: Colors.grey,
  //                         foregroundImage: member.imagePath.isNotEmpty
  //                             ? NetworkImage('${myAccount.domain}/api/upload/file.php?member_id=${member.id}&app_token=${myAccount.member.appToken}')
  //                             : null,
  //                         child: member.imagePath.isEmpty
  //                             ? const Icon(Icons.person, size: 35, color: Colors.white)
  //                             : null,
  //                       ),
  //                       trailing: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           SizedBox(
  //                               width: 20,
  //                               height: 20,
  //                               child: selectButton(widget.messageType, member)
  //                           ),
  //                         ],
  //                       ),
  //                       onTap: () => {
  //
  //                       },
  //                       onLongPress: () => {},
  //                       //trailing: Icon(Icons.more_vert),
  //                       dense: true,
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           )
  //               : const Center(child: Text('メンバー情報がありません'));
  //           // }else{
  //           //   return const Center(child: Text('メンバー情報がありません'));
  //           // }
  //         },
  //         error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
  //         loading: () => const Center(child: CircularProgressIndicator()),
  //       ),
  //     ),
  //     // body: SafeArea(
  //     //   child: FutureBuilder<List<Member>?>(
  //     //     future:
  //     //         _futureFetchMembers, //MemberApi.fetchMembers(myAccount.id!),
  //     //     builder: (context, memberSnapshot) {
  //     //       if (memberSnapshot.hasData &&
  //     //           memberSnapshot.connectionState == ConnectionState.done) {
  //     //         return ListView.builder(
  //     //           itemCount: memberSnapshot.data!.length,
  //     //           itemBuilder: (context, index) {
  //     //             Member member = memberSnapshot.data![index];
  //     //             return Container(
  //     //               width: double.infinity,
  //     //               decoration: BoxDecoration(
  //     //                   border: index == 0
  //     //                       ? const Border(
  //     //                           top: BorderSide(
  //     //                               color: Colors.grey, width: 0),
  //     //                           bottom: BorderSide(
  //     //                               color: Colors.grey, width: 0),
  //     //                         )
  //     //                       : const Border(
  //     //                           bottom: BorderSide(
  //     //                               color: Colors.grey, width: 0),
  //     //                         )),
  //     //               padding: const EdgeInsets.symmetric(
  //     //                   horizontal: 10, vertical: 15),
  //     //               child: Row(
  //     //                 children: [
  //     //                   WidgetUtils.getCircleAvatar(member.imagePath, 22),
  //     //                   Expanded(
  //     //                     child: Container(
  //     //                         padding: const EdgeInsets.only(left: 10),
  //     //                         child: Text(member.name,
  //     //                             style: const TextStyle(
  //     //                                 fontWeight: FontWeight.bold))),
  //     //                   ),
  //     //                   Radio<String>(
  //     //                     value: member.id,
  //     //                     groupValue: _memberId,
  //     //                     onChanged: (value) {
  //     //                       setState(() {
  //     //                         _memberId = value!;
  //     //                       });
  //     //                     },
  //     //                   ),
  //     //                 ],
  //     //               ),
  //     //             );
  //     //           },
  //     //         );
  //     //       } else {
  //     //         return const Center(child: CircularProgressIndicator());
  //     //       }
  //     //     },
  //     //   ),
  //     // ),
  //   );
  //   // if (_isLoading)
  //   //   const ColoredBox(
  //   //     color: Colors.black54,
  //   //     child: Center(
  //   //       child: CircularProgressIndicator(),
  //   //     ),
  //   //   ),
  //
  // }
}

