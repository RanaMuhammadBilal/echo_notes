import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:echo_notes/utils/snackbar_utils.dart';

class VoiceNote extends StatefulWidget {
  const VoiceNote({super.key});

  @override
  State<VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<VoiceNote>
    with SingleTickerProviderStateMixin {
  final SpeechToText speechToText = SpeechToText();
  String liveText = '';
  final TextEditingController controller = TextEditingController();
  final DateFormat formattedDate = DateFormat('d MMMM, y, h:mm a');

  bool _isManuallyListening = false;
  bool _speechInitialized = false;

  late AnimationController _waveAnimationController;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _isManuallyListening = false;
    _recordingTimer?.cancel();
    if (speechToText.isListening) {
      speechToText.stop();
    }
    controller.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await speechToText.initialize(
        onStatus: (status) {
          debugPrint("Speech Status: $status");
          if (!mounted) return;
          setState(() {});

          // PERSISTENT CONTINUOUS LISTENING LOOP:
          // Re-trigger listening automatically if Android / STT tries to auto-stop
          if (_isManuallyListening &&
              (status == 'done' || status == 'notListening')) {
            _restartListeningLoop();
          }
        },
        onError: (error) {
          debugPrint("Speech Error: $error");
          if (!mounted) return;
          setState(() {});
          if (_isManuallyListening) {
            _restartListeningLoop();
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Speech init exception: $e");
    }
  }

  void _restartListeningLoop() {
    if (!_isManuallyListening || !mounted) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isManuallyListening && mounted && speechToText.isNotListening) {
        _startListeningService();
      }
    });
  }

  double _soundLevel = 0.0;

  void _onSoundLevelChange(double level) {
    if (!mounted || !_isManuallyListening) return;
    setState(() {
      _soundLevel = level;
    });
  }

  void _startListeningService() async {
    if (!_speechInitialized) {
      await _initSpeech();
    }
    try {
      await speechToText.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: _onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(hours: 1), // Long duration loop
          pauseFor: const Duration(seconds: 60),
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint("Error starting listening service: $e");
    }
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    HapticFeedback.mediumImpact();
    if (_isManuallyListening) {
      // STOP LISTENING MANUALLY
      setState(() {
        _isManuallyListening = false;
      });
      _recordingTimer?.cancel();
      await speechToText.stop();
    } else {
      // START LISTENING MANUALLY
      if (!_speechInitialized) {
        await _initSpeech();
      }
      setState(() {
        _isManuallyListening = true;
        _recordingSeconds = 0;
      });

      _startTimer();
      _startListeningService();
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isManuallyListening && mounted) {
        setState(() {
          _recordingSeconds++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      liveText = result.recognizedWords;
    });

    if (result.finalResult) {
      setState(() {
        if (controller.text.isNotEmpty && !controller.text.endsWith(' ')) {
          controller.text += ' ';
        }
        controller.text += '$liveText ';
        liveText = '';
      });
    }
  }

  void _clearText() {
    HapticFeedback.lightImpact();
    setState(() {
      controller.clear();
      liveText = '';
    });
  }

  void _saveVoiceNote() {
    _isManuallyListening = false;
    _recordingTimer?.cancel();
    speechToText.stop();

    var fullText = controller.text.trim();
    if (fullText.isEmpty && liveText.trim().isNotEmpty) {
      fullText = liveText.trim();
    }

    if (fullText.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Please record or type some text first!',
        icon: Icons.mic_off_rounded,
        isError: true,
      );
      return;
    }

    List<String> words =
        fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    String generatedTitle;
    if (words.isEmpty) {
      generatedTitle = "Voice Note";
    } else if (words.length <= 4) {
      generatedTitle = words.join(" ");
    } else {
      generatedTitle = "${words.take(4).join(" ")}...";
    }

    // Convert plain text into Quill Delta JSON format
    final List<Map<String, dynamic>> deltaOps = [
      {'insert': '$fullText\n'}
    ];
    final String contentJson = jsonEncode(deltaOps);

    context.read<NotesProvider>().addNote(
          generatedTitle,
          contentJson,
          "General",
        );

    HapticFeedback.successNotification();
    AppSnackBar.show(
      context,
      message: 'Voice Note saved successfully!',
      isSuccess: true,
      icon: Icons.check_circle_outline_rounded,
    );
    Navigator.pop(context);
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notesProvider = Provider.of<NotesProvider>(context);
    final wordCount =
        controller.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: notesProvider.enableGlassmorphism
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AppBar(
                    title: const Text(
                      'Voice Dictation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    centerTitle: true,
                    backgroundColor: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(180),
                    elevation: 0,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton.tonal(
                          onPressed: _saveVoiceNote,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 4),
                              Text('Save',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : AppBar(
                title: const Text(
                  'Voice Dictation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.tonal(
                      onPressed: _saveVoiceNote,
                      child: const Row(
                        children: [
                          Icon(Icons.check_rounded, size: 18),
                          SizedBox(width: 4),
                          Text('Save',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status & Timer Header Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isManuallyListening
                      ? Colors.red.withAlpha(20)
                      : colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isManuallyListening
                        ? Colors.red.withAlpha(100)
                        : colorScheme.primary.withAlpha(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isManuallyListening
                            ? Colors.red
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isManuallyListening
                          ? 'Listening... (${_formatDuration(_recordingSeconds)})'
                          : 'Tap Mic to Start Continuous Dictation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _isManuallyListening
                            ? Colors.red
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Waveform Visualizer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AudioWaveformVisualizer(
                isListening: _isManuallyListening,
                animation: _waveAnimationController,
                color: _isManuallyListening
                    ? Colors.red
                    : colorScheme.primary,
                soundLevel: _soundLevel,
                isSynthetic: notesProvider.enableSyntheticWaveform,
              ),
            ),
            const SizedBox(height: 12),

            // Text Editor Box
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withAlpha(70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: colorScheme.primary.withAlpha(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$wordCount WORDS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Spacer(),
                            if (controller.text.isNotEmpty || liveText.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20),
                                tooltip: 'Clear Text',
                                onPressed: _clearText,
                              ),
                          ],
                        ),
                        const Divider(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: controller,
                                  maxLines: null,
                                  style: const TextStyle(
                                      fontSize: 18, height: 1.5),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Your transcribed words will appear here continuously...\n\nYou can also type or edit text directly.',
                                    border: InputBorder.none,
                                  ),
                                ),
                                if (liveText.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$liveText...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Continuous Listening Floating Mic Button Container
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: _toggleListening,
                child: PulsingMicButton(
                  isListening: _isManuallyListening,
                  animation: _waveAnimationController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- AUDIO WAVEFORM VISUALIZER WIDGET ---
class AudioWaveformVisualizer extends StatelessWidget {
  final bool isListening;
  final Animation<double> animation;
  final Color color;
  final double soundLevel;
  final bool isSynthetic;

  const AudioWaveformVisualizer({
    super.key,
    required this.isListening,
    required this.animation,
    required this.color,
    this.soundLevel = 0.0,
    this.isSynthetic = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Normalize sound level from dB (-2..10) to 0.05..1.0 range
        final normalizedVolume =
            ((soundLevel + 2.0) / 12.0).clamp(0.05, 1.0);

        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(24, (index) {
              double height;
              if (isListening) {
                if (isSynthetic) {
                  // Synthetic Mode: Oscillating sine pattern
                  final double seed = math.sin(
                      (animation.value * math.pi * 2) + (index * 0.4));
                  height = 8 + (seed.abs() * 32);
                } else {
                  // Live Volume Mode (Default):
                  // Quiet voice -> lines are small (6px - 10px)
                  // Loud voice -> lines become tall (up to 44px)
                  final double barVariation =
                      0.6 + (math.sin(index * 0.75).abs() * 0.5);
                  height = (6.0 + (normalizedVolume * 38.0 * barVariation))
                      .clamp(6.0, 44.0);
                }
              } else {
                height = 6;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: isListening
                      ? color.withAlpha(160 + ((index % 5) * 20))
                      : color.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// --- PULSING MIC BUTTON WIDGET ---
class PulsingMicButton extends StatelessWidget {
  final bool isListening;
  final Animation<double> animation;

  const PulsingMicButton({
    super.key,
    required this.isListening,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = isListening ? Colors.red : colorScheme.primary;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final scale = isListening ? 1.0 + (animation.value * 0.12) : 1.0;
        final outerGlowRadius =
            isListening ? 20.0 + (animation.value * 15.0) : 8.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Pulsing Aura Ring
            if (isListening)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 96 * scale,
                height: 96 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withAlpha(40),
                ),
              ),
            // Core Glowing Mic Button
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(isListening ? 120 : 60),
                    blurRadius: outerGlowRadius,
                    spreadRadius: isListening ? 4 : 1,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.square_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ],
        );
      },
    );
  }
}