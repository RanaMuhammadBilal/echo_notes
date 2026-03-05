import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class EditNote extends StatefulWidget {
  final dynamic index; // Using dynamic for Hive Keys
  final String title, content;

  const EditNote({
    super.key,
    required this.index,
    required this.title,
    required this.content
  });

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  late QuillController _controller;
  late TextEditingController _titleController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController(); // Added Controller
  String _selectedCategory = "General";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _editorFocusNode.addListener(() {
      if (_editorFocusNode.hasFocus) {
        // Small delay to allow the keyboard to start opening
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToEditor();
        });
      }
    });

    // Get existing category from Provider
    final provider = context.read<NotesProvider>();
    final noteData = provider.notes.firstWhere((n) => n['key'] == widget.index);
    _selectedCategory = noteData['folder'] ?? "General";

    try {
      final List<dynamic> json = jsonDecode(widget.content);
      _controller = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0)
      );
    } catch (e) {
      _controller = QuillController.basic()..document.insert(0, widget.content);
    }
  }


// ✅ Helper function to handle the scroll
  void _scrollToEditor() {
    if (_editorScrollController.hasClients) {
      _editorScrollController.animateTo(
        150.0, // This value jumps past the Title and Category chips
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateNote() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final contentJson = jsonEncode(_controller.document.toDelta().toJson());
    final timestamp = DateFormat('d MMMM, y, h:mm a').format(DateTime.now());

    // Update the core note and ensure the folder is synced
    context.read<NotesProvider>().editNote(widget.index, title, contentJson, timestamp);
    context.read<NotesProvider>().moveNoteToFolder(widget.index, _selectedCategory);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose(); // Clean up
    super.dispose();
  }


  // Same OCR logic as AddNote for consistency
  Future<void> _performOCR() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
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
      final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFilePath(image.path));
      String scannedText = recognizedText.text.trim();
      if (scannedText.isEmpty) return;

      final index = _controller.selection.baseOffset;
      final safeIndex = index < 0 ? _controller.document.length - 1 : index;
      _controller.document.insert(safeIndex, "\n$scannedText\n");
      _controller.updateSelection(TextSelection.collapsed(offset: safeIndex + scannedText.length + 2), ChangeSource.local);
      setState(() {});
    } finally {
      textRecognizer.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dynamicCategories = context.watch<NotesProvider>().categories;
    bool _showBorder = context.watch<NotesProvider>().showNoteBorder;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Edit Note', style: TextStyle(fontWeight: FontWeight.bold)),
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

          // 2. OCR SCANNER
          IconButton(
            onPressed: _performOCR,
            icon: Icon(Icons.document_scanner_outlined, color: colorScheme.primary),
            tooltip: 'Scan Text from Image', // ✅ Added Tooltip
          ),

          // 3. SAVE BUTTON
          IconButton(
            onPressed: _updateNote,
            icon: Icon(Icons.save_as_rounded, size: 28, color: colorScheme.primary),
            tooltip: 'Save Changes', // ✅ Added Tooltip
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          controller: _editorScrollController, // Entire page scrolls
          slivers: [
            // 1. TITLE FIELD (Scrolls away)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ),

            // 2. CATEGORY SELECTOR (Scrolls away)
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                            color: isSelected ? Colors.transparent : colorScheme.primary.withAlpha(50)
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 3. STICKY TOOLBAR (Remains at top after scrolling up)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyToolbarDelegate(
                child: Container(
                  // Matches your scaffold background to hide text scrolling behind it
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: [
                      QuillSimpleToolbar(
                        controller: _controller,
                        config: const QuillSimpleToolbarConfig(
                            showFontFamily: false,
                            showFontSize: false,
                            multiRowsDisplay: false
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
            ),

            // 4. EDITOR AREA (Grows with text content)
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // This ensures the "page" is always at least 70% of the screen height
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    decoration: _showBorder
                        ? BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                    clipBehavior: _showBorder ? Clip.hardEdge : Clip.none,
                    child: QuillEditor(
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      controller: _controller,
                      config: QuillEditorConfig(
                        padding: const EdgeInsets.all(8),
                        expands: false,    // Editor height is determined by text
                        scrollable: false, // Page handles the scroll
                        autoFocus: false,
                        embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 5. BOTTOM PADDING (Room for keyboard)
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

  @override
  double get minExtent => 56.0; // Standard single-row toolbar height
  @override
  double get maxExtent => 56.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyToolbarDelegate oldDelegate) => false;
}