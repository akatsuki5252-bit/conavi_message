import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:conavi_message/model/group_message.dart';
import 'package:conavi_message/model/member.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;

class FunctionUtils {
  static Future<dynamic> getImageFromGallery() async {
    ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile;
  }

  static Future<String> uploadImage(File image) async {
    String path = image.path.substring(image.path.lastIndexOf('/') + 1);
    final ref = FirebaseStorage.instance.ref(path);
    final storedImage = await ref.putFile(image);
    String downloadUrl = await storedImage.ref.getDownloadURL();
    FunctionUtils.log('image_path:$downloadUrl');
    return downloadUrl;
  }

  //List<String>を「カンマ」区切りのStringに変換
  static String listToString(List<String> list) {
    return list.map<String>((String value) => value.toString()).join(',');
  }

  static String listToString2(List<int> list) {
    return list.map<String>((int value) => value.toString()).join(',');
  }

  //「カンマ」区切りをList<String>に変換
  static List<String> stringToList(String listAsString) {
    return listAsString.split(',').map<String>((String item) => item).toList();
  }

  static String getTalkRoomName(Member myAccount, List<Member> members) {
    String roomName = '';
    //選択メンバーが1人
    if (members.length == 2) {
      for (var member in members) {
        if (myAccount.id != member.id) roomName = member.name;
      }
    } else {
      //選択メンバーが2人以上
      roomName = '${myAccount.name},';
      var index = 0;
      for (var member in members) {
        if (index == (members.length - 1)) {
          roomName += member.name;
        } else {
          roomName += '${member.name},';
        }
        index++;
      }
    }

    if (12 < roomName.length) {
      roomName = '${roomName.substring(0, 12)}…';
    }

    if (2 < members.length) {
      roomName = '$roomName(${members.length})';
    }

    return roomName;
  }

  static String createLastSendTime(String sendTime){
    var currentDate = DateTime.now();
    var lastTalkDate = DateTime.parse(sendTime);

    var differenceDayTime = '';
    if(currentDate.year == lastTalkDate.year){
      int difDay = currentDate.difference(lastTalkDate).inDays;
      int difHour = currentDate.difference(lastTalkDate).inHours;
      int difMinute = currentDate.difference(lastTalkDate).inMinutes;
      // FunctionUtils.log(difDay);
      // FunctionUtils.log(difHour);
      // FunctionUtils.log(difMinute);
      //FunctionUtils.log(differenceDayTime);
      if(difDay < 1){
        if(difMinute < 60){
          differenceDayTime = '$difMinute分前';
        }else {
          differenceDayTime = '$difHour時間前';
        }
      }else if(24 <= difHour && difDay < 2){
        differenceDayTime = '昨日';
      }else if(48 <= difHour && difDay < 3){
        differenceDayTime = '一昨日';
      }else{
        DateFormat outputFormat = DateFormat('M/d');
        differenceDayTime = outputFormat.format(lastTalkDate);
      }
    }else{
      DateFormat outputFormat = DateFormat('yyyy/M/d');
      differenceDayTime = outputFormat.format(lastTalkDate);
    }

    return differenceDayTime;
  }

  static String formatFileSize(double size) {
    String hrSize = "";

    double b = size;
    double k = size / 1024.0;
    double m = ((size / 1024.0) / 1024.0);
    double g = (((size / 1024.0) / 1024.0) / 1024.0);
    double t = ((((size / 1024.0) / 1024.0) / 1024.0) / 1024.0);

    // FunctionUtils.log('size:$size');
    // FunctionUtils.log('m:$m');

    if (t > 1) {
      hrSize = "${t.toStringAsFixed(2)} TB";
    } else if (g > 1) {
      hrSize = "${g.toStringAsFixed(2)} GB";
    } else if (m > 1) {
      hrSize = "${m.toStringAsFixed(2)} MB";
    } else if (k > 1) {
      hrSize = "${k.toStringAsFixed(2)} KB";
    } else {
      hrSize = "${b.toStringAsFixed(2)} Bytes";
    }
    return hrSize;
  }

