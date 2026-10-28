import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/result/models/result_score.dart';
import 'package:ivoire_quiz/features/result/widgets/result_celebration.dart';

void main() {
  group('parseScoreValue', () {
    test('lit un entier, un décimal ou un texte', () {
      expect(parseScoreValue(850), 850);
      expect(parseScoreValue(7.0), 7);
      expect(parseScoreValue(7.6), 8);
      expect(parseScoreValue('850'), 850);
      expect(parseScoreValue(' 42 '), 42);
      expect(parseScoreValue('12.50'), 13);
    });

    test('renvoie null pour une valeur absente ou illisible', () {
      expect(parseScoreValue(null), isNull);
      expect(parseScoreValue(''), isNull);
      expect(parseScoreValue('abc'), isNull);
      expect(parseScoreValue(<String, dynamic>{}), isNull);
    });
  });

  group('ResultScore.fromResultData', () {
    test('session en ligne : reprend les chiffres du serveur', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'correct_answers': 7,
        'total_questions': 10,
        'score': 700,
        'bonus_score': 150,
        'total_score': 850,
      });

      expect(score.correctAnswers, 7);
      expect(score.totalQuestions, 10);
      expect(score.baseScore, 700);
      expect(score.bonusScore, 150);
      expect(score.totalScore, 850);
    });

    test('accepte des nombres envoyés en texte ou en décimal', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'correct_answers': '7',
        'total_questions': 10.0,
        'score': '700',
        'bonus_score': '150',
        'total_score': '850',
      });

      expect(score.correctAnswers, 7);
      expect(score.totalQuestions, 10);
      expect(score.baseScore, 700);
      expect(score.bonusScore, 150);
      expect(score.totalScore, 850);
    });

    test('partie hors ligne : le score de base vaut le total, pas 0', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'correct_answers': 3,
        'total_questions': 10,
        'total_score': 300,
        'offline': true,
      });

      expect(score.totalScore, 300);
      expect(score.bonusScore, 0);
      expect(score.baseScore, 300);
    });

    test('défi : seul le total est connu', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'correct_answers': 8,
        'total_questions': 10,
        'total_score': 920,
        'challenge_code': 'AB12CD34',
      });

      expect(score.baseScore, 920);
      expect(score.totalScore, 920);
    });

    test('campagne : score et total identiques, sans bonus', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'mode': 'campaign',
        'correct_answers': 4,
        'total_questions': 5,
        'score': 450,
        'total_score': 450,
      });

      expect(score.baseScore, 450);
      expect(score.bonusScore, 0);
      expect(score.totalScore, 450);
      expect(
        ResultOutcome.fromScore(score.correctAnswers, score.totalQuestions),
        ResultOutcome.victory,
      );
    });

    test('sans total, additionne score de base et bonus', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'correct_answers': 6,
        'total_questions': 10,
        'score': 600,
        'bonus_score': 90,
      });

      expect(score.totalScore, 690);
    });

    test('le score de base ne devient jamais négatif', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'total_score': 50,
        'bonus_score': 80,
      });

      expect(score.baseScore, 0);
    });

    test('sans nombre de questions, utilise le nombre de réponses', () {
      final score = ResultScore.fromResultData(<String, dynamic>{
        'correct_answers': 2,
        'answers': <Map<String, dynamic>>[{}, {}, {}, {}, {}],
      });

      expect(score.totalQuestions, 5);
    });

    test('sans aucune information, retombe sur 0 / 10 et 0 point', () {
      final score = ResultScore.fromResultData(<String, dynamic>{});

      expect(score.correctAnswers, 0);
      expect(score.totalQuestions, 10);
      expect(score.totalScore, 0);
      expect(score.baseScore, 0);
      expect(score.bonusScore, 0);
    });

    test('borne les bonnes réponses entre 0 et le nombre de questions', () {
      expect(
        ResultScore.fromResultData(<String, dynamic>{
          'correct_answers': 12,
          'total_questions': 10,
        }).correctAnswers,
        10,
      );
      expect(
        ResultScore.fromResultData(<String, dynamic>{
          'correct_answers': -1,
          'total_questions': 10,
        }).correctAnswers,
        0,
      );
    });
  });
}
