import 'package:echo_notes/models/note_model.dart';
import 'package:echo_notes/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteModel Tests', () {
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

      expect(note.plainTextSnippet, equals('Just plain text without JSON format'));
    });
  });

  group('BackupService Tests', () {
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
  });
}
