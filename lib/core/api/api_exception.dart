class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException(
    this.message, {
    this.statusCode,
    this.errors,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;
  bool get isRateLimit => statusCode == 429;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  String get userMessage {
    if (isUnauthorized) return 'Session expirée. Veuillez vous reconnecter.';
    if (isForbidden) return 'Accès refusé.';
    if (isNotFound) return 'Ressource introuvable.';
    if (isRateLimit) return 'Trop de tentatives. Réessayez plus tard.';
    if (isServerError) return 'Erreur serveur. Réessayez dans un moment.';
    return message.isNotEmpty ? message : 'Une erreur est survenue.';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
