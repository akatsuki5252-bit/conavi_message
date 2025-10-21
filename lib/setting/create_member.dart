class CreateMember {
  String userName; //ユーザー名
  String email; //メールアドレス
  String password; //パスワード
  String communityName; //コミュニティ名
  String conaviId; //コナビID
  String inviteCode; //招待コード

  CreateMember({
    required this.userName,
    required this.email,
    required this.password,
    this.communityName = '',
    this.conaviId = '',
    this.inviteCode = '',
  });
}