class LeaderboardEntry {
  const LeaderboardEntry({
    required this.displayName,
    required this.score,
    required this.position,
    required this.isCurrentUser,
    this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;
  final int score;
  final int position;
  final bool isCurrentUser;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        displayName: json['display_name'] as String? ?? 'Note maker',
        avatarUrl: json['avatar_url'] as String?,
        score: (json['score'] as num).toInt(),
        position: (json['rank_position'] as num).toInt(),
        isCurrentUser: json['is_current_user'] as bool? ?? false,
      );
}
