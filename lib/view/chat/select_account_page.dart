import 'package:conavi_message/firestore/room_firestore.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:flutter/material.dart';

class SelectAccountPage extends StatefulWidget {
  const SelectAccountPage({super.key});

  @override
  State<SelectAccountPage> createState() => _SelectAccountPageState();
}

class _SelectAccountPageState extends State<SelectAccountPage> {
  Auth myAccount = Authentication.myAccount!;
  late Future<List<Member>?> _futureFetchMembers;

  /*Future<List<Member>?> asyncFetchMembers() async {
    return await MemberApi.fetchMembers(myAccount.id!);
  }*/

  final List<String> _memberIds = [];

  @override
  void initState() {
    super.initState();
    _futureFetchMembers = ApiMembers.fetchMembers(
      domain: myAccount.domain.url,
      domainId: myAccount.domain.id,
      mid: myAccount.member.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isChecked = false;
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'メンバーを選択',
            style: TextStyle(color: Colors.black),
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (_memberIds.isEmpty || _memberIds.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.grey,
                    content: Text('メンバーを2人以上選択してください'),
                  ),
                );
              } else {
                _memberIds.add(myAccount.member.id);
                for (var element in _memberIds) {
                  print(element);
                }
                var result = await RoomFirestore.createRoom(_memberIds);
                if (result) {
                  // contextを渡す前に、contextが現在のWidgetツリー内に存在しているかどうかチェック
                  // 存在しなければ、画面遷移済を意味するので、以降の画面遷移処理は行わない
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.grey,
                      content: Text('チャットルームを作成しました'),
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  // contextを渡す前に、contextが現在のWidgetツリー内に存在しているかどうかチェック
                  // 存在しなければ、画面遷移済を意味するので、以降の画面遷移処理は行わない
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.grey,
                      content: Text('チャットルームを作成できません'),
                    ),
                  );
                }
              }
            },
            child: const Text(
              '作成',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Member>?>(
          future: _futureFetchMembers, //MemberApi.fetchMembers(myAccount.id!),
          builder: (context, memberSnapshot) {
            if (memberSnapshot.hasData &&
                memberSnapshot.connectionState == ConnectionState.done) {
              return ListView.builder(
                itemCount: memberSnapshot.data!.length,
                itemBuilder: (context, index) {
                  Member member = memberSnapshot.data![index];
                  return Container(
                    width: double.infinity,
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
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(member.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                        ),
                        Checkbox(
                          value: member.isChecked,
                          onChanged: (value) {
                            setState(() {
                              if (value!) {
                                _memberIds.add(member.id);
                              } else {
                                _memberIds.remove(member.id);
                              }
                              member.isChecked = value;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
