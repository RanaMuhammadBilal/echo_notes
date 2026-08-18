import 'dart:io';
import 'package:echo_notes/AuthenticationProvider.dart';
import 'package:echo_notes/ThemeProvider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../AuthenticationServices.dart';
import '../provider_notes.dart';
import 'TrashScreen.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  Future<void> _exportBackup(BuildContext context, NotesProvider notesProvider) async {
    try {
      final jsonContent = notesProvider.exportNotesBackup();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/echo_notes_backup.json');
      await file.writeAsString(jsonContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Echo Notes Backup',
        text: 'Backup file generated from Echo Notes.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Backup export failed: $e")),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, NotesProvider notesProvider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          final file = File(filePath);
          final content = await file.readAsString();
          final success = await notesProvider.importNotesBackup(content);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? "Notes successfully imported and restored!"
                    : "Invalid backup file format."),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Backup import failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context);
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ExpansionTile(
                shape: const Border(),
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
                        _buildThemeOption(context, 'amethyst', 'Amethyst', const Color(0xFFD0BCFF), const Color(0xFF1D1B20)),
                        _buildThemeOption(context, 'matcha', 'Matcha', const Color(0xFF4A6B22), const Color(0xFFF4F6F0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- VIEW LAYOUT SECTION ---
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile.adaptive(
              secondary: Icon(
                notesProvider.isGridView
                    ? Icons.grid_view_rounded
                    : Icons.view_agenda_rounded,
                color: colorScheme.primary,
              ),
              value: notesProvider.isGridView,
              onChanged: (value) {
                notesProvider.toggleGridView();
              },
              title: const Text('Grid Layout', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Display notes in a 2-column grid'),
            ),
          ),
          const SizedBox(height: 12),

          // --- ANIMATIONS & VISUAL EFFECTS SECTION ---
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                  value: notesProvider.enableAnimations,
                  onChanged: (_) => notesProvider.toggleAnimations(),
                  title: const Text('App Animations', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Master switch for all UI animations'),
                ),
                if (notesProvider.enableAnimations) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.only(left: 40, right: 16),
                    value: notesProvider.enableCardAnimations,
                    onChanged: (_) => notesProvider.toggleCardAnimations(),
                    title: const Text('Card Entrance Animations', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Staggered entry effects for note cards', style: TextStyle(fontSize: 12)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.only(left: 40, right: 16),
                    value: notesProvider.enableChipAnimations,
                    onChanged: (_) => notesProvider.toggleChipAnimations(),
                    title: const Text('Category Chip Scaling', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Interactive micro-scaling on selection', style: TextStyle(fontSize: 12)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.only(left: 40, right: 16),
                    value: notesProvider.enableHeroTransitions,
                    onChanged: (_) => notesProvider.toggleHeroTransitions(),
                    title: const Text('Hero Page Transitions', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Fluid note card expansion transitions', style: TextStyle(fontSize: 12)),
                  ),
                ],
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  secondary: Icon(Icons.blur_on_rounded, color: colorScheme.primary),
                  value: notesProvider.enableGlassmorphism,
                  onChanged: (_) => notesProvider.toggleGlassmorphism(),
                  title: const Text('Glassmorphic Blur Effects', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Frosted glass backdrop on bars & toolbars'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- APP-WIDE BIOMETRIC LOCK SECTION (PRESERVED) ---
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
                      List<BiometricType> biometrics = await auth.localAuthentication.getAvailableBiometrics();
                      bool isSupported = await auth.localAuthentication.isDeviceSupported();

                      if (biometrics.isEmpty && !isSupported) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No security set! Please add a PIN or Fingerprint in Device Settings.")),
                          );
                        }
                        return;
                      }
                    }
                    await authProvider.saveAuthentication(value: value);
                  },
                  title: const Text('App Lock', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Require biometrics/PIN when opening application'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // --- EDITOR BORDER SECTION ---
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
                    color: colorScheme.primary,
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

          // --- BACKUP & RESTORE SECTION ---
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_upload_outlined, color: colorScheme.primary),
                  title: const Text('Backup Notes (Export JSON)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Export all notes and notebooks to file'),
                  onTap: () => _exportBackup(context, notesProvider),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.cloud_download_outlined, color: colorScheme.primary),
                  title: const Text('Restore Notes (Import JSON)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Import notes from a JSON backup file'),
                  onTap: () => _importBackup(context, notesProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- RECYCLE BIN SECTION ---
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
              leading: Icon(Icons.delete_sweep_outlined, color: colorScheme.primary),
              title: const Text('Recycle Bin', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Notes are auto-deleted after 30 days'),
              trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

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