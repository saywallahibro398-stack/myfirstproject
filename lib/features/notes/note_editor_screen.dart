import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/notes_repository.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../../widgets/pastel_card.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    required this.client,
    required this.onSaved,
    this.note,
    this.initialTitle,
    this.initialContent,
    this.initialFolderId,
    super.key,
  });

  final SupabaseClient client;
  final VoidCallback onSaved;
  final Note? note;
  final String? initialTitle;
  final String? initialContent;
  final String? initialFolderId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final Future<List<NoteFolder>> _folders;
  late String _color;
  String? _folderId;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? widget.initialContent ?? '');
    _tagsController = TextEditingController(text: widget.note?.tags.join(', ') ?? '');
    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
    _tagsController.addListener(_markDirty);
    _color = widget.note?.color ?? AppPalette.toHex(AppPalette.noteColors.first);
    _folderId = widget.note?.folderId ?? widget.initialFolderId;
    _folders = NotesRepository(widget.client).fetchFolders();
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      _message('Add a title or a few words before saving.');
      return;
    }
    setState(() => _saving = true);
    try {
      await NotesRepository(widget.client).saveNote(
        id: widget.note?.id,
        title: _titleController.text,
        content: _contentController.text,
        color: _color,
        folderId: _folderId,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(),
      );
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Your note could not be saved. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This note will be permanently removed from your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep note')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await NotesRepository(widget.client).deleteNote(widget.note!.id);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _message('The note could not be deleted. Try again.');
    }
  }

  Future<void> _confirmLeave() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without saving?'),
        content: const Text('Your latest changes will be discarded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard changes')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _format(String marker, {String? prefix, String? suffix}) {
    final selection = _contentController.selection;
    final text = _contentController.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final before = text.substring(0, start);
    final selected = text.substring(start, end);
    final after = text.substring(end);
    final opening = prefix ?? marker;
    final closing = suffix ?? marker;
    final replacement = '$before$opening$selected$closing$after';
    _contentController.value = TextEditingValue(
      text: replacement,
      selection: TextSelection.collapsed(offset: start + opening.length + selected.length + closing.length),
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close editor',
            onPressed: _confirmLeave,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(widget.note == null ? 'New note' : 'Edit note'),
          actions: [
            if (widget.note != null)
              IconButton(
                tooltip: 'Delete note',
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<NoteFolder>>(
            future: _folders,
            builder: (context, snapshot) {
              final folders = snapshot.data ?? const <NoteFolder>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                children: [
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: 'Give this thought a title',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  if (widget.note != null) ...[
                    Text(
                      'Created ${_formatDate(widget.note!.createdAt)}  ·  Edited ${_formatDate(widget.note!.updatedAt)}',
                      style: const TextStyle(fontSize: 12, color: AppPalette.mutedInk),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FormatButton(icon: Icons.format_bold, tooltip: 'Bold', onPressed: () => _format('**')),
                        _FormatButton(icon: Icons.format_italic, tooltip: 'Italic', onPressed: () => _format('*')),
                        _FormatButton(icon: Icons.format_underline, tooltip: 'Underline', onPressed: () => _format('__')),
                        _FormatButton(icon: Icons.title, tooltip: 'Heading', onPressed: () => _format('', prefix: '## ', suffix: '')),
                        _FormatButton(icon: Icons.format_list_bulleted, tooltip: 'Bullet list', onPressed: () => _format('', prefix: '- ', suffix: '')),
                        _FormatButton(icon: Icons.format_list_numbered, tooltip: 'Numbered list', onPressed: () => _format('', prefix: '1. ', suffix: '')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 12,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Let the words find their way here...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PastelCard(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Note color', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: AppPalette.noteColors.map((color) {
                            final hex = AppPalette.toHex(color);
                            return InkWell(
                              onTap: () => setState(() { _color = hex; _dirty = true; }),
                              borderRadius: BorderRadius.circular(24),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: color,
                                child: _color == hex ? const Icon(Icons.check, size: 17) : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String?>(
                          initialValue: folders.any((folder) => folder.id == _folderId) ? _folderId : null,
                          decoration: const InputDecoration(labelText: 'Folder'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('No folder')),
                            ...folders.map((folder) => DropdownMenuItem<String?>(value: folder.id, child: Text(folder.name))),
                          ],
                          onChanged: (value) => setState(() { _folderId = value; _dirty = true; }),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Labels',
                            hintText: 'Separate labels with commas',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.note == null ? 'Your note syncs to your private Supabase account when saved.' : 'Changes sync to your account when you save.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 19),
        style: IconButton.styleFrom(backgroundColor: AppPalette.lavender.withValues(alpha: .6)),
      );
}