  static bool checkFileSize(double fileSize,double limitSize) {
    // FunctionUtils.log('fileSize:$fileSize');
    // FunctionUtils.log(('limitSize:$limitSize');
    //MB
    double m = ((fileSize / 1024.0) / 1024.0);
    //FunctionUtils.log(('m:$m');
    if (m > 1) {
      if(m > limitSize){
        return true;
      }else{
        return false;
      }
    } else {
      return false;
    }
  }

  ///メンバー配列情報でカンマ区切りのメンバーId文字列を作成
  static String createJoinedMemberIds(List<Member> selectedMembers){
    List<int> memberIds = [];
    //選択したメンバーidを追加
    for(Member selectedMember in selectedMembers){
      memberIds.add(int.parse(selectedMember.id));
    }
    //idの並び順を変更
    memberIds.sort((a, b) => a.compareTo(b));
    //配列をカンマ区切りの文字列に変更
    return memberIds.map<String>((int value) => value.toString()).join(',');
  }

  static String createMessageSendDayString(GroupMessage message,List<GroupMessage> talkList,int index){
    //日付：日本語対応
    initializeDateFormatting('ja');
    //送信日付
    String sendDay = '${intl.DateFormat('yyyy年MM月dd日').format(message.sendTime)}(${intl.DateFormat.E('ja').format(message.sendTime)})';
    //次の送信日付（※最後のメッセージは除外）
    if ((index + 1) < talkList.length) {
      GroupMessage nextMessage = talkList[(index + 1)];
      //次の送信日付と同じ場合は表示しない
      String nextDay = '${intl.DateFormat('yyyy年MM月dd日').format(nextMessage.sendTime)}(${intl.DateFormat.E('ja').format(nextMessage.sendTime)})';
      if (sendDay == nextDay) sendDay = '';
    }
    return sendDay;
  }

  ///日付でユニークキーを作成　※年(2桁)月日 + 時分秒
  static String createUniqueKeyFromDate(DateTime date){
    int nYmd = int.parse(DateFormat('yyMMdd').format(date));
    int nHms = int.parse(DateFormat('HHmmss').format(date));
    return (nYmd + nHms).toString();
  }

  static List<String> createArrayMemberIds(List<Member> members){
    List<int> memberIds = [];
    List<String> resultMemberIds = [];
    //選択したメンバーidを追加
    for(var member in members){
      memberIds.add(int.parse(member.id));
    }
    //idの並び順を変更
    memberIds.sort((a, b) => a.compareTo(b));
    //String型配列に変換
    for(var memberId in memberIds){
      resultMemberIds.add(memberId.toString());
    }
    return resultMemberIds;
  }

  ///ランダム英数字
  static String generateRandomString([int length = 6]) {
    const String charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZ';
    final Random random = Random.secure();
    final String randomStr =  List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
    return randomStr;
  }

  // //トースト表示
  static void showToast({
    String message = '',
    Toast toastLength = Toast.LENGTH_LONG,
    ToastGravity toastGravity = ToastGravity.BOTTOM,
    int time = 10,
    Color? backgroundColor,
    Color? textColor,
    double? textSize,
    bool cancelFlg = false
  }) {
    if (cancelFlg) {
      Fluttertoast.cancel();
    }
    Fluttertoast.showToast(
        msg: message,
        toastLength: toastLength,
        gravity: toastGravity,
        timeInSecForIosWeb: time,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: textSize
    );
  }

  static void log(Object? message) {
    // Debugモード以外ではログ無効
    if (!kDebugMode) return;
    // nullガード
    final text = message?.toString() ?? '';

    // 長すぎるログは分割（debugPrintの仕様に合わせる）
    const int maxLogLength = 800;
    if (text.length > maxLogLength) {
      int start = 0;
      while (start < text.length) {
        final end = (start + maxLogLength < text.length)
            ? start + maxLogLength
            : text.length;
        debugPrint(text.substring(start, end));
        start = end;
      }
    } else {
      debugPrint(text);
    }
  }
}
