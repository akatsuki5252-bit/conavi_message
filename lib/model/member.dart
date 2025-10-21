
class Member {
  String id = '';
  String? email = '';
  String? password = '';
  String name = '';
  String imagePath = '';
  String selfIntroduction = '';
  String? notifyEmailFlag = ''; //メールアドレス通知フラグ
  String notifyAppFlag = ''; //アプリ通知フラグ
  String? appToken = '';
  String? fcmToken = '';
  DateTime? createTime;
  DateTime? updateTime;

  int sortId = 0;
  bool isChecked = false;

  Member({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.selfIntroduction,
    this.email,
    this.password,
    this.notifyEmailFlag,
    this.appToken,
    this.fcmToken,
    this.createTime,
    this.updateTime,
  });

  void setSortId(String id){
    sortId = int.parse(id);
  }

  Map<String, dynamic> toJson() {
    var data = {
      'id' : id,
      'email' : email,
      'password' : password,
      'name' : name,
      'imagePath' : imagePath,
      'selfIntroduction': selfIntroduction,
      'appToken' : appToken,
      'fcmToken' : fcmToken,
      'createTime': createTime,
      'updateTime': updateTime,
    };
    return data;
  }
}
