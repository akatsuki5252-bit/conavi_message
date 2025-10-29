import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conavi_message/model/member.dart';
import 'package:conavi_message/model/talk_room.dart';
import 'package:conavi_message/api/api_members.dart';
import 'package:conavi_message/utils/authentication.dart';
import 'package:conavi_message/utils/function_utils.dart';

class RoomFirestore {
  static final FirebaseFirestore _firebaseFirestoreInstance = FirebaseFirestore.instance;
  static final _roomCollection = _firebaseFirestoreInstance.collection('room');
  static final joinedRoomSnapshot = _roomCollection
      .where('joined_user_ids', arrayContains: Authentication.myAccount?.member.id)
      .snapshots();

  static Future<bool> createRoom(List<String> memberIds) async {
    try {
      await _roomCollection.add({
        'joined_user_ids': memberIds,
        'created_time': Timestamp.now(),
        'modified_time': Timestamp.now(),
      });

      FunctionUtils.log('ルーム作成完了');
      return true;
    } catch (e) {
      FunctionUtils.log('ルームの作成失敗 ===== $e');
      return false;
    }
  }

  static Stream<QuerySnapshot> fetchJoinedRoomSnapshot(String mid) {
    return _roomCollection.where('joined_user_ids', arrayContains: mid).snapshots();
  }

  // static Future<void> createRoom(String? mid) async {
  //   var deepEq = const DeepCollectionEquality.unordered().equals;
  //   try {
  //     final members = await MemberApi.fetchMembers(mid!);
  //     if (members == null) return;
  //     //FunctionUtils.log(mid);
  //     for (var member in members) {
  //       //FunctionUtils.log(member.id);
  //       if (member.id == mid) return;
  //
  //       ///roomコレクション内のルーム情報を検索
  //       final snapshot = await _roomCollection
  //           .where('joined_user_ids', isEqualTo: [member.id, mid]).get();
  //
  //       ///存在しない場合はルーム情報を作成
  //       if (snapshot.docs.isEmpty) {
  //         await _roomCollection.add({
  //           'joined_user_ids': [member.id, mid],
  //           'created_time': Timestamp.now(),
  //         });
  //         FunctionUtils.log('ルーム[${member.id}=${mid}]作成');
  //       }
  //     }
  //     /*final snapshot = await _roomCollection
  //         .where('joined_user_ids', isEqualTo: ['11', mid]).get();
  //     FunctionUtils.log(snapshot.docs);*/
  //
  //     // for (var doc in snapshot.docs) {
  //     //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //     //   FunctionUtils.log(data);
  //     //   /*var list = <String>['11', '1'];
  //     //   if (deepEq(data['joined_user_ids'], list)) {
  //     //     FunctionUtils.log('yes');
  //     //   }*/
  //     //   /*if (doc.id == myUid) return;
  //     //   await _roomCollection.add({
  //     //     'joined_user_ids': [doc.id, myUid],
  //     //     'created_time': Timestamp.now(),
  //     //   });*/
  //     // }
  //
  //     FunctionUtils.log('ルーム作成完了');
  //   } catch (e) {
  //     FunctionUtils.log('ルームの作成失敗 ===== $e');
  //   }
  // }

  static Future<List<TalkRoom>?> fetchJoinedRooms({
      required QuerySnapshot snapshot,
      required String domain}) async {
    try {
      List<TalkRoom> talkRooms = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> userIds = data['joined_user_ids'];
        //FunctionUtils.log(userIds);
        List<Member> talkMembers = [];
        for (var id in userIds) {
          //if (id == myUid) continue;
          Member? talkMember = await ApiMembers.fetchProfile(
            domain: domain,
            memberId: id,
          );
          if (talkMember == null) return null;
          talkMembers.add(talkMember);
        }
        final talkRoom = TalkRoom(
            roomId: doc.id,
            talkMembers: talkMembers,
            lastMessage: data['last_message'] ?? '',
            createdTime: data['modified_time'].toDate(),
            modifiedTime: data['modified_time'].toDate());
        talkRooms.add(talkRoom);
        FunctionUtils.log(talkRooms);
      }
      //並び順
      talkRooms.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
      //FunctionUtils.log(talkRooms.length);
      return talkRooms;
    } catch (e) {
      FunctionUtils.log('参加しているルームの取得失敗 ===== $e');
      return null;
    }
  }

  static Stream<QuerySnapshot> fetchMessageSnapshot(String roomId) {
    return _roomCollection
        .doc(roomId)
        .collection('message')
        .orderBy('send_time', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage(
      {required String roomId,
      required String senderId,
      required String message}) async {
    try {
      final messageCollection =
          _roomCollection.doc(roomId).collection('message');
      await messageCollection.add({
        'message': message,
        'sender_id': senderId,
        'send_time': DateTime.now(),
      });

      await _roomCollection.doc(roomId).update({
        'last_message': message,
        'modified_time': Timestamp.now(),
      });
    } catch (e) {
      FunctionUtils.log('メッセージの送信失敗 ===== $e');
    }
  }
}
