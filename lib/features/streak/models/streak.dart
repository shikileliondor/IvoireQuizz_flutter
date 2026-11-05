class Streak {
  final int current;
  final int longest;
  final int freezes;

  const Streak({
    required this.current,
    required this.longest,
    this.freezes = 0,
  });

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      current: (json['current_streak'] as num?)?.toInt() ?? 0,
      longest: (json['longest_streak'] as num?)?.toInt() ?? 0,
      freezes: (json['streak_freezes'] as num?)?.toInt() ?? 0,
    );
  }
}
