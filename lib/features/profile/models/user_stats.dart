class CategoryStat {
  final String name;
  final double successRate;

  const CategoryStat({required this.name, required this.successRate});

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    final rawRate = (json['success_rate'] ?? json['rate'] ?? 0.0) as num;
    final rate = rawRate.toDouble();
    return CategoryStat(
      name: (json['category_name'] ?? json['name'] ?? '').toString(),
      successRate: (rate > 1 ? rate / 100 : rate).clamp(0.0, 1.0),
    );
  }
}

class UserStats {
  final int bestScore;
  final double successRate;
  final List<CategoryStat> byCategory;

  const UserStats({
    required this.bestScore,
    required this.successRate,
    required this.byCategory,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final rawCats = json['by_category'];
    return UserStats(
      bestScore: (json['best_score'] as num?)?.toInt() ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      byCategory: rawCats is List
          ? rawCats.whereType<Map<String, dynamic>>().map(CategoryStat.fromJson).toList()
          : const [],
    );
  }
}
