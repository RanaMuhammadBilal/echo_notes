import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:echo_notes/models/note_model.dart';
import 'package:echo_notes/services/backup_service.dart';
import 'package:echo_notes/services/notification_service.dart';

class NotesProvider extends ChangeNotifier {
  final _box = Hive.box('notesBox');
  final _categoryBox = Hive.box('categoryBox');
  final _settingsBox = Hive.box('settings');

  bool _showNoteBorder = true;
  bool get showNoteBorder => _showNoteBorder;

  bool _isGridView = false;
  bool get isGridView => _isGridView;

  List<Map<String, dynamic>> _notes = [];
  List<String> _categories = [];

  List<String> get categories => _categories;

  // --- 1. FILTERED ACTIVE NOTES GETTER ---
  List<Map<String, dynamic>> get notes {
    List<Map<String, dynamic>> activeNotes =
        _notes.where((n) => !(n['isDeleted'] ?? false)).toList();

    activeNotes.sort((a, b) {
      bool aPinned = a['isPinned'] ?? false;
      bool bPinned = b['isPinned'] ?? false;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      // Safe key compare
      final keyA = a['key'];
      final keyB = b['key'];
      if (keyA is Comparable && keyB is Comparable) {
        return keyB.compareTo(keyA);
      }
      return 0;
    });

    return activeNotes;
  }

  /// Returns typed NoteModel active notes list
  List<NoteModel> get noteModels {
    return notes.map((map) => NoteModel.fromMap(map['key'], map)).toList();
  }

  // --- 2. TRASHED NOTES GETTER ---
  List<Map<String, dynamic>> get trashedNotes {
    return _notes.where((n) => n['isDeleted'] == true).toList();
  }

  List<NoteModel> get trashedNoteModels {
    return trashedNotes.map((map) => NoteModel.fromMap(map['key'], map)).toList();
  }

  NotesProvider() {
    loadNotes();
    loadCategories();
    _loadPreferences();
    cleanUpTrash(); // Run 30-day cleanup automatically when app starts
  }

  void _loadPreferences() {
    _showNoteBorder = _settingsBox.get('showNoteBorder', defaultValue: true);
    _isGridView = _settingsBox.get('isGridView', defaultValue: false);
    notifyListeners();
  }

