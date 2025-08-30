import 'package:echo_notes/screens/HomePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditNote extends StatefulWidget{
  int index;
  String  title, content;
  EditNote({required this.index, required this.title, required this.content});

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  var titleController = TextEditingController();
  var contentController = TextEditingController();
  DateFormat formattedDate = DateFormat('d MMMM, y, h:mm a');


  @override
  void initState() {
    super.initState();
    titleController.text = widget.title;
    contentController.text = widget.content;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_document),
            SizedBox(width: 10,),
            Text('Edit Note'),
            SizedBox(width: 20,),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
              var titleC = titleController.text.toString();
              var contentC = contentController.text.toString();
              if(titleC.isEmpty || contentC.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please fill all the fields!')));
            }else{
              context.read<NotesProvider>().editNote(widget.index, titleC, contentC, formattedDate.format(DateTime.now()).toString());
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Note! Updated Saved!')));
              Navigator.pop(context);

            }
          }, icon: Icon(Icons.save_as))
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