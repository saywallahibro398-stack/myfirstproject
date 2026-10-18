import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/leaderboard_entry.dart';

class RankingRepository {
  RankingRepository(this.client);

  final SupabaseClient client;

  Future<List<LeaderboardEntry>> fetchLeaderboard(String period) async {
    final rows = await client.rpc(
      'get_leaderboard',
      params: {'p_period': period, 'p_limit': 100},
    );
    return (rows as List<dynamic>)
        .map((row) => LeaderboardEntry.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);
  }
}
