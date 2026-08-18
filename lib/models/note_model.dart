import 'dart:convert';

class NoteModel {
  final dynamic key;
  final String title;
  final String content;
  final String timestamp;
  final String folder;
  final bool isPinned;
  final bool isDeleted;
  final bool isLocked;
  final String? deletedAt;
  final String? reminderDateTime;

  NoteModel({
    this.key,
    required this.title,
    required this.content,
    required this.timestamp,
    this.folder = "General",
    this.isPinned = false,
    this.isDeleted = false,
    this.isLocked = false,
    this.deletedAt,
    this.reminderDateTime,
  });

  factory NoteModel.fromMap(dynamic key, Map<dynamic, dynamic> map) {
    return NoteModel(
      key: key,
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? '',
      folder: map['folder']?.toString() ?? 'General',
      isPinned: map['isPinned'] == true,
      isDeleted: map['isDeleted'] == true,
      isLocked: map['isLocked'] == true,
      deletedAt: map['deletedAt']?.toString(),
      reminderDateTime: map['reminderDateTime']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'folder': folder,
      'isPinned': isPinned,
      'isDeleted': isDeleted,
      'isLocked': isLocked,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (reminderDateTime != null) 'reminderDateTime': reminderDateTime,
    };
  }

  NoteModel copyWith({
    dynamic key,
    String? title,
    String? content,
    String? timestamp,
    String? folder,
    bool? isPinned,
    bool? isDeleted,
    bool? isLocked,
    String? deletedAt,
    String? reminderDateTime,
  }) {
    return NoteModel(
      key: key ?? this.key,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      folder: folder ?? this.folder,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      isLocked: isLocked ?? this.isLocked,
      deletedAt: deletedAt ?? this.deletedAt,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
    );
  }

  /// Converts note content to plain text snippet if it is formatted in Quill Delta JSON
  String get plainTextSnippet {
    if (content.trim().isEmpty) return '';
    try {
      final List<dynamic> decoded = jsonDecode(content);
      final buffer = StringBuffer();
      for (final op in decoded) {
        if (op is Map && op.containsKey('insert')) {
          final insertVal = op['insert'];
          if (insertVal is String) {
            buffer.write(insertVal);
          }
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return content.trim();
    }
  }
}
