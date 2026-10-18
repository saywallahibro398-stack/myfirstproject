import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/ranking_repository.dart';
import '../../models/leaderboard_entry.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pastel_card.dart';
import 'ranking_period.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({required this.client, super.key});

  final SupabaseClient client;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  RankingPeriod _period = RankingPeriod.weekly;
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await RankingRepository(widget.client).fetchLeaderboard(_period.rpcValue);
      if (mounted) setState(() { _entries = rows; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'The leaderboard could not be loaded. Check your connection and database migration.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _entries.where((entry) => entry.isCurrentUser).firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 18, AppSpacing.page, 30),
            children: [
              Text('A little friendly spark', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Celebrate the words you put into the world.', style: TextStyle(color: AppPalette.mutedInk)),
              const SizedBox(height: 20),
              SegmentedButton<RankingPeriod>(
                showSelectedIcon: false,
                segments: RankingPeriod.values
                    .map((period) => ButtonSegment(value: period, label: Text(period.label)))
                    .toList(),
                selected: {_period},
                onSelectionChanged: (selection) {
                  setState(() => _period = selection.first);
                  _load();
                },
              ),
              const SizedBox(height: 24),
              if (currentUser != null) _yourPosition(currentUser),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(42),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Ranks are taking a pause',
                  message: _error!,
                  actionLabel: 'Try again',
                  onAction: _load,
                )
              else if (_entries.isEmpty)
                const EmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'The first page is yours to write',
                  message: 'There are no public scores for this period yet. Opt in from Settings to join the board.',
                )
              else ...[
                _podium(),
                const SizedBox(height: 14),
                for (final entry in _entries.skip(3)) _rankRow(entry),
              ],
              const SizedBox(height: 18),
              _scoringRules(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _yourPosition(LeaderboardEntry entry) => PastelCard(
        color: AppPalette.mint,
        child: Row(
          children: [
            const Icon(Icons.person_pin_circle_outlined, color: AppPalette.lavenderDeep),
            const SizedBox(width: 10),
            Expanded(child: Text('Your place  #${entry.position}', style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('${entry.score} pts', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _podium() {
    final top = _entries.take(3).toList();
    final ordered = <LeaderboardEntry?>[
      top.length > 1 ? top[1] : null,
      top.firstOrNull,
      top.length > 2 ? top[2] : null,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < ordered.length; index++)
          if (ordered[index] != null)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                child: _podiumPlace(ordered[index]!, heights: const [124.0, 158.0, 108.0][index]),
              ),
            )
          else
            const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _podiumPlace(LeaderboardEntry entry, {required double heights}) {
    final colors = switch (entry.position) {
      1 => AppPalette.yellow,
      2 => AppPalette.lavender,
      _ => AppPalette.peach,
    };
    return Container(
      height: heights,
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
      decoration: BoxDecoration(
        color: colors,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22), bottom: Radius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _avatar(entry, radius: 22),
          const SizedBox(height: 7),
          Text(entry.position == 1 ? '✦ 1' : '#${entry.position}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          Text('${entry.score} pts', style: const TextStyle(fontSize: 11, color: AppPalette.mutedInk)),
        ],
      ),
    );
  }

  Widget _rankRow(LeaderboardEntry entry) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: PastelCard(
          color: entry.isCurrentUser ? AppPalette.mint : AppPalette.white,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text('${entry.position}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppPalette.mutedInk))),
              _avatar(entry, radius: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${entry.score} pts', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );

  Widget _avatar(LeaderboardEntry entry, {required double radius}) {
    final url = entry.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppPalette.pink,
      foregroundColor: AppPalette.ink,
      backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      onBackgroundImageError: url == null || url.isEmpty ? null : (exception, stackTrace) {},
      child: url == null || url.isEmpty ? Text(entry.displayName.isEmpty ? '?' : entry.displayName[0].toUpperCase()) : null,
    );
  }

  Widget _scoringRules() => PastelCard(
        color: AppPalette.yellow,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kind words count', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('A saved note of at least 5 words earns 10 points. The first 3 qualifying notes each UTC day can earn points, plus one 2-point daily writing bonus. Daily, weekly, monthly and yearly boards use UTC calendar boundaries; all-time sums every eligible point.', style: TextStyle(color: AppPalette.mutedInk, height: 1.45)),
          ],
        ),
      );
}
