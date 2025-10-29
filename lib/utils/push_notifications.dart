import 'dart:convert';

import 'package:conavi_message/utils/function_utils.dart';
import 'package:http/http.dart' as http;

class PushNotifications {

  static Future<bool> sendPushMessage({
    required String domain,
    required String title,
    required String body,
    required List<String?> memberIds,
    required String type,
    required String roomId,
    required String uniqueKey,
    required String imageUrl
  }) async {
    try {
      var response = await http.post(
        Uri.parse('$domain/api/push/push.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: createPayload(
          title: title,
          body: body,
          memberIds: memberIds,
          type: type,
          roomId: roomId,
          uniqueKey: uniqueKey,
          imageUrl: imageUrl,
        ),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if (!data.containsKey('error')) {
          FunctionUtils.log('PushNotifications:FCM request for device sent!');
          return true;
        } else {
          FunctionUtils.log('sendPushMessage error ===== ${data['error']}');
        }
      } else {
        FunctionUtils.log('sendPushMessage statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('sendPushMessage try catch error ===== $e');
    }
    return false;
  }

  static Future<bool> sendPushGroupMessage({
    required String domain,
    required String roomId,
    required String type,
    required String sendFromMemberId,
    required String uniqueKey,
    required String title,
    required String body,
    required String imageUrl,
    }) async {
    try {
      var response = await http.post(
        Uri.parse('$domain/api/push/push_group_message.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: createGroupMessagePayload(
          title: title,
          body: body,
          roomId: roomId,
          sendFromMemberId: sendFromMemberId,
          type: type,
          uniqueKey: uniqueKey,
          imageUrl: imageUrl
        ),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        FunctionUtils.log(response.body);
        if (data.containsKey('result') && data['result'] == true) {
          FunctionUtils.log('sendPushGroupMessage:FCM request for device sent!');
          return true;
        } else {
          FunctionUtils.log('sendPushGroupMessage error ===== ${data['error']}');
          return false;
        }
      } else {
        FunctionUtils.log('sendPushGroupMessage statusCode error ===== ${response.statusCode}');
      }
    } catch (e) {
      FunctionUtils.log('sendPushGroupMessage try catch error ===== $e');
    }
    return false;
  }

  static String createPayload({
    required String title,
    required String body,
    required List<String?> memberIds,
    required String roomId,
    required String type,
    required String uniqueKey,
    required String imageUrl
  }) {
    return jsonEncode({
      'title': title,
      'body': body,
      'member_ids': memberIds,
      'payload': {
        'type': type,
        'room_id': roomId,
        'unique_key': uniqueKey,
        'image_url': imageUrl,
      },
    });
  }

  static String createGroupMessagePayload({
    required String title,
    required String body,
    required String roomId,
    required String sendFromMemberId,
    required String type,
    required String uniqueKey,
    required String imageUrl
  }) {
    return jsonEncode({
      'room_id': roomId,
      'send_from_member_id': sendFromMemberId,
      'title': title,
      'body': body,
      'payload': {
        'type': type,
        'room_id': roomId,
        'unique_key': uniqueKey,
        'image_url': imageUrl,
      },
    });
  }
}
