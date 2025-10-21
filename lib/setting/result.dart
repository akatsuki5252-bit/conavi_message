import 'auth.dart';

class Result {
  bool isSuccess;
  String? error;
  Map<String, String> data = {};
  Auth? account;

  Result({
    this.isSuccess = false,
    this.error = '',
  });

  void set(String key,String value){
    Map<String, String> map = {key:value};
    data.addAll(map);
  }
}