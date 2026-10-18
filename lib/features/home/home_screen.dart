import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/notes_repository.dart';
import '../../data/profile_repository.dart';
import '../../features/streaks/activity_summary.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../../models/profile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
import '../../widgets/pastel_card.dart';
import '../../widgets/section_heading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.client,
    required this.onThemeChanged,
    required this.onCreateNote,
    required this.onCreateTemplate,
    required this.onOpenNotes,
    required this.onOpenFolders,
    required this.onOpenStreaks,
    required this.onOpenNote,
    required this.onOpenProfile,
    super.key,
  });

  final SupabaseClient client;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onCreateNote;
  final void Function(String title, String content) onCreateTemplate;
  final VoidCallback onOpenNotes;
  final VoidCallback onOpenFolders;
  final VoidCallback onOpenStreaks;
  final ValueChanged<Note> onOpenNote;
  final VoidCallback onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeData {
  const _HomeData(this.profile, this.notes, this.folders, this.activity);
  final UserProfile profile;
  final List<Note> notes;
  final List<NoteFolder> folders;
  final ActivitySummary activity;
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _data;
  bool _appearanceApplied = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_HomeData> _load() async {
    final profiles = ProfileRepository(widget.client);
    final notes = NotesRepository(widget.client);
    final result = await Future.wait<dynamic>([
      profiles.fetchProfile(),
      notes.fetchNotes(limit: 6),
      notes.fetchFolders(),
      notes.fetchActivityDates(),
    ]);
    final profile = result[0] as UserProfile;
    if (!_appearanceApplied) {
      _appearanceApplied = true;
      widget.onThemeChanged(profile.preferences['darkMode'] == true);
    }
    return _HomeData(
      profile,
      result[1] as List<Note>,
      result[2] as List<NoteFolder>,
      ActivitySummary.fromUtcDates(result[3] as Set<DateTime>),
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _data = future);
    await future;
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text(
          '“${note.displayTitle}” will be removed from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await NotesRepository(widget.client).deleteNote(note.id);
      await _refresh();
    } catch (_) {
      if (mounted) _message('The note could not be deleted. Try again.');
    }
  }

  Future<void> _showTemplates() async {
    const templates = <(String, String, String)>[
      (
        'Daily reflection',
        'A little check-in',
        'Today I feel...\n\nOne good thing that happened...\n\nTomorrow I want to...',
      ),
      (
        'Meeting notes',
        'Meeting notes',
        'Date: \nAttendees: \n\nTopics\n- \n\nDecisions\n- \n\nNext steps\n- ',
      ),
      (
        'Study outline',
        'Study notes',
        'Topic: \n\nKey ideas\n- \n\nQuestions to revisit\n- \n\nSummary\n',
      ),
    ];
    final selected = await showModalBottomSheet<(String, String, String)>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            Text(
              'Start with a template',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final template in templates)
              ListTile(
                leading: const Icon(
                  Icons.notes_rounded,
                  color: AppPalette.lavenderDeep,
                ),
                title: Text(template.$1),
                subtitle: Text(template.$2),
                onTap: () => Navigator.pop(context, template),
              ),
          ],
        ),
      ),
    );
    if (selected != null) widget.onCreateTemplate(selected.$2, selected.$3);
  }

  Future<void> _showReminderSettings(UserProfile profile) async {
    var enabled = profile.preferences['dailyReminder'] == true;
    var hour = (profile.preferences['reminderHour'] as num?)?.toInt() ?? 20;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A gentle reminder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily writing reminder'),
                  subtitle: const Text('Save this preference to your account.'),
                  value: enabled,
                  onChanged: (value) => setSheetState(() => enabled = value),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Preferred reminder time'),
                  subtitle: Text(
                    TimeOfDay(hour: hour, minute: 0).format(context),
                  ),
                  trailing: const Icon(Icons.schedule_outlined),
                  onTap: enabled
                      ? () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: hour, minute: 0),
                          );
                          if (time != null) {
                            setSheetState(() => hour = time.hour);
                          }
                        }
                      : null,
                ),
                const Text(
                  'This preference syncs to your account. Notification delivery is not configured for this app.',
                  style: TextStyle(color: AppPalette.mutedInk, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, {
                      ...profile.preferences,
                      'dailyReminder': enabled,
                      'reminderHour': hour,
                    }),
                    child: const Text('Save preference'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (updated == null || !mounted) return;
    try {
      await ProfileRepository(widget.client).updatePreferences(updated);
      await _refresh();
      if (mounted) _message('Reminder preference saved to your account.');
    } catch (_) {
      _message('Could not save the reminder preference. Try again.');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Your notes could not load',
                message:
                    'Check your connection and Supabase setup, then try again.',
                actionLabel: 'Try again',
                onAction: () => setState(() => _data = _load()),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      14,
                      AppSpacing.page,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(child: _header(data.profile)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      22,
                      AppSpacing.page,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _streakCard(data.activity),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      24,
                      AppSpacing.page,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _quickActions(data.profile),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      26,
                      AppSpacing.page,
                      8,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeading(
                        'Recent notes',
                        action: 'See all',
                        onAction: widget.onOpenNotes,
                      ),
                    ),
                  ),
                  if (data.notes.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: 'A page just for you',
                        message: 'Your first thought can be the start of something lovely.',
                        actionLabel: 'Write a note',
                        onAction: widget.onCreateNote,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        0,
                        AppSpacing.page,
                        26,
                      ),
                      sliver: SliverList.separated(
                        itemCount: data.notes.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final note = data.notes[index];
                          return NoteCard(
                            note: note,
                            folderName: _folderName(
                              data.folders,
                              note.folderId,
                            ),
                            onTap: () => widget.onOpenNote(note),
                            onEdit: () => widget.onOpenNote(note),
                            onDelete: () => _deleteNote(note),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(UserProfile profile) {
    final firstName = profile.displayName.trim().split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A little space for you',
                style: TextStyle(color: AppPalette.mutedInk),
              ),
              const SizedBox(height: 4),
              Text(
                'Hello, $firstName',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Search notes',
          onPressed: widget.onOpenNotes,
          icon: const Icon(Icons.search_rounded),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: widget.onOpenProfile,
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            backgroundColor: AppPalette.lavender,
            foregroundColor: AppPalette.lavenderDeep,
            backgroundImage:
                profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? null
                : NetworkImage(profile.avatarUrl!),
            onBackgroundImageError:
                profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? null
                : (exception, stackTrace) {},
            child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? Text(firstName.isEmpty ? 'M' : firstName[0].toUpperCase())
                : null,
          ),
        ),
      ],
    );
  }

  Widget _streakCard(ActivitySummary activity) {
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return PastelCard(
      color: AppPalette.lavender,
      onTap: widget.onOpenStreaks,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFE89863),
                size: 30,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${activity.currentStreak} day streak',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${activity.activeDaysThisWeek} days written this week',
                      style: const TextStyle(color: AppPalette.mutedInk),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppPalette.mutedInk),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final active = activity.thisWeek[index];
              return Column(
                children: [
                  Text(
                    weekdayLabels[index],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPalette.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: active
                        ? AppPalette.lavenderDeep
                        : Colors.white.withValues(alpha: .75),
                    child: Icon(
                      active ? Icons.check_rounded : Icons.circle_outlined,
                      size: 13,
                      color: active ? Colors.white : AppPalette.mutedInk,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Your little shortcuts'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _QuickAction(
              icon: Icons.add_rounded,
              label: 'New note',
              color: AppPalette.pink,
              onTap: widget.onCreateNote,
            ),
            _QuickAction(
              icon: Icons.notifications_none_rounded,
              label: 'Reminders',
              color: AppPalette.yellow,
              onTap: () => _showReminderSettings(profile),
            ),
            _QuickAction(
              icon: Icons.folder_open_rounded,
              label: 'Folders',
              color: AppPalette.mint,
              onTap: widget.onOpenFolders,
            ),
            _QuickAction(
              icon: Icons.auto_awesome_outlined,
              label: 'Templates',
              color: AppPalette.peach,
              onTap: _showTemplates,
            ),
          ],
        ),
      ],
    );
  }

  String? _folderName(List<NoteFolder> folders, String? id) {
    for (final folder in folders) {
      if (folder.id == id) return folder.name;
    }
    return null;
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppPalette.ink),
      label: Text(label),
      backgroundColor: color,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      onPressed: onTap,
    );
  }
}
