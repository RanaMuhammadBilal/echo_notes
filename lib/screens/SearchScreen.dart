import 'package:animations/animations.dart';
import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echo_notes/provider_notes.dart';
import 'EditNote.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<StatefulWidget> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  var controller = TextEditingController();
  String query = "";

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.notes;
    final colorScheme = Theme.of(context).colorScheme;

    final filteredNotes = notes.where((note) {
      final title = note['title'].toLowerCase();
      final content = note['content'].toLowerCase(); // Content search
      final searchLower = query.toLowerCase();
      return title.contains(searchLower) || content.contains(searchLower);
    }).toList();
    // --- START OF FIX: SORT LATEST TO TOP ---
    filteredNotes.sort((a, b) {
      // First, prioritize Pinned notes
      bool aPinned = a['isPinned'] ?? false;
      bool bPinned = b['isPinned'] ?? false;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      // Secondly, sort by Hive Key (Latest = Higher Key)
      return (b['key'] as int).compareTo(a['key'] as int);
    });
    // --- END OF FIX ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Modern Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              controller: controller,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: 'Search by keyword...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    setState(() => query = "");
                  },
                )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Results List
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern subtle icon
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: colorScheme.onSurface.withAlpha(40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    query.isEmpty ? 'Search your notes' : 'No matching notes found',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      query.isEmpty
                          ? 'Type a keyword above to find titles or content quickly.'
                          : 'Try searching for something else or check your spelling.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredNotes.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                // THE FIX: Use Hive Key for search results to avoid editing/deleting the wrong note
                final dynamic noteKey = note['key'];
                final bool isPinned = note['isPinned'] ?? false;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OpenContainer(
                    transitionDuration: const Duration(milliseconds: 500),
                    closedColor: colorScheme.surfaceContainerLow,
                    closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    closedElevation: 0, // NO ELEVATION / NO SHADOW
                    openElevation: 0,
                    openColor: Theme.of(context).scaffoldBackgroundColor,
                    closedBuilder: (context, openContainer) => InkWell(
                      onTap: openContainer,
                      onLongPress: () => _showNoteActions(context, noteKey, note, notesProvider),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isPinned ? colorScheme.primary.withAlpha(150) : colorScheme.primary.withAlpha(25),
                            width: isPinned ? 2 : 1,
                          ),
                          // Shadow removed to match Home Page
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    note['title'],
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPinned) Icon(Icons.push_pin_rounded, size: 18, color: colorScheme.primary),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                // Folder Icon
                                Icon(Icons.folder_open_rounded, size: 14, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  note['folder'] ?? "General",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),

                                const Spacer(),

                                // Time Icon and Timestamp
                                Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  note['timestamp'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    openBuilder: (context, _) => DetailScreen(
                      titleNote: note['title'],
                      contentNote: note['content'],
                      timestamp: note['timestamp'], index: noteKey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Matching Action Sheet from Home Page
  void _showNoteActions(BuildContext context, dynamic noteKey, Map note, NotesProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                setState(() {}); // Refresh search list
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note deleted')));
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
                  setState(() {}); // Refresh UI
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}