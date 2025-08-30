import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    loadTheme();
  }

  bool getThemeValue() => _isDarkMode;

  Future<void> loadTheme() async {
    var box = Hive.box('settings');
    _isDarkMode = box.get('isDarkMode', defaultValue: false);
    notifyListeners();
  }

  Future<void> saveTheme({required bool value}) async {
    var box = Hive.box('settings');
    await box.put('isDarkMode', value);
    _isDarkMode = value;
    notifyListeners();
  }
}
