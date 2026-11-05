import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_response.dart';
import '../models/quiz_models.dart';

class QuizApi {
  const QuizApi(this._client);
  final ApiClient _client;

  Future<({QuizSession session, List<QuizQuestion> questions})> startSession(
    int levelId,
  ) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/levels/$levelId/start',
      data: {'mode': 'level'},
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    if (!api.success) {
      throw ApiException(
        api.message.isEmpty ? 'Impossible de démarrer ce niveau.' : api.message,
      );
    }
    final data = api.data;
    if (data == null) {
      throw const ApiException(
        'Le serveur n’a retourné aucune donnée pour ce niveau.',
      );
    }

    // Le backend historique a utilisé `session`, `game_session`, puis parfois
    // directement l'objet session dans `data`. Cette lecture tolérante permet
    // une migration sans faire planter l'application.
    final sessionData = _asMap(data['session']) ??
        _asMap(data['game_session']) ??
        (data.containsKey('id') ? data : null);
    if (sessionData == null) {
      throw const ApiException(
        'La session de jeu est absente de la réponse du serveur.',
      );
    }

    final rawQ = _asList(data['questions']) ??
        _asList(sessionData['questions']) ??
        const <dynamic>[];
    if (rawQ.isEmpty) {
      throw const ApiException(
        'Aucune question n’est disponible pour ce niveau.',
      );
    }

    final session = QuizSession.fromJson(sessionData);
    final questions = rawQ
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestion.fromJson)
        .toList();

    if (questions.isEmpty) {
      throw const ApiException(
        'Les questions reçues du serveur sont invalides.',
      );
    }

    return (session: session, questions: questions);
  }

  Future<AnswerResult> submitAnswer({
    required int sessionId,
    required int questionId,
    required int? answerId,
    required int responseTime,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/game-sessions/$sessionId/answer',
      data: {
        'question_id': questionId,
        'answer_id': answerId,
        'response_time': responseTime,
      },
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    final data = api.data;
    if (data == null) {
      throw const ApiException('Le résultat de la réponse est absent.');
    }
    return AnswerResult.fromJson(
      data,
      fallbackQuestionId: questionId,
      fallbackAnswerId: answerId,
    );
  }

  Future<Map<String, dynamic>> finishSession(int sessionId) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/game-sessions/$sessionId/finish',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    return api.data ?? {};
  }

  Future<void> abandonSession(int sessionId) async {
    await _client.post<void>('/game-sessions/$sessionId/abandon');
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is! Map) return null;
  return Map<String, dynamic>.from(value);
}

List<dynamic>? _asList(dynamic value) => value is List ? value : null;

final quizApiProvider = Provider<QuizApi>(
  (ref) => QuizApi(ref.watch(apiClientProvider)),
);
