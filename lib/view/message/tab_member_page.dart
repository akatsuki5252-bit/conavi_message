import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';
import 'package:conavi_message/view/message/member_page.dart';
import 'package:conavi_message/view/screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabMemberPage extends ConsumerStatefulWidget {
  const TabMemberPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TabMemberPage> createState() => _TabMemberPageState();
}

class _TabMemberPageState extends ConsumerState<TabMemberPage> {
  //late Future<List<Member>?> _futureFetchMembers;

  @override
  void initState() {
    super.initState();
    // Auth myAccount = ref.read(authProvider);
    // _futureFetchMembers = ApiMembers.fetchMembers(
    //     mid: myAccount.member.id,
    //     domain: myAccount.domain
    // );
    //ScreenState.setReloadMessageScreen(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final myAccount = ref.read(authProvider);
    final membersList = ref.watch(membersFutureProvider);
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.refresh),
      //   onPressed: () {
      //     // 状態を更新する
      //     ref.refresh(membersFutureProvider);
      //   },
      // ),
      body: membersList.when(
        data: (membersList) {
          //キャッシュをクリア
          PaintingBinding.instance.imageCache.clear();
          return membersList != null && membersList.isNotEmpty && 1 < membersList.length ? RefreshIndicator(
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
                    //padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: InkWell(
                      highlightColor: Colors.amber.shade100,
                      splashColor: Colors.amber.shade100,
                      onTap: (){
                        Future.delayed(const Duration(milliseconds: 300), () async {
                          var result = await Navigator.push(context,
                            MaterialPageRoute(builder: (context) => MemberPage(member)),
                          );
                          FunctionUtils.log('result:$result');
                          if (result is bool && result) {
                            ref.refresh(membersFutureProvider);
                          }
                        });
                      },
                      child: ListTile(
                        tileColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        dense: true,
                        // onTap: () => {},
                        // onLongPress: () => {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ) : const Center(child: Text('新しいメンバーを招待してください'));
          // }else{
          //   return const Center(child: Text('メンバー情報がありません'));
          // }
        },
        error: (error, stack) => Center(child: Text('エラーが発生しました。\n ${error.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      /*body: FutureBuilder<List<Member>?>(
        future: _futureFetchMembers,
        builder: (context, memberSnapshot) {
          if (memberSnapshot.hasData &&
              memberSnapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
              itemCount: memberSnapshot.data!.length,
              itemBuilder: (context, index) {
                Member member = memberSnapshot.data![index];
                return InkWell(
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberPage(member),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        border: index == 0
                            ? const Border(
                                top: BorderSide(color: Colors.grey, width: 0),
                                bottom:
                                    BorderSide(color: Colors.grey, width: 0),
                              )
                            : const Border(
                                bottom:
                                    BorderSide(color: Colors.grey, width: 0),
                              )),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          foregroundImage: member.imagePath.isNotEmpty
                              ? NetworkImage(member.imagePath)
                              : null,
                          child: member.imagePath.isEmpty
                              ? const Icon(Icons.person,
                                  size: 35, color: Colors.white)
                              : null,
                        ),
                        Expanded(
                          child: Container(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(member.name,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),*/
    );
  }

  /*void _reload() {
    _futureFetchMembers = ApiMembers.fetchMembers(
      mid: myAccount.member.id,
      domain: myAccount.domain
    );
    setState(() {});
  }*/
}
