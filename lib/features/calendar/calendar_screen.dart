import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/notes_repository.dart';
import '../../models/note.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
import '../../widgets/pastel_card.dart';
import '../../widgets/section_heading.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({required this.client, required this.onOpenNote, super.key});

  final SupabaseClient client;
  final ValueChanged<Note> onOpenNote;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selectedDay;
  late Future<List<Note>> _notes;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _month = DateTime.utc(now.year, now.month);
    _selectedDay = DateTime.utc(now.year, now.month, now.day);
    _notes = NotesRepository(widget.client).fetchAllNotes();
  }

  Future<void> _refresh() async {
    final future = NotesRepository(widget.client).fetchAllNotes();
    setState(() => _notes = future);
    await future;
  }

  DateTime _dayKey(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Note>>(
          future: _notes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Calendar is unavailable',
                message: 'Your notes could not be loaded from Supabase.',
                actionLabel: 'Retry',
                onAction: () => setState(() => _notes = NotesRepository(widget.client).fetchAllNotes()),
              );
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final notes = snapshot.data!;
            final activeDays = <DateTime>{};
            for (final note in notes) {
              activeDays.add(_dayKey(note.createdAt.toUtc()));
              activeDays.add(_dayKey(note.updatedAt.toUtc()));
            }
            final selectedNotes = notes.where((note) {
              return _dayKey(note.createdAt.toUtc()) == _selectedDay ||
                  _dayKey(note.updatedAt.toUtc()) == _selectedDay;
            }).toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 18, AppSpacing.page, 28),
                children: [
                  Text('Your calendar', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Little moments, gathered day by day.', style: TextStyle(color: AppPalette.mutedInk)),
                  const SizedBox(height: 20),
                  PastelCard(
                    color: AppPalette.lavender,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Previous month',
                              onPressed: () => setState(() => _month = DateTime.utc(_month.year, _month.month - 1)),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: Text(
                                DateFormat.yMMMM().format(_month),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next month',
                              onPressed: () => setState(() => _month = DateTime.utc(_month.year, _month.month + 1)),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(day, style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12)),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        _monthGrid(activeDays),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.circle, size: 7, color: AppPalette.lavenderDeep),
                            SizedBox(width: 6),
                            Text('A note was written or updated', style: TextStyle(fontSize: 12, color: AppPalette.mutedInk)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeading(DateFormat('EEEE, MMMM d').format(_selectedDay)),
                  const SizedBox(height: 10),
                  if (selectedNotes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: EmptyState(
                        icon: Icons.event_note_outlined,
                        title: 'A quiet day',
                        message: 'No notes were created or updated on this date.',
                      ),
                    )
                  else
                    for (final note in selectedNotes) ...[
                      NoteCard(note: note, onTap: () => widget.onOpenNote(note), onEdit: () => widget.onOpenNote(note)),
                      const SizedBox(height: 9),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _monthGrid(Set<DateTime> activeDays) {
    final firstDay = DateTime.utc(_month.year, _month.month, 1);
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime.utc(_month.year, _month.month + 1, 0).day;
    final cellCount = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cellCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 43,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - startOffset + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
        final date = DateTime.utc(_month.year, _month.month, dayNumber);
        final selected = date == _selectedDay;
        final hasNote = activeDays.contains(date);
        return InkWell(
          onTap: () => setState(() => _selectedDay = date),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: selected ? AppPalette.lavenderDeep : Colors.transparent,
                foregroundColor: selected ? Colors.white : AppPalette.ink,
                child: Text('$dayNumber', style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 2),
              Icon(Icons.circle, size: 5, color: hasNote ? AppPalette.lavenderDeep : Colors.transparent),
            ],
          ),
        );
      },
    );
  }
}
