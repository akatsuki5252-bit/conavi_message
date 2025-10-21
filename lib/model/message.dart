import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/utils/upload_file.dart';
import 'package:flutter/material.dart';

class Message {
  String id;
  String message;
  Widget widgetMessage;
  String fileUrl;
  String fileName;
  String fileExt;
  UploadFile file;
  Member? member;
  bool isMe;
  bool readFlag;
  DateTime sendTime;
  String type;

  Message({
    required this.id,
    required this.message,
    required this.widgetMessage,
    required this.fileUrl,
    required this.fileName,
    required this.fileExt,
    required this.file,
    required this.member,
    required this.isMe,
    required this.readFlag,
    required this.sendTime,
    this.type = ''
  });
}
