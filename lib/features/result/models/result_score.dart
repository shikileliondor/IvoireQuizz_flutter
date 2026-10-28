import 'dart:math' as math;

/// Lit un nombre de l'API, qu'il arrive en entier, en décimal ou en texte.
int? parseScoreValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final String trimmed = value.trim();
    return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.round();
  }
  return null;
}

/// Chiffres affichés sur l'écran de résultat, quelle que soit la source de la
/// partie (session en ligne, hors ligne, défi ou campagne).
class ResultScore {
  const ResultScore({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.totalScore,
    required this.baseScore,
    required this.bonusScore,
  });

  factory ResultScore.fromResultData(Map<String, dynamic> data) {
    final dynamic answers = data['answers'];
    final int? questions = parseScoreValue(data['total_questions']);
    final int totalQuestions = questions != null && questions > 0
        ? questions
        : answers is List && answers.isNotEmpty
            ? answers.length
            : 10;
    final int correctAnswers = (parseScoreValue(data['correct_answers']) ?? 0)
        .clamp(0, totalQuestions);
    final int bonusScore = parseScoreValue(data['bonus_score']) ?? 0;
    final int? baseScore = parseScoreValue(data['score']);
    final int totalScore =
        parseScoreValue(data['total_score']) ?? (baseScore ?? 0) + bonusScore;

    return ResultScore(
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      totalScore: totalScore,
      bonusScore: bonusScore,
      // Hors ligne et en défi, seul le total est connu : le score de base est
      // alors le total moins le bonus, et non 0.
      baseScore: baseScore ?? math.max(totalScore - bonusScore, 0),
    );
  }

  final int correctAnswers;
  final int totalQuestions;
  final int totalScore;
  final int baseScore;
  final int bonusScore;
}
