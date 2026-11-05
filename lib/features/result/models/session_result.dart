class SessionAnswer {
  final bool isCorrect;
  final String questionText;
  final String selectedText;
  final String correctText;
  final String explanation;
  final int pointsEarned;

  const SessionAnswer({
    required this.isCorrect,
    required this.questionText,
    required this.selectedText,
    required this.correctText,
    required this.explanation,
    required this.pointsEarned,
  });

  factory SessionAnswer.fromJson(Map<String, dynamic> json) {
    return SessionAnswer(
      isCorrect: json['is_correct'] == true,
      questionText: json['question']?['question_text']?.toString() ?? '',
      selectedText: json['selected_option']?['option_text']?.toString() ??
          json['selected_answer']?['answer_text']?.toString() ??
          'Pas de réponse',
      correctText: json['correct_option']?['option_text']?.toString() ??
          json['correct_answer']?['answer_text']?.toString() ??
          '',
      explanation: json['question']?['explanation']?.toString() ?? '',
      pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionRewards {
  final int xp;
  final int coins;
  final int gems;

  const SessionRewards({
    required this.xp,
    required this.coins,
    required this.gems,
  });

  factory SessionRewards.fromJson(Map<String, dynamic> json) {
    return SessionRewards(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionResult {
  final int correctAnswers;
  final int totalQuestions;
  final int score;
  final int bonusScore;
  final int totalScore;
  final String categoryName;
  final String mode;
  final List<SessionAnswer> answers;
  final SessionRewards? rewards;
  final bool chestUnlocked;

  const SessionResult({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.bonusScore,
    required this.totalScore,
    required this.categoryName,
    required this.mode,
    required this.answers,
    this.rewards,
    this.chestUnlocked = false,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    // Support both old API shape and new V1 shape
    final session = json['session'] is Map<String, dynamic>
        ? json['session'] as Map<String, dynamic>
        : json;

    final rawAnswers = json['answers'] ?? session['answers'];
    final rawRewards = json['rewards'];

    final categoryRaw = json['category'] ?? session['category'];
    String catName = 'Quiz';
    if (categoryRaw is Map) {
      catName = categoryRaw['name']?.toString() ?? 'Quiz';
    }

    return SessionResult(
      correctAnswers: (session['correct_answers'] as num?)?.toInt() ??
          (json['correct_answers'] as num?)?.toInt() ?? 0,
      totalQuestions: (session['total_questions'] as num?)?.toInt() ?? 10,
      score: (session['score'] as num?)?.toInt() ?? (json['score'] as num?)?.toInt() ?? 0,
      bonusScore: (json['bonus_score'] as num?)?.toInt() ?? 0,
      totalScore: (session['total_score'] as num?)?.toInt() ??
          (json['total_score'] as num?)?.toInt() ?? 0,
      categoryName: catName,
      mode: session['mode']?.toString() ?? json['mode']?.toString() ?? 'level',
      answers: rawAnswers is List
          ? rawAnswers.whereType<Map<String, dynamic>>().map(SessionAnswer.fromJson).toList()
          : const [],
      rewards: rawRewards is Map<String, dynamic>
          ? SessionRewards.fromJson(rawRewards)
          : null,
      chestUnlocked: json['unlocks']?['chest'] == true,
    );
  }
}
