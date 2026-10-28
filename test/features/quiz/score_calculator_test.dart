import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/quiz/utils/score_calculator.dart';

Map<String, dynamic> question(int id, {required int correctOptionId}) =>
    <String, dynamic>{
      'id': id,
      'question_text': 'Question $id',
      'options': <Map<String, dynamic>>[
        for (var option = 1; option <= 4; option++)
          <String, dynamic>{
            'id': id * 10 + option,
            'option_text': 'Option $option',
            'is_correct': id * 10 + option == correctOptionId,
          },
      ],
    };

Map<String, dynamic> answer(int questionId, int? optionId) => <String, dynamic>{
      'question_id': questionId,
      'selected_option_id': optionId,
      'response_time_seconds': 5,
    };

void main() {
  final questions = <Map<String, dynamic>>[
    question(1, correctOptionId: 12),
    question(2, correctOptionId: 21),
    question(3, correctOptionId: 34),
  ];

  group('isCorrectOption', () {
    test('reconnaît la bonne option', () {
      expect(isCorrectOption(questions[0], 12), isTrue);
    });

    test('refuse une mauvaise option', () {
      expect(isCorrectOption(questions[0], 11), isFalse);
    });

    test('compte faux quand le temps est écoulé (aucune réponse)', () {
      expect(isCorrectOption(questions[0], null), isFalse);
    });

    test('refuse une option qui n’appartient pas à la question', () {
      expect(isCorrectOption(questions[0], 21), isFalse);
    });

    test('refuse une question sans options', () {
      expect(isCorrectOption(<String, dynamic>{'id': 9}, 1), isFalse);
    });

    test('accepte un id d’option reçu en texte', () {
      final fromCache = <String, dynamic>{
        'id': 1,
        'options': <Map<String, dynamic>>[
          <String, dynamic>{'id': '12', 'is_correct': true},
        ],
      };
      expect(isCorrectOption(fromCache, 12), isTrue);
    });
  });

  group('countCorrectAnswers', () {
    test('compte les bonnes réponses d’une partie', () {
      final answers = [answer(1, 12), answer(2, 22), answer(3, 34)];
      expect(countCorrectAnswers(questions, answers), 2);
    });

    test('vaut 0 quand toutes les réponses sont fausses ou absentes', () {
      final answers = [answer(1, 11), answer(2, null), answer(3, 31)];
      expect(countCorrectAnswers(questions, answers), 0);
    });

    test('vaut le nombre de questions quand tout est juste', () {
      final answers = [answer(1, 12), answer(2, 21), answer(3, 34)];
      expect(countCorrectAnswers(questions, answers), 3);
    });

    test('ignore une réponse à une question inconnue au lieu de planter', () {
      final answers = [answer(1, 12), answer(99, 991)];
      expect(countCorrectAnswers(questions, answers), 1);
    });

    test('ne compte une question qu’une fois, avec la dernière réponse', () {
      final answers = [answer(1, 12), answer(1, 12), answer(2, 21)];
      expect(countCorrectAnswers(questions, answers), 2);

      final changedMind = [answer(1, 12), answer(1, 11)];
      expect(countCorrectAnswers(questions, changedMind), 0);
    });

    test('ne dépasse jamais le nombre de questions', () {
      final answers = [
        for (var i = 0; i < 5; i++) ...[
          answer(1, 12),
          answer(2, 21),
          answer(3, 34),
        ],
      ];
      expect(countCorrectAnswers(questions, answers), questions.length);
    });

    test('vaut 0 sans aucune réponse', () {
      expect(countCorrectAnswers(questions, const []), 0);
    });
  });

  test('une partie hors ligne rapporte 100 points par bonne réponse', () {
    final answers = [answer(1, 12), answer(2, 21), answer(3, 31)];
    final correct = countCorrectAnswers(questions, answers);
    expect(correct * offlinePointsPerCorrectAnswer, 200);
  });
}
