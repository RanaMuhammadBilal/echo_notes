import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DetailScreen extends StatelessWidget{

  String titleNote, contentNote, timestamp;
  DetailScreen({required this.titleNote, required this.contentNote, required this.timestamp});
  FlutterTts flutterTts = FlutterTts();
  
  void textToSpeech(String query) async{
    await flutterTts.speak(query);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_rounded),
            SizedBox(width: 10,),
            Text('Note Detail'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            textToSpeech(titleNote + contentNote);
          }, icon: Icon(Icons.record_voice_over))
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
          child: Text(titleNote ,style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(timestamp,style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),),
          ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
          child: Text(contentNote ,style: TextStyle(fontSize: 22),),
        ),
      ],),
    );
  }

}