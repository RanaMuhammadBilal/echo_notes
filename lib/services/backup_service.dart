import 'dart:convert';
import 'package:flutter/foundation.dart';

class BackupService {
  /// Serializes notes and category data into a JSON backup string.
  static String createJsonBackup({
    required List<Map<String, dynamic>> notes,
    required List<String> categories,
  }) {
    final Map<String, dynamic> backupData = {
      'app': 'Echo Notes',
      'version': '1.1.1',
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories,
      'notes': notes.map((n) {
        final map = Map<String, dynamic>.from(n);
        // Clean key out before exporting payload
        map.remove('key');
        return map;
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Parses JSON backup string into categories and notes lists.
  static Map<String, dynamic>? parseJsonBackup(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic> && decoded.containsKey('notes')) {
        final categories = List<String>.from(decoded['categories'] ?? []);
        final notes = List<Map<String, dynamic>>.from(
          (decoded['notes'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        return {
          'categories': categories,
          'notes': notes,
        };
      }
    } catch (e) {
      debugPrint("Error parsing backup JSON: $e");
    }
    return null;
  }

  /// Converts a note (with Quill Delta content or plain text) into Markdown string.
  static String convertToMarkdown({
    required String title,
    required String content,
    required String timestamp,
    String? folder,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# $title');
    buffer.writeln();
    buffer.writeln('_Created on $timestamp${folder != null ? " • Notebook: $folder" : ""}_');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    try {
      final List<dynamic> decoded = jsonDecode(content);
      for (final op in decoded) {
        if (op is Map) {
          final insertVal = op['insert'];
          final attributes = op['attributes'] as Map<String, dynamic>?;

          if (insertVal is String) {
            String text = insertVal;
            if (attributes != null) {
              if (attributes['bold'] == true) text = '**$text**';
              if (attributes['italic'] == true) text = '*$text*';
              if (attributes['code'] == true) text = '`$text`';
            }
            buffer.write(text);
          } else if (insertVal is Map && insertVal.containsKey('image')) {
            final imagePath = insertVal['image'].toString();
            buffer.writeln('\n![Image]($imagePath)\n');
          }
        }
      }
    } catch (_) {
      buffer.writeln(content);
    }

    return buffer.toString();
  }

  /// Converts plain text or simple markdown lines to Quill Delta JSON format.
  static String convertMarkdownToDeltaJson(String rawText) {
    final lines = rawText.split('\n');
    final List<Map<String, dynamic>> deltaOps = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.startsWith('# ')) {
        deltaOps.add({'insert': line.substring(2)});
        deltaOps.add({
          'insert': '\n',
          'attributes': {'header': 1}
        });
      } else if (line.startsWith('## ')) {
        deltaOps.add({'insert': line.substring(3)});
        deltaOps.add({
          'insert': '\n',
          'attributes': {'header': 2}
        });
      } else {
        deltaOps.add({'insert': line});
        if (i < lines.length - 1) {
          deltaOps.add({'insert': '\n'});
        }
      }
    }

    if (deltaOps.isEmpty) {
      deltaOps.add({'insert': '\n'});
    }

    return jsonEncode(deltaOps);
  }
}
