class NoteFolder {
  const NoteFolder({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.noteCount = 0,
  });

  final String id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;
  final int noteCount;

  NoteFolder withCount(int value) => NoteFolder(
    id: id,
    name: name,
    color: color,
    icon: icon,
    createdAt: createdAt,
    noteCount: value,
  );

  factory NoteFolder.fromJson(Map<String, dynamic> json) => NoteFolder(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String,
    icon: json['icon'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
  );
}
