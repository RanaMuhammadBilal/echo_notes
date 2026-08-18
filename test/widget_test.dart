import 'dart:io';
import 'package:echo_notes/AppThemes.dart';
import 'package:echo_notes/AuthenticationProvider.dart';
import 'package:echo_notes/ThemeProvider.dart';
import 'package:echo_notes/models/note_model.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:echo_notes/screens/AnimationControlScreen.dart';
import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:echo_notes/screens/HomePage.dart';
import 'package:echo_notes/screens/SearchScreen.dart';
import 'package:echo_notes/screens/Settings.dart';
import 'package:echo_notes/screens/VoiceNote.dart';
import 'package:echo_notes/services/backup_service.dart';
import 'package:echo_notes/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('notesBox')) await Hive.openBox('notesBox');
    if (!Hive.isBoxOpen('categoryBox')) await Hive.openBox('categoryBox');
    if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
  });

  group('1. NoteModel Unit Tests', () {
    test('NoteModel serialization and deserialization works correctly', () {
      final note = NoteModel(
        key: 1,
        title: 'Test Title',
        content: '[{"insert":"Hello World\\n"}]',
        timestamp: '18 August, 2026, 6:00 PM',
        folder: 'Work',
        isPinned: true,
        isDeleted: false,
        isLocked: true,
        reminderDateTime: '2026-08-19T10:00:00.000',
      );

      final map = note.toMap();
      expect(map['title'], equals('Test Title'));
      expect(map['folder'], equals('Work'));
      expect(map['isPinned'], isTrue);
      expect(map['isLocked'], isTrue);
      expect(map['reminderDateTime'], equals('2026-08-19T10:00:00.000'));

      final reconstructed = NoteModel.fromMap(1, map);
      expect(reconstructed.title, equals(note.title));
      expect(reconstructed.folder, equals(note.folder));
      expect(reconstructed.isPinned, equals(note.isPinned));
      expect(reconstructed.isLocked, equals(note.isLocked));
      expect(reconstructed.plainTextSnippet, equals('Hello World'));
    });

    test('NoteModel plainTextSnippet handles raw text gracefully', () {
      final note = NoteModel(
        key: 2,
        title: 'Plain Text Note',
        content: 'Just plain text without JSON format',
        timestamp: '18 August, 2026, 6:00 PM',
      );

      expect(
          note.plainTextSnippet, equals('Just plain text without JSON format'));
    });
  });

  group('2. BackupService Unit Tests', () {
    test('JSON Backup creation and parsing works correctly', () {
      final notes = [
        {
          'key': 101,
          'title': 'Backup Note 1',
          'content': 'Content 1',
          'timestamp': 'Today',
          'folder': 'Personal',
        },
        {
          'key': 102,
          'title': 'Backup Note 2',
          'content': 'Content 2',
          'timestamp': 'Today',
          'folder': 'Work',
        }
      ];

      final categories = ['General', 'Personal', 'Work'];

      final jsonBackup = BackupService.createJsonBackup(
        notes: notes,
        categories: categories,
      );

      expect(jsonBackup, contains('Backup Note 1'));
      expect(jsonBackup, contains('Echo Notes'));

      final parsed = BackupService.parseJsonBackup(jsonBackup);
      expect(parsed, isNotNull);
      expect(parsed!['categories'], equals(categories));
      expect((parsed['notes'] as List).length, equals(2));
    });

    test('Markdown conversion formats title, timestamp, and content', () {
      final md = BackupService.convertToMarkdown(
        title: 'My Important Note',
        content: '[{"insert":"Sample markdown text\\n"}]',
        timestamp: '18 August, 2026',
        folder: 'Ideas',
      );

      expect(md, contains('# My Important Note'));
      expect(md, contains('_Created on 18 August, 2026 • Notebook: Ideas_'));
      expect(md, contains('Sample markdown text'));
    });

    test('parseJsonBackup returns null for invalid JSON string', () {
      final parsed = BackupService.parseJsonBackup("invalid_json_string");
      expect(parsed, isNull);
    });
  });

  group('3. AppThemes & ThemeProvider Unit Tests', () {
    test('AppThemes defines all themes with valid color schemes', () {
      expect(AppThemes.lightTheme.colorScheme.primary, isNotNull);
      expect(AppThemes.darkTheme.brightness, equals(Brightness.dark));
      expect(AppThemes.amethystVelvet.colorScheme.primary,
          equals(const Color(0xFFD0BCFF)));
      expect(AppThemes.matchaCream.colorScheme.primary,
          equals(const Color(0xFF4A6B22)));
    });

    test('ThemeProvider loads theme and switches themes correctly', () async {
      final themeProvider = ThemeProvider();
      await themeProvider.saveTheme('amethyst');
      expect(themeProvider.currentThemeName, equals('amethyst'));
      expect(themeProvider.getThemeData().colorScheme.primary,
          equals(const Color(0xFFD0BCFF)));

      await themeProvider.saveTheme('matcha');
      expect(themeProvider.currentThemeName, equals('matcha'));
      expect(themeProvider.getThemeData().colorScheme.primary,
          equals(const Color(0xFF4A6B22)));
    });
  });

  group('4. NotesProvider Unit Tests', () {
    test(
        'NotesProvider toggles grid view, borders, animations, and glassmorphism',
        () {
      final provider = NotesProvider();

      final initialGrid = provider.isGridView;
      provider.toggleGridView();
      expect(provider.isGridView, equals(!initialGrid));

      final initialBorder = provider.showNoteBorder;
      provider.toggleNoteBorder();
      expect(provider.showNoteBorder, equals(!initialBorder));

      final initialGridAnim = provider.enableGridAnimations;
      provider.toggleGridAnimations();
      expect(provider.enableGridAnimations, equals(!initialGridAnim));

      final initialButtonBounce = provider.enableButtonBounce;
      provider.toggleButtonBounce();
      expect(provider.enableButtonBounce, equals(!initialButtonBounce));

      final initialFabPulse = provider.enableFabPulse;
      provider.toggleFabPulse();
      expect(provider.enableFabPulse, equals(!initialFabPulse));

      final initialSyntheticWave = provider.enableSyntheticWaveform;
      provider.toggleSyntheticWaveform();
      expect(provider.enableSyntheticWaveform, equals(!initialSyntheticWave));

      final initialAnim = provider.enableAnimations;
      provider.toggleAnimations();
      expect(provider.enableAnimations, equals(!initialAnim));

      final initialGlass = provider.enableGlassmorphism;
      provider.toggleGlassmorphism();
      expect(provider.enableGlassmorphism, equals(!initialGlass));
    });

    test('NotesProvider adds, edits, pins, locks, and deletes notes', () {
      final provider = NotesProvider();

      final initialCount = provider.notes.length;
      provider.addNote(
        "Unit Test Note",
        "Unit Test Content",
        "General",
      );

      expect(provider.notes.length, equals(initialCount + 1));
      final addedKey = provider.notes.first['key'];

      provider.togglePin(addedKey);
      expect(provider.notes.first['isPinned'], isTrue);

      provider.toggleNoteLock(addedKey);
      expect(provider.notes.first['isLocked'], isTrue);

      provider.deleteNote(addedKey);
      expect(provider.trashedNotes.any((n) => n['key'] == addedKey), isTrue);

      provider.restoreNote(addedKey);
      expect(provider.notes.any((n) => n['key'] == addedKey), isTrue);

      provider.permanentlyDeleteNote(addedKey);
      expect(provider.notes.any((n) => n['key'] == addedKey), isFalse);
    });
  });

  group('5. AuthenticationProvider Unit Tests', () {
    test('AuthenticationProvider stores and updates authentication state',
        () async {
      final authProvider = AuthenticationProvider();
      await authProvider.saveAuthentication(value: true);
      expect(authProvider.getAuthenticationValue(), isTrue);

      await authProvider.saveAuthentication(value: false);
      expect(authProvider.getAuthenticationValue(), isFalse);
    });
  });

  group('6. NotificationService Unit Tests', () {
    test('NotificationService initializes safely', () async {
      final notif = NotificationService();
      expect(notif, isNotNull);
    });

    test('NotesProvider setNoteReminder updates and clears note reminderDateTime', () {
      final provider = NotesProvider();
      provider.addNote("Reminder Test Note", "Content", "General");
      final key = provider.notes.first['key'];

      final futureDate = DateTime.now().add(const Duration(days: 1));
      provider.setNoteReminder(key, futureDate);

      final updatedNote = provider.notes.firstWhere((n) => n['key'] == key);
      expect(updatedNote['reminderDateTime'], isNotNull);
      expect(updatedNote['reminderDateTime'], equals(futureDate.toIso8601String()));

      // Clear reminder
      provider.setNoteReminder(key, null);
      final clearedNote = provider.notes.firstWhere((n) => n['key'] == key);
      expect(clearedNote['reminderDateTime'], isNull);
    });
  });

  group('7. Widget Tests', () {
    Widget buildTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NotesProvider()),
          ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('HomePage renders App Title and Category Chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Echo Notes'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('General'), findsAtLeast(1));
    });

    testWidgets('DetailScreen renders Note Title and Folder Tag',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const DetailScreen(
        index: 999,
        titleNote: 'Sample Detail Note',
        contentNote: 'Sample Content text',
        timestamp: '18 August 2026',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Sample Detail Note'), findsOneWidget);
      expect(find.text('18 August 2026'), findsOneWidget);
    });

    testWidgets('SearchScreen renders Search Input and Empty State',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const SearchScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Search Notes'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Settings screen renders App Theme and Animation Options',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const Settings()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('Animation Control Center'), findsOneWidget);
    });

    testWidgets('AnimationControlScreen renders Master & Fine-grained Switches',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const AnimationControlScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Animation Control Center'), findsOneWidget);
      expect(find.text('Master Animations Switch'), findsOneWidget);
      expect(find.text('Card Entrance Animations'), findsOneWidget);
      expect(find.text('Grid / List Layout Motion'), findsOneWidget);
      expect(find.text('Tactile Button Spring Bounce'), findsOneWidget);
    });

    testWidgets('VoiceNote screen renders dictation banner, waveform, and mic button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const VoiceNote()));
      await tester.pump();

      expect(find.text('Voice Dictation'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Tap Mic to Start Continuous Dictation'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(AudioWaveformVisualizer), findsOneWidget);
      expect(find.byType(PulsingMicButton), findsOneWidget);
    });
  });
}
