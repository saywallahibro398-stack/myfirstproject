import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this.client);

  final SupabaseClient client;
  String get _userId => client.auth.currentUser!.id;

  Future<UserProfile> fetchProfile() async {
    final row = await client
        .from('profiles')
        .select()
        .eq('id', _userId)
        .single();
    return UserProfile.fromJson(row);
  }

  Future<UserProfile> updateProfile({
    required String displayName,
    required String? avatarUrl,
    required bool leaderboardPublic,
    required Map<String, dynamic> preferences,
  }) async {
    final row = await client
        .from('profiles')
        .update({
          'display_name': displayName.trim(),
          'avatar_url': avatarUrl?.trim().isEmpty == true ? null : avatarUrl?.trim(),
          'leaderboard_public': leaderboardPublic,
          'preferences': preferences,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', _userId)
        .select()
        .single();
    return UserProfile.fromJson(row);
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    await client
        .from('profiles')
        .update({
          'preferences': preferences,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', _userId);
  }
}
