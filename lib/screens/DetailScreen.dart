import 'dart:convert';
import 'package:echo_notes/screens/EditNote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../provider_notes.dart';

class DetailScreen extends StatefulWidget {
  final dynamic index;
  final String titleNote, contentNote, timestamp;
  const DetailScreen({
    super.key,
    required this.index,
    required this.titleNote,
    required this.contentNote,
    required this.timestamp
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FlutterTts flutterTts = FlutterTts();
  late QuillController _controller;
  final GlobalKey _menuKey = GlobalKey();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _pageScrollController = ScrollController();

  double _currentSpeed = 0.5;
  bool _isSpeaking = false;
  bool _isPaused = false;

  // Tracking offsets for precise highlighting
  int _lastOffset = 0;
  int _lastEndOffset = 0;    // ✅ Remembers the end of the word
  int _globalOffset = 0;

  @override
  void initState() {
    super.initState();
    _initTtsHandlers();
    _setupQuillController();
  }

  void _initTtsHandlers() {
    flutterTts.setLanguage("en-US");

    flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
    });

    flutterTts.setCompletionHandler(() {
      _resetTtsUI();
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        _isSpeaking = false;
        _isPaused = true;
      });
      // ✅ Keep the word highlighted even while paused
      _controller.updateSelection(
        TextSelection(baseOffset: _lastOffset, extentOffset: _lastEndOffset),
        ChangeSource.local,
      );
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        _isSpeaking = true;
        _isPaused = false;
      });
    });

    flutterTts.setErrorHandler((msg) => _resetTtsUI());

    flutterTts.setCancelHandler(() {
      // Manual stops are handled by _stopTts, so we ignore system cancels
    });

    flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (_isSpeaking) {
        int absoluteStart = _globalOffset + start;
        int absoluteEnd = _globalOffset + end;

        _lastOffset = absoluteStart;
        _lastEndOffset = absoluteEnd; // ✅ Store the end position

        setState(() {
          _controller.updateSelection(
            TextSelection(baseOffset: absoluteStart, extentOffset: absoluteEnd),
            ChangeSource.local,
          );
        });
      }
    });
  }

  void _resetTtsUI() {
    setState(() {
      _isSpeaking = false;
      _isPaused = false;
      _lastOffset = 0;
      _lastEndOffset = 0;
      _globalOffset = 0;
      _controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        ChangeSource.local,
      );
    });
  }

  void _setupQuillController() {
    try {
      final decodedData = jsonDecode(widget.contentNote);
      _controller = QuillController(
        document: Document.fromJson(decodedData),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e) {
      _controller = QuillController(
        document: Document()..insert(0, widget.contentNote),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }
  }

  // --- TTS ACTIONS ---

  void _handleSpeakTap() async {
    String plainText = _controller.document.toPlainText().trim();
    if (plainText.isEmpty) return;

    // Keep the editor focused so the highlight is visible
    _editorFocusNode.requestFocus();

    if (_isSpeaking) {
      await flutterTts.pause();
    } else {
      await flutterTts.setSpeechRate(_currentSpeed);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      if (_isPaused && _lastOffset > 0 && _lastOffset < plainText.length) {
        _globalOffset = _lastOffset;
        String remainingText = plainText.substring(_lastOffset);
        await flutterTts.speak(remainingText);
      } else {
        _globalOffset = 0;
        _lastOffset = 0;
        await flutterTts.speak(plainText);
      }
    }
  }

  void _stopTts() async {
    await flutterTts.stop();
    _resetTtsUI();
  }

  void _showSpeedMenu() async {
    final colorScheme = Theme.of(context).colorScheme;
    final RenderBox renderBox = _menuKey.currentContext?.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final RelativeRect position = RelativeRect.fromLTRB(
        offset.dx, offset.dy + renderBox.size.height, offset.dx + renderBox.size.width, 0);

    final double? selected = await showMenu<double>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      items: [
        _buildSpeedItem(0.25, "0.5x"),
        _buildSpeedItem(0.5, "1.0x (Normal)"),
        _buildSpeedItem(0.75, "1.5x"),
        _buildSpeedItem(1.0, "2.0x (Fast)"),
      ],
    );

    if (selected != null) {
      setState(() => _currentSpeed = selected);
    }
  }

  // --- Utility Logic (Stats/PDF) ---

  void _showStatistics() {
    final String text = _controller.document.toPlainText();
    final int characters = text.length;
    final int words = text.isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final int readTime = (words / 200).ceil();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Note Insights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.text_fields_rounded, "Words", words.toString()),
                _buildStatItem(Icons.numbers_rounded, "Chars", characters.toString()),
                _buildStatItem(Icons.timer_outlined, "Read", "$readTime min"),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final String plainTextContent = _controller.document.toPlainText();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(widget.titleNote, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(widget.timestamp, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 20),
              pw.Text(plainTextContent, style: const pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${widget.titleNote}.pdf',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    bool _showBorder = context.watch<NotesProvider>().showNoteBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => EditNote(index: widget.index, title: widget.titleNote, content: widget.contentNote))
              );
            },
            icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
          ),

          // ✅ PLAY / PAUSE
          IconButton(
            key: _menuKey,
            onPressed: _handleSpeakTap,
            onLongPress: _showSpeedMenu,
            icon: Icon(
              _isSpeaking ? Icons.pause_circle_filled : (_isPaused ? Icons.play_circle_fill : Icons.record_voice_over),
              color: colorScheme.primary,
            ),
          ),

          // ✅ STOP
          if (_isSpeaking || _isPaused)
            IconButton(
              onPressed: _stopTts,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
            ),

          PopupMenuButton<String>(
            color: colorScheme.surface,
            tooltip: "More Options",
            icon: Icon(Icons.more_vert_rounded, color: colorScheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'stats') _showStatistics();
              else if (value == 'pdf') _exportToPdf();
              else if (value == 'border') context.read<NotesProvider>().toggleNoteBorder();
            },
            itemBuilder: (BuildContext context) {
              return [
                // 1. NOTE INSIGHTS
                PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      const Text('Note Insights'),
                    ],
                  ),
                ),

                // 2. EXPORT TO PDF
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      const Text('Export to PDF'),
                    ],
                  ),
                ),

                const PopupMenuDivider(), // Optional: adds a thin line for visual separation

                // 3. TOGGLE BORDER
                PopupMenuItem(
                  value: 'border',
                  child: Row(
                    children: [
                      Icon(
                        _showBorder ? Icons.border_clear : Icons.border_outer,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(_showBorder ? 'Hide Border' : 'Show Border'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _pageScrollController,
        slivers: [
          // 1. TITLE & TIMESTAMP
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: SelectableText(
                    widget.titleNote,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface, letterSpacing: -0.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(widget.timestamp, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. DIVIDER
           SliverToBoxAdapter(
            child: _showBorder ? SizedBox.shrink() : Divider(height: 1, indent: 20, endIndent: 20),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 3. EDITOR AREA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                decoration: _showBorder
                    ? BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                )
                    : null,
                clipBehavior: _showBorder ? Clip.hardEdge : Clip.none,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Ensures the "page" is always at least 60% of the screen height
                    minHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: QuillEditor.basic(
                          controller: _controller,
                          config: QuillEditorConfig(
                            padding: const EdgeInsets.all(10),
                            // ✅ THE FIX: Let the page scroll, not the editor
                            expands: false,
                            scrollable: false,
                            autoFocus: false,
                            showCursor: false,
                            enableInteractiveSelection: true,
                            embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                          ),
                        ),
                      ),
                      // The 25% empty bottom space
                      /*const SizedBox(height: 100),*/
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. BOTTOM BUMPER SPACE
          SliverToBoxAdapter(
            child: SizedBox(height: 50),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<double> _buildSpeedItem(double value, String label) {
    bool isSelected = _currentSpeed == value;
    return PopupMenuItem(
      value: value,
      child: Text(label, style: TextStyle(color: isSelected ? Colors.blue : null, fontWeight: isSelected ? FontWeight.bold : null)),
    );
  }
}