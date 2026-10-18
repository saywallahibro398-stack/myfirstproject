import 'package:flutter_test/flutter_test.dart';

import 'package:myfirstproject/models/note.dart';

void main() {
  test('Note parses Supabase records and preserves UTC timestamps', () {
    final note = Note.fromJson({
      'id': 'note-1',
      'title': '  A small title  ',
      'content': '# Welcome\nThis is a thought to remember.',
      'color': '#F4E9F2',
      'tags': ['journal', 'idea'],
      'folder_id': 'folder-1',
      'created_at': '2026-10-18T09:00:00+00:00',
      'updated_at': '2026-10-18T10:15:00+00:00',
    });

    expect(note.displayTitle, 'A small title');
    expect(note.preview, 'Welcome This is a thought to remember.');
    expect(note.tags, ['journal', 'idea']);
    expect(note.folderId, 'folder-1');
    expect(note.updatedAt.isUtc, isTrue);
  });

  test('Note uses a safe title and empty preview for blank content', () {
    final note = Note.fromJson({
      'id': 'note-2',
      'title': '',
      'content': '',
      'color': '#F4E9F2',
      'tags': <String>[],
      'folder_id': null,
      'created_at': '2026-10-18T09:00:00Z',
      'updated_at': '2026-10-18T09:00:00Z',
    });

    expect(note.displayTitle, 'Untitled note');
    expect(note.preview, isEmpty);
  });
}
