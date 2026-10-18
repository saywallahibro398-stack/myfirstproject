enum RankingPeriod {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  yearly('yearly', 'Yearly'),
  allTime('all_time', 'All time');

  const RankingPeriod(this.rpcValue, this.label);

  final String rpcValue;
  final String label;
}

abstract final class RankingRules {
  static const minimumWords = 5;
  static const pointsPerQualifyingNote = 10;
  static const maximumQualifyingNotesPerUtcDay = 3;
  static const dailyActivityBonus = 2;

  static int pointsForUtcDay(int qualifyingNotes) {
    if (qualifyingNotes <= 0) return 0;
    final cappedNotes = qualifyingNotes.clamp(0, maximumQualifyingNotesPerUtcDay);
    return cappedNotes * pointsPerQualifyingNote + dailyActivityBonus;
  }
}
