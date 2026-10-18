import 'package:flutter_test/flutter_test.dart';

import 'package:myfirstproject/features/ranking/ranking_period.dart';
import 'package:myfirstproject/features/streaks/activity_summary.dart';

void main() {
  group('Ranking rules', () {
    test('caps note awards and limits the daily activity bonus to one', () {
      expect(RankingRules.pointsForUtcDay(0), 0);
      expect(RankingRules.pointsForUtcDay(1), 12);
      expect(RankingRules.pointsForUtcDay(3), 32);
      expect(RankingRules.pointsForUtcDay(20), 32);
    });

    test('periods map to distinct server calendar ranges', () {
      expect(
        RankingPeriod.values.map((period) => period.rpcValue).toSet(),
        hasLength(5),
      );
      expect(RankingPeriod.allTime.rpcValue, 'all_time');
    });

    test(
      'period bounds use UTC calendar day, Monday week, month, and year',
      () {
        final date = DateTime.utc(2026, 10, 18, 23, 30);
        expect(RankingPeriod.daily.rangeContaining(date), (
          start: DateTime.utc(2026, 10, 18),
          end: DateTime.utc(2026, 10, 19),
        ));
        expect(RankingPeriod.weekly.rangeContaining(date), (
          start: DateTime.utc(2026, 10, 12),
          end: DateTime.utc(2026, 10, 19),
        ));
        expect(RankingPeriod.monthly.rangeContaining(date), (
          start: DateTime.utc(2026, 10, 1),
          end: DateTime.utc(2026, 11, 1),
        ));
        expect(RankingPeriod.yearly.rangeContaining(date), (
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2027, 1, 1),
        ));
        expect(RankingPeriod.allTime.rangeContaining(date), (
          start: null,
          end: null,
        ));
      },
    );
  });

  group('Activity summary', () {
    test('calculates current streak, longest streak, and weekly activity', () {
      final summary = ActivitySummary.fromUtcDates([
        DateTime.utc(2026, 10, 15),
        DateTime.utc(2026, 10, 16),
        DateTime.utc(2026, 10, 17),
        DateTime.utc(2026, 10, 18),
        DateTime.utc(2026, 10, 12),
        DateTime.utc(2026, 10, 13),
      ], now: DateTime.utc(2026, 10, 18, 14));

      expect(summary.currentStreak, 4);
      expect(summary.longestStreak, 4);
      expect(summary.activeDaysThisWeek, 6);
    });

    test('does not extend a streak across a missing day', () {
      final summary = ActivitySummary.fromUtcDates([
        DateTime.utc(2026, 10, 18),
        DateTime.utc(2026, 10, 16),
      ], now: DateTime.utc(2026, 10, 18));

      expect(summary.currentStreak, 1);
      expect(summary.longestStreak, 1);
    });
  });
}
