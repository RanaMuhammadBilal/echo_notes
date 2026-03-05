import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'AppThemes.dart';

class ThemeProvider extends ChangeNotifier {
  // Default to 'light'
  String _currentThemeName = 'light';

  ThemeProvider() {
    loadTheme();
  }

  // Helper to get the actual ThemeData based on the name
  ThemeData getThemeData() {
    switch (_currentThemeName) {
      case 'dark': return AppThemes.darkTheme;
      case 'island': return AppThemes.islandDark;
      case 'creamy': return AppThemes.creamyLight;
      case 'native': return AppThemes.nativeTheme;
      case 'midnight': return AppThemes.midnightGradient;
      case 'sunset': return AppThemes.sunsetGlow;
      case 'forest': return AppThemes.forestEmerald;
      case 'aero': return AppThemes.aeroGlass;
      case 'rose': return AppThemes.roseQuartz;
      case 'cyber': return AppThemes.cyberpunk;
      case 'nordic': return AppThemes.nordicBlue;
      case 'monochrome': return AppThemes.monochromePro;
      case 'espresso': return AppThemes.espressoShot;
      case 'solarized': return AppThemes.solarizedPro;
      case 'valentine': return AppThemes.valentineTheme;
      case 'volcano': return AppThemes.volcanoMagma;
      case 'ivory': return AppThemes.ivoryPaper;
      default: return AppThemes.lightTheme;
    }
  }

  String get currentThemeName => _currentThemeName;

  Future<void> loadTheme() async {
    var box = Hive.box('settings');
    // Load the string name, defaulting to 'light'
    _currentThemeName = box.get('themeName', defaultValue: 'light');
    notifyListeners();
  }

  Future<void> saveTheme(String themeName) async {
    var box = Hive.box('settings');
    await box.put('themeName', themeName);
    _currentThemeName = themeName;
    notifyListeners();
  }
}
