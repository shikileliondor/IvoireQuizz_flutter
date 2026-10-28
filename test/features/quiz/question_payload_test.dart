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
}
