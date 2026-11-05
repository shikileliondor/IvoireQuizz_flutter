import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/quiz/models/quiz_models.dart';

void main() {
  test('uses submitted identifiers when answer payload omits them', () {
    final result = AnswerResult.fromJson(
      {
        'is_correct': true,
        'points_earned': 18,
        'xp_earned': 5,
        'correct_answer_id': 30,
        'explanation': 'Bonne réponse.',
      },
      fallbackQuestionId: 12,
      fallbackAnswerId: 30,
    );

    expect(result.questionId, 12);
    expect(result.answerId, 30);
    expect(result.correctAnswerId, 30);
    expect(result.isCorrect, isTrue);
  });

  test('preserves a wrong answer and exposes the correct answer id', () {
    final result = AnswerResult.fromJson(
      {
        'is_correct': false,
        'correct_answer_id': 31,
        'points_earned': 0,
        'xp_earned': 0,
      },
      fallbackQuestionId: 12,
      fallbackAnswerId: 30,
    );

    expect(result.answerId, 30);
    expect(result.correctAnswerId, 31);
    expect(result.isCorrect, isFalse);
  });
}
