import 'package:conavi_message/setting/auth.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:flutter/material.dart';

/// Manages & returns the users FCM token.
///
/// Also monitors token refreshes and updates state.
class TokenMonitor extends StatefulWidget {
  // ignore: public_member_api_docs
  TokenMonitor(this._builder);

  final Widget Function(String? token) _builder;

  @override
  State<StatefulWidget> createState() => _TokenMonitor();
}

class _TokenMonitor extends State<TokenMonitor> {
  String? _token;
  late Stream<String> _tokenStream;
  Auth myAccount = Authentication.myAccount!;

  void setToken(String? token) {
    setState(() {
      _token = token;
    });
  }

  @override
  void initState() {
    super.initState();
    setToken(myAccount.member.fcmToken);
  }

  @override
  Widget build(BuildContext context) {
    return widget._builder(_token);
  }
}
