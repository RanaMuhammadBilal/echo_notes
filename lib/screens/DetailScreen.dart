import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DetailScreen extends StatefulWidget {
  final String titleNote, contentNote, timestamp;
  const DetailScreen({
    super.key,
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

  double _currentSpeed = 0.5;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _setupQuillController();
    _initTtsHandlers();
  }

  void _initTtsHandlers() {
    flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    flutterTts.setErrorHandler((msg) => setState(() => _isSpeaking = false));
    flutterTts.setCancelHandler(() => setState(() => _isSpeaking = false));
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

  // --- NEW: Statistics Logic ---
  void _showStatistics() {
    final String text = _controller.document.toPlainText();
    final int characters = text.length;
    final int words = text.isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final int readTime = (words / 200).ceil(); // Average reading speed is 200 wpm

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

  void _speak() async {
    String plainText = _controller.document.toPlainText();
    await flutterTts.setSpeechRate(_currentSpeed);
    await flutterTts.speak(plainText);
  }

  void _showSpeedMenu() async {
    final RenderBox renderBox = _menuKey.currentContext?.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final RelativeRect position = RelativeRect.fromLTRB(offset.dx, offset.dy + renderBox.size.height, offset.dx + renderBox.size.width, 0);

    final double? selected = await showMenu<double>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        _buildSpeedItem(0.25, "0.5x"),
        _buildSpeedItem(0.5, "1.0x (Normal)"),
        _buildSpeedItem(0.75, "1.5x"),
        _buildSpeedItem(1.0, "2.0x (Fast)"),
        if (_isSpeaking) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            onTap: () => flutterTts.stop(),
            child: const Row(
              children: [
                Icon(Icons.stop_circle_outlined, color: Colors.red, size: 20),
                SizedBox(width: 10),
                Text("Stop", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ]
      ],
    );

    if (selected != null) {
      setState(() => _currentSpeed = selected);
      flutterTts.stop();
      _speak();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Note Detail', style: TextStyle(fontWeight: FontWeight.bold)),
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // --- NEW: Statistics Icon ---
          IconButton(
            onPressed: _showStatistics,
            icon: Icon(Icons.info_outline_rounded, color: colorScheme.primary),
            tooltip: "Note Insights",
          ),
          IconButton(
            onPressed: _exportToPdf,
            icon: Icon(Icons.picture_as_pdf_outlined, color: colorScheme.primary),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: _menuKey,
                onTap: _speak,
                onLongPress: _showSpeedMenu,
                borderRadius: BorderRadius.circular(50),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(_isSpeaking ? Icons.volume_up_rounded : Icons.record_voice_over, color: colorScheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
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
          const Divider(height: 1, indent: 20, endIndent: 20),
          Expanded(
            child: QuillEditor.basic(
              controller: _controller,
              config: QuillEditorConfig(
                autoFocus: false,
                expands: true,
                padding: const EdgeInsets.all(20),
                showCursor: false,
                enableInteractiveSelection: true,
                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<double> _buildSpeedItem(double value, String label) {
    bool isSelected = _currentSpeed == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(Icons.speed, size: 18, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.primary : null)),
        ],
      ),
    );
  }
}