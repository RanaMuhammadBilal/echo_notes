import 'package:echo_notes/provider_notes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddNote extends StatelessWidget{

  var titleController = TextEditingController();
  var contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes),
            SizedBox(width: 10,),
            Text('Add Note'),
            SizedBox(width: 20,),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            var titleC = titleController.text.toString();
            var contentC = contentController.text.toString();
            DateFormat formattedDate = DateFormat('d MMMM, y, h:mm a');

            if(titleC.isEmpty || contentC.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all the fields!')));
            }else{
              context.read<NotesProvider>().addNote(titleC, contentC, formattedDate.format(DateTime.now()).toString() );
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Note! successfully Saved!')));
              Navigator.pop(context);
            }
          }, icon: Icon(Icons.save))
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
          child: TextField(
            style: TextStyle(fontSize: 24),
            textInputAction: TextInputAction.next,
            controller: titleController,
            decoration: InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,

            ),

          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
          child: TextField(
            style: TextStyle(fontSize: 20),
            controller: contentController,
            maxLines: 16,
            decoration: InputDecoration(
                hintText: 'Type Something...',
                border: InputBorder.none)

          ),
        ),
      ],),
    );
  }

}