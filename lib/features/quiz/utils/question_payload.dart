List<dynamic> extractQuestionPayload(dynamic payload) {
  if (payload is List) return payload;
  if (payload is! Map) return const <dynamic>[];

  final dynamic data = payload['data'];
  if (data is List) return data;
  if (data is! Map) return const <dynamic>[];

  final dynamic questions = data['questions'];
  if (questions is List) return questions;

  final dynamic nestedData = data['data'];
  if (nestedData is List) return nestedData;
  return const <dynamic>[];
}

/// Niveau de difficulté : 1 (facile), 2 (moyen), 3 (difficile), ou `null`
/// si la valeur est inconnue. L'API envoie du texte (`"medium"`), d'anciennes
/// réponses un nombre.
int? parseDifficulty(dynamic value) {
  if (value is num) return value.toInt();
  final String text = value?.toString().trim().toLowerCase() ?? '';
  switch (text) {
    case 'easy':
    case 'facile':
      return 1;
    case 'medium':
    case 'moyen':
      return 2;
    case 'hard':
    case 'difficile':
      return 3;
  }
  return int.tryParse(text);
}

/// URL de l'image d'une question (un logo par exemple), ou `null` si elle
/// n'en a pas ou si l'URL n'est pas une adresse web.
String? questionImageUrl(Map<String, dynamic> question) {
  final String url = question['image_url']?.toString().trim() ?? '';
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return null;
  }
  return url;
}
