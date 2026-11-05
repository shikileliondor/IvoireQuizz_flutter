class Lives {
  final int current;
  final int max;
  final DateTime? nextLifeAt;

  const Lives({
    required this.current,
    required this.max,
    this.nextLifeAt,
  });

  bool get isFull => current >= max;

  factory Lives.fromJson(Map<String, dynamic> json) {
    final raw = json['next_life_at'];
    return Lives(
      current: (json['lives'] as num?)?.toInt() ?? 0,
      max: (json['max_lives'] as num?)?.toInt() ?? 5,
      nextLifeAt: raw is String ? DateTime.tryParse(raw) : null,
    );
  }
}
