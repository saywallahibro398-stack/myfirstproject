import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/folder.dart';
import '../models/note.dart';

class NotesRepository {
  NotesRepository(this.client);

  final SupabaseClient client;
  String get _userId => client.auth.currentUser!.id;

  Future<List<Note>> fetchNotes({
    int offset = 0,
    int limit = 40,
    String? folderId,
    String? search,
    String orderBy = 'updated_at',
  }) async {
    var query = client.from('notes').select().eq('user_id', _userId);
    if (folderId != null) query = query.eq('folder_id', folderId);
    final term = search?.trim();
    if (term != null && term.isNotEmpty) {
      final safeTerm = term.replaceAll('%', r'\%').replaceAll('_', r'\_');
      query = query.or('title.ilike.%$safeTerm%,content.ilike.%$safeTerm%');
    }
    final rows = await query
        .order(orderBy, ascending: orderBy == 'title')
        .range(offset, offset + limit - 1);
    return rows.map((row) => Note.fromJson(row)).toList(growable: false);
  }

  Future<List<Note>> fetchAllNotes({String? folderId}) async {
    const pageSize = 200;
    final notes = <Note>[];
    for (var offset = 0; ; offset += pageSize) {
      var query = client.from('notes').select().eq('user_id', _userId);
      if (folderId != null) query = query.eq('folder_id', folderId);
      final rows = await query
          .order('updated_at', ascending: false)
          .range(offset, offset + pageSize - 1);
      notes.addAll(rows.map(Note.fromJson));
      if (rows.length < pageSize) break;
    }
    return notes;
  }

  Future<Note> saveNote({
    String? id,
    required String title,
    required String content,
    required String color,
    required String? folderId,
    required List<String> tags,
  }) async {
    final values = <String, dynamic>{
      'user_id': _userId,
      'title': title.trim(),
      'content': content,
      'color': color,
      'folder_id': folderId,
      'tags': tags,
    };
    if (id != null) values['id'] = id;
    final row = await client.from('notes').upsert(values).select().single();
    return Note.fromJson(row);
  }

  Future<void> deleteNote(String id) async {
    await client.from('notes').delete().eq('id', id).eq('user_id', _userId);
  }

  Future<List<NoteFolder>> fetchFolders() async {
    final rows = await client
        .from('folders')
        .select()
        .eq('user_id', _userId)
        .order('name');
    return rows.map((row) => NoteFolder.fromJson(row)).toList(growable: false);
  }

  Future<NoteFolder> saveFolder({
    String? id,
    required String name,
    required String color,
    required String icon,
  }) async {
    final values = <String, dynamic>{
      'user_id': _userId,
      'name': name.trim(),
      'color': color,
      'icon': icon,
    };
    if (id != null) values['id'] = id;
    final row = await client.from('folders').upsert(values).select().single();
    return NoteFolder.fromJson(row);
  }

  Future<void> deleteFolder(String id) async {
    await client.from('folders').delete().eq('id', id).eq('user_id', _userId);
  }

  Future<Set<DateTime>> fetchActivityDates() async {
    final rows = await client
        .from('writing_activity')
        .select('activity_date')
        .eq('user_id', _userId)
        .order('activity_date', ascending: false);
    return rows
        .map((row) => DateTime.parse(row['activity_date'] as String).toUtc())
        .toSet();
  }
}
