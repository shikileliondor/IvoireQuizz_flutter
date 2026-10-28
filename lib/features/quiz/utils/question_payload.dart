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
