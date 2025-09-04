import 'package:get_storage/get_storage.dart';
var appStorage = AppStoragePref.shared;
class AppStoragePref {
  AppStoragePref._();
  static final shared = AppStoragePref._();
  var customerStorage =
  GetStorage("customerStorage");


  init() async {
    await GetStorage.init("customerStorage");
    return true;
  }

  String get getAuthToken =>
     customerStorage.read("AuthToken") ?? "";

  setAuthToken(String token) {
    customerStorage.write("AuthToken", token);
  }
  bool get getIsLogin =>
      customerStorage.read("isLogin") ?? false;

  setIsLogin(bool isLogin) {
    customerStorage.write("isLogin", isLogin);
  }

  int get getUserId =>
      customerStorage.read("setUserId") ?? 0;

  setUserId(int userId) {
    customerStorage.write("setUserId", userId);
  }
}