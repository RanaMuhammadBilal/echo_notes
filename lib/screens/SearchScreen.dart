import 'package:animations/animations.dart';
import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echo_notes/provider_notes.dart';
import 'EditNote.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  var controller = TextEditingController();
  String query = "";
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.notes;

    final filteredNotes = notes.where((note) {
      final title = note['title'].toLowerCase();
      final timestamp = note['timestamp'].toLowerCase();
      final searchLower = query.toLowerCase();
      return title.contains(searchLower) || timestamp.contains(searchLower);
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search),
            SizedBox(width: 10),
            Text('Search'),
            SizedBox(width: 70),
          ],
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        //reverse: true, // newest notes first
        slivers: [
          // Search bar at the top
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: true,
                      controller: controller,
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                      style: TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                          onPressed: () {
                            setState(() {
                              query = "";
                              controller.clear();
                            });
                            FocusScope.of(context).unfocus();
                          },
                          icon: Icon(Icons.clear),
                        )
                            : null,
                        hintText: 'Search by the Keyword...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            )
          ),

          // Filtered notes
          filteredNotes.isEmpty
              ? SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No matching note found')),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final note = filteredNotes[index];
                final originalIndex = notes.indexOf(note);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6),
                  child: OpenContainer(
                    closedElevation: 0,
                    closedColor: Theme.of(context).cardColor,
                    openColor: Theme.of(context).scaffoldBackgroundColor,
                    closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                    closedBuilder: (_, openContainer) => InkWell(
                      onTap: openContainer,
                      onLongPress: () {
                        // Show edit/delete bottom sheet
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            height: 150,
                            width: double.infinity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditNote(
                                            index: originalIndex,
                                            title: note['title'],
                                            content: note['content'],
                                          ),
                                        ),
                                      ).then((_) {
                                        controller.clear();
                                        setState(() {
                                          query = "";
                                        });
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Icon(Icons.edit),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      notesProvider.deleteNote(originalIndex);
                                      controller.clear();
                                      setState(() {
                                        query = "";
                                      });
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Note Deleted Successfully')),
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        Text(
                                          'Delete',
                                          style:
                                          TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: Container(
                          height: 120,
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                note['title'],
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    overflow: TextOverflow.ellipsis),
                                maxLines: 2,
                              ),
                              Spacer(),
                              Text(
                                note['timestamp'],
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    openBuilder: (_, __) => DetailScreen(
                      titleNote: note['title'],
                      contentNote: note['content'],
                      timestamp: note['timestamp'],
                    ),
                  ),
                );
              },
              childCount: filteredNotes.length,
            ),
          ),
        ],
      ),
    );
  }
}
