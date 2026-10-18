enum RankingPeriod {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  yearly('yearly', 'Yearly'),
  allTime('all_time', 'All time');

  const RankingPeriod(this.rpcValue, this.label);

  final String rpcValue;
  final String label;

  ({DateTime? start, DateTime? end}) rangeContaining(DateTime value) {
    final utc = value.toUtc();
    final day = DateTime.utc(utc.year, utc.month, utc.day);
    final start = switch (this) {
      RankingPeriod.daily => day,
      RankingPeriod.weekly => day.subtract(Duration(days: day.weekday - 1)),
      RankingPeriod.monthly => DateTime.utc(day.year, day.month),
      RankingPeriod.yearly => DateTime.utc(day.year),
      RankingPeriod.allTime => null,
    };
    if (start == null) return (start: null, end: null);
    final end = switch (this) {
      RankingPeriod.daily => start.add(const Duration(days: 1)),
      RankingPeriod.weekly => start.add(const Duration(days: 7)),
      RankingPeriod.monthly => DateTime.utc(start.year, start.month + 1),
      RankingPeriod.yearly => DateTime.utc(start.year + 1),
      RankingPeriod.allTime => null,
    };
    return (start: start, end: end);
  }
}

abstract final class RankingRules {
  static const minimumWords = 5;
  static const pointsPerQualifyingNote = 10;
  static const maximumQualifyingNotesPerUtcDay = 3;
  static const dailyActivityBonus = 2;

  static int pointsForUtcDay(int qualifyingNotes) {
    if (qualifyingNotes <= 0) return 0;
    final cappedNotes = qualifyingNotes.clamp(
      0,
      maximumQualifyingNotesPerUtcDay,
    );
    return cappedNotes * pointsPerQualifyingNote + dailyActivityBonus;
  }
}
