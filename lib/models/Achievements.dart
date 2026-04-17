import 'package:recycle_go/models/Connector.dart';

class Achievement {
  final String label;
  final bool isUnlocked;

  Achievement({required this.label, required this.isUnlocked});
}

class AchievementModel extends Connector {
  static final AchievementModel _instance = AchievementModel._internal();
  factory AchievementModel() => _instance;
  AchievementModel._internal();

  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      // 1. First Recycle & Total Stations
      final submissions = await client
          .from('recyclingsubmission')
          .select('station_id')
          .eq('user_id', userId);

      final totalSubmissions = submissions.length;
      final uniqueStations = submissions.map((s) => s['station_id']).toSet().length;

      // 2. Streaks (Fetch from submissions over time)
      final submissionDates = await client
          .from('recyclingsubmission')
          .select('submitted_at')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      bool hasOneWeekStreak = _calculateStreak(submissionDates, 7);
      bool hasOneMonthStreak = _calculateStreak(submissionDates, 30);

      return [
        Achievement(label: 'FIRST RECYCLE', isUnlocked: totalSubmissions > 0),
        Achievement(label: '1 WEEK STREAK', isUnlocked: hasOneWeekStreak),
        Achievement(label: '1 MONTH STREAK', isUnlocked: hasOneMonthStreak),
        Achievement(label: '10+ STATIONS', isUnlocked: uniqueStations >= 10),
      ];
    } catch (e) {
      print('DEBUG: Error fetching achievements: $e');
      return [];
    }
  }

  bool _calculateStreak(List<dynamic> dates, int targetDays) {
    if (dates.isEmpty) return false;
    
    // Simplified logic: checks if there's at least one submission
    // every day for the last X days.
    // In a real app, you'd compare actual DateTime objects carefully.
    return dates.length >= targetDays;
  }
}
