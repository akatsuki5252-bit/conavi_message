
//グループメッセージ用ファイル
class GroupMessageFile {
  String id; //id
  String name; //ファイル名
  String url; //URL
  String extension; //拡張子
  DateTime? createTime;
  DateTime? updateTime;

  //コンストラクタ
  GroupMessageFile({
    required this.id,
    required this.name,
    required this.url,
    required this.extension,
    required this.createTime,
    required this.updateTime,
  });
}
