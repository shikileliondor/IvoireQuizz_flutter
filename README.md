# ivoire_quizz

Application Flutter de quiz de culture générale ivoirienne.

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuration Google Sign-In

Le backend attend un `idToken` Google sur `POST /auth/google`. Pour que le
plugin `google_sign_in` puisse fournir ce jeton, lancez l'application avec l'ID
client **Web** OAuth 2.0 créé dans Google Cloud Console :

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID="VOTRE_ID_CLIENT_WEB.apps.googleusercontent.com"
```

Si la connexion échoue encore sur Android avec une erreur `sign_in_failed`,
vérifiez aussi dans Google Cloud/Firebase que :

- le nom du package Android correspond à `com.example.ivoire_quizz` ;
- les empreintes SHA-1 et SHA-256 de la clé utilisée pour lancer l'app sont
  bien enregistrées ;
- l'ID client Web ci-dessus appartient au même projet Google que le client
  Android.
