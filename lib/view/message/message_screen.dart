import 'package:conavi_message/api/api_messages.dart';
import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/main.dart';
import 'package:conavi_message/model/talk_group_room.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/providers/create_group_provider.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/setting/user_setting.dart';
import 'package:conavi_message/utils/custom_alert_dialog.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/utils/loading.dart';
import 'package:conavi_message/utils/widget_dialogs.dart';
import 'package:conavi_message/view/message/select_message_member_page.dart';
import 'package:conavi_message/view/message/tab_group_message_page.dart';
import 'package:conavi_message/view/message/tab_member_page.dart';
import 'package:conavi_message/view/message/tab_message_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageScreen extends ConsumerStatefulWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends ConsumerState<MessageScreen> with SingleTickerProviderStateMixin {

  final _tab = <Tab>[
    const Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
              child: Text('メンバー',style: TextStyle(fontSize: 12),maxLines: 1)
          ),
        ],
      ),
    ),
    const Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
              child: Text('メッセージ一覧',style: TextStyle(fontSize: 12),maxLines: 1)
          ),
        ],
      ),
    ),
    const Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
              child: Text('グループ一覧',style: TextStyle(fontSize: 12),maxLines: 1)
          ),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // final userSetting = ref.read(userSettingProvider);
    // //FunctionUtils.log('initState:${userSetting.currentMessageTabIndex}');
    // _tabController = TabController(vsync: this, length: _tab.length, initialIndex: userSetting.currentMessageTabIndex);
    // if(userSetting.currentMessageTabIndex == MessageTab.member.index){
    //   ref.refresh(membersFutureProvider);
    // }else if(userSetting.currentMessageTabIndex == MessageTab.message.index){
    //   ref.refresh(talkRoomsFutureProvider);
    // }
    // _tabController?.addListener(() {
    //   if(_tabController != null) {
    //     //userSetting.currentMessageTabIndex = _tabController!.index;
    //   }
    // });
  }

  @override
  void dispose() {
    //_tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Auth myAccount = ref.watch(authProvider);
    return DefaultTabController(
      initialIndex: myAccount.userSetting.currentMessageTabIndex,
      length: _tab.length,
      child: Scaffold(
        appBar: AppBar(
          //title: Text('メッセージ', style: TextStyle(fontWeight: FontWeight.bold,color: subColor)),
          title: SizedBox(
              width: 75,
              child: Image.asset('assets/logo.png',fit: BoxFit.contain)
          ),
          shape: null,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              color: Colors.black,
              onPressed: () async{
                final MessageType? selectedMessageType = await showDialog<MessageType>(
                    context: context,
                    builder: (_) {
                      return showCreateMessageDialog(context);
                    });
                switch(selectedMessageType){
                  //メッセージを作成
                  case MessageType.message:
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectMessageMemberPage(MessageType.message),
                      ),
                    );
                    break;
                  //グループメッセージを作成
                  case MessageType.group:
                    //FunctionUtils.log("add:group");
                    //グループ設定で使用するグループ名・グループ画像・グループ参加メンバー変数を初期化
                    ref.invalidate(createGroupNameProvider);
                    ref.invalidate(createGroupImagePathProvider);
                    ref.invalidate(createGroupMembersProvider);
                    if (!context.mounted) return;
                    var result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectMessageMemberPage(MessageType.group),
                      ),
                    );
                    if(result is TalkGroupRoom){
                      ref.refresh(talkGroupRoomsFutureProvider);
                    }
                    break;
                  case null:
                    // TODO: Handle this case.
                }
              },
            ),
            PopupMenuButton<MessageSetting>(
              onSelected: (MessageSetting result) async{
                switch(result){
                  ///メッセージを並び替える
                  case MessageSetting.sort:
                    FunctionUtils.log(myAccount.userSetting.currentMessageSort);
                    final MessageSort? selectedSort = await showDialog<MessageSort>(context: context, builder: (_) {
                      return WidgetDialogs.showMessageRoomSortDialog(context,myAccount.userSetting.currentMessageSort);
                    });
                    FunctionUtils.log(selectedSort);
                    if(selectedSort is MessageSort){
                      if(myAccount.userSetting.currentMessageSort != selectedSort) {
                        ref.read(selectedMessageSortProvider.notifier).state = selectedSort;
                        if(myAccount.userSetting.currentMessageTabIndex == MessageTab.message.index){
                          ref.refresh(talkRoomsFutureProvider);
                        }else if(myAccount.userSetting.currentMessageTabIndex == MessageTab.groupMessage.index) {
                          ref.refresh(talkGroupRoomsFutureProvider);
                        }
                      }
                    }
                    break;
                  ///すべて既読にする
                  case MessageSetting.allRead:
                    showDialog(
                      context: context,
                      builder: (dialogContext) => CustomAlertDialog(
                        title: '確認',
                        contentWidget: const Text('すべてのメッセージを既読にしますか？', style: TextStyle(fontSize: 15)),
                        cancelActionText: 'いいえ',
                        cancelAction: () {},
                        defaultActionText: 'はい',
                        action: () async {
                          //ローディングメッセージを表示
                          Loading.show(message: '処理中...', isDismissOnTap: false);
                          //すべて既読
                          bool result = await ApiMessages.updateAllRead(domain: myAccount.domain.url, memberId: myAccount.member.id);
                          FunctionUtils.log(result);
                          if(result){
                            ref.refresh(talkRoomsFutureProvider);
                            ref.refresh(talkGroupRoomsFutureProvider);
                          }
                          //ローディングメッセージを破棄
                          Loading.dismiss();
                        },
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<MessageSetting>>[
                // const PopupMenuItem<MessageSetting>(
                //   value: MessageSetting.sort,
                //   child: Text('メッセージを並び替える'),
                // ),
                const PopupMenuItem<MessageSetting>(
                  value: MessageSetting.allRead,
                  child: Text('すべて既読にする'),
                ),
              ],
            ),
          ],
          //shape: const Border(bottom: BorderSide.none),
          bottom: ColoredTabBar(
            color: Colors.white,
            tabBar: TabBar(
              //controller: _tabController,
              tabs: _tab,
              isScrollable: false,
              labelColor: Colors.black, //選択文字色
              //labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: Colors.black, //未選文字色
              //indicatorColor: Colors.red,
              indicator: const BoxDecoration(
                //color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xff3166f7),
                    width: 3,
                  ),
                )
              ),
              onTap: (index){
                ref.read(selectedMessageTabIndexProvider.notifier).state = index;
                //FunctionUtils.log(myAccount.userSetting.currentMessageTabIndex);
                if(index == MessageTab.member.index){
                  ref.refresh(membersFutureProvider);
                }else if(index == MessageTab.message.index){
                  ref.refresh(talkRoomsFutureProvider);
                } if(index == MessageTab.groupMessage.index){
                  ref.refresh(talkGroupRoomsFutureProvider);
                }
                //FunctionUtils.log('TabBar_onTap:$index');
              },
            ),
          ),
          //automaticallyImplyLeading: false,
          /*flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                tabs: _tab,
                isScrollable: false,
              ),
            ],
          ),*/

          /*bottom: TabBar(
            controller: _tabController,
            tabs: _tab,
          ),*/
        ),
        body: const TabBarView(children: <Widget>[
          TabMemberPage(),
          TabMessagePage(),
          TabGroupMessagePage(),
        ]),
        // floatingActionButton: FloatingActionButton(
        //     onPressed: (){
        //       _tabController?.animateTo(1);
        // }),
      ),
    );
  }

  Widget showCreateMessageDialog(BuildContext context){
    return SimpleDialog(
      title: const Text('メッセージを作成'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      children: [
        SimpleDialogOption(
          child: const ListTile(
            leading: Icon(Icons.mail_outline),
            title: Text('メッセージ',style:TextStyle(fontSize: 15),maxLines: 1),
          ),
          onPressed: () {
            Navigator.pop(context,MessageType.message);
          },
        ),
        SimpleDialogOption(
          child: const ListTile(
            leading: Icon(Icons.group_outlined),
            title: Text('グループメッセージ',style:TextStyle(fontSize: 15),maxLines: 1),
          ),
          onPressed: () {
            Navigator.pop(context, MessageType.group);
          },
        )
      ],
    );
  }
}

class ColoredTabBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget tabBar;
  final Color color;

  const ColoredTabBar({super.key, required this.tabBar, required this.color});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: color,
      ),
      child: tabBar,
    );
  }

  @override
  Size get preferredSize => tabBar.preferredSize;
}
