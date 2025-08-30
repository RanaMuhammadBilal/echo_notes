import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:echo_notes/provider_notes.dart';

class VoiceNote extends StatefulWidget{
  @override
  State<VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<VoiceNote> {

  SpeechToText speechToText = SpeechToText();
  var liveText = '';
  String finalText = '';
  var controller = TextEditingController();
  DateFormat formattedDate = DateFormat('d MMMM, y, h:mm a');

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    await speechToText.initialize(
      onStatus: (status) {
        debugPrint("Status: $status");
        setState(() {});
      },
      onError: (error) {
        debugPrint("Error: $error");
      },
    );
  }

  void startListening() async {
    await speechToText.listen(onResult: onSpeechResult,pauseFor: Duration(seconds: 30), listenFor: const Duration(minutes: 5),);
    setState(() {});
  }
  void stopListening() async {
    await speechToText.stop();
    setState(() {});

  }

  Future<void> onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      liveText = result.recognizedWords;
    });
    if (result.finalResult) {
      setState(() {
        finalText = liveText;
        controller.text += finalText + ' ';
      });
    }

  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic),
            SizedBox(width: 10,),
            Text('Voice Note'),
            SizedBox(width: 20,),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: (){
            var fullText = controller.text.trim();
            List<String> words = fullText.split(" ");
            var titleC = words.take(3).join(" ") + ' ...';
            var contentC = controller.text.toString();
            if(contentC.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all the fields!')));
            }else{
              context.read<NotesProvider>().addNote(titleC, contentC, formattedDate.format(DateTime.now()).toString());
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Note! successfully Saved!')));
              Navigator.pop(context);
            }
          }, icon: Icon(Icons.save))
        ],
      ),
      body:  Center(
        child: ListView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: controller,
                        maxLines: 16,
                        style: TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Press on mic button to start speaking - click here to edit',
                          border: InputBorder.none
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(textAlign: TextAlign.justify ,liveText, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async{
          if(await speechToText.hasPermission && speechToText.isNotListening){
            startListening();
          }else if (speechToText.isListening){
            stopListening();
          }else{
            initSpeech();
          }
        }, child: speechToText.isNotListening ? Icon(Icons.mic) : Icon(Icons.stop)
      )
    );
  }
}