import 'package:echo_notes/provider_notes.dart';
import 'package:echo_notes/screens/AddNote.dart';
import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:echo_notes/screens/EditNote.dart';
import 'package:echo_notes/screens/SearchScreen.dart';
import 'package:echo_notes/screens/VoiceNote.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget{

  var fabKey = GlobalObjectKey<ExpandableFabState>(1);
  final ScrollController _scrollController = ScrollController();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Echo Notes', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
          }, icon: Icon(Icons.search))
        ],
      ),
      body: Consumer<NotesProvider>(builder: (context, provider, _){
        List<Map> notes =  provider.notes;
        if (notes.isNotEmpty) {
          /// Jump to top whenever a new note is added
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          });
        }
        return notes.isEmpty ? Center(child: Text('Nothing to Show!'),) : ListView.builder(reverse: true, shrinkWrap: true, controller: _scrollController, itemCount: notes.length ,itemBuilder: (context, index){
          return InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(titleNote: notes[index]['title'], contentNote: notes[index]['content'], timestamp: notes[index]['timestamp'],)));
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Container(
                  height: 120,
                  child: Align(alignment: Alignment.centerLeft ,child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(notes[index]['title'],style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis), maxLines: 2,),
                        Spacer(),
                        Text(notes[index]['timestamp'],style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),),
                      ],
                    ),
                  )),
                ),
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EditNote(index: index, title: notes[index]['title'], content: notes[index]['content'])));
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
                          provider.deleteNote(index);
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
          );
        });
      }),

      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: fabKey,
        type: ExpandableFabType.fan,
        distance: 80,
        children: [
          FloatingActionButton(
            heroTag: 'btn1',
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> AddNote()));
              fabKey.currentState?.close();
          }, child: Icon(Icons.add),),
          FloatingActionButton(
            heroTag: 'btn2',
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> VoiceNote()));
              fabKey.currentState?.close();
            }, child: Icon(Icons.mic),),
        ]
      ),
    );
  }

}