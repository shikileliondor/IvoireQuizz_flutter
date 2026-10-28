import 'package:flutter_test/flutter_test.dart';
import 'package:ivoire_quiz/core/audio/app_audio_controller.dart';
import 'package:ivoire_quiz/core/audio/audio_preferences.dart';

void main() {
  group('AudioPreferences', () {
    test('active la musique et les effets par défaut', () {
      const preferences = AudioPreferences.defaults();

      expect(preferences.musicEnabled, isTrue);
      expect(preferences.effectsEnabled, isTrue);
    });

    test('lit les deux réglages persistés indépendamment', () {
      final preferences = AudioPreferences.fromMap(<String, Object?>{
        AudioPreferences.musicKey: false,
        AudioPreferences.effectsKey: true,
      });

      expect(preferences.musicEnabled, isFalse);
      expect(preferences.effectsEnabled, isTrue);
    });

    test('revient aux valeurs par défaut pour des valeurs invalides', () {
      final preferences = AudioPreferences.fromMap(<String, Object?>{
        AudioPreferences.musicKey: 'non',
        AudioPreferences.effectsKey: 0,
      });

      expect(preferences, const AudioPreferences.defaults());
    });
  });

  group('GameSound', () {
    test('associe une réponse correcte et incorrecte à leur effet', () {
      expect(GameSound.forAnswer(isCorrect: true), GameSound.correct);
      expect(GameSound.forAnswer(isCorrect: false), GameSound.incorrect);
    });

    test('associe le résultat à la victoire ou à la défaite', () {
      expect(GameSound.forResult(celebrates: true), GameSound.victory);
      expect(GameSound.forResult(celebrates: false), GameSound.defeat);
    });
  });
}
