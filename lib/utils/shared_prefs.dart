import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _preferences;

  static Future<void> setInstance() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  static Future<void> set({
    required String name,
    required String value,
  }) async {
    await setInstance();
    await _preferences!.setString(name,value);
  }

  static String fetch({
    required String name,
  }) {
    return _preferences!.getString(name) ?? '';
  }

  static Future<void> clear() async {
    await setInstance();
    await _preferences!.clear();
  }

  static Future<void> setAuth({
    required String domainId,
    required String appToken}) async {

    await setInstance();
    await _preferences!.setString('domainId', domainId);
    await _preferences!.setString('appToken', appToken);
  }

  static String fetchDomainId() {
    return _preferences!.getString('domainId') ?? '';
  }

  static String fetchAppToken() {
    return _preferences!.getString('appToken') ?? '';
  }

  static Future<void> removeAuth() async {
    await setInstance();
    await _preferences!.remove('domainId');
    await _preferences!.remove('appToken');
  }



  static Future<void> setRoomMessage({
    required String roomId,
    required String message}) async {

    await setInstance();
    await _preferences!.setString('roomMessage$roomId', message);
  }

  static String getRoomMessage({required String roomId}) {
    return _preferences!.getString('roomMessage$roomId') ?? '';
  }

  static Future<void> setGroupMessage({
    required String roomId,
    required String message}) async {

    await setInstance();
    await _preferences!.setString('groupMessage$roomId', message);
  }

  static String getGroupMessage({required String roomId}) {
    return _preferences!.getString('groupMessage$roomId') ?? '';
  }
}
