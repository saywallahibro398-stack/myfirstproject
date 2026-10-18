class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.leaderboardPublic,
    required this.preferences,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final bool leaderboardPublic;
  final Map<String, dynamic> preferences;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String? ?? 'Note maker',
    avatarUrl: json['avatar_url'] as String?,
    leaderboardPublic: json['leaderboard_public'] as bool? ?? false,
    preferences: Map<String, dynamic>.from(
      json['preferences'] as Map<String, dynamic>? ?? const {},
    ),
  );
}
