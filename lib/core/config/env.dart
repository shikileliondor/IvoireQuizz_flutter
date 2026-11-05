enum AppEnv { dev, prod }

/// Sélectionne l'environnement via --dart-define=ENV=dev|prod
/// Exemple : flutter run --dart-define=ENV=dev
final AppEnv currentEnv = _resolveEnv(const String.fromEnvironment('ENV', defaultValue: 'dev'));

AppEnv _resolveEnv(String value) {
  switch (value) {
    case 'prod':
      return AppEnv.prod;
    default:
      return AppEnv.dev;
  }
}
