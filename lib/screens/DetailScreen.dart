import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:echo_notes/models/note_model.dart';

import 'package:echo_notes/screens/EditNote.dart';
import 'package:echo_notes/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:echo_notes/AuthenticationServices.dart';
import 'package:echo_notes/provider_notes.dart';

class _PdfLineOp {
  final String text;
  final Map<String, dynamic>? attributes;
  final Uint8List? imageBytes;

  _PdfLineOp({required this.text, this.attributes, this.imageBytes});
}

class _PdfLine {
  final List<_PdfLineOp> ops = [];
  Map<String, dynamic> lineAttributes = {};
}

class DetailScreen extends StatefulWidget {
  final dynamic index;
  final String titleNote, contentNote, timestamp;
  const DetailScreen({
    super.key,
    required this.index,
    required this.titleNote,
    required this.contentNote,
    required this.timestamp,
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

  int _lastOffset = 0;
  int _lastEndOffset = 0;
  int _globalOffset = 0;

  @override
  void initState() {
    super.initState();
    _initTtsHandlers();
    _setupQuillController(widget.contentNote);
  }

  void _initTtsHandlers() {
    flutterTts.setLanguage("en-US");

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _isPaused = false;
        });
      }
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) _resetTtsUI();
    });

    flutterTts.setPauseHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isPaused = true;
        });
        _controller.updateSelection(
          TextSelection(baseOffset: _lastOffset, extentOffset: _lastEndOffset),
          ChangeSource.local,
        );
      }
    });

    flutterTts.setContinueHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _isPaused = false;
        });
      }
    });

    flutterTts.setErrorHandler((msg) {
      if (mounted) _resetTtsUI();
    });

    flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (_isSpeaking && mounted) {
        int absoluteStart = _globalOffset + start;
        int absoluteEnd = _globalOffset + end;

        _lastOffset = absoluteStart;
        _lastEndOffset = absoluteEnd;

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

  void _setupQuillController(String content) {
    try {
      final decodedData = jsonDecode(content);
      _controller = QuillController(
        document: Document.fromJson(decodedData),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (e) {
      _controller = QuillController(
        document: Document()..insert(0, content),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }
  }

  void _updateQuillDocumentIfChanged(String newContent) {
    try {
      final newDecoded = jsonDecode(newContent);
      final newDoc = Document.fromJson(newDecoded);
      if (_controller.document.toPlainText() != newDoc.toPlainText()) {
        setState(() {
          _controller = QuillController(
            document: newDoc,
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true,
          );
        });
      }
    } catch (_) {
      if (_controller.document.toPlainText() != newContent) {
        setState(() {
          _controller = QuillController(
            document: Document()..insert(0, newContent),
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true,
          );
        });
      }
    }
  }

  void _handleSpeakTap() async {
    String plainText = _controller.document.toPlainText().trim();
    if (plainText.isEmpty) return;

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
    final RenderBox? renderBox =
        _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final RelativeRect position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        0);

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

  void _showStatistics() {
    final String text = _controller.document.toPlainText();
    final int characters = text.length;
    final int words =
        text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final int readTime = (words / 200).ceil();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Note Insights",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    Icons.text_fields_rounded, "Words", words.toString()),
                _buildStatItem(
                    Icons.numbers_rounded, "Chars", characters.toString()),
                _buildStatItem(
                    Icons.timer_outlined, "Read", "$readTime min"),
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
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // --- SET REMINDER DIALOG ---
  Future<void> _pickReminderDateTime(
      BuildContext context, dynamic noteKey, String? existingReminder) async {
    final provider = context.read<NotesProvider>();
    DateTime initial = DateTime.now().add(const Duration(hours: 1));
    if (existingReminder != null) {
      try {
        initial = DateTime.parse(existingReminder);
      } catch (_) {}
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(minutes: 5))
          : initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null || !mounted) return;

    final DateTime scheduled = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduled.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future date and time.')),
      );
      return;
    }

    provider.setNoteReminder(noteKey, scheduled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Reminder set for ${DateFormat('d MMM y, h:mm a').format(scheduled)}'),
      ),
    );
  }

  // --- MARKDOWN EXPORT / SHARE ---
  Future<void> _exportToMarkdown(
      String title, String content, String timestamp, String? folder) async {
    final mdString = BackupService.convertToMarkdown(
      title: title,
      content: content,
      timestamp: timestamp,
      folder: folder,
    );

    await Share.share(
      mdString,
      subject: '$title.md',
    );
  }

  PdfColor? _parsePdfColor(String? hexString) {
    if (hexString == null) return null;
    try {
      String clean = hexString.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return PdfColor.fromInt(int.parse(clean, radix: 16));
    } catch (e) {
      return null;
    }
  }

  Future<void> _exportToPdf(String title, String timestamp, {String? folder}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fonts = await Future.wait([
        PdfGoogleFonts.openSansRegular(),
        PdfGoogleFonts.openSansBold(),
        PdfGoogleFonts.openSansItalic(),
        PdfGoogleFonts.openSansBoldItalic(),
        PdfGoogleFonts.notoColorEmoji(),
      ]);

      final baseFont = fonts[0];
      final boldFont = fonts[1];
      final italicFont = fonts[2];
      final boldItalicFont = fonts[3];
      final emojiFont = fonts[4];

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          italic: italicFont,
          boldItalic: boldItalicFont,
        ),
      );

      final titleStyle =
          pw.TextStyle(font: boldFont, fontFallback: [emojiFont], fontSize: 24);
      final timestampStyle = pw.TextStyle(
          font: baseFont,
          fontFallback: [emojiFont],
          fontSize: 11,
          color: PdfColors.grey700);

      // Parse document into lines with inline ops and line attributes
      List<_PdfLine> docLines = [];
      _PdfLine currentLine = _PdfLine();
      final sanitizeRegex = RegExp(r'[\uFE0F\u200D]');

      for (final op in _controller.document.toDelta().toList()) {
        if (op.data is String) {
          String text = (op.data as String).replaceAll(sanitizeRegex, '');
          final parts = text.split('\n');

          for (int i = 0; i < parts.length; i++) {
            if (parts[i].isNotEmpty) {
              currentLine.ops.add(_PdfLineOp(text: parts[i], attributes: op.attributes));
            }
            if (i < parts.length - 1) {
              if (op.attributes != null) {
                currentLine.lineAttributes.addAll(op.attributes!);
              }
              docLines.add(currentLine);
              currentLine = _PdfLine();
            }
          }
        } else if (op.data is Map && (op.data as Map).containsKey('image')) {
          final String imageSource = (op.data as Map)['image'].toString();
          Uint8List? imageBytes;
          try {
            if (imageSource.startsWith('data:image')) {
              final base64Str = imageSource.split(',').last;
              imageBytes = base64Decode(base64Str);
            } else {
              final file = File(imageSource);
              if (file.existsSync()) {
                imageBytes = file.readAsBytesSync();
              }
            }
          } catch (e) {
            debugPrint("PDF Image load error: $e");
          }
          if (imageBytes != null) {
            currentLine.ops.add(_PdfLineOp(text: '', imageBytes: imageBytes));
          }
        }
      }
      if (currentLine.ops.isNotEmpty || currentLine.lineAttributes.isNotEmpty) {
        docLines.add(currentLine);
      }

      // Convert docLines to PDF widgets
      List<pw.Widget> pdfContent = [];
      int orderedListIndex = 0;

      for (final line in docLines) {
        final lineAttrs = line.lineAttributes;
        final String? listType = lineAttrs['list'] as String?;
        final dynamic rawHeader = lineAttrs['header'];
        final int? headerLevel = rawHeader is int ? rawHeader : null;
        final bool isBlockquote = lineAttrs['blockquote'] == true;
        final bool isCodeBlock = lineAttrs['code-block'] == true;

        if (listType == 'ordered') {
          orderedListIndex++;
        } else {
          orderedListIndex = 0;
        }

        bool hasImage = line.ops.any((op) => op.imageBytes != null);
        if (hasImage) {
          for (final op in line.ops) {
            if (op.imageBytes != null) {
              pdfContent.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12),
                  child: pw.Center(
                    child: pw.SizedBox(
                      height: 250,
                      child: pw.Image(
                        pw.MemoryImage(op.imageBytes!),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            }
          }
          continue;
        }

        List<pw.InlineSpan> spans = [];
        double baseFontSize = 13.0;
        pw.Font defaultFont = baseFont;

        if (headerLevel == 1) {
          baseFontSize = 22.0;
          defaultFont = boldFont;
        } else if (headerLevel == 2) {
          baseFontSize = 18.0;
          defaultFont = boldFont;
        } else if (headerLevel == 3) {
          baseFontSize = 15.0;
          defaultFont = boldFont;
        }

        for (final op in line.ops) {
          if (op.text.isEmpty) continue;

          bool isBold = op.attributes?['bold'] == true || headerLevel != null;
          bool isItalic = op.attributes?['italic'] == true;
          bool isUnderline = op.attributes?['underline'] == true;
          bool isStrike = op.attributes?['strike'] == true;
          PdfColor? color = _parsePdfColor(op.attributes?['color']);
          PdfColor? bg = _parsePdfColor(op.attributes?['background']);

          pw.Font targetFont = defaultFont;
          if (isBold && isItalic) {
            targetFont = boldItalicFont;
          } else if (isBold) {
            targetFont = boldFont;
          } else if (isItalic) {
            targetFont = italicFont;
          }

          pw.TextDecoration? decoration;
          if (isUnderline && isStrike) {
            decoration = pw.TextDecoration.combine(
                [pw.TextDecoration.underline, pw.TextDecoration.lineThrough]);
          } else if (isUnderline) {
            decoration = pw.TextDecoration.underline;
          } else if (isStrike) {
            decoration = pw.TextDecoration.lineThrough;
          }

          spans.add(
            pw.TextSpan(
              text: op.text,
              style: pw.TextStyle(
                font: targetFont,
                fontFallback: [emojiFont],
                fontSize: baseFontSize,
                color: color ?? PdfColors.black,
                background: bg != null ? pw.BoxDecoration(color: bg) : null,
                decoration: decoration,
                lineSpacing: 1.4,
              ),
            ),
          );
        }

        if (spans.isEmpty) {
          pdfContent.add(pw.SizedBox(height: 8));
          continue;
        }

        pw.Widget lineWidget = pw.RichText(
          text: pw.TextSpan(children: spans),
        );

        if (listType != null) {
          pw.Widget prefixWidget;
          if (listType == 'ordered') {
            prefixWidget = pw.Padding(
              padding: const pw.EdgeInsets.only(right: 6),
              child: pw.Text(
                '$orderedListIndex.',
                style: pw.TextStyle(
                  font: boldFont,
                  fontFallback: [emojiFont],
                  fontSize: baseFontSize,
                  color: PdfColors.blue800,
                ),
              ),
            );
          } else if (listType == 'bullet') {
            prefixWidget = pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8, top: 4),
              child: pw.Container(
                width: 5,
                height: 5,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey900,
                  shape: pw.BoxShape.circle,
                ),
              ),
            );
          } else if (listType == 'checked') {
            prefixWidget = pw.Padding(
              padding: const pw.EdgeInsets.only(right: 6),
              child: pw.Text('[✓] ',
                  style: pw.TextStyle(font: boldFont, color: PdfColors.green700)),
            );
          } else {
            prefixWidget = pw.Padding(
              padding: const pw.EdgeInsets.only(right: 6),
              child: pw.Text('[  ] ',
                  style: pw.TextStyle(font: baseFont, color: PdfColors.grey600)),
            );
          }

          lineWidget = pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              prefixWidget,
              pw.Expanded(child: lineWidget),
            ],
          );
        }

        if (isBlockquote) {
          lineWidget = pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.blue500, width: 3),
              ),
              color: PdfColors.blueGrey50,
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const pw.EdgeInsets.only(left: 8, top: 4, bottom: 4),
            child: lineWidget,
          );
        } else if (isCodeBlock) {
          lineWidget = pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            margin: const pw.EdgeInsets.only(left: 4, top: 4, bottom: 4),
            child: lineWidget,
          );
        }

        double bottomPadding =
            headerLevel != null ? 8.0 : (listType != null ? 4.0 : 6.0);
        pdfContent.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: bottomPadding),
            child: lineWidget,
          ),
        );
      }

      String rawTitle = title.replaceAll(RegExp(r'[\uFE0F\u200D]'), '');
      String rawTimestamp = timestamp.replaceAll(RegExp(r'[\uFE0F\u200D]'), '');
      String rawFolder = (folder ?? 'General').replaceAll(RegExp(r'[\uFE0F\u200D]'), '');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(rawTitle, style: titleStyle),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Text(
                      rawFolder,
                      style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.blue800),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(rawTimestamp, style: timestampStyle),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              ...pdfContent,
            ];
          },
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '$title.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error exporting PDF: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    flutterTts.stop();
    _editorFocusNode.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<NotesProvider>();

    // Fetch reactive live note data by key
    final List<Map<String, dynamic>> allNotes =
        List<Map<String, dynamic>>.from([...provider.notes, ...provider.trashedNotes]);
    final Map<String, dynamic> liveNoteMap = allNotes.firstWhere(
      (n) => n['key'] == widget.index,
      orElse: () => <String, dynamic>{
        'title': widget.titleNote,
        'content': widget.contentNote,
        'timestamp': widget.timestamp,
        'folder': 'General',
        'isLocked': false,
      },
    );

    final NoteModel currentNote = NoteModel.fromMap(widget.index, liveNoteMap);
    _updateQuillDocumentIfChanged(currentNote.content);
    bool _showBorder = provider.showNoteBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(currentNote.folder, style: const TextStyle(fontWeight: FontWeight.bold)),
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          // Edit Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditNote(
                    index: widget.index,
                    title: currentNote.title,
                    content: currentNote.content,
                  ),
                ),
              );
            },
            icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
            tooltip: 'Edit Note',
          ),

          // Individual Note Lock Toggle Button
          IconButton(
            onPressed: () async {
              final auth = AuthenticationServices();
              bool isSecure = await auth.isDeviceSecure();
              if (!isSecure) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please set up a PIN/Biometrics on your device first.')),
                  );
                }
                return;
              }
              bool success = await auth.authenticateLocally();
              if (success && mounted) {
                provider.toggleNoteLock(widget.index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(currentNote.isLocked
                        ? 'Note Unlocked'
                        : 'Note Locked with Security'),
                  ),
                );
              }
            },
            icon: Icon(
              currentNote.isLocked
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              color: currentNote.isLocked ? Colors.orange : colorScheme.primary,
            ),
            tooltip: currentNote.isLocked ? 'Unlock Note' : 'Lock Note',
          ),

          // TTS Play/Pause Button
          IconButton(
            key: _menuKey,
            onPressed: _handleSpeakTap,
            onLongPress: _showSpeedMenu,
            icon: Icon(
              _isSpeaking
                  ? Icons.pause_circle_filled
                  : (_isPaused
                      ? Icons.play_circle_fill
                      : Icons.record_voice_over),
              color: colorScheme.primary,
            ),
          ),

          if (_isSpeaking || _isPaused)
            IconButton(
              onPressed: _stopTts,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
            ),

          // More Options Popup Menu
          PopupMenuButton<String>(
            color: colorScheme.surface,
            tooltip: "More Options",
            icon: Icon(Icons.more_vert_rounded, color: colorScheme.primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'stats') {
                _showStatistics();
              } else if (value == 'pdf') {
                _exportToPdf(currentNote.title, currentNote.timestamp,
                    folder: currentNote.folder);
              } else if (value == 'markdown') {
                _exportToMarkdown(currentNote.title, currentNote.content,
                    currentNote.timestamp, currentNote.folder);
              } else if (value == 'reminder') {
                _pickReminderDateTime(
                    context, widget.index, currentNote.reminderDateTime);
              } else if (value == 'border') {
                context.read<NotesProvider>().toggleNoteBorder();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'reminder',
                  child: Row(
                    children: [
                      Icon(Icons.notification_add_outlined,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      Text(currentNote.reminderDateTime != null
                          ? 'Change Reminder'
                          : 'Set Reminder'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      const Text('Note Insights'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'markdown',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      const Text('Share as Markdown'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      const Text('Export to PDF'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
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
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: provider.enableHeroTransitions
                      ? Hero(
                          tag: 'note_title_${widget.index}',
                          child: Material(
                            color: Colors.transparent,
                            child: SelectableText(
                              currentNote.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        )
                      : SelectableText(
                          currentNote.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(currentNote.timestamp,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      if (currentNote.reminderDateTime != null)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.notifications_active_rounded,
                              size: 14, color: Colors.amber),
                          label: Text(
                            DateFormat('d MMM, h:mm a').format(
                              DateTime.parse(currentNote.reminderDateTime!),
                            ),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onDeleted: () {
                            provider.setNoteReminder(widget.index, null);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: _showBorder
                ? const SizedBox.shrink()
                : const Divider(height: 1, indent: 20, endIndent: 20),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                    minHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: QuillEditor.basic(
                          controller: _controller,
                          config: const QuillEditorConfig(
                            padding: EdgeInsets.all(10),
                            expands: false,
                            scrollable: false,
                            autoFocus: false,
                            showCursor: false,
                            enableInteractiveSelection: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
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
      child: Text(label,
          style: TextStyle(
              color: isSelected ? Colors.blue : null,
              fontWeight: isSelected ? FontWeight.bold : null)),
    );
  }
}