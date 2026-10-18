class ActivitySummary {
  ActivitySummary._(this.days, this.today);

  final Set<DateTime> days;
  final DateTime today;

  factory ActivitySummary.fromUtcDates(
    Iterable<DateTime> dates, {
    DateTime? now,
  }) {
    final current = now?.toUtc() ?? DateTime.now().toUtc();
    final today = DateTime.utc(current.year, current.month, current.day);
    final normalized = dates
        .map(
          (date) => DateTime.utc(
            date.toUtc().year,
            date.toUtc().month,
            date.toUtc().day,
          ),
        )
        .toSet();
    return ActivitySummary._(normalized, today);
  }

  int get currentStreak {
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return 0;

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    if (days.isEmpty) return 0;
    final ordered = days.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var index = 1; index < ordered.length; index++) {
      if (ordered[index].difference(ordered[index - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  List<bool> get thisWeek {
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List<bool>.generate(
      7,
      (index) => days.contains(monday.add(Duration(days: index))),
    );
  }

  int get activeDaysThisWeek => thisWeek.where((active) => active).length;
}
