import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/notes_repository.dart';
import '../../data/profile_repository.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../../models/profile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pastel_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.client,
    required this.onThemeChanged,
    required this.onSignedOut,
    super.key,
  });

  final SupabaseClient client;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onSignedOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<UserProfile> _profile;
  bool _themeApplied = false;

  @override
  void initState() {
    super.initState();
    _profile = ProfileRepository(widget.client).fetchProfile();
  }

  Future<void> _reload() async {
    final future = ProfileRepository(widget.client).fetchProfile();
    setState(() => _profile = future);
    await future;
  }

  Future<void> _editName(UserProfile profile) async {
    final controller = TextEditingController(text: profile.displayName);
    final avatarController = TextEditingController(
      text: profile.avatarUrl ?? '',
    );
    final details = await showDialog<(String, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit your profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: avatarController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Avatar image URL (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              controller.text.trim(),
              avatarController.text.trim(),
            )),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    avatarController.dispose();
    if (details == null || details.$1.isEmpty) return;
    try {
      await ProfileRepository(widget.client).updateProfile(
        displayName: details.$1,
        avatarUrl: details.$2,
        leaderboardPublic: profile.leaderboardPublic,
        preferences: profile.preferences,
      );
      await _reload();
    } catch (_) {
      if (mounted) _message('Your profile could not be updated.');
    }
  }

  Future<void> _setAppearance(UserProfile profile) async {
    var dark = profile.preferences['darkMode'] == true;
    final value = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {dark},
                  onSelectionChanged: (selection) =>
                      setSheetState(() => dark = selection.first),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, dark),
                    child: const Text('Apply appearance'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (value == null) return;
    try {
      await ProfileRepository(widget.client)
          .updatePreferences({...profile.preferences, 'darkMode': value});
      widget.onThemeChanged(value);
      await _reload();
    } catch (_) {
      if (mounted) _message('Appearance could not be saved to your account.');
    }
  }

  Future<void> _setReminder(UserProfile profile) async {
    var enabled = profile.preferences['dailyReminder'] == true;
    var hour = (profile.preferences['reminderHour'] as num?)?.toInt() ?? 20;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Writing reminder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SwitchListTile.adaptive(
                  title: const Text('Daily reminder preference'),
                  subtitle: const Text(
                    'Stored with your account and synced across devices.',
                  ),
                  value: enabled,
                  onChanged: (value) => setSheetState(() => enabled = value),
                ),
                ListTile(
                  title: const Text('Preferred time'),
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
                  'This saves your preference. Delivery requires a notification provider, which is not configured for this project.',
                  style: TextStyle(color: AppPalette.mutedInk, fontSize: 12),
                ),
                const SizedBox(height: 14),
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
    if (updated == null) return;
    try {
      await ProfileRepository(widget.client).updatePreferences(updated);
      await _reload();
    } catch (_) {
      if (mounted) _message('Reminder preference could not be saved.');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your saved notes will stay safely in your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay here'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.client.auth.signOut();
      widget.onSignedOut();
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _showHelp() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('A little help'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notes and folders sync to your signed-in Supabase account when you save.',
            ),
            SizedBox(height: 12),
            Text(
              'To use another device, install the app and log in with the same account.',
            ),
            SizedBox(height: 12),
            Text(
              'For account or service help, contact the administrator of the My Notes repository.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _openSync() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BackupSyncScreen(client: widget.client),
      ),
    );
  }

  void _openPrivacy(UserProfile profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PrivacySecurityScreen(
          client: widget.client,
          profile: profile,
          onSaved: _reload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.client.auth.currentUser?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<UserProfile>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Settings could not load',
                message: 'Your private profile is unavailable right now.',
                actionLabel: 'Retry',
                onAction: () => setState(
                  () =>
                      _profile = ProfileRepository(widget.client)
                          .fetchProfile(),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = snapshot.data!;
            final dark = profile.preferences['darkMode'] == true;
            if (!_themeApplied) {
              _themeApplied = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) widget.onThemeChanged(dark);
              });
            }
            final reminder = profile.preferences['dailyReminder'] == true;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                20,
                AppSpacing.page,
                26,
              ),
              children: [
                Text(
                  'Your space',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Make My Notes feel like yours.',
                  style: TextStyle(color: AppPalette.mutedInk),
                ),
                const SizedBox(height: 20),
                PastelCard(
                  color: AppPalette.lavender,
                  onTap: () => _editName(profile),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: Colors.white,
                        foregroundColor: AppPalette.lavenderDeep,
                        backgroundImage:
                            profile.avatarUrl == null ||
                                profile.avatarUrl!.isEmpty
                            ? null
                            : NetworkImage(profile.avatarUrl!),
                        onBackgroundImageError:
                            profile.avatarUrl == null ||
                                profile.avatarUrl!.isEmpty
                            ? null
                            : (exception, stackTrace) {},
                        child:
                            profile.avatarUrl == null ||
                                profile.avatarUrl!.isEmpty
                            ? Text(
                                profile.displayName.isEmpty
                                    ? 'M'
                                    : profile.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              email,
                              style: const TextStyle(
                                color: AppPalette.mutedInk,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        color: AppPalette.lavenderDeep,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _GroupLabel('PREFERENCES'),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: dark ? 'Dark mode' : 'Light mode',
                  color: AppPalette.pink,
                  onTap: () => _setAppearance(profile),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: reminder
                      ? 'Reminder preference on'
                      : 'Reminder preference off',
                  color: AppPalette.yellow,
                  onTap: () => _setReminder(profile),
                ),
                const SizedBox(height: 16),
                const _GroupLabel('ACCOUNT'),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy & security',
                  subtitle: profile.leaderboardPublic
                      ? 'Leaderboard profile is public'
                      : 'Private profile',
                  color: AppPalette.mint,
                  onTap: () => _openPrivacy(profile),
                ),
                _SettingsTile(
                  icon: Icons.sync_rounded,
                  title: 'Backup & sync',
                  subtitle: 'Supabase account sync',
                  color: AppPalette.lavender,
                  onTap: _openSync,
                ),
                const SizedBox(height: 16),
                const _GroupLabel('MORE'),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  subtitle: 'Account and sync guidance',
                  color: AppPalette.peach,
                  onTap: _showHelp,
                ),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  subtitle: 'Your notes stay in your account',
                  color: AppPalette.pink,
                  onTap: _logout,
                ),
                const SizedBox(height: 16),
                const Text(
                  'My Notes · your thoughts stay yours',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.mutedInk, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(
      label,
      style: const TextStyle(
        letterSpacing: 1.2,
        fontSize: 11,
        color: AppPalette.mutedInk,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    leading: CircleAvatar(
      backgroundColor: color,
      child: Icon(icon, color: AppPalette.ink, size: 20),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({
    required this.client,
    required this.profile,
    required this.onSaved,
    super.key,
  });

  final SupabaseClient client;
  final UserProfile profile;
  final Future<void> Function() onSaved;

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  late bool _public = widget.profile.leaderboardPublic;
  bool _saving = false;

  Future<void> _toggle(bool value) async {
    setState(() {
      _public = value;
      _saving = true;
    });
    try {
      await ProfileRepository(widget.client).updateProfile(
        displayName: widget.profile.displayName,
        avatarUrl: widget.profile.avatarUrl,
        leaderboardPublic: value,
        preferences: widget.profile.preferences,
      );
      await widget.onSaved();
    } catch (_) {
      if (mounted) setState(() => _public = !value);
      if (mounted) _message('Privacy setting could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = widget.client.auth.currentUser?.email;
    if (email == null) return;
    try {
      await widget.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        _message('If an account exists, a password reset link is on its way.');
      }
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy & security')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        PastelCard(
          color: AppPalette.lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your notes are private',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Row-level security keeps notes and folders accessible only to your signed-in account. The leaderboard shares only your chosen display name, optional avatar, and score.',
                style: TextStyle(height: 1.5, color: AppPalette.mutedInk),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          title: const Text('Join the public leaderboard'),
          subtitle: const Text(
            'Your display name, optional avatar and score become visible. Notes and email remain private.',
          ),
          value: _public,
          onChanged: _saving ? null : _toggle,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.password_outlined),
          title: const Text('Reset password'),
          subtitle: const Text(
            'Send a secure reset link to your account email.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _resetPassword,
        ),
      ],
    ),
  );
}

class BackupSyncScreen extends StatefulWidget {
  const BackupSyncScreen({required this.client, super.key});
  final SupabaseClient client;

  @override
  State<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends State<BackupSyncScreen> {
  late Future<int> _sync;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _sync = _checkSync();
  }

  Future<int> _checkSync() async {
    final notes = await NotesRepository(widget.client).fetchAllNotes();
    _lastChecked = DateTime.now();
    return notes.length;
  }

  Future<void> _refresh() async {
    final future = _checkSync();
    setState(() => _sync = future);
    await future;
  }

  Future<void> _copyBackup() async {
    try {
      final repository = NotesRepository(widget.client);
      final result = await Future.wait<dynamic>([
        repository.fetchAllNotes(),
        repository.fetchFolders(),
      ]);
      final notes = result[0] as List<Note>;
      final folders = result[1] as List<NoteFolder>;
      final backup = <String, dynamic>{
        'formatVersion': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'folders': folders
            .map(
              (folder) => {
                'id': folder.id,
                'name': folder.name,
                'color': folder.color,
                'icon': folder.icon,
              },
            )
            .toList(),
        'notes': notes
            .map(
              (note) => {
                'id': note.id,
                'title': note.title,
                'content': note.content,
                'color': note.color,
                'tags': note.tags,
                'folderId': note.folderId,
                'createdAt': note.createdAt.toIso8601String(),
                'updatedAt': note.updatedAt.toIso8601String(),
              },
            )
            .toList(),
      };
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(backup)),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your JSON backup was copied to the clipboard. Store it securely.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The backup could not be created. Check your connection and try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup & sync')),
    body: FutureBuilder<int>(
      future: _sync,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Sync status unavailable',
            message: 'Sign in and check your connection to Supabase.',
            actionLabel: 'Try again',
            onAction: _refresh,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            PastelCard(
              color: AppPalette.mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.cloud_done_outlined,
                    size: 34,
                    color: AppPalette.lavenderDeep,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your notes are in sync',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.data} notes stored in your private Supabase account.',
                    style: const TextStyle(color: AppPalette.mutedInk),
                  ),
                  if (_lastChecked != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Checked ${TimeOfDay.fromDateTime(_lastChecked!).format(context)}',
                      style: const TextStyle(
                        color: AppPalette.mutedInk,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Notes sync when you save while online. Supabase protects your records with row-level security. Copy a JSON backup below when you want an offline copy; keep it somewhere private.',
              style: TextStyle(height: 1.5, color: AppPalette.mutedInk),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.sync),
              label: const Text('Check sync now'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _copyBackup,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy notes backup'),
            ),
          ],
        );
      },
    ),
  );
}
