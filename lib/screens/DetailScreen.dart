import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DetailScreen extends StatefulWidget{

  String titleNote, contentNote, timestamp;
  DetailScreen({required this.titleNote, required this.contentNote, required this.timestamp});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  FlutterTts flutterTts = FlutterTts();

  void textToSpeech(String query) async{
    await flutterTts.speak(query);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
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
            textToSpeech(widget.contentNote);
          }, icon: Icon(Icons.record_voice_over))
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
          child: Text(widget.titleNote ,style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),),
        ),
        SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(widget.timestamp,style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),),
          ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
          child: Text(widget.contentNote ,style: TextStyle(fontSize: 22),),
        ),
      ],),
    );
  }
}