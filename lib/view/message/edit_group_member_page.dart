import 'package:conavi_message/api/api_group_message.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/talk_group_member.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///グループメッセージ：メンバー編集ページ
class EditGroupMemberPage extends ConsumerStatefulWidget {
  final TalkGroupRoom talkRoom;
  const EditGroupMemberPage(this.talkRoom, {super.key});

  @override
  ConsumerState<EditGroupMemberPage> createState() => _EditGroupMemberPageState();
}

class _EditGroupMemberPageState extends ConsumerState<EditGroupMemberPage> {
  ///承認済みメンバー
  final List<TalkGroupMember> _approvalTalkMembers = [];
  ///戻り値メンバー（削除後）
  final List<TalkGroupMember> _resultTalkMembers = [];
  ///削除押下フラグ
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    final myAccount = ref.read(authProvider);

    ///承認済みのメンバーのみ格納
    for (var talkMember in widget.talkRoom.talkMembers) {
      if (talkMember.member != myAccount.member &&
          talkMember.state ==
              (GroupMessageMemberState.approval.index + 1).toString()) {
        _approvalTalkMembers.add(talkMember);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        Navigator.pop(context, _isDeleted);
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        appBar: AppBar(
          title: const Text('メンバー編集',style: TextStyle(fontWeight: FontWeight.bold),),
          centerTitle: false,
        ),
        body: SafeArea(
          child: _approvalTalkMembers.isNotEmpty ? ListView.builder(
            itemCount: _approvalTalkMembers.length,
            itemBuilder: (BuildContext context, int index) {
              final talkGroupMember = _approvalTalkMembers[index];
              if(talkGroupMember.member != myAccount.member && talkGroupMember.state == (GroupMessageMemberState.approval.index+1).toString()) {
                final talkMember = talkGroupMember.member!;
                //画像パス
                String imagePath = talkMember.imagePath.isNotEmpty ? '${myAccount.domain.url}/api/upload/file.php?member_id=${talkMember.id}&app_token=${myAccount.member.appToken}' : '';
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xffC0C0C0), width: 1),
                    ),
                  ),
                  child: ListTile(
                    tileColor: Colors.white,
                    contentPadding: const EdgeInsets.only(top:7.5,bottom:7.5,left:10,right:10),
                    title: Text(talkMember.name, style: const TextStyle(fontSize: 16)),
                    leading: WidgetUtils.getCircleAvatar(imagePath),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => CustomAlertDialog(
                                title: '削除',
                                contentWidget: Text('${talkMember.name}をグループから削除しますか？', style: const TextStyle(fontSize: 15)),
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
                                      state: (GroupMessageMemberState.delete.index+1).toString(),
                                      deleteMemberId: talkMember.id);
                                  //ローディングメッセージを破棄
                                  Loading.dismiss();
                                  FunctionUtils.log(result);
                                  if(result is bool && result){
                                    Loading.show(message: '取得中...', isDismissOnTap: false);
                                    final talkMembers = await ApiGroupMessages.fetchGroupMembers(myAccount: myAccount, roomId: widget.talkRoom.roomId);
                                    if(talkMembers is List<TalkGroupMember>){
                                      ///承認済みのメンバーのみ格納
                                      _approvalTalkMembers.clear();
                                      setState(() {
                                        for (var talkMember in talkMembers) {
                                          if(talkMember.member != myAccount.member &&
                                              talkMember.state == (GroupMessageMemberState.approval.index + 1).toString()){
                                            _approvalTalkMembers.add(talkMember);
                                          }
                                        }
                                      });
                                      _isDeleted = true;
                                    }
                                    Loading.dismiss();
                                  }
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline,color: Colors.red),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.red,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          label: const Text('削除', style: TextStyle(fontSize: 14,color: Colors.red)),
                        ),
                      ],
                    ),
                    onTap: () =>
                    {
                    },
                    onLongPress: () => {},
                    //trailing: Icon(Icons.more_vert),
                    dense: true,
                  ),
                );
              }else{
                return Container();
              }
            },
          ) : const Center(child: Text('表示できるメンバーはいません'),),
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

