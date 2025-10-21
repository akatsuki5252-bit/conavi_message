import 'package:flutter/material.dart';

class NotificationTapBackground extends StatelessWidget {
  const NotificationTapBackground(this.payload, {Key? key}) : super(key: key);

  static const String routeName = '/notificationTapBackground';
  final String? payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('NotificationTapBackground'),
              Text('paylod:$payload'),
            ],
          ),
        ),
      ),
    );
  }
}

class GetNotificationAppLaunchDetails extends StatelessWidget {
  const GetNotificationAppLaunchDetails(this.payload, {Key? key})
      : super(key: key);

  static const String routeName = '/getNotificationAppLaunchDetails';
  final String? payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GetNotificationAppLaunchDetails'),
              Text('paylod:$payload'),
            ],
          ),
        ),
      ),
    );
  }
}
