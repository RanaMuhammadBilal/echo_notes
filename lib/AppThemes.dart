import 'package:flutter/material.dart';

class AppThemes {
  // 1. Classic Light
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  // 2. Classic Dark
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    ),
  );

  // 3. Island Dark (Tropical / Deep Sea)
  static final islandDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00BFA5), // Teal Accent
      surface: Color(0xFF001F24),  // Deep Cyan/Black
      onSurface: Color(0xFFE0F7FA), // Very light blue text
      secondary: Color(0xFF006064),
    ),
    scaffoldBackgroundColor: const Color(0xFF001F24),
  );

  // 4. Creamy Light (Vintage / Warm)
  static final creamyLight = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8D6E63), // Brownish accent
      surface: Color(0xFFFFF8E1),  // Soft Cream
      onSurface: Color(0xFF3E2723), // Dark Chocolate text
      secondary: Color(0xFFFFECB3),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF8E1),
  );
  // 5. Material Native (Android M3 Style)
  static final nativeTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4), // Standard M3 Purple
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFFEF7FF),
  );

  // 6. Midnight Gradient (Deep Space)
  static final midnightGradient = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFBB86FC),
      surface: Color(0xFF121212),
      secondary: Color(0xFF03DAC6),
      surfaceContainerLow: Color(0xFF1E1E2E), // Subtle dark blue-grey for cards
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
  );

  // 7. Sunset Glow (Warm Aesthetic)
  static final sunsetGlow = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      surface: const Color(0xFFFFF5F0),
      primary: const Color(0xFFFF5722),
      secondary: const Color(0xFFFFAB91),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF5F0),
  );

  // 8. Forest Emerald (Nature Premium)
  static final forestEmerald = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF81C784),
      surface: Color(0xFF1B2E1B),
      secondary: Color(0xFF4CAF50),
      surfaceContainerLow: Color(0xFF253D25),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1B0D),
  );
  // 9. Aero Glass (Clean & Airy)
  static final aeroGlass = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E5FF),
      surface: const Color(0xFFF0F9FF),
      primary: const Color(0xFF00B0FF),
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F9FF),
  );

  // 10. Rose Quartz (Elegant Luxury)
  static final roseQuartz = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF48FB1),
      surface: const Color(0xFFFFF5F8),
      primary: const Color(0xFFD81B60),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF5F8),
  );

  // 11. Cyberpunk (Neon Night)
  static final cyberpunk = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF06292), // Neon Pink
      secondary: Color(0xFFFFFF00), // Neon Yellow
      surface: Color(0xFF0D0221), // Deepest Purple-Black
      surfaceContainerLow: Color(0xFF190033),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D0221),
  );

  // 12. Nordic Blue (Professional Arctic)
  static final nordicBlue = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF81A1C1),
      surface: Color(0xFF2E3440),
      secondary: Color(0xFF88C0D0),
      surfaceContainerLow: Color(0xFF3B4252),
    ),
    scaffoldBackgroundColor: const Color(0xFF2E3440),
  );

  // 13. Monochrome Pro (Extreme Minimalism)
  static final monochromePro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF000000),
      secondary: Color(0xFFA1887F),
      onPrimary: Color(0xFFFFFFFF),
      surface: Color(0xFFF5F5F5),
      surfaceContainerLow: Color(0xFFE0E0E0),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
  );

  // 14. Espresso Shot (Cozy Dark)
  static final espressoShot = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD7CCC8), // Light Latte
      secondary: Color(0xFFA1887F),
      surface: Color(0xFF3E2723), // Coffee Bean
      surfaceContainerLow: Color(0xFF4E342E),
    ),
    scaffoldBackgroundColor: const Color(0xFF2D1B18),
  );

  // 15. Solarized Pro (Developer Classic)
  static final solarizedPro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF268BD2), // Solarized Blue
      secondary: Color(0xFF2AA198), // Solarized Cyan
      surface: Color(0xFF073642),
      surfaceContainerLow: Color(0xFF002B36),
    ),
    scaffoldBackgroundColor: const Color(0xFF002B36),
  );

  // 16. Valentine (Soft Pastel)
  static final valentineTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFB7C5),
      surface: const Color(0xFFFFF0F3),
      primary: const Color(0xFFFF4D6D),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFBFC),
  );
  // 17. Volcano Magma (High Contrast Dark)
  static final volcanoMagma = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF5722), // Vibrant Orange
      secondary: Color(0xFFFF9800),
      surface: Color(0xFF1A1A1A),
      surfaceContainerLow: Color(0xFF262626), // Dark Grey for Cards
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );

  // 18. Ivory Paper (Classic Notebook Feel)
  static final ivoryPaper = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF795548), // Brown seed
      surface: const Color(0xFFFDFCF0), // Warm Paper Color
      primary: const Color(0xFF5D4037), // Dark Coffee Brown
      secondary: const Color(0xFF8D6E63),
    ),
    scaffoldBackgroundColor: const Color(0xFFFDFCF0),
  );

}