  void toggleNoteBorder() {
    _showNoteBorder = !_showNoteBorder;
    _settingsBox.put('showNoteBorder', _showNoteBorder);
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void toggleGridView() {
    _isGridView = !_isGridView;
    _settingsBox.put('isGridView', _isGridView);
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void loadCategories() {
    bool hasInitialized = _settingsBox.get('hasInitializedCategories', defaultValue: false);

    if (_categoryBox.isEmpty && !hasInitialized) {
      _categories = ["General", "Work", "Personal", "College", "Ideas"];
      for (var cat in _categories) {
        _categoryBox.add(cat);
      }
      _settingsBox.put('hasInitializedCategories', true);
    } else {
      _categories = _categoryBox.values.cast<String>().toList();
    }
    notifyListeners();
  }

  void addCategory(String name) {
    if (!_categories.contains(name) && name.isNotEmpty) {
      _categoryBox.add(name);
      _settingsBox.put('hasInitializedCategories', true);
      loadCategories();
    }
  }

  void deleteCategory(String categoryName) {
    // 1. Move all notes in this category back to "General"
    final Map<dynamic, dynamic> notesMap = _box.toMap();

    notesMap.forEach((key, value) {
      if (value is Map) {
        final note = Map<String, dynamic>.from(value);
        if (note['folder'] == categoryName) {
          note['folder'] = "General";
          _box.put(key, note);
        }
      }
    });

    // 2. Find and delete category entry
    final Map<dynamic, dynamic> categoryMap = _categoryBox.toMap();
    dynamic keyToDelete;

    categoryMap.forEach((key, value) {
      if (value == categoryName) {
        keyToDelete = key;
      }
    });

    if (keyToDelete != null) {
      _categoryBox.delete(keyToDelete);
      _settingsBox.put('hasInitializedCategories', true);
      loadCategories();
      loadNotes();
    }
  }

  void loadNotes() {
    _notes = _box.keys.map((key) {
      final note = _box.get(key);
      final Map<String, dynamic> noteMap =
          note != null ? Map<String, dynamic>.from(note as Map) : {};
      return {
        'key': key,
        ...noteMap,
      };
    }).toList();
    notifyListeners();
  }

  void addNote(
    String title,
    String content,
    String timestamp, {
    String folder = "General",
    bool isLocked = false,
  }) {
    _box.add({
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'folder': folder,
      'isPinned': false,
      'isDeleted': false,
      'isLocked': isLocked,
    });
    loadNotes();
  }

  // --- SOFT DELETE ---
  void deleteNote(dynamic key) {
    final rawNote = _box.get(key);
    if (rawNote == null) return;
    final note = Map<String, dynamic>.from(rawNote as Map);
    note['isDeleted'] = true;
    note['isPinned'] = false;
    note['deletedAt'] = DateTime.now().toIso8601String();
    _box.put(key, note);

    // Cancel notification if any
    if (key is int) {
      NotificationService().cancelReminder(key);
    }

    HapticFeedback.heavyImpact();
    loadNotes();
  }

  // --- TRASH MANAGEMENT ---
  void restoreNote(dynamic key) {
    final rawNote = _box.get(key);
    if (rawNote == null) return;
    final note = Map<String, dynamic>.from(rawNote as Map);
    note['isDeleted'] = false;
    note.remove('deletedAt');
    _box.put(key, note);
    loadNotes();
  }

  void permanentlyDeleteNote(dynamic key) {
    if (key is int) {
      NotificationService().cancelReminder(key);
    }
    _box.delete(key);
    loadNotes();
  }

  void emptyTrash() {
    final keysToDelete =
        _notes.where((n) => n['isDeleted'] == true).map((n) => n['key']).toList();
    for (var key in keysToDelete) {
      if (key is int) {
        NotificationService().cancelReminder(key);
      }
      _box.delete(key);
    }
    loadNotes();
  }

  void cleanUpTrash() {
    final keysToDelete = [];
    for (var note in _notes) {
      if (note['isDeleted'] == true && note['deletedAt'] != null) {
        try {
          final deletedDate = DateTime.parse(note['deletedAt']);
          if (DateTime.now().difference(deletedDate).inDays >= 30) {
            keysToDelete.add(note['key']);
          }
        } catch (_) {}
      }
    }
    for (var key in keysToDelete) {
      if (key is int) {
        NotificationService().cancelReminder(key);
      }
      _box.delete(key);
    }
    if (keysToDelete.isNotEmpty) loadNotes();
  }

  void editNote(
    dynamic key,
    String newTitle,
    String newContent,
    String timestamp,
  ) {
    final rawNote = _box.get(key);
    if (rawNote == null) return;
    final oldNote = Map<String, dynamic>.from(rawNote as Map);
    _box.put(key, {
      'title': newTitle,
      'content': newContent,
      'timestamp': timestamp,
      'folder': oldNote['folder'] ?? "General",
      'isPinned': oldNote['isPinned'] ?? false,
      'isDeleted': oldNote['isDeleted'] ?? false,
      'isLocked': oldNote['isLocked'] ?? false,
      'deletedAt': oldNote['deletedAt'],
      'reminderDateTime': oldNote['reminderDateTime'],
    });
    loadNotes();
  }

  void togglePin(dynamic key) {
    final rawNote = _box.get(key);
    if (rawNote == null) return;
    final note = Map<String, dynamic>.from(rawNote as Map);
    note['isPinned'] = !(note['isPinned'] ?? false);
    _box.put(key, note);
    HapticFeedback.mediumImpact();
    loadNotes();
  }

  // --- INDIVIDUAL NOTE LOCK FEATURE ---
  void toggleNoteLock(dynamic key) {
    final rawNote = _box.get(key);
    if (rawNote == null) return;
    final note = Map<String, dynamic>.from(rawNote as Map);
    note['isLocked'] = !(note['isLocked'] ?? false);
    _box.put(key, note);
    HapticFeedback.mediumImpact();
    loadNotes();
  }

  // --- NOTE REMINDER FEATURE ---
  void setNoteReminder(dynamic key, DateTime? reminderDateTime) {
    final rawNote = _box.get(key);
    if (rawNote == null) return;
    final note = Map<String, dynamic>.from(rawNote as Map);

    if (reminderDateTime == null) {
      note.remove('reminderDateTime');
      if (key is int) {
        NotificationService().cancelReminder(key);
      }
    } else {
      note['reminderDateTime'] = reminderDateTime.toIso8601String();
      if (key is int) {
        final NoteModel noteModel = NoteModel.fromMap(key, note);
        NotificationService().scheduleNoteReminder(
          id: key,
          title: noteModel.title,
          body: noteModel.plainTextSnippet,
          scheduledDate: reminderDateTime,
        );
      }
    }

    _box.put(key, note);
    HapticFeedback.lightImpact();
    loadNotes();
  }

  void moveNoteToFolder(dynamic key, String newFolder) {
    final rawNote = _box.get(key);
    if (rawNote == null) return;
    final note = Map<String, dynamic>.from(rawNote as Map);
    note['folder'] = newFolder;
    _box.put(key, note);
    loadNotes();
  }

  List<Map<String, dynamic>> getNotesByFolder(String folderName) {
    if (folderName == "All") return notes;
    return notes.where((note) => note['folder'] == folderName).toList();
  }

  // --- BACKUP AND RESTORE FEATURE ---
  String exportNotesBackup() {
    final allNotesList = _box.keys.map((key) {
      final item = _box.get(key);
      final Map<String, dynamic> noteMap = Map<String, dynamic>.from(item as Map);
      return noteMap;
    }).toList();

    return BackupService.createJsonBackup(
      notes: allNotesList,
      categories: categories,
    );
  }

  Future<bool> importNotesBackup(String jsonString) async {
    final parsed = BackupService.parseJsonBackup(jsonString);
    if (parsed == null) return false;

    final List<String> newCategories = parsed['categories'] ?? [];
    final List<Map<String, dynamic>> importedNotes = parsed['notes'] ?? [];

    for (var cat in newCategories) {
      if (!_categories.contains(cat)) {
        _categoryBox.add(cat);
      }
    }
    _settingsBox.put('hasInitializedCategories', true);
    loadCategories();

    for (var noteMap in importedNotes) {
      _box.add(noteMap);
    }

    loadNotes();
    return true;
  }
}