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


  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // ... your existing init code ...

    // ✅ Add listener to the editor's FocusNode
    _editorFocusNode.addListener(() {
      if (_editorFocusNode.hasFocus) {
        // Small delay to allow the keyboard to start opening
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToEditor();
        });
      }
    });
  }

// ✅ Helper function to handle the scroll
  void _scrollToEditor() {
    if (_editorScrollController.hasClients) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      _editorScrollController.animateTo(
        keyboardHeight + 100, // keyboard height + some padding
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
    bool _showBorder = context.watch<NotesProvider>().showNoteBorder;

    return Scaffold(
      resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('New Note', style: TextStyle(fontWeight: FontWeight.bold)),
          scrolledUnderElevation: 0,
          // ✅ This prevents the color change/splash effect on scroll
          surfaceTintColor: Colors.transparent,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          actions: [
            IconButton(
              onPressed: () => context.read<NotesProvider>().toggleNoteBorder(),
              icon: Icon(
                context.watch<NotesProvider>().showNoteBorder
                    ? Icons.border_outer
                    : Icons.border_clear,
              ),
              color: colorScheme.primary,
              tooltip: context.watch<NotesProvider>().showNoteBorder
                  ? 'Remove Border'
                  : 'Show Border',
            ),
            IconButton(
              onPressed: _performOCR,
              icon: Icon(Icons.document_scanner_outlined, color: colorScheme.primary),
              tooltip: 'Scan Text from Image',
            ),
            IconButton(
              onPressed: _saveNote,
              icon: Icon(Icons.check, size: 28, color: colorScheme.primary),
              tooltip: 'Save Note',
            ),
          ],
        ),
        // --- THE FIX: CustomScrollView handles complex scrolling perfectly in Release Mode ---
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          controller: _editorScrollController,
          slivers: [
            // 1. TITLE FIELD (Scrolls away)
            SliverToBoxAdapter(
              child: Padding(
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
            ),

            // 2. CATEGORY LIST (Scrolls away)
            SliverToBoxAdapter(
              child: SizedBox(
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
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 3. STICKY TOOLBAR (Remains at top)
            // ✅ This pins the toolbar after it reaches the AppBar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyToolbarDelegate(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor, // Matches background
                  child: Column(
                    children: [
                      QuillSimpleToolbar(
                        controller: _controller,
                        config: QuillSimpleToolbarConfig(
                          embedButtons: FlutterQuillEmbeds.toolbarButtons(
                            imageButtonOptions: const QuillToolbarImageButtonOptions(),
                          ),
                          showFontFamily: true,
                          showFontSize: true,
                          multiRowsDisplay: false,
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
            ),

            // 4. EDITOR AREA (Grows the page)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_editorFocusNode.hasFocus) {
                      _editorFocusNode.requestFocus();
                    }
                  },
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
                        // This ensures the "page" is always at least 70% of the screen height
                        minHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: QuillEditor(
                              focusNode: _editorFocusNode,
                              scrollController: _editorScrollController,
                              controller: _controller,

                              config: QuillEditorConfig(
                                placeholder: 'Start typing...',
                                customStyles: DefaultStyles(
                                  placeHolder: DefaultTextBlockStyle(
                                    const TextStyle(
                                      fontSize: 18, // Adjust size here
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    const HorizontalSpacing(0, 0), // 1. Horizontal spacing
                                    const VerticalSpacing(0, 0),   // 2. Vertical spacing
                                    const VerticalSpacing(0, 0),   // 3. Line spacing
                                    null,                          // 4. Decoration (can be null)
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                expands: false,    // Crucial: Let the widget find its own height
                                scrollable: false, // Page handles the scroll
                                autoFocus: false,
                                embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                              ),
                            ),
                          ),
                          // ✅ THIS IS THE 25% FIX:
                          // We use a LayoutBuilder to check the text height and add 25% of it as extra space
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // We use a basic listener to rebuild when text changes
                              return ListenableBuilder(
                                listenable: _controller,
                                builder: (context, child) {
                                  return const SizedBox(height: 100); // Base padding
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

// 5. BOTTOM SPACE
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),


    );
  }
}
class _StickyToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyToolbarDelegate({required this.child});

  // Adjust these heights if your toolbar looks squashed
  @override
  double get minExtent => 56.0; // Height of the toolbar when pinned
  @override
  double get maxExtent => 56.0; // Height of the toolbar when scrolling

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyToolbarDelegate oldDelegate) => false;
}