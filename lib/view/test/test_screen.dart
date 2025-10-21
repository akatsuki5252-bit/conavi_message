import 'package:conavi_message/const/enum.dart';
import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/providers/auth_provider.dart';
import 'package:conavi_message/providers/message_provider.dart';
import 'package:conavi_message/providers/user_setting_provider.dart';
import 'package:conavi_message/setting/user_setting.dart';
import 'package:conavi_message/view/message/select_message_member_page.dart';
import 'package:conavi_message/view/message/tab_member_page.dart';
import 'package:conavi_message/view/message/tab_message_page.dart';
import 'package:conavi_message/view/test/file_page.dart';
import 'package:conavi_message/view/test/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> with SingleTickerProviderStateMixin {
  final _tab = <Tab>[
    Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('ファイル'),
        ],
      ),
    ),
    Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('通知'),
        ],
      ),
    ),
  ];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Auth myAccount = ref.watch(authProvider);
    return DefaultTabController(
      initialIndex: _selectedTabIndex,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('テスト', style: TextStyle(color: Colors.black)),
          bottom: TabBar(
            tabs: _tab,
            isScrollable: false,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            onTap: (index){
              _selectedTabIndex = index;
            },
          ),
        ),
        body: const TabBarView(children: <Widget>[
          TestFilePage(),
          NotificationPage(),
        ]),
      ),
    );
  }
}
