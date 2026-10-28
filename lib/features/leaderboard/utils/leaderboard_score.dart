/// Lit le score porté par une ligne de classement.
///
/// Les classements général et hebdomadaire utilisent des métriques propres à
/// la période, tandis que les réponses plus anciennes exposent un score total.
int leaderboardScore(
  Map<String, dynamic> entry, {
  int fallback = 0,
}) {
  for (final String key in const <String>[
    'campaign_score',
    'current_score',
    'weekly_points',
    'total_score',
    'score',
    'points',
    'xp',
    'best_score',
    'quiz_score',
  ]) {
    final dynamic value = entry[key];
    if (value is num) return value.toInt();
    final int? parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }

  return fallback;
}
