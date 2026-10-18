import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../calendar/calendar_screen.dart';
import '../folders/folders_screen.dart';
import '../home/home_screen.dart';
import '../notes/note_editor_screen.dart';
import '../notes/notes_screen.dart';
import '../ranking/ranking_screen.dart';
import '../settings/settings_screen.dart';
import '../streaks/streaks_screen.dart';
import '../../models/note.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.client,
    required this.onThemeChanged,
    super.key,
  });

  final SupabaseClient client;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _refreshVersion = 0;
  String? _folderId;

  void _refreshData() => setState(() => _refreshVersion++);

  Future<void> _openEditor({
    Note? note,
    String? title,
    String? content,
    String? folderId,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          client: widget.client,
          note: note,
          initialTitle: title,
          initialContent: content,
          initialFolderId: folderId,
          onSaved: _refreshData,
        ),
      ),
    );
    if (mounted) _refreshData();
  }

  void _openFolders() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FoldersScreen(
          client: widget.client,
          onOpenFolder: (folderId) {
            setState(() {
              _folderId = folderId;
              _selectedIndex = 2;
            });
            Navigator.of(context).pop();
          },
          onChanged: _refreshData,
          onCreateNote: (folderId) => _openEditor(folderId: folderId),
        ),
      ),
    );
  }

  void _openStreaks() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StreaksScreen(client: widget.client),
      ),
    );
  }

  void _openNotes({String? folderId}) {
    setState(() {
      _folderId = folderId;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        key: ValueKey('home-$_refreshVersion'),
        client: widget.client,
        onCreateNote: () => _openEditor(),
        onCreateTemplate: (title, content) => _openEditor(title: title, content: content),
        onOpenNotes: () => _openNotes(),
        onOpenFolders: _openFolders,
        onOpenStreaks: _openStreaks,
        onOpenNote: (note) => _openEditor(note: note),
        onOpenProfile: () => setState(() => _selectedIndex = 4),
      ),
      CalendarScreen(
        key: ValueKey('calendar-$_refreshVersion'),
        client: widget.client,
        onOpenNote: (note) => _openEditor(note: note),
      ),
      NotesScreen(
        key: ValueKey('notes-$_refreshVersion-$_folderId'),
        client: widget.client,
        folderId: _folderId,
        onClearFolder: () => setState(() => _folderId = null),
        onOpenFolders: _openFolders,
        onOpenNote: (note) => _openEditor(note: note),
        onCreateNote: () => _openEditor(folderId: _folderId),
        onChanged: _refreshData,
      ),
      RankingScreen(key: ValueKey('ranking-$_refreshVersion'), client: widget.client),
      SettingsScreen(
        key: ValueKey('settings-$_refreshVersion'),
        client: widget.client,
        onThemeChanged: widget.onThemeChanged,
        onSignedOut: _refreshData,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.sticky_note_2_outlined), selectedIcon: Icon(Icons.sticky_note_2), label: 'Notes'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Ranking'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              tooltip: 'Create note',
              onPressed: () => _openEditor(folderId: _folderId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
