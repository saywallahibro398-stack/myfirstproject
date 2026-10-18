import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/notes_repository.dart';
import '../../features/streaks/activity_summary.dart';
import '../../models/note.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pastel_card.dart';
import '../../widgets/section_heading.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({required this.client, super.key});

  final SupabaseClient client;

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen> {
  late Future<_StreakData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_StreakData> _load() async {
    final repository = NotesRepository(widget.client);
    final result = await Future.wait<dynamic>([
      repository.fetchActivityDates(),
      repository.fetchAllNotes(),
    ]);
    return _StreakData(
      ActivitySummary.fromUtcDates(result[0] as Set<DateTime>),
      result[1] as List<Note>,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _data = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your writing journey')),
      body: FutureBuilder<_StreakData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Activity is unavailable',
              message: 'Your writing history could not be loaded.',
              actionLabel: 'Retry',
              onAction: () => setState(() => _data = _load()),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final achievements = _achievements(data);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                28,
              ),
              children: [
                PastelCard(
                  color: AppPalette.peach,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 52,
                        color: Color(0xFFE89863),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data.activity.currentStreak} days',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              'current writing streak',
                              style: TextStyle(color: AppPalette.mutedInk),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${data.activity.longestStreak}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            'longest',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppPalette.mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeading('This week'),
                const SizedBox(height: 10),
                PastelCard(
                  color: AppPalette.lavender,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final labels = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      final active = data.activity.thisWeek[index];
                      return Column(
                        children: [
                          Text(
                            labels[index],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppPalette.mutedInk,
                            ),
                          ),
                          const SizedBox(height: 9),
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: active
                                ? AppPalette.lavenderDeep
                                : Colors.white,
                            child: Icon(
                              active ? Icons.edit_rounded : Icons.remove,
                              size: 15,
                              color: active
                                  ? Colors.white
                                  : AppPalette.mutedInk,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeading('Little milestones'),
                const SizedBox(height: 10),
                for (final item in achievements) ...[
                  _AchievementCard(item: item),
                  const SizedBox(height: 9),
                ],
                const SizedBox(height: 8),
                const Text(
                  'A writing day is counted when you save a note with at least five words. Days are measured in UTC so your streak stays consistent across devices.',
                  style: TextStyle(
                    color: AppPalette.mutedInk,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_Achievement> _achievements(_StreakData data) {
    final activeDays = data.activity.days.length;
    return [
      _Achievement(
        'First Note',
        'A thought saved and kept.',
        Icons.edit_note_rounded,
        data.notes.isNotEmpty,
        data.notes.length,
        1,
        AppPalette.pink,
      ),
      _Achievement(
        'Week Warrior',
        'Write on seven different days.',
        Icons.local_fire_department_rounded,
        data.activity.longestStreak >= 7,
        data.activity.longestStreak,
        7,
        AppPalette.peach,
      ),
      _Achievement(
        'Monthly Star',
        'Keep a 30-day writing streak.',
        Icons.star_rounded,
        data.activity.longestStreak >= 30,
        data.activity.longestStreak,
        30,
        AppPalette.yellow,
      ),
      _Achievement(
        'Note Collector',
        'Save fifty notes to your library.',
        Icons.auto_stories_rounded,
        data.notes.length >= 50,
        data.notes.length,
        50,
        AppPalette.mint,
      ),
      _Achievement(
        'Many moments',
        'Write on thirty different days.',
        Icons.calendar_month_rounded,
        activeDays >= 30,
        activeDays,
        30,
        AppPalette.lavender,
      ),
    ];
  }
}

class _StreakData {
  const _StreakData(this.activity, this.notes);
  final ActivitySummary activity;
  final List<Note> notes;
}

class _Achievement {
  const _Achievement(
    this.title,
    this.description,
    this.icon,
    this.unlocked,
    this.value,
    this.goal,
    this.color,
  );
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final int value;
  final int goal;
  final Color color;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});
  final _Achievement item;

  @override
  Widget build(BuildContext context) => PastelCard(
    color: item.color,
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: .8),
          child: Icon(
            item.unlocked ? item.icon : Icons.lock_outline,
            color: AppPalette.lavenderDeep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppPalette.mutedInk,
                ),
              ),
              const SizedBox(height: 7),
              LinearProgressIndicator(
                value: (item.value / item.goal).clamp(0, 1).toDouble(),
                backgroundColor: Colors.white.withValues(alpha: .7),
                color: AppPalette.lavenderDeep,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          item.unlocked ? 'Done' : '${item.value}/${item.goal}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
