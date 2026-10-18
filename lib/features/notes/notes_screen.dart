import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/notes_repository.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_card.dart';
import '../../widgets/section_heading.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    required this.client,
    required this.onOpenNote,
    required this.onCreateNote,
    required this.onOpenFolders,
    required this.onClearFolder,
    required this.onChanged,
    this.folderId,
    super.key,
  });

  final SupabaseClient client;
  final String? folderId;
  final ValueChanged<Note> onOpenNote;
  final VoidCallback onCreateNote;
  final VoidCallback onOpenFolders;
  final VoidCallback onClearFolder;
  final VoidCallback onChanged;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _pageSize = 40;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Note> _notes = [];
  List<NoteFolder> _folders = [];
  String? _selectedFolder;
  String _sort = 'updated_at';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.folderId;
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant NotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folderId != widget.folderId) {
      _selectedFolder = widget.folderId;
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _notes = [];
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final repository = NotesRepository(widget.client);
      final offset = reset ? 0 : _notes.length;
      final result = await Future.wait<dynamic>([
        repository.fetchNotes(
          offset: offset,
          limit: _pageSize,
          folderId: _selectedFolder,
          search: _searchController.text,
          orderBy: _sort,
        ),
        if (reset) repository.fetchFolders(),
      ]);
      if (!mounted) return;
      final page = result[0] as List<Note>;
      setState(() {
        _notes = reset ? page : [..._notes, ...page];
        _hasMore = page.length == _pageSize;
        if (reset) _folders = result[1] as List<NoteFolder>;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = error;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) _load(reset: false);
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () => _load(reset: true));
  }

  Future<void> _delete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${note.displayTitle}” will be removed from your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await NotesRepository(widget.client).deleteNote(note.id);
      await _load(reset: true);
      widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The note could not be deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final folderName = _folders.where((folder) => folder.id == _selectedFolder).firstOrNull?.name;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 16, AppSpacing.page, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(child: SectionHeading(folderName ?? 'All notes')),
                    IconButton(tooltip: 'Manage folders', onPressed: widget.onOpenFolders, icon: const Icon(Icons.folder_open_outlined)),
                    if (folderName != null)
                      IconButton(tooltip: 'Show all notes', onPressed: widget.onClearFolder, icon: const Icon(Icons.close)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search your notes',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              _load(reset: true);
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, AppSpacing.page, 6),
              sliver: SliverToBoxAdapter(child: _filters()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'updated_at', child: Text('Recently updated')),
                      DropdownMenuItem(value: 'created_at', child: Text('Date created')),
                      DropdownMenuItem(value: 'title', child: Text('Title A–Z')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() { _sort = value; _load(reset: true); });
                    },
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Notes are unavailable',
                  message: 'Check your connection, then try loading them again.',
                  actionLabel: 'Retry',
                  onAction: () => _load(reset: true),
                ),
              )
            else if (_notes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: _searchController.text.isEmpty ? 'No notes here yet' : 'No notes found',
                  message: _searchController.text.isEmpty
                      ? 'Start with one small thought. You can sort it into a folder later.'
                      : 'Try a different title or phrase.',
                  actionLabel: _searchController.text.isEmpty ? 'Write a note' : null,
                  onAction: widget.onCreateNote,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 22),
                sliver: SliverList.separated(
                  itemCount: _notes.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (context, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    if (index >= _notes.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final note = _notes[index];
                    final folder = _folders.where((value) => value.id == note.folderId).firstOrNull;
                    return NoteCard(
                      note: note,
                      folderName: folder?.name,
                      onTap: () => widget.onOpenNote(note),
                      onEdit: () => widget.onOpenNote(note),
                      onDelete: () => _delete(note),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    final folders = _folders;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(label: 'All', selected: _selectedFolder == null, onTap: () => _setFolder(null)),
          for (final folder in folders)
            _FilterChip(
              label: folder.name,
              selected: _selectedFolder == folder.id,
              color: AppPalette.fromHex(folder.color),
              onTap: () => _setFolder(folder.id),
            ),
        ],
      ),
    );
  }

  void _setFolder(String? value) {
    setState(() => _selectedFolder = value);
    _load(reset: true);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          backgroundColor: color ?? AppPalette.white,
          selectedColor: AppPalette.lavender,
          side: BorderSide.none,
        ),
      );
}
