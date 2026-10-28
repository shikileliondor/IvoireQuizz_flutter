import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/leaderboard/utils/leaderboard_score.dart';

void main() {
  test('lit le score de campagne du classement général', () {
    expect(
      leaderboardScore(<String, dynamic>{'campaign_score': '875'}),
      875,
    );
  });
}
