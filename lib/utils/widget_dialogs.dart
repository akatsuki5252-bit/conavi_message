

import 'package:conavi_message/const/enum.dart';
import 'package:flutter/material.dart';

class WidgetDialogs {

  ///メッセージ並び替えダイアログ
  static Widget showMessageRoomSortDialog(BuildContext context,MessageSort sort){
    return SimpleDialog(
      children: [
        SimpleDialogOption(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('受信時間'),
              if(sort == MessageSort.time)
                const Icon(Icons.check,color: Colors.amber),
            ],
          ),
          onPressed: () {
            Navigator.pop(context, MessageSort.time);
          },
        ),
        SimpleDialogOption(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('未読メッセージ'),
              if(sort == MessageSort.unRead)
                const Icon(Icons.check,color: Colors.amber)
            ],
          ),
          onPressed: () {
            Navigator.pop(context, MessageSort.unRead);
          },
        )
      ],
    );
  }

  ///グループメッセージ操作ダイアログ
  static Widget showGroupMessageActionDialog(BuildContext context){
    return SimpleDialog(
      children: [
        SimpleDialogOption(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text('受信時間'),
              Icon(Icons.check,color: Colors.amber)
            ],
          ),
          onPressed: () {
            Navigator.pop(context, '受信時間');
          },
        ),
        SimpleDialogOption(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text('未読メッセージ'),
              Icon(Icons.check,color: Colors.amber)
            ],
          ),
          onPressed: () {
            Navigator.pop(context, '未読メッセージ');
          },
        )
      ],
    );
  }

  ///グループメッセージ操作画像ファイル選択ダイアログ
  static Widget showFileTypeDialog(BuildContext context){
    return SimpleDialog(
      children: [
        SimpleDialogOption(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text('画像'),
              Icon(Icons.image_outlined,color: Colors.amber)
            ],
          ),
          onPressed: () {
            Navigator.pop(context, MessageFileType.image);
          },
        ),
        SimpleDialogOption(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text('ファイル'),
              Icon(Icons.insert_drive_file_outlined,color: Colors.amber)
            ],
          ),
          onPressed: () {
            Navigator.pop(context, MessageFileType.file);
          },
        ),
      ],
    );
  }
}