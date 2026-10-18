class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
  });

  final String id;
  final String title;
  final String content;
  final String color;
  final List<String> tags;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle =>
      title.trim().isEmpty ? 'Untitled note' : title.trim();

  String get preview {
    final plain = content
        .replaceAll(RegExp(r'[#*_`~>]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return plain.length > 120 ? '${plain.substring(0, 117)}...' : plain;
  }

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    color: json['color'] as String? ?? '#F3EAF7',
    tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
    folderId: json['folder_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
  );
}
