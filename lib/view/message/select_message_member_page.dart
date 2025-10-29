import 'dart:async';

import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/providers/create_group_provider.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_utils.dart';
import 'package:conavi_message/view/message/create_group_page.dart';
import 'package:conavi_message/view/message/message_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class SelectMessageMemberPage extends ConsumerStatefulWidget {
  final MessageType messageType;
  const SelectMessageMemberPage(this.messageType,{Key? key}) : super(key: key);

  @override
  ConsumerState<SelectMessageMemberPage> createState() => _SelectMessageMemberPageState();
}

final selectMemberIdProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

class _SelectMessageMemberPageState extends ConsumerState<SelectMessageMemberPage> {

  @override
  void initState() {
    super.initState();
  }

  Widget? selectButton(MessageType messageType,Member member){
    if(messageType == MessageType.message) {
      final selectedMemberId = ref.watch(selectMemberIdProvider);
      return Radio(
          value: member.id,
          groupValue: selectedMemberId,
          onChanged: (String? value) {
            if (value == null) return;
            ref.read(selectMemberIdProvider.notifier).state = value;
          },
      );
    }else if(messageType == MessageType.group){
      final selectedMembers = ref.watch(createGroupMembersProvider);
      if(selectedMembers.isEmpty){
        member.isChecked = false;
      }else {
        for (var selectedMember in selectedMembers) {
          if(member.id == selectedMember.id){
            member.isChecked = true;
          }
        }
      }
      return Checkbox(
        value: member.isChecked,
        onChanged: (bool? value) {
          if (value == null) return;
          if(value){
            selectedMembers.add(member);
          }else{
            selectedMembers.remove(member);
          }
          setState(() {
            member.isChecked = value;
          });
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    final membersList = ref.watch(membersFutureProvider);
    final selectedMemberId = ref.watch(selectMemberIdProvider);
    final selectedMembers = ref.read(createGroupMembersProvider);
    //build完了後
    // WidgetsBinding.instance.addPostFrameCallback((_){
    //   ref.read(selectMembersProvider.notifier).state = [];
    // });
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('メンバーを選択'),
        centerTitle: false,
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              //選択チェック
              if (selectedMemberId.isEmpty && selectedMembers.isEmpty) {
                EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
                EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                EasyLoading.showError(
                  'メンバーを選択してください',
                  dismissOnTap: true,
                  maskType: EasyLoadingMaskType.black,
                );
                return;
              }
              //メッセージ
              if (widget.messageType == MessageType.message) {
                //ローディングメッセージを表示
                Loading.show(message: '処理中...', isDismissOnTap: false);
                //ルームidを作成
                final List<String> memberIds = [
                  myAccount.member.id,
                  selectedMemberId
                ];
                memberIds.sort((a, b) => a.compareTo(b));
                String listAsString = FunctionUtils.listToString(memberIds);
                //FunctionUtils.log(listAsString);
                //ルーム情報を作成・取得
                final talkRoom = await ApiMessages.createRoom(
                  joinedMemberIds: listAsString,
                  myAccount: myAccount,
                );
                if (talkRoom is TalkRoom) {
                  //ローディングを終了
                  Loading.dismiss();
                  if (!context.mounted) return;
                  //メッセージルームへ遷移
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageRoomPage(talkRoom),
                    ),
                  );
                } else {
                  //エラーメッセージ表示
                  EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                  EasyLoading.showError(
                    'ルームの作成に失敗しました',
                    dismissOnTap: true,
                    maskType: EasyLoadingMaskType.black,
                  );
                }
              } else if (widget.messageType == MessageType.group) {
                //グループメッセージ
                var result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupPage(),
                  ),
                );
                if (result is TalkGroupRoom) {
                  if (!context.mounted) return;
                  Navigator.pop(context, result);
                }
              }
            },
            child: Text(
              widget.messageType == MessageType.message ? '作成' :
              widget.messageType == MessageType.group ? '選択' : '',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: membersList.when(
          data: (membersList) {
            return membersList != null && membersList.isNotEmpty ? RefreshIndicator(
              onRefresh: () async {
                // 状態を更新する
                ref.refresh(membersFutureProvider);
              },
              child: ListView.builder(
                itemCount: membersList.length,
                itemBuilder: (BuildContext context, int index) {
                  final member = membersList[index];
                  return Visibility(
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
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          foregroundImage: member.imagePath.isNotEmpty
                              ? NetworkImage('${myAccount.domain.url}/api/upload/file.php?member_id=${member.id}&app_token=${myAccount.member.appToken}')
                              : null,
                          child: member.imagePath.isEmpty
                              ? const Icon(Icons.person, size: 35, color: Colors.white)
                              : null,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: selectButton(widget.messageType, member)
                            ),
                          ],
                        ),
                        onTap: () => {

                        },
                        onLongPress: () => {},
                        //trailing: Icon(Icons.more_vert),
                        dense: true,
                      ),
                    ),
                  );
                },
              ),
            ) : const Center(child: Text('メンバー情報がありません'));
            // }else{
            //   return const Center(child: Text('メンバー情報がありません'));
            // }
          },
          error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      // body: SafeArea(
          //   child: FutureBuilder<List<Member>?>(
          //     future:
          //         _futureFetchMembers, //MemberApi.fetchMembers(myAccount.id!),
          //     builder: (context, memberSnapshot) {
          //       if (memberSnapshot.hasData &&
          //           memberSnapshot.connectionState == ConnectionState.done) {
          //         return ListView.builder(
          //           itemCount: memberSnapshot.data!.length,
          //           itemBuilder: (context, index) {
          //             Member member = memberSnapshot.data![index];
          //             return Container(
          //               width: double.infinity,
          //               decoration: BoxDecoration(
          //                   border: index == 0
          //                       ? const Border(
          //                           top: BorderSide(
          //                               color: Colors.grey, width: 0),
          //                           bottom: BorderSide(
          //                               color: Colors.grey, width: 0),
          //                         )
          //                       : const Border(
          //                           bottom: BorderSide(
          //                               color: Colors.grey, width: 0),
          //                         )),
          //               padding: const EdgeInsets.symmetric(
          //                   horizontal: 10, vertical: 15),
          //               child: Row(
          //                 children: [
          //                   WidgetUtils.getCircleAvatar(member.imagePath, 22),
          //                   Expanded(
          //                     child: Container(
          //                         padding: const EdgeInsets.only(left: 10),
          //                         child: Text(member.name,
          //                             style: const TextStyle(
          //                                 fontWeight: FontWeight.bold))),
          //                   ),
          //                   Radio<String>(
          //                     value: member.id,
          //                     groupValue: _memberId,
          //                     onChanged: (value) {
          //                       setState(() {
          //                         _memberId = value!;
          //                       });
          //                     },
          //                   ),
          //                 ],
          //               ),
          //             );
          //           },
          //         );
          //       } else {
          //         return const Center(child: CircularProgressIndicator());
          //       }
          //     },
          //   ),
          // ),
        );
        // if (_isLoading)
        //   const ColoredBox(
        //     color: Colors.black54,
        //     child: Center(
        //       child: CircularProgressIndicator(),
        //     ),
        //   ),

  }
}
