import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/features/quiz/utils/logo_mode.dart';

void main() {
  test('puts the logo category first so the home screen shows it', () {
    final categories = withLogosFirst(<Map<String, dynamic>>[
      <String, dynamic>{'id': 1, 'slug': 'histoire', 'questions_count': 40},
      <String, dynamic>{'id': 2, 'slug': 'geographie', 'questions_count': 30},
      <String, dynamic>{'id': 3, 'slug': 'logos', 'questions_count': 25},
    ]);

    expect(categories.map((category) => category['id']), <int>[3, 1, 2]);
  });

  test('hides the logo category until a logo is published', () {
    final categories = withLogosFirst(<Map<String, dynamic>>[
      <String, dynamic>{'id': 1, 'slug': 'histoire', 'questions_count': 40},
      <String, dynamic>{'id': 3, 'slug': 'logos', 'questions_count': 0},
    ]);

    expect(categories.map((category) => category['id']), <int>[1]);
  });

  test('recognises the logo category by its slug', () {
    expect(isLogoCategory(<String, dynamic>{'slug': 'logos'}), isTrue);
    expect(isLogoCategory(<String, dynamic>{'slug': 'histoire'}), isFalse);
    expect(isLogoCategory(<String, dynamic>{'name': 'Logos'}), isFalse);
  });
}
