/// Core Habit Streak Synchronization Logic (Per SDD UC-02, UC-06)
class HabitStreakEngine {
  /// Calculates if the group streak remains active based on member completions.
  /// Rule: Group streak only advances if ALL members finish daily workout before midnight.
  static bool isGroupStreakActive({
    required List<MemberWorkoutStatus> members,
  }) {
    if (members.isEmpty) return false;
    return members.every((m) => m.hasCompletedToday);
  }

  /// Calculates consecutive streak days given historical daily records.
  static int calculateConsecutiveDays(List<DailyStreakRecord> history) {
    if (history.isEmpty) return 0;
    int streak = 0;
    // Iterate backwards from today
    for (final record in history.reversed) {
      if (record.isSuccessful) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class MemberWorkoutStatus {
  final String userId;
  final String displayName;
  final bool hasCompletedToday;

  MemberWorkoutStatus({
    required this.userId,
    required this.displayName,
    required this.hasCompletedToday,
  });
}

class DailyStreakRecord {
  final DateTime date;
  final bool isSuccessful;

  DailyStreakRecord({
    required this.date,
    required this.isSuccessful,
  });
}
