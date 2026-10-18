import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/notes_repository.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pastel_card.dart';
import '../../widgets/section_heading.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({
    required this.client,
    required this.onOpenFolder,
    required this.onChanged,
    required this.onCreateNote,
    super.key,
  });

  final SupabaseClient client;
  final ValueChanged<String> onOpenFolder;
  final VoidCallback onChanged;
  final ValueChanged<String> onCreateNote;

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  late Future<_FolderData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_FolderData> _load() async {
    final repository = NotesRepository(widget.client);
    final result = await Future.wait<dynamic>([
      repository.fetchFolders(),
      repository.fetchAllNotes(),
    ]);
    return _FolderData(result[0] as List<NoteFolder>, result[1] as List<Note>);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _data = future);
    await future;
  }

  Future<void> _editFolder({NoteFolder? folder}) async {
    final nameController = TextEditingController(text: folder?.name ?? '');
    var color = folder?.color ?? AppPalette.toHex(AppPalette.lavender);
    var icon = folder?.icon ?? 'folder';
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(folder == null ? 'New folder' : 'Edit folder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Folder name'),
                ),
                const SizedBox(height: 12),
                const Text('Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: AppPalette.noteColors.map((value) {
                    final hex = AppPalette.toHex(value);
                    return InkWell(
                      onTap: () => setDialogState(() => color = hex),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: value,
                        child: color == hex
                            ? const Icon(Icons.check, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: icon,
                  decoration: const InputDecoration(labelText: 'Folder icon'),
                  items: const [
                    DropdownMenuItem(value: 'folder', child: Text('Folder')),
                    DropdownMenuItem(value: 'school', child: Text('Study')),
                    DropdownMenuItem(
                      value: 'favorite',
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem(value: 'work', child: Text('Work')),
                    DropdownMenuItem(value: 'lightbulb', child: Text('Ideas')),
                    DropdownMenuItem(value: 'more_horiz', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => icon = value ?? 'folder'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context, (
                  nameController.text.trim(),
                  color,
                  icon,
                ));
              },
              child: const Text('Save folder'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result == null) return;
    try {
      await NotesRepository(widget.client).saveFolder(
        id: folder?.id,
        name: result.$1,
        color: result.$2,
        icon: result.$3,
      );
      await _refresh();
      widget.onChanged();
    } on PostgrestException catch (error) {
      if (mounted) {
        _message(
          error.code == '23505'
              ? 'A folder with that name already exists.'
              : error.message,
        );
      }
    } catch (_) {
      if (mounted) _message('The folder could not be saved.');
    }
  }

  Future<void> _deleteFolder(NoteFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${folder.name}?'),
        content: const Text('Your notes will be kept and moved to No folder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete folder'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await NotesRepository(widget.client).deleteFolder(folder.id);
      await _refresh();
      widget.onChanged();
    } catch (_) {
      if (mounted) _message('The folder could not be deleted.');
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  IconData _icon(String value) => switch (value) {
    'school' => Icons.school_outlined,
    'favorite' => Icons.favorite_border_rounded,
    'work' => Icons.work_outline_rounded,
    'lightbulb' => Icons.lightbulb_outline_rounded,
    'more_horiz' => Icons.more_horiz_rounded,
    _ => Icons.folder_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your folders'),
        actions: [
          IconButton(
            tooltip: 'Create folder',
            onPressed: () => _editFolder(),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      body: FutureBuilder<_FolderData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Folders are unavailable',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => setState(() => _data = _load()),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.folders.isEmpty) {
            return EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'Start with a folder',
              message:
                  'Create a place for the thoughts you want to keep together.',
              actionLabel: 'Create folder',
              onAction: () => _editFolder(),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                30,
              ),
              children: [
                const SectionHeading('A place for every thought'),
                const SizedBox(height: 16),
                for (var index = 0; index < data.folders.length; index++) ...[
                  _folderCard(data, data.folders[index]),
                  if (index < data.folders.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _folderCard(_FolderData data, NoteFolder folder) {
    final count = data.notes.where((note) => note.folderId == folder.id).length;
    return PastelCard(
      color: AppPalette.fromHex(folder.color),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      child: Row(
        children: [
          Icon(_icon(folder.icon), size: 25, color: AppPalette.lavenderDeep),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: () => widget.onOpenFolder(folder.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$count ${count == 1 ? 'note' : 'notes'}',
                    style: const TextStyle(color: AppPalette.mutedInk),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Create note in ${folder.name}',
            onPressed: () => widget.onCreateNote(folder.id),
            icon: const Icon(Icons.add_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _editFolder(folder: folder);
              if (value == 'delete') _deleteFolder(folder);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Rename or recolor')),
              PopupMenuItem(value: 'delete', child: Text('Delete folder')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FolderData {
  const _FolderData(this.folders, this.notes);
  final List<NoteFolder> folders;
  final List<Note> notes;
}
