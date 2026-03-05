import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotesProvider extends ChangeNotifier {
  final _box = Hive.box('notesBox');
  final _categoryBox = Hive.box('categoryBox');
  final _settingsBox = Hive.box('settings');
  bool _showNoteBorder = true;
  bool get showNoteBorder => _showNoteBorder;

  List<Map<String, dynamic>> _notes = [];
  List<String> _categories = [];

  List<String> get categories => _categories;

  // --- 1. FILTERED MAIN NOTES ---
  // Only returns active notes (not in trash), sorted by Pin status
  List<Map<String, dynamic>> get notes {
    List<Map<String, dynamic>> activeNotes = _notes.where((n) => !(n['isDeleted'] ?? false)).toList();

    activeNotes.sort((a, b) {
      bool aPinned = a['isPinned'] ?? false;
      bool bPinned = b['isPinned'] ?? false;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });
    return activeNotes;
  }

  // --- 2. TRASHED NOTES GETTER ---
  List<Map<String, dynamic>> get trashedNotes {
    return _notes.where((n) => n['isDeleted'] == true).toList();
  }

  NotesProvider() {
    loadNotes();
    loadCategories();
    _loadBorderPreference();
    cleanUpTrash(); // Run 30-day cleanup automatically when app starts
  }

  void loadCategories() {
    if (_categoryBox.isEmpty) {
      _categories = ["General", "Work", "Personal", "College", "Ideas"];
      // Save defaults to Hive so they persist
      for (var cat in _categories) {
        _categoryBox.add(cat);
      }
    } else {
      _categories = _categoryBox.values.cast<String>().toList();
    }
    notifyListeners();
  }

  void addCategory(String name) {
    if (!_categories.contains(name) && name.isNotEmpty) {
      _categoryBox.add(name);
      loadCategories(); // Refresh the list
    }
  }

  void loadNotes() {
    _notes = _box.keys.map((key) {
      final note = _box.get(key);
      final Map<String, dynamic> noteMap = Map<String, dynamic>.from(note as Map);
      return {
        'key': key,
        ...noteMap,
      };
    }).toList();
    notifyListeners();
  }

  void addNote(String title, String content, String timestamp, {String folder = "General"}) {
    _box.add({
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'folder': folder,
      'isPinned': false,
      'isDeleted': false, // Initialize as not deleted
    });
    loadNotes();
  }

  // --- 3. SOFT DELETE (Move to Trash) ---
  void deleteNote(dynamic key) {
    final note = Map<String, dynamic>.from(_box.get(key) as Map);
    note['isDeleted'] = true;
    note['isPinned'] = false; // Unpin when moved to trash
    note['deletedAt'] = DateTime.now().toIso8601String(); // Record exact time of deletion
    _box.put(key, note);
    loadNotes();
  }

  // --- 4. TRASH MANAGEMENT METHODS ---
  void restoreNote(dynamic key) {
    final note = Map<String, dynamic>.from(_box.get(key) as Map);
    note['isDeleted'] = false;
    note.remove('deletedAt'); // Clear the deletion timestamp
    _box.put(key, note);
    loadNotes();
  }

  void permanentlyDeleteNote(dynamic key) {
    _box.delete(key);
    loadNotes();
  }

  void emptyTrash() {
    final keysToDelete = _notes.where((n) => n['isDeleted'] == true).map((n) => n['key']).toList();
    for (var key in keysToDelete) {
      _box.delete(key);
    }
    loadNotes();
  }

  void cleanUpTrash() {
    final keysToDelete = [];
    for (var note in _notes) {
      if (note['isDeleted'] == true && note['deletedAt'] != null) {
        final deletedDate = DateTime.parse(note['deletedAt']);
        // If 30 days or more have passed, mark for deletion
        if (DateTime.now().difference(deletedDate).inDays >= 30) {
          keysToDelete.add(note['key']);
        }
      }
    }
    for (var key in keysToDelete) {
      _box.delete(key);
    }
    if (keysToDelete.isNotEmpty) loadNotes();
  }

  void editNote(dynamic key, String newTitle, String newContent, String timestamp) {
    final oldNote = Map<String, dynamic>.from(_box.get(key) as Map);
    _box.put(key, {
      'title': newTitle,
      'content': newContent,
      'timestamp': timestamp,
      'folder': oldNote['folder'] ?? "General",
      'isPinned': oldNote['isPinned'] ?? false,
      'isDeleted': oldNote['isDeleted'] ?? false, // Preserve trash status if edited
      'deletedAt': oldNote['deletedAt'],          // Preserve delete time
    });
    loadNotes();
  }

  void togglePin(dynamic key) {
    final note = Map<String, dynamic>.from(_box.get(key) as Map);
    note['isPinned'] = !(note['isPinned'] ?? false);
    _box.put(key, note);
    loadNotes();
  }

  void moveNoteToFolder(dynamic key, String newFolder) {
    final note = Map<String, dynamic>.from(_box.get(key) as Map);
    note['folder'] = newFolder;
    _box.put(key, note);
    loadNotes();
  }

  List<Map<String, dynamic>> getNotesByFolder(String folderName) {
    if (folderName == "All") return notes; // uses the filtered active notes getter
    return notes.where((note) => note['folder'] == folderName).toList();
  }

  void deleteCategory(String categoryName) {
    // 1. Move all notes in this category back to "General"
    final Map<dynamic, dynamic> notesMap = _box.toMap();

    notesMap.forEach((key, value) {
      final note = Map<String, dynamic>.from(value as Map);
      if (note['folder'] == categoryName) {
        note['folder'] = "General"; // Reset to default
        _box.put(key, note);
      }
    });

    // 2. Find and delete the category from the category box
    final Map<dynamic, dynamic> categoryMap = _categoryBox.toMap();
    dynamic keyToDelete;

    categoryMap.forEach((key, value) {
      if (value == categoryName) {
        keyToDelete = key;
      }
    });

    if (keyToDelete != null) {
      _categoryBox.delete(keyToDelete);
      loadCategories(); // Refresh folders
      loadNotes();      // Refresh notes to show updated "General" tags
    }
  }
  void _loadBorderPreference() {
    // Fetches the value from settingsBox. Defaults to true if null.
    _showNoteBorder = _settingsBox.get('showNoteBorder', defaultValue: true);
    notifyListeners();
  }

  void toggleNoteBorder() {
    _showNoteBorder = !_showNoteBorder;
    // Save the new value to Hive immediately
    _settingsBox.put('showNoteBorder', _showNoteBorder);
    notifyListeners();
  }



}