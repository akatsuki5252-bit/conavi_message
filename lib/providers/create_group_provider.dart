import 'dart:io';
import 'package:conavi_message/model/member.dart';
import 'package:flutter_riverpod/legacy.dart';


//グループ名
final createGroupNameProvider = StateProvider<String>((ref) => '');
//グループ画像
final createGroupImagePathProvider = StateProvider<File?>((ref) => null);
//グループ参加メンバー
final createGroupMembersProvider = StateProvider<List<Member>>((ref) {
  return [];
});