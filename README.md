# Ivoire Quizz

Application Flutter de quiz de culture générale ivoirienne.

Documentation complète : [docs/](docs/README.md).

## Google Sign-In

Le backend attend un `idToken` Google sur `POST /api/v1/auth/google`. Le client
OAuth **Web** du même projet Google est transmis comme `serverClientId` afin que
`google_sign_in` retourne ce jeton. L'ID client Web du projet
(`121288560456-jj4rih1vl48d655tklm6n30o0g17d5f7.apps.googleusercontent.com`) est
la valeur par défaut dans `auth_screen.dart` ; `--dart-define` permet de le
remplacer.

### Android

Dans le projet Google Cloud du client Web, créez également un client OAuth de
type **Android** avec le package `net.studiobeyam.ivoirequiz` pour chaque
certificat qui signe l'app (un SHA-1 par client) : clé de debug, clé de
publication et clé de signature Google Play. Détails dans
[docs/developpement.md](docs/developpement.md#google-sign-in).

### iOS

L'identifiant de bundle configuré est `com.example.ivoireQuizz`. Créez un client
OAuth iOS pour cet identifiant dans le même projet Google. La configuration
présente n'inclut pas encore de `GoogleService-Info.plist` ni d'URL scheme
Google; ajoutez la configuration iOS fournie par Google/Firebase avant d'utiliser
Google Sign-In sur iOS.

### Lancement et build

```bash
flutter run
flutter build appbundle
# Pour utiliser un autre client Web (ID complet, suffixe compris) :
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID="123456789-abcdef.apps.googleusercontent.com"
```

`GOOGLE_WEB_CLIENT_ID` doit être l'ID du client **Web**, jamais celui du client
Android (`121288560456-683m9oc5…`). Avec l'ID Android, Google refuse la
connexion (`Invalid audience value` dans `adb logcat`, `sign_in_failed` dans
l'app). Sans `--dart-define`, le bon ID Web est utilisé.

L'ID client OAuth est un identifiant public. Ne mettez jamais de secret client
OAuth dans l'application. Le flux Flutter envoie l'ID token à l'API, qui le
valide côté serveur.

Si Android renvoie `sign_in_failed`, vérifiez le package et les empreintes
SHA-1/SHA-256 du certificat qui signe l'application installée dans le projet
Google associé au client Web. Pour le développement local, la clé debug peut
être inspectée avec `cd android && .\\gradlew signingReport`.
