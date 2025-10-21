import 'dart:convert';
import 'dart:math' as math;

import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/local_notifications.dart';
import 'package:conavi_message/view/test/permissions.dart';
import 'package:conavi_message/view/test/token_monitor.dart';
import 'package:conavi_message/view/util/choice_image_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Auth myAccount = Authentication.myAccount!;
  String? _token;

  @override
  void initState() {
    super.initState();
    print(myAccount.member.fcmToken);
  }

  Future<void> sendPushMessage() async {
    if (_token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      await http.post(
        Uri.parse('https://.conavi.net/fcm_test2.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: constructFCMPayload(_token),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendPushMessage2() async {
    try {
      await http.post(
        Uri.parse('https://.conavi.net/push.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: createPayload(),
      );
      print('FCM request for device sent!');
    } catch (e) {
      print(e);
    }
  }

  /// The API endpoint here accepts a raw FCM payload for demonstration purposes.
  String constructFCMPayload(String? token) {
    return jsonEncode({
      'token': token,
      'data': {
        'via': 'FlutterFire Cloud Messaging!!!',
        'count': '0',
      },
      'notification': {
        'title': 'Hello FlutterFire!',
        'body': 'This notification was created via FCM!',
      },
    });
  }

  String createPayload() {
    List<int> a = [1];
    a.add(11);
    return jsonEncode(
      {
        'title': 'タイトル',
        'body': 'メッセージ',
        'member_ids': a,
        'payload': {'type': 'chat', 'room_id': '1'},
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print(myAccount.member.imagePath);
    var rand = math.Random();
    return GestureDetector(
      onTap: () => primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(right: 15, left: 15, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MetaCard('Permissions', Permissions()),
                  MetaCard(
                    'FCM Token',
                    TokenMonitor((token) {
                      _token = token;
                      return token == null
                          ? const CircularProgressIndicator()
                          : //Text(token, style: const TextStyle(fontSize: 12));
                          TextField(
                              controller: TextEditingController(text: token),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                            );
                    }),
                  ),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     child: const Text('fcm test'),
                  //     onPressed: sendPushMessage,
                  //   ),
                  // ),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     child: const Text('fcm chat test'),
                  //     onPressed: sendPushMessage2,
                  //   ),
                  // ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('画像アップロード'),
                      onPressed: () async {

                        //ローディング
                        EasyLoading.instance.loadingStyle = EasyLoadingStyle.light;
                        EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.ring;
                        EasyLoading.instance.animationStyle = EasyLoadingAnimationStyle.scale;
                        await EasyLoading.show(
                          status: 'アップロード中...',
                          dismissOnTap: false,
                          maskType: EasyLoadingMaskType.black,
                        );

                        var uri = Uri.parse("https://.conavi.net/uploads/test.php");
                        //var uri = Uri.https('.conavi.net','/uploads/test.php');
                        var request = http.MultipartRequest("POST", uri);
                        request.fields['img_length'] = '2';
                        //request.headers['Authorization'] = '';
                        print(request);

                        var picture = http.MultipartFile.fromBytes(
                          'img1',
                          (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
                          filename: 'logo.png',
                          //contentType: MediaType.parse('image/jpeg'),
                        );

                        request.files.add(picture);

                        var picture2 = http.MultipartFile.fromBytes(
                          'img2',
                          (await rootBundle.load('assets/sample.pdf')).buffer.asUint8List(),
                          filename: 'sample.pdf',
                          //contentType: MediaType.parse('image/jpeg'),
                        );


                        request.files.add(picture2);

                        var response = await request.send();
                        print(response.statusCode);
                        if(response.statusCode == 200){
                          var responseData = await response.stream.toBytes();
                          var body = String.fromCharCodes(responseData);
                          print(body);
                          Map<String, dynamic> data = jsonDecode(body);
                          if(!data.containsKey('error')) {
                            EasyLoading.dismiss();
                          }else{
                            EasyLoading.showError(
                              "${data['error']}",
                              dismissOnTap: true,
                              maskType: EasyLoadingMaskType.black,
                            );
                          }
                        }else{
                          EasyLoading.showError(
                            'アップロードに失敗しました',
                            dismissOnTap: true,
                            maskType: EasyLoadingMaskType.black,
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('Show local notification with payload'),
                      onPressed: () async {
                        await LocalNotifications.showTestNotification(myAccount.member.imagePath);
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('プロフィール画像'),
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChoiceImagePage(fileName:'test',multipleType: false, limitFileSize: 5.0),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('複数画像'),
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChoiceImagePage(fileName:'test',multipleType: true, limitFileSize: 5.0),
                          ),
                        );
                      },
                    ),
                  ),

                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     child: const Text('チャット'),
                  //     onPressed: () async {
                  //       await LocalNotifications.showNotification(
                  //           'chat',
                  //           1,
                  //           'グループ名',
                  //           'こんにちは${rand.nextInt(99)}',
                  //           'http://cdn.shopify.com/s/files/1/0413/3122/8829/products/0330104644_5e814f84817e4_48fb6097-17b2-4dc7-a09d-9d80893756cb.jpg?v=1614697050',
                  //           {"menuIndex": "0"});
                  //     },
                  //   ),
                  // ),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     child: const Text('メッセージ'),
                  //     onPressed: () async {
                  //       await LocalNotifications.showNotification(
                  //         'message',
                  //         2,
                  //         '送信者名',
                  //         'おはようございます${rand.nextInt(99)}',
                  //         'https://www.ricoh-imaging.co.jp/japan/dc/past/rdc/7/img/rdc7_sample01b.jpg',
                  //         {"menuIndex": "1"},
                  //       );
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// UI Widget for displaying metadata.
class MetaCard extends StatelessWidget {
  final String _title;
  final Widget _children;

  // ignore: public_member_api_docs
  MetaCard(this._title, this._children);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Text(_title, style: const TextStyle(fontSize: 18)),
              ),
              _children,
            ],
          ),
        ),
      ),
    );
  }
}
