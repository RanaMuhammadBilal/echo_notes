import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:echo_notes/provider_notes.dart';

class VoiceNote extends StatefulWidget {
  const VoiceNote({super.key});

  @override
  State<VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<VoiceNote> {
  final SpeechToText speechToText = SpeechToText();
  String liveText = '';
  String finalText = '';
  final TextEditingController controller = TextEditingController();
  final DateFormat formattedDate = DateFormat('d MMMM, y, h:mm a');

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  @override
  void dispose() {
    if (speechToText.isListening) {
      speechToText.stop();
    }
    controller.dispose();
    super.dispose();
  }

  Future<void> initSpeech() async {
    try {
      await speechToText.initialize(
        onStatus: (status) {
          debugPrint("Speech Status: $status");
          if (mounted) setState(() {});
        },
        onError: (error) {
          debugPrint("Speech Error: $error");
          if (mounted) setState(() {});
        },
      );
    } catch (e) {
      debugPrint("Speech init exception: $e");
    }
  }

  void startListening() async {
    await speechToText.listen(
      onResult: onSpeechResult,
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 30),
      ),
    );
    if (mounted) setState(() {});
  }

  void stopListening() async {
    await speechToText.stop();
    if (mounted) setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      liveText = result.recognizedWords;
    });
    if (result.finalResult) {
      setState(() {
        finalText = liveText;
        if (controller.text.isNotEmpty && !controller.text.endsWith(' ')) {
          controller.text += ' ';
        }
        controller.text += '$finalText ';
        liveText = '';
      });
    }
  }

  void _saveVoiceNote() {
    var fullText = controller.text.trim();
    if (fullText.isEmpty && liveText.trim().isNotEmpty) {
      fullText = liveText.trim();
    }

    if (fullText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record or type some text first!')),
      );
      return;
    }

    List<String> words =
        fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    String generatedTitle;
    if (words.isEmpty) {
      generatedTitle = "Voice Note";
    } else if (words.length <= 3) {
      generatedTitle = words.join(" ");
    } else {
      generatedTitle = "${words.take(3).join(" ")}...";
    }

    // Convert plain text into Quill Delta JSON format
    final List<Map<String, dynamic>> deltaOps = [
      {'insert': fullText},
      {'insert': '\n'}
    ];
    final String contentJson = jsonEncode(deltaOps);

    context.read<NotesProvider>().addNote(
          generatedTitle,
          contentJson,
          formattedDate.format(DateTime.now()),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice Note saved successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic),
            SizedBox(width: 8),
            Text('Voice Note', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _saveVoiceNote,
            icon: const Icon(Icons.check_rounded, size: 28),
            tooltip: 'Save Voice Note',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: controller,
                  maxLines: 12,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    hintText:
                        'Tap mic below to speak, or tap here to edit text manually...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            if (liveText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(100),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  liveText,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          if (await speechToText.hasPermission && speechToText.isNotListening) {
            startListening();
          } else if (speechToText.isListening) {
            stopListening();
          } else {
            await initSpeech();
          }
        },
        child: speechToText.isListening
            ? const Icon(Icons.stop, color: Colors.red, size: 36)
            : const Icon(Icons.mic, size: 36),
      ),
    );
  }
}