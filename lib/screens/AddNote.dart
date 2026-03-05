import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class AddNote extends StatefulWidget {
  const AddNote({super.key});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  final QuillController _controller = QuillController.basic();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  String _selectedCategory = "General";
  bool _showBorder = true;

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _performOCR() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final RecognizedText recognizedText =
      await textRecognizer.processImage(InputImage.fromFilePath(image.path));
      String scannedText = recognizedText.text.trim();
      if (scannedText.isEmpty) return;

      final index = _controller.selection.baseOffset;
      final safeIndex = index < 0 ? _controller.document.length - 1 : index;
      _controller.document.insert(safeIndex, "\n$scannedText\n");
      _controller.updateSelection(
          TextSelection.collapsed(offset: safeIndex + scannedText.length + 2),
          ChangeSource.local);
      setState(() {});
    } finally {
      textRecognizer.close();
    }
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title for your note'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final contentJson = jsonEncode(_controller.document.toDelta().toJson());
    final timestamp = DateFormat('d MMMM, y, h:mm a').format(DateTime.now());

    context
        .read<NotesProvider>()
        .addNote(title, contentJson, timestamp, folder: _selectedCategory);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dynamicCategories = context.watch<NotesProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showBorder = !_showBorder),
            icon: Icon(_showBorder ? Icons.border_clear : Icons.border_outer),
            color: colorScheme.primary,
          ),
          IconButton(
            onPressed: _performOCR,
            icon: Icon(Icons.document_scanner_outlined, color: colorScheme.primary),
          ),
          IconButton(
            onPressed: _saveNote,
            icon: Icon(Icons.check, size: 28, color: colorScheme.primary),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // --- TITLE FIELD ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(100)),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _editorFocusNode.requestFocus(),
                      ),
                    ),

                    // --- CATEGORY LIST ---
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: dynamicCategories.length,
                        itemBuilder: (context, index) {
                          final category = dynamicCategories[index];
                          bool isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (val) => setState(() => _selectedCategory = category),
                              selectedColor: colorScheme.primary,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              labelStyle: TextStyle(
                                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // --- TOOLBAR ---
                    QuillSimpleToolbar(
                      controller: _controller,
                      config: QuillSimpleToolbarConfig(
                        embedButtons: FlutterQuillEmbeds.toolbarButtons(
                          imageButtonOptions: const QuillToolbarImageButtonOptions(),
                          videoButtonOptions: null,
                        ),
                        showFontFamily: true,
                        showFontSize: true,
                        multiRowsDisplay: false,
                      ),
                    ),

                    const Divider(height: 1),

                    // --- EDITOR AREA (FILLS REST OF SCREEN) ---
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          width: double.infinity,
                          decoration: _showBorder
                              ? BoxDecoration(
                            color: Colors.white,
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
                          padding: const EdgeInsets.all(10),
                          child: QuillEditor(
                            focusNode: _editorFocusNode,
                            scrollController: _editorScrollController,
                            controller: _controller,
                            config: QuillEditorConfig(
                              placeholder: 'Start typing...',
                                customStyles: DefaultStyles(
                                  placeHolder: DefaultTextBlockStyle(
                                    TextStyle(
                                      fontSize: 18, // Set your font size here
                                      color: Colors.grey.withAlpha(150),
                                    ),
                                    const HorizontalSpacing(0, 0), // Argument 2: Horizontal spacing
                                    const VerticalSpacing(0, 0),   // Argument 3: Vertical spacing
                                    const VerticalSpacing(0, 0),   // Argument 4: Line spacing
                                    null,

                                  ),
                                ),
                              padding: const EdgeInsets.all(8),
                              expands: false, // Grow with text
                              scrollable: false, // Let parent handle scrolling
                              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}