import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/result/widgets/result_celebration.dart';

void main() {
  test('classe le score en parfait, victoire, moyen ou défaite', () {
    expect(ResultOutcome.fromScore(10, 10), ResultOutcome.perfect);
    expect(ResultOutcome.fromScore(7, 10), ResultOutcome.victory);
    expect(ResultOutcome.fromScore(4, 10), ResultOutcome.average);
    expect(ResultOutcome.fromScore(3, 10), ResultOutcome.defeat);
    expect(ResultOutcome.fromScore(0, 0), ResultOutcome.defeat);
  });

  test('suit le ratio quand une partie n’a pas 10 questions', () {
    expect(ResultOutcome.fromScore(5, 5), ResultOutcome.perfect);
    expect(ResultOutcome.fromScore(4, 5), ResultOutcome.victory);
    expect(ResultOutcome.fromScore(1, 5), ResultOutcome.defeat);
  });

  test('donne de 0 à 3 étoiles', () {
    expect(resultStars(10, 10), 3);
    expect(resultStars(9, 10), 3);
    expect(resultStars(7, 10), 2);
    expect(resultStars(4, 10), 1);
    expect(resultStars(3, 10), 0);
  });
}
