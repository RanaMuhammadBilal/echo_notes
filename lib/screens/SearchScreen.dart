import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echo_notes/provider_notes.dart';

import 'EditNote.dart';

class SearchScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>{

  @override
  void initState() {
    super.initState();
  }

  var controller = TextEditingController();
  String query = "";



  @override
  Widget build(BuildContext context) {

    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.notes;

    final filteredNotes = notes.where((note) {
      final title = note['title'].toLowerCase();
      final content = note['timestamp'].toLowerCase();
      final searchLower = query.toLowerCase();
      return title.contains(searchLower) || content.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search),
            SizedBox(width: 10,),
            Text('Search'),
            SizedBox(width: 40,),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<NotesProvider>(builder: (context, provider, _){
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4, right: 12, left: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: true,
                      onChanged: (value){
                        setState(() {
                          query = value;
                        });
                      },
                      controller: controller,
                      style: TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: query.isNotEmpty ? IconButton(onPressed: (){
                          setState(() {
                            query = "";
                            controller.clear();
                          });
                        }, icon: Icon(Icons.clear)) : null,
                        hintText: 'Search by the Keyword...',
                        hintStyle: TextStyle(fontSize: 20,),
                        border: InputBorder.none,
                      ),

                    ),
                  ),
                ),
              ),
              SizedBox(height: 20,),
              SizedBox(
                child: filteredNotes.isEmpty ? Center(child: Text('No matching note found'),) : ListView.builder(reverse: true, shrinkWrap: true ,itemCount: filteredNotes.length ,itemBuilder: (Context, index){
                  final note = filteredNotes[index];
                  final originalIndex = notes.indexOf(note);
                  return Container(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=> DetailScreen(titleNote: note['title'], contentNote: note['content'], timestamp: note['timestamp'])));
                            },
                            child: Card(
                              child: Container(
                                height: 120,
                                child: Align(alignment: Alignment.centerLeft ,child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(note['title'],style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis), maxLines: 2,),
                                      Spacer(),
                                      Text(note['timestamp'],style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),),
                                    ],
                                  ),
                                )),
                              ),
                            ),
                            onLongPress: (){
                              showModalBottomSheet(context: context, builder: (context) => Container(
                                height: 150,
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: SizedBox(
                                        width: 140,
                                        child: OutlinedButton(onPressed: (){
                                          Navigator.pop(context);
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditNote(index: originalIndex, title: note['title'], content: note['content']))).then((value){
                                            controller.clear();
                                            setState(() {
                                              query = "";   // reset search
                                            });
                                          });
                                        }, child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Icon(Icons.edit),
                                            Text('Edit')
                                          ],)),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: SizedBox(
                                        width: 140,
                                        child: OutlinedButton(onPressed: (){
                                          provider.deleteNote(originalIndex);
                                          controller.clear();
                                          setState(() {
                                            query = "";   // reset search
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Note Deleted Successfully')));
                                        }, child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Icon(Icons.delete, color: Colors.red,),
                                            Text('Delete', style: TextStyle(color: Colors.red),)
                                          ],)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              );
                            },
                          ),
                        ),
                      ),
                
                  );
                }),
              ),
            ],
          );
        }
      )
    );
  }

}