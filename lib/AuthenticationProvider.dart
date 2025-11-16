import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class AuthenticationProvider extends ChangeNotifier{
  bool isAuthentication = false;
  bool getAuthenticationValue() => isAuthentication;

  AuthenticationProvider(){
    loadAuthentication();
  }


  Future<void> loadAuthentication() async{
    var box = Hive.box('settings');
    isAuthentication = box.get('isAuthentication', defaultValue: false);
    notifyListeners();
  }

  Future<void> saveAuthentication({required bool value}) async{
    var box = Hive.box('settings');
    await box.put('isAuthentication', value);
    isAuthentication = value;
    notifyListeners();
  }

}