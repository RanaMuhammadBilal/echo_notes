import 'package:echo_notes/AuthenticationProvider.dart';
import 'package:echo_notes/ThemeProvider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../AuthenticationServices.dart';
import '../provider_notes.dart';
import 'TrashScreen.dart';

class Settings extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => SettingsState();

}

class SettingsState extends State<Settings> {

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // --- THEME SELECTOR SECTION ---
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Material(
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(   // ✅ ADD THIS LINE
                borderRadius: BorderRadius.circular(20),
              ),
              child: ExpansionTile(
                shape: const Border(), // Removes default lines
                leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
                title: const Text('App Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Current: ${themeProvider.currentThemeName.toUpperCase()}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildThemeOption(context, 'light', 'Classic', Colors.blue, Colors.white),
                        _buildThemeOption(context, 'dark', 'Dark', Colors.indigo, const Color(0xFF121212)),
                        _buildThemeOption(context, 'island', 'Island', const Color(0xFF00BFA5), const Color(0xFF001F24)),
                        _buildThemeOption(context, 'creamy', 'Creamy', const Color(0xFF8D6E63), const Color(0xFFFFF8E1)),
                        _buildThemeOption(context, 'native', 'Native', const Color(0xFF6750A4), const Color(0xFFFEF7FF)),
                        _buildThemeOption(context, 'midnight', 'Midnight', const Color(0xFFBB86FC), const Color(0xFF0F0F1A)),
                        _buildThemeOption(context, 'sunset', 'Sunset', const Color(0xFFFF5722), const Color(0xFFFFF5F0)),
                        _buildThemeOption(context, 'forest', 'Forest', const Color(0xFF81C784), const Color(0xFF0D1B0D)),
                        _buildThemeOption(context, 'aero', 'Aero', const Color(0xFF00B0FF), const Color(0xFFF0F9FF)),
                        _buildThemeOption(context, 'rose', 'Rose', const Color(0xFFD81B60), const Color(0xFFFFF5F8)),
                        _buildThemeOption(context, 'cyber', 'Cyber', const Color(0xFFF06292), const Color(0xFF0D0221)),
                        _buildThemeOption(context, 'nordic', 'Nordic', const Color(0xFF81A1C1), const Color(0xFF2E3440)),
                        _buildThemeOption(context, 'monochrome', 'Monochrome', Colors.black, Colors.white),
                        _buildThemeOption(context, 'espresso', 'Espresso', const Color(0xFFA1887F), const Color(0xFF3E2723)),
                        _buildThemeOption(context, 'solarized', 'Solarized', const Color(0xFF268BD2), const Color(0xFF002B36)),
                        _buildThemeOption(context, 'valentine', 'Valentine', const Color(0xFFFF4D6D), const Color(0xFFFFF0F3)),
                        _buildThemeOption(context, 'volcano', 'Volcano', const Color(0xFFFF5722), const Color(0xFF121212)),
                        _buildThemeOption(context, 'ivory', 'Ivory', const Color(0xFF5D4037), const Color(0xFFFDFCF0)),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- BIOMETRIC SECTION ---
          Consumer<AuthenticationProvider>(
            builder: (context, authProvider, _) {
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile.adaptive(
                  secondary: Icon(Icons.fingerprint_rounded, color: colorScheme.primary),
                  value: authProvider.getAuthenticationValue(),
                  onChanged: (value) async {
                    HapticFeedback.mediumImpact();
                    if (value == true) {
                      final auth = AuthenticationServices();

                      // Check available biometrics
                      List<BiometricType> biometrics = await auth.localAuthentication.getAvailableBiometrics();
                      bool isSupported = await auth.localAuthentication.isDeviceSupported();

                      // If no biometrics are enrolled AND the device doesn't support basic PIN/Pass
                      // (or they aren't set), block the toggle.
                      if (biometrics.isEmpty && !isSupported) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No security set! Please add a PIN or Fingerprint in Device Settings.")),
                        );
                        return;
                      }
                    }
                    await authProvider.saveAuthentication(value: value);
                  },
                  title: const Text('Biometric Lock', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Secure your notes with fingerprint'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // --- RECYCLE BIN SECTION (NEW) ---
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrashScreen()),
                );
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              title: const Text('Recycle Bin', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Notes are auto-deleted after 30 days'),
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          Consumer<NotesProvider>(
            builder: (context, notesProvider, _) {
              return Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile.adaptive(
                  secondary: Icon(
                      notesProvider.showNoteBorder
                          ? Icons.border_all_rounded
                          : Icons.border_clear_rounded,
                      color: colorScheme.primary
                  ),
                  value: notesProvider.showNoteBorder,
                  onChanged: (value) {
                    notesProvider.toggleNoteBorder();
                  },
                  title: const Text('Editor Border', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Show a framed border around your notes'),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Theme Preview Circle Helper ---
  Widget _buildThemeOption(BuildContext context, String themeKey, String label, Color accent, Color bg) {
    final provider = context.read<ThemeProvider>();
    final isSelected = provider.currentThemeName == themeKey;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        provider.saveTheme(themeKey);
        },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent, bg],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}