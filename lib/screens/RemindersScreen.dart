import 'dart:ui';
import 'package:echo_notes/models/note_model.dart';
import 'package:echo_notes/provider_notes.dart';
import 'package:echo_notes/screens/DetailScreen.dart';
import 'package:echo_notes/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Future<void> _editReminderDateTime(
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
      AppSnackBar.show(
        context,
        message: 'Please select a future date and time.',
        isError: true,
      );
      return;
    }

    provider.setNoteReminder(noteKey, scheduled);
    AppSnackBar.show(
      context,
      message:
          'Reminder updated for ${DateFormat('d MMM y, h:mm a').format(scheduled)}',
      isSuccess: true,
      icon: Icons.notifications_active_rounded,
    );
  }

  void _clearReminder(BuildContext context, dynamic noteKey, String noteTitle) {
    HapticFeedback.mediumImpact();
    context.read<NotesProvider>().setNoteReminder(noteKey, null);
    AppSnackBar.show(
      context,
      message: 'Reminder for "$noteTitle" cleared.',
      icon: Icons.notifications_off_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<NotesProvider>();
    final reminderNotes = provider.reminderNoteModels;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: provider.enableGlassmorphism
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AppBar(
                    title: const Text(
                      'Scheduled Reminders',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    centerTitle: true,
                    backgroundColor: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(180),
                    elevation: 0,
                  ),
                ),
              )
            : AppBar(
                title: const Text(
                  'Scheduled Reminders',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
        ),
      ),
      body: reminderNotes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(70),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer.withAlpha(120),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Active Reminders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can schedule reminders on any note from the note options menu or details screen!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant.withAlpha(180),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: reminderNotes.length,
              itemBuilder: (context, index) {
                final NoteModel note = reminderNotes[index];
                DateTime? reminderDate;
                if (note.reminderDateTime != null) {
                  try {
                    reminderDate = DateTime.parse(note.reminderDateTime!);
                  } catch (_) {}
                }

                final isOverdue = reminderDate != null &&
                    reminderDate.isBefore(DateTime.now());

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isOverdue
                            ? Colors.red.withAlpha(100)
                            : colorScheme.primary.withAlpha(40),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              index: note.key,
                              titleNote: note.title,
                              contentNote: note.content,
                              timestamp: note.timestamp,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer
                                        .withAlpha(120),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    note.folder,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOverdue
                                        ? Colors.red.withAlpha(30)
                                        : Colors.green.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isOverdue ? 'Overdue' : 'Scheduled',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOverdue
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              note.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.alarm_rounded,
                                  size: 16,
                                  color: isOverdue
                                      ? Colors.red
                                      : colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  reminderDate != null
                                      ? DateFormat('d MMMM, y, h:mm a')
                                          .format(reminderDate)
                                      : 'No date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isOverdue
                                        ? Colors.red
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _editReminderDateTime(
                                    context,
                                    note.key,
                                    note.reminderDateTime,
                                  ),
                                  icon: const Icon(Icons.edit_calendar_rounded,
                                      size: 16),
                                  label: const Text('Change'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _clearReminder(
                                      context, note.key, note.title),
                                  icon: const Icon(
                                    Icons.notifications_off_outlined,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: 'Cancel Reminder',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
