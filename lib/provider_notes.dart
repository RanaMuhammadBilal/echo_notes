import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotesProvider extends ChangeNotifier{

  final _box = Hive.box('notesBox');
  List<Map> _notes = [];

  List<Map> get notes => _notes;

  NotesProvider(){
    loadNotes();
    notifyListeners();
  }

  void loadNotes() {
    _notes = _box.values.cast<Map>().toList();
    notifyListeners();
  }

  void addNote(String title, String content, String timestamp) {
     _box.add({
      'title' : title,
      'content' : content,
      'timestamp' : timestamp,
    });
    loadNotes();
  }

  void deleteNote (int index){
    _box.deleteAt(index);
    loadNotes();
  }

  void editNote (int index, String newTitle, String newContent, String timestamp){
    _box.putAt(index, {
      'title' : newTitle,
      'content' : newContent,
      'timestamp' : timestamp,
    });
    loadNotes();
  }
}

// import 'package:flutter/cupertino.dart';
// import 'package:hive_flutter/hive_flutter.dart';
//
// class NotesProvider extends ChangeNotifier{
//
//   final _box = Hive.box('notesBox');
//
//   List<Map> getNotes() {
//     return  _box.values.cast<Map>().toList();
//   }
//
//   void addNote(String title, String content) {
//     _box.add({
//       'title' : title,
//       'content' : content,
//     });
//     notifyListeners();
//   }
//
//   void deleteNote (int index){
//     _box.deleteAt(index);
//     notifyListeners();
//
//   }
//
//
// }