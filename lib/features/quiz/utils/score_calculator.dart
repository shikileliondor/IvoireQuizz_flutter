/// Calcul du score fait sur l'appareil, pour les parties hors ligne.
/// En ligne, c'est le serveur qui calcule les points.
const int offlinePointsPerCorrectAnswer = 100;

int? _asInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

/// Vrai si [optionId] désigne une option marquée correcte de [question].
/// Une absence de réponse (temps écoulé) n'est jamais correcte.
bool isCorrectOption(Map<String, dynamic> question, int? optionId) {
  if (optionId == null) return false;
  final dynamic options = question['options'];
  if (options is! List) return false;
  return options.whereType<Map>().any((option) =>
      _asInt(option['id']) == optionId && option['is_correct'] == true);
}

/// Nombre de bonnes réponses. Chaque question compte au plus une fois (la
/// dernière réponse donnée) et une réponse à une question inconnue est ignorée.
int countCorrectAnswers(
  List<Map<String, dynamic>> questions,
  List<Map<String, dynamic>> answers,
) {
  final Map<int?, int?> lastAnswerByQuestion = <int?, int?>{
    for (final answer in answers)
      _asInt(answer['question_id']): _asInt(answer['selected_option_id']),
  };
  return questions
      .where((question) =>
          lastAnswerByQuestion.containsKey(_asInt(question['id'])))
      .where((question) => isCorrectOption(
          question, lastAnswerByQuestion[_asInt(question['id'])]))
      .length;
}
