import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/quiz/utils/question_payload.dart';

void main() {
  test('reads challenge questions from the Laravel data.questions payload', () {
    final questions = extractQuestionPayload(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'code': 'AB12CD34',
        'status': 'pending',
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{'id': 17, 'question_text': 'Question du défi'},
        ],
      },
    });

    expect(questions, hasLength(1));
    expect(questions.single['id'], 17);
  });

  test('reads difficulty sent as text by the API', () {
    expect(parseDifficulty('easy'), 1);
    expect(parseDifficulty('medium'), 2);
    expect(parseDifficulty(' Hard '), 3);
  });

  test('keeps numeric difficulty and rejects unknown values', () {
    expect(parseDifficulty(2), 2);
    expect(parseDifficulty('3'), 3);
    expect(parseDifficulty('expert'), isNull);
    expect(parseDifficulty(null), isNull);
  });

  test('reads the image URL of a logo question', () {
    expect(
      questionImageUrl(<String, dynamic>{
        'image_url': ' https://api.example.ci/storage/questions/logo.png ',
      }),
      'https://api.example.ci/storage/questions/logo.png',
    );
  });

  test('ignores missing or non-web image URLs', () {
    expect(questionImageUrl(<String, dynamic>{}), isNull);
    expect(questionImageUrl(<String, dynamic>{'image_url': null}), isNull);
    expect(questionImageUrl(<String, dynamic>{'image_url': ''}), isNull);
    expect(
      questionImageUrl(<String, dynamic>{'image_url': 'questions/logo.png'}),
      isNull,
    );
  });
}
