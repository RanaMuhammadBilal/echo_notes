import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:echo_notes/screens/AddNote.dart';
import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:echo_notes/screens/EditNote.dart';
import 'package:echo_notes/screens/SearchScreen.dart';
import 'package:echo_notes/screens/Settings.dart';
import 'package:echo_notes/screens/VoiceNote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final fabKey = GlobalObjectKey<ExpandableFabState>(1);
  final ScrollController _scrollController = ScrollController();
  String selectedFolder = "All";

  // --- SELECTION STATE ---
  bool isSelectionMode = false;
  Set<dynamic> selectedNoteKeys = {};

  void _toggleSelection(dynamic key) {
    setState(() {
      if (selectedNoteKeys.contains(key)) {
        selectedNoteKeys.remove(key);
        if (selectedNoteKeys.isEmpty) isSelectionMode = false;
      } else {
        selectedNoteKeys.add(key);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedNoteKeys.clear();
    });
  }

  void _showDeleteCategoryDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Removing "$categoryName" will move all notes inside it to "General".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().deleteCategory(categoryName);
              if (selectedFolder == categoryName) setState(() => selectedFolder = "All");
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$categoryName" removed.')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addNewCategoryDialog() {
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Notebook'),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter name (e.g. Gym)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (catController.text.isNotEmpty) {
                context.read<NotesProvider>().addCategory(catController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<NotesProvider>();
    final List<String> folders = ["All", ...provider.categories];
    final bool isMonochrome = colorScheme.primary == Colors.black;

    return Scaffold(
      // --- DYNAMIC APP BAR ---
      appBar: AppBar(
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _exitSelectionMode)
            : null,
        title: Text(isSelectionMode ? '${selectedNoteKeys.length} Selected' : 'Echo Notes',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              onPressed: () {
                for (var key in selectedNoteKeys) {
                  provider.deleteNote(key);
                }
                _exitSelectionMode();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Trash')));
              },
            )
          else
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
              icon: const Icon(Icons.search),
            )
        ],
      ),
      body: Column(
        children: [
          // Folder Chips Row (Hidden in Selection Mode for focus)
          if (!isSelectionMode)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ...folders.map((folder) {
                    bool isSelected = selectedFolder == folder;
                    final defaultCategories = ["All", "General", "Work", "Personal", "College", "Ideas"];
                    bool isDeletable = !defaultCategories.contains(folder);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onLongPress: isDeletable ? () => _showDeleteCategoryDialog(folder) : null,
                        child: ChoiceChip(
                          label: Text(folder),
                          selected: isSelected,
                          onSelected: (val) => setState(() => selectedFolder = folder),
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(color: isSelected ? Colors.transparent : colorScheme.primary.withAlpha(50)),
                        ),
                      ),
                    );
                  }).toList(),
                  IconButton.filledTonal(
                    onPressed: _addNewCategoryDialog,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: "New Category",
                  ),
                ],
              ),
            ),

          // Notes List
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, provider, _) {
                List<Map> notes = List.from(provider.getNotesByFolder(selectedFolder));
                notes.sort((a, b) {
                  bool aPinned = a['isPinned'] ?? false;
                  bool bPinned = b['isPinned'] ?? false;
                  if (aPinned && !bPinned) return -1;
                  if (!aPinned && bPinned) return 1;
                  return (b['key'] as int).compareTo(a['key'] as int);
                });

                if (notes.isEmpty) {
                  // Define relative icon and text based on the folder
                  IconData emptyIcon;
                  String emptyTitle;
                  String emptyDesc;

                  if (selectedFolder == "All") {
                    emptyIcon = Icons.note_add_rounded;
                    emptyTitle = 'No notes yet';
                    emptyDesc = 'Capture your thoughts and ideas with the + button below.';
                  } else if (selectedFolder == "Work") {
                    emptyIcon = Icons.business_center_rounded;
                    emptyTitle = 'Work is empty';
                    emptyDesc = 'Time to plan your next big project or meeting.';
                  } else if (selectedFolder == "College") {
                    emptyIcon = Icons.school_rounded;
                    emptyTitle = 'No study notes';
                    emptyDesc = 'Keep track of your lectures and assignments here.';
                  } else if (selectedFolder == "Personal") {
                    emptyIcon = Icons.favorite_rounded;
                    emptyTitle = 'Personal space';
                    emptyDesc = 'A quiet place for your private thoughts and goals.';
                  } else if (selectedFolder == "Ideas") {
                    emptyIcon = Icons.lightbulb_outline_rounded;
                    emptyTitle = 'No ideas yet';
                    emptyDesc = 'Don\'t let a great idea slip away. Write it down!';
                  } else {
                    // Default for custom folders
                    emptyIcon = Icons.folder_open_rounded;
                    emptyTitle = '$selectedFolder is empty';
                    emptyDesc = 'Start adding notes to your "$selectedFolder" notebook.';
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pulsing-style circular background
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            emptyIcon,
                            size: 80,
                            color: colorScheme.primary.withAlpha(100),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          emptyTitle,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: Text(
                            emptyDesc,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant.withAlpha(160),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Primary action button
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddNote()),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Write a Note'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  controller: _scrollController,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    final dynamic noteKey = note['key'];
                    final bool isPinned = note['isPinned'] ?? false;
                    final bool isSelected = selectedNoteKeys.contains(noteKey);
                    final Color selectionColor = isMonochrome
                        ? Colors.black.withAlpha(30)
                        : colorScheme.primaryContainer;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: OpenContainer(
                        transitionDuration: const Duration(milliseconds: 500),
                        closedColor: isSelected ?  selectionColor : colorScheme.surfaceContainerLow,
                        closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        closedElevation: 0,
                        openElevation: 0,
                        openColor: Theme.of(context).scaffoldBackgroundColor,
                        closedBuilder: (context, openContainer) => InkWell(
                          onTap: isSelectionMode ? () => _toggleSelection(noteKey) : openContainer,
                          onLongPress: isSelectionMode
                              ? () => _toggleSelection(noteKey)
                              : () => _showNoteActions(context, noteKey, note, provider),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected ? selectionColor : colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : (isPinned ? colorScheme.primary.withAlpha(150) : colorScheme.primary.withAlpha(25)),
                                width: (isSelected || isPinned) ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isSelectionMode)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Icon(
                                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        note['title'],
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isPinned && !isSelectionMode) Icon(Icons.push_pin_rounded, size: 18, color: colorScheme.primary),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    Icon(Icons.folder_open_rounded, size: 14, color: colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(note['folder'] ?? "General", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(note['timestamp'], style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        openBuilder: (context, _) => DetailScreen(
                          titleNote: note['title'],
                          contentNote: note['content'],
                          timestamp: note['timestamp'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: isSelectionMode ? null : ExpandableFab(
        key: fabKey,
        type: ExpandableFabType.fan,
        distance: 120,
        children: [
          FloatingActionButton(
            heroTag: 'btn3',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
              fabKey.currentState?.close();
            },
            child: const Icon(Icons.settings_rounded),
          ),
          FloatingActionButton(
            heroTag: 'btn1',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNote()));
              fabKey.currentState?.close();
            },
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: 'btn2',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceNote()));
              fabKey.currentState?.close();
            },
            child: const Icon(Icons.mic),
          ),
        ],
      ),
    );
  }

  void _showNoteActions(BuildContext context, dynamic noteKey, Map note, NotesProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- NEW: SELECT NOTES OPTION ---
            ListTile(
              leading: const Icon(Icons.check_box_outlined),
              title: const Text('Select Notes'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  isSelectionMode = true;
                  selectedNoteKeys.add(noteKey);
                });
              },
            ),
            ListTile(
              leading: Icon(note['isPinned'] == true ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(note['isPinned'] == true ? 'Unpin Note' : 'Pin to Top'),
              onTap: () {
                provider.togglePin(noteKey);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(context);
                _showFolderPicker(context, noteKey, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Note'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EditNote(index: noteKey, title: note['title'], content: note['content']),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Move to Trash', style: TextStyle(color: Colors.red)),
              onTap: () {
                provider.deleteNote(noteKey);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderPicker(BuildContext context, dynamic noteKey, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: provider.categories.map((folder) {
              return ListTile(
                title: Text(folder),
                onTap: () {
                  provider.moveNoteToFolder(noteKey, folder);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}