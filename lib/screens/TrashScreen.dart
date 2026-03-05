import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:echo_notes/provider_notes.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  // Track selected keys
  final Set<dynamic> _selectedKeys = {};
  bool _isSelectionMode = false;

  void _toggleSelection(dynamic key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
        if (_selectedKeys.isEmpty) _isSelectionMode = false;
      } else {
        _selectedKeys.add(key);
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<NotesProvider>();
    final trashedNotes = provider.trashedNotes;

    return Scaffold(
      appBar: AppBar(
        // Dynamic Title based on selection
        title: Text(
          _isSelectionMode ? '${_selectedKeys.length} Selected' : 'Recycle Bin',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: _isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _isSelectionMode = false;
            _selectedKeys.clear();
          }),
        )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            // Select All Toggle
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              onPressed: () {
                setState(() {
                  if (_selectedKeys.length == trashedNotes.length) {
                    _selectedKeys.clear();
                    _isSelectionMode = false;
                  } else {
                    _selectedKeys.addAll(trashedNotes.map((n) => n['key']));
                  }
                });
              },
            ),
            // Batch Restore
            IconButton(
              icon: const Icon(Icons.restore_page_rounded, color: Colors.green),
              onPressed: () {
                for (var key in _selectedKeys) {
                  provider.restoreNote(key);
                }
                setState(() {
                  _selectedKeys.clear();
                  _isSelectionMode = false;
                });
              },
            ),
            // Batch Delete
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              onPressed: () => _confirmBatchDelete(context, provider),
            ),
          ] else if (trashedNotes.isNotEmpty)
          // Option to empty whole trash
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              onPressed: () => _confirmEmptyTrash(context, provider),
            ),
        ],
      ),
      body: trashedNotes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 80, color: colorScheme.onSurface.withAlpha(50)),
            const SizedBox(height: 16),
            Text('Trash is empty', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Items are permanently deleted after 30 days',
                style: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(150), fontSize: 12)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: trashedNotes.length,
        itemBuilder: (context, index) {
          final note = trashedNotes[index];
          final dynamic noteKey = note['key'];
          final bool isSelected = _selectedKeys.contains(noteKey);

          // Calculate days left
          int daysLeft = 30;
          if (note['deletedAt'] != null) {
            final deletedDate = DateTime.parse(note['deletedAt']);
            final daysPassed = DateTime.now().difference(deletedDate).inDays;
            daysLeft = 30 - daysPassed;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: InkWell(
              onTap: _isSelectionMode ? () => _toggleSelection(noteKey) : null,
              onLongPress: () => _toggleSelection(noteKey),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer.withAlpha(150)
                      : colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : Colors.red.withAlpha(50),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['title'],
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$daysLeft days left • Originally in ${note['folder'] ?? "General"}',
                            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                    if (!_isSelectionMode) ...[
                      IconButton(
                        onPressed: () => provider.restoreNote(noteKey),
                        icon: const Icon(Icons.restore_rounded, color: Colors.green),
                      ),
                      IconButton(
                        onPressed: () => _confirmPermanentDelete(context, noteKey, provider),
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, dynamic noteKey, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forever?'),
        content: const Text('This note will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.permanentlyDeleteNote(noteKey);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmBatchDelete(BuildContext context, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedKeys.length} notes?'),
        content: const Text('Selected notes will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              for (var key in _selectedKeys) {
                provider.permanentlyDeleteNote(key);
              }
              setState(() {
                _selectedKeys.clear();
                _isSelectionMode = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text('All notes in the trash will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.emptyTrash();
              Navigator.pop(context);
            },
            child: const Text('Empty', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}