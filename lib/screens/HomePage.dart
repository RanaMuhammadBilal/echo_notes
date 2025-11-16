import 'package:animations/animations.dart';
import 'package:echo_notes/ThemeProvider.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:echo_notes/screens/AddNote.dart';
import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:echo_notes/screens/EditNote.dart';
import 'package:echo_notes/screens/SearchScreen.dart';
import 'package:echo_notes/screens/Settings.dart';
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
        leading: IconButton(onPressed: (){
          final provider = context.read<ThemeProvider>();
          provider.saveTheme(value: !provider.getThemeValue());
        }, icon: context.watch<ThemeProvider>().getThemeValue() ? Icon(Icons.dark_mode) : Icon(Icons.light_mode)),
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
          return Padding(
            padding: EdgeInsets.all(10),
            child: OpenContainer(
              closedElevation: 0,
              closedColor: Theme.of(context).cardColor,
              openColor: Theme.of(context).scaffoldBackgroundColor,

              closedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            
              closedBuilder: (_, openContainer) => InkWell(
                onTap: openContainer,   // open animation
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      height: 150,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditNote(
                                      index: index,
                                      title: notes[index]['title'],
                                      content: notes[index]['content'],
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(Icons.edit),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: OutlinedButton(
                              onPressed: () {
                                provider.deleteNote(index);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Note Deleted Successfully')),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
            
                child: Card(
                  child: Container(
                    height: 120,
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          notes[index]['title'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 2,
                        ),
                        Spacer(),
                        Text(
                          notes[index]['timestamp'],
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
              openBuilder: (_, __) => DetailScreen(
                titleNote: notes[index]['title'],
                contentNote: notes[index]['content'],
                timestamp: notes[index]['timestamp'],
              ),
            ),
          );

        });
      }),

      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: fabKey,
        type: ExpandableFabType.fan,
        distance: 120,
        children: [
          FloatingActionButton(
            heroTag: 'btn3',
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=> Settings()));
              fabKey.currentState?.close();
            }, child: Icon(Icons.settings_rounded),),
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