class QuizAnswer {
  final int id;
  final String text;

  const QuizAnswer({required this.id, required this.text});

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: _requiredInt(json['id'], 'réponse'),
      text:
          (json['answer_text'] ?? json['text'] ?? json['label'])?.toString() ??
              '',
    );
  }
}

class QuizQuestion {
  final int id;
  final String text;
  final int timeLimit;
  final List<QuizAnswer> answers;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.timeLimit,
    required this.answers,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    return QuizQuestion(
      id: _requiredInt(json['id'], 'question'),
      text: (json['question_text'] ?? json['text'] ?? json['question'])
              ?.toString() ??
          '',
      timeLimit: _int(json['time_limit'], 20),
      answers: rawAnswers is List
          ? rawAnswers
              .whereType<Map>()
              .map((answer) =>
                  QuizAnswer.fromJson(Map<String, dynamic>.from(answer)))
              .toList()
          : const [],
    );
  }
}

class QuizSession {
  final int id;
  final String status;
  final int totalQuestions;

  const QuizSession({
    required this.id,
    required this.status,
    required this.totalQuestions,
  });

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: _requiredInt(json['id'], 'session'),
      status: json['status']?.toString() ?? 'started',
      totalQuestions: _int(json['total_questions'], 10),
    );
  }
}

class AnswerResult {
  final int questionId;
  final int? answerId;
  final int? correctAnswerId;
  final bool isCorrect;
  final int pointsEarned;
  final int xpEarned;
  final String explanation;

  const AnswerResult({
    required this.questionId,
    this.answerId,
    this.correctAnswerId,
    required this.isCorrect,
    required this.pointsEarned,
    required this.xpEarned,
    required this.explanation,
  });

  factory AnswerResult.fromJson(
    Map<String, dynamic> json, {
    int? fallbackQuestionId,
    int? fallbackAnswerId,
  }) {
    return AnswerResult(
      questionId: json['question_id'] == null
          ? fallbackQuestionId ??
              (throw const FormatException('Identifiant de question absent.'))
          : _requiredInt(json['question_id'], 'question'),
      answerId: json['answer_id'] == null
          ? fallbackAnswerId
          : _int(json['answer_id']),
      correctAnswerId: json['correct_answer_id'] == null
          ? null
          : _int(json['correct_answer_id']),
      isCorrect: json['is_correct'] == true,
      pointsEarned: _int(json['points_earned']),
      xpEarned: _int(json['xp_earned']),
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int _requiredInt(dynamic value, String field) {
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed != null) return parsed;
  throw FormatException('Identifiant de $field invalide.');
}
