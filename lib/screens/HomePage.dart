import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:echo_notes/AuthenticationServices.dart';
import 'package:echo_notes/models/note_model.dart';
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

  Future<bool> _authenticateLockedNote(BuildContext context) async {
    final auth = AuthenticationServices();
    bool isSecure = await auth.isDeviceSecure();
    if (!isSecure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Locked Note: Please set a PIN or Fingerprint in Device Settings to view."),
          ),
        );
      }
      return false;
    }
    return await auth.authenticateLocally();
  }

  void _showDeleteCategoryDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            'Removing "$categoryName" will move all notes inside it to "General".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().deleteCategory(categoryName);
              if (selectedFolder == categoryName) {
                setState(() => selectedFolder = "All");
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$categoryName" removed.')));
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (catController.text.isNotEmpty) {
                context
                    .read<NotesProvider>()
                    .addCategory(catController.text.trim());
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<NotesProvider>();
    final List<String> folders = ["All", ...provider.categories];
    final bool isMonochrome = colorScheme.primary == Colors.black;

    final String targetCategory =
        selectedFolder == "All" ? "General" : selectedFolder;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: provider.enableGlassmorphism
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AppBar(
                    leading: isSelectionMode
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _exitSelectionMode)
                        : null,
                    title: Text(
                        isSelectionMode
                            ? '${selectedNoteKeys.length} Selected'
                            : 'Echo Notes',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    centerTitle: true,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    backgroundColor: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(180),
                    actions: _buildAppBarActions(provider),
                  ),
                ),
              )
            : AppBar(
                leading: isSelectionMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _exitSelectionMode)
                    : null,
                title: Text(
                    isSelectionMode
                        ? '${selectedNoteKeys.length} Selected'
                        : 'Echo Notes',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                centerTitle: true,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                actions: _buildAppBarActions(provider),
              ),
      ),
      body: Column(
        children: [
          if (!isSelectionMode)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ...folders.map((folder) {
                    bool isSelected = selectedFolder == folder;
                    final defaultCategories = [
                      "All",
                      "General",
                      "Work",
                      "Personal",
                      "College",
                      "Ideas"
                    ];
                    bool isDeletable = !defaultCategories.contains(folder);

                    final chipWidget = ChoiceChip(
                      label: Text(folder),
                      selected: isSelected,
                      onSelected: (val) =>
                          setState(() => selectedFolder = folder),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      selectedColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : colorScheme.primary.withAlpha(50)),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onLongPress: isDeletable
                            ? () => _showDeleteCategoryDialog(folder)
                            : null,
                        child: provider.enableChipAnimations
                            ? AnimatedScale(
                                scale: isSelected ? 1.05 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: chipWidget,
                              )
                            : chipWidget,
                      ),
                    );
                  }),
                  IconButton.filledTonal(
                    onPressed: _addNewCategoryDialog,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: "New Category",
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, provider, _) {
                List<Map<String, dynamic>> rawNotes =
                    List.from(provider.getNotesByFolder(selectedFolder));

                rawNotes.sort((a, b) {
                  bool aPinned = a['isPinned'] ?? false;
                  bool bPinned = b['isPinned'] ?? false;
                  if (aPinned && !bPinned) return -1;
                  if (!aPinned && bPinned) return 1;

                  final keyA = a['key'];
                  final keyB = b['key'];
                  if (keyA is Comparable && keyB is Comparable) {
                    return keyB.compareTo(keyA);
                  }
                  return 0;
                });

                if (rawNotes.isEmpty) {
                  IconData emptyIcon;
                  String emptyTitle;
                  String emptyDesc;

                  if (selectedFolder == "All") {
                    emptyIcon = Icons.note_add_rounded;
                    emptyTitle = 'No notes yet';
                    emptyDesc =
                        'Capture your thoughts and ideas with the + button below.';
                  } else if (selectedFolder == "Work") {
                    emptyIcon = Icons.business_center_rounded;
                    emptyTitle = 'Work is empty';
                    emptyDesc =
                        'Time to plan your next big project or meeting.';
                  } else if (selectedFolder == "College") {
                    emptyIcon = Icons.school_rounded;
                    emptyTitle = 'No study notes';
                    emptyDesc =
                        'Keep track of your lectures and assignments here.';
                  } else if (selectedFolder == "Personal") {
                    emptyIcon = Icons.favorite_rounded;
                    emptyTitle = 'Personal space';
                    emptyDesc =
                        'A quiet place for your private thoughts and goals.';
                  } else if (selectedFolder == "Ideas") {
                    emptyIcon = Icons.lightbulb_outline_rounded;
                    emptyTitle = 'No ideas yet';
                    emptyDesc =
                        'Don\'t let a great idea slip away. Write it down!';
                  } else {
                    emptyIcon = Icons.folder_open_rounded;
                    emptyTitle = '$selectedFolder is empty';
                    emptyDesc =
                        'Start adding notes to your "$selectedFolder" notebook.';
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                        FilledButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNote(
                                initialCategory: targetCategory,
                              ),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(selectedFolder == "All"
                              ? 'Write a Note'
                              : 'Write in $selectedFolder'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.isGridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    controller: _scrollController,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: rawNotes.length,
                    itemBuilder: (context, index) {
                      final NoteModel note = NoteModel.fromMap(
                          rawNotes[index]['key'], rawNotes[index]);
                      final cardWidget = _buildGridCard(
                          context, note, colorScheme, isMonochrome, provider);

                      if (provider.enableCardAnimations) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(
                              milliseconds: 250 + (index * 40).clamp(0, 350)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Transform.translate(
                            offset: Offset(0, (1 - value) * 16),
                            child: Opacity(opacity: value, child: child),
                          ),
                          child: cardWidget,
                        );
                      }
                      return cardWidget;
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  controller: _scrollController,
                  itemCount: rawNotes.length,
                  itemBuilder: (context, index) {
                    final NoteModel note = NoteModel.fromMap(
                        rawNotes[index]['key'], rawNotes[index]);
                    final cardWidget = _buildListCard(
                        context, note, colorScheme, isMonochrome, provider);

                    if (provider.enableCardAnimations) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(
                            milliseconds: 250 + (index * 40).clamp(0, 350)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, (1 - value) * 16),
                          child: Opacity(opacity: value, child: child),
                        ),
                        child: cardWidget,
                      );
                    }
                    return cardWidget;
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: isSelectionMode
          ? null
          : ExpandableFab(
              key: fabKey,
              type: ExpandableFabType.fan,
              distance: 120,
              children: [
                FloatingActionButton(
                  heroTag: 'btn3',
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Settings()));
                    fabKey.currentState?.close();
                  },
                  child: const Icon(Icons.settings_rounded),
                ),
                FloatingActionButton(
                  heroTag: 'btn1',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddNote(
                          initialCategory: targetCategory,
                        ),
                      ),
                    );
                    fabKey.currentState?.close();
                  },
                  child: const Icon(Icons.add),
                ),
                FloatingActionButton(
                  heroTag: 'btn2',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const VoiceNote()));
                    fabKey.currentState?.close();
                  },
                  child: const Icon(Icons.mic),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildAppBarActions(NotesProvider provider) {
    if (isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
          onPressed: () {
            for (var key in selectedNoteKeys) {
              provider.deleteNote(key);
            }
            _exitSelectionMode();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Moved to Trash')));
          },
        )
      ];
    }

    return [
      IconButton(
        tooltip: provider.isGridView ? 'List View' : 'Grid View',
        icon: Icon(
          provider.isGridView
              ? Icons.view_agenda_outlined
              : Icons.grid_view_rounded,
        ),
        onPressed: () => provider.toggleGridView(),
      ),
      IconButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SearchScreen())),
        icon: const Icon(Icons.search),
        tooltip: 'Search',
      ),
    ];
  }

  // --- RESTORED ORIGINAL LIST CARD WITH LOCKED BLUR & HERO SUPPORT ---
  Widget _buildListCard(
    BuildContext context,
    NoteModel note,
    ColorScheme colorScheme,
    bool isMonochrome,
    NotesProvider provider,
  ) {
    final dynamic noteKey = note.key;
    final bool isSelected = selectedNoteKeys.contains(noteKey);
    final Color selectionColor = isMonochrome
        ? Colors.black.withAlpha(30)
        : colorScheme.primaryContainer;

    Widget titleText = Text(
      note.title,
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (provider.enableHeroTransitions) {
      titleText = Hero(
        tag: 'note_title_${note.key}',
        child: Material(
          color: Colors.transparent,
          child: titleText,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        closedColor:
            isSelected ? selectionColor : colorScheme.surfaceContainerLow,
        closedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        closedElevation: 0,
        openElevation: 0,
        openColor: Theme.of(context).scaffoldBackgroundColor,
        closedBuilder: (context, openContainer) => InkWell(
          onTap: () async {
            if (isSelectionMode) {
              _toggleSelection(noteKey);
              return;
            }
            if (note.isLocked) {
              bool authSuccess = await _authenticateLockedNote(context);
              if (authSuccess) {
                openContainer();
              }
            } else {
              openContainer();
            }
          },
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
                    : (note.isPinned
                        ? colorScheme.primary.withAlpha(150)
                        : colorScheme.primary.withAlpha(25)),
                width: (isSelected || note.isPinned) ? 2 : 1,
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
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Expanded(child: titleText),
                    if (note.isLocked && !isSelectionMode)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.lock_rounded,
                            size: 18, color: Colors.orange),
                      ),
                    if (note.isPinned && !isSelectionMode)
                      Icon(Icons.push_pin_rounded,
                          size: 18, color: colorScheme.primary),
                  ],
                ),
                if (note.isLocked) ...[
                  const SizedBox(height: 12),
                  // GORGEOUS FROSTED BLUR EFFECT FOR LOCKED NOTE DESCRIPTION
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: colorScheme.onSurface.withAlpha(20),
                        child: Text(
                          "This note description is secured and encrypted with biometric lock.",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const SizedBox(height: 28),
                ],
                Row(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      note.folder,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (note.reminderDateTime != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.notifications_active_rounded,
                          size: 14, color: Colors.amber),
                    ],
                    const Spacer(),
                    Icon(Icons.access_time_rounded,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      note.timestamp,
                      style: TextStyle(
                          fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        openBuilder: (context, _) => DetailScreen(
          titleNote: note.title,
          contentNote: note.content,
          timestamp: note.timestamp,
          index: noteKey,
        ),
      ),
    );
  }

  // --- GRID CARD WITH BLUR EFFECT FOR LOCKED NOTES ---
  Widget _buildGridCard(
    BuildContext context,
    NoteModel note,
    ColorScheme colorScheme,
    bool isMonochrome,
    NotesProvider provider,
  ) {
    final dynamic noteKey = note.key;
    final bool isSelected = selectedNoteKeys.contains(noteKey);
    final Color selectionColor = isMonochrome
        ? Colors.black.withAlpha(30)
        : colorScheme.primaryContainer;

    Widget titleText = Text(
      note.title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (provider.enableHeroTransitions) {
      titleText = Hero(
        tag: 'note_title_${note.key}',
        child: Material(
          color: Colors.transparent,
          child: titleText,
        ),
      );
    }

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 500),
      closedColor:
          isSelected ? selectionColor : colorScheme.surfaceContainerLow,
      closedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      closedElevation: 0,
      openElevation: 0,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedBuilder: (context, openContainer) => InkWell(
        onTap: () async {
          if (isSelectionMode) {
            _toggleSelection(noteKey);
            return;
          }
          if (note.isLocked) {
            bool authSuccess = await _authenticateLockedNote(context);
            if (authSuccess) {
              openContainer();
            }
          } else {
            openContainer();
          }
        },
        onLongPress: isSelectionMode
            ? () => _toggleSelection(noteKey)
            : () => _showNoteActions(context, noteKey, note, provider),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isSelected ? selectionColor : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : (note.isPinned
                      ? colorScheme.primary.withAlpha(150)
                      : colorScheme.primary.withAlpha(25)),
              width: (isSelected || note.isPinned) ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 18,
                          ),
                        ),
                      Expanded(child: titleText),
                      if (note.isLocked && !isSelectionMode)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.lock_rounded,
                              size: 15, color: Colors.orange),
                        ),
                      if (note.isPinned && !isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.push_pin_rounded,
                              size: 15, color: colorScheme.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (note.isLocked)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          color: colorScheme.onSurface.withAlpha(20),
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            "Secured locked content text blur",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (note.plainTextSnippet.isNotEmpty)
                    Text(
                      note.plainTextSnippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withAlpha(180),
                        height: 1.3,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: 12, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note.folder,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.reminderDateTime != null)
                        const Icon(Icons.notifications_active_rounded,
                            size: 12, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note.timestamp,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      openBuilder: (context, _) => DetailScreen(
        titleNote: note.title,
        contentNote: note.content,
        timestamp: note.timestamp,
        index: noteKey,
      ),
    );
  }

  void _showNoteActions(BuildContext context, dynamic noteKey, NoteModel note,
      NotesProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              leading: Icon(note.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin),
              title: Text(note.isPinned ? 'Unpin Note' : 'Pin to Top'),
              onTap: () {
                provider.togglePin(noteKey);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                  note.isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: note.isLocked ? Colors.orange : null),
              title: Text(note.isLocked
                  ? 'Unlock Note'
                  : 'Lock Note (Security Required)'),
              onTap: () async {
                Navigator.pop(context);
                final auth = AuthenticationServices();
                bool isSecure = await auth.isDeviceSecure();
                if (!isSecure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please set up a PIN/Biometrics on your device first.')),
                    );
                  }
                  return;
                }
                bool success = await auth.authenticateLocally();
                if (success) {
                  provider.toggleNoteLock(noteKey);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(note.isLocked
                            ? 'Note Unlocked'
                            : 'Note Locked with Security'),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('Move to Folder'),
              onTap: () {
                Navigator.pop(context);
                _showFolderPicker(context, noteKey, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Note'),
              onTap: () async {
                Navigator.pop(context);
                if (note.isLocked) {
                  bool authSuccess = await _authenticateLockedNote(context);
                  if (!authSuccess) return;
                }
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditNote(
                        index: noteKey,
                        title: note.title,
                        content: note.content,
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Move to Trash',
                  style: TextStyle(color: Colors.red)),
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

  void _showFolderPicker(
      BuildContext context, dynamic noteKey, NotesProvider provider) {
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