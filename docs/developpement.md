# Développement

## Prérequis

- Flutter 3.47 (canal stable) et son Dart.
- JDK 17 (Eclipse Adoptium installé sur le PC actuel).
- Android SDK avec `platform-tools` (adb).
- Un téléphone Android en mode développeur, ou un émulateur.

```bash
flutter pub get
```

## Lancer sur un téléphone

### Par Wi-Fi (recommandé)

Sur le téléphone de test (Samsung SM-A176B), la liaison USB décroche pendant
l'envoi de l'APK (environ 136 Mo en debug). `flutter run` échoue alors avec
`adb.exe: failed to install … :` sans raison. Le Wi-Fi n'a pas ce problème.

Une fois, câble branché :

```bash
adb tcpip 5555
adb shell ip -f inet addr show wlan0     # repérer l'IP du téléphone
adb connect <ip-du-téléphone>:5555
```

Ensuite, à chaque session :

```bash
flutter run -d <ip-du-téléphone>:5555
```

Précisez toujours `-d` : si le câble est aussi branché, Flutter peut choisir
l'USB et échouer.

- Le PC et le téléphone doivent être sur le même réseau.
- Le mode Wi-Fi se désactive au redémarrage du téléphone : refaire
  `adb tcpip 5555` avec le câble.
- Activer *Options de développement › Rester activé* évite que la veille coupe
  la connexion. Si elle est coupée alors que l'app tourne encore :
  `adb connect <ip>:5555` puis `flutter attach -d <ip>:5555`.
- Le débogage Wi-Fi reste ouvert sur le réseau local jusqu'au redémarrage :
  éviter de le laisser actif sur un Wi-Fi public.

### Rechargement à chaud

Dans le terminal de `flutter run` :

| Touche | Effet | Quand |
|---|---|---|
| `r` | Hot reload, garde l'état | Modification de l'affichage (`build`, styles, textes) |
| `R` | Hot restart, repart de zéro | `initState`, `main.dart`, routes, variables globales, `enum` |
| `q` | Quitter | |

Relancer complètement `flutter run` après une modification de `pubspec.yaml`
(packages, assets), des fichiers Android ou d'une option `--dart-define`.

Dans VS Code : choisir l'appareil en bas à droite, F5 pour lancer, **Ctrl+S**
recharge à chaud, **Ctrl+Shift+F5** redémarre.

## Tests et qualité

```bash
flutter test            # tests unitaires (dossier test/)
flutter analyze         # analyse statique (flutter_lints)
dart format lib test    # mise en forme
```

| Fichier de test | Ce qui est vérifié |
|---|---|
| `test/features/quiz/question_payload_test.dart` | Lecture des questions d'un défi (`data.questions`) |
| `test/features/quiz/score_calculator_test.dart` | Bonne réponse ou non, comptage des bonnes réponses, points hors ligne |
| `test/features/result/result_score_test.dart` | Lecture des chiffres du résultat (texte, décimaux, champs manquants) |
| `test/features/result/result_outcome_test.dart` | Paliers parfait / victoire / moyen / défaite et nombre d'étoiles |

Il n'y a pas de test d'écran (widget test) ni de test d'intégration.
`flutter analyze` signale aujourd'hui une trentaine d'avertissements de style
déjà présents (dont `withOpacity` déprécié et des imports inutilisés), aucune
erreur.

## Configuration

Deux valeurs se règlent à la compilation avec `--dart-define` :

| Variable | Défaut | Rôle |
|---|---|---|
| `API_BASE_URL` | `https://laravelquizz.studiobeyam.net` | Serveur Laravel (sans `/api`) |
| `GOOGLE_WEB_CLIENT_ID` | `121288560456-jj4rih1vl48d655tklm6n30o0g17d5f7.apps.googleusercontent.com` | Client OAuth Web pour Google Sign-In |

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

## Google Sign-In

Projet Google Cloud : `advance-copilot-512410-f6`.

| Client OAuth | ID | Rôle |
|---|---|---|
| Web | `121288560456-jj4rih1v…` | `serverClientId` ; le backend vérifie que l'`idToken` lui est destiné |
| Android | `121288560456-683m9oc5…` | Autorise l'app Android signée avec la clé de debug du PC |
| Android (à créer) | « IvoireQuiz upload », « IvoireQuiz Play » | Autorisent la version signée avec la clé de publication et celle re-signée par Google Play |

- **Jamais de secret client OAuth dans l'app.** Seuls les ID clients (publics)
  y figurent. Les fichiers `client_secret_*.json` restent hors du dépôt.
- Chaque client Android déclare le package `net.studiobeyam.ivoirequiz` et
  **un seul** SHA-1 : il faut donc un client par certificat qui signe l'app
  (clé de debug de chaque PC, clé de publication, clé Google Play). Sinon
  Google répond `sign_in_failed` / `ApiException: 10`.
- Clé de debug du PC actuel :
  `C5:ED:A2:5E:0F:EF:C3:CD:27:49:85:26:57:E7:D7:BF:6B:15:96:DD`.
- Clé de publication (`C:/Users/Lenovo/cles/ivoirequiz-upload.jks`, alias
  `upload`) : `FA:C6:4A:39:AD:B8:26:DA:3B:AC:A8:5A:61:59:86:FC:58:CB:96:55`.
- Pour lire une empreinte : `cd android && ./gradlew signingReport`, ou
  `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`.
- iOS n'est pas configuré : il manque le client OAuth iOS
  (`com.example.ivoireQuizz`), le `GoogleService-Info.plist` et le schéma d'URL.

## Compiler

```bash
flutter build apk --debug --target-platform android-arm64   # APK de test
flutter build appbundle                                       # pour le Play Store
```

Installer un APK sur le téléphone en Wi-Fi :

```bash
adb -s <ip>:5555 install -t -r build/app/outputs/flutter-apk/app-debug.apk
```

### Signer la version de publication

`android/app/build.gradle.kts` lit la clé de publication dans
`android/key.properties`. Sans ce fichier, la release est signée avec la clé
de **debug** : elle s'installe sur un téléphone, mais le Play Store la refuse.

1. Créer la clé **une seule fois**, hors du dépôt, et la sauvegarder ailleurs
   (clé USB, gestionnaire de mots de passe) avec ses mots de passe :

   ```bash
   keytool -genkeypair -v -keystore C:/Users/Lenovo/cles/ivoirequiz-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Créer `android/key.properties` (ignoré par git, comme les `*.jks`) :

   ```properties
   storePassword=<mot de passe du keystore>
   keyPassword=<mot de passe de la clé>
   keyAlias=upload
   storeFile=C:/Users/Lenovo/cles/ivoirequiz-upload.jks
   ```

3. `flutter build appbundle`, puis envoyer
   `build/app/outputs/bundle/release/app-release.aab` dans la Play Console.
4. **Google Sign-In** : créer un client OAuth Android pour le SHA-1 de cette
   clé (`keytool -list -v -keystore <fichier .jks> -alias upload`) **et** un
   autre pour celui de la clé de signature Google Play (*Play Console › Tester
   et publier › Intégrité de l'application*). Le Play Store re-signe l'app avec
   sa propre clé : sans ce second client, la connexion Google échoue pour tous
   les joueurs qui installent depuis le Store.

Avec la signature d'application Play, une clé d'envoi perdue peut être
réinitialisée par le support Google, mais cela prend plusieurs jours.

### Avant une publication

- **Identifiant** : `net.studiobeyam.ivoirequiz` (`applicationId` et
  `namespace` dans `android/app/build.gradle.kts`). Il ne pourra plus changer
  après la première publication. `google-services.json` doit contenir une app
  Firebase avec ce même package, sinon la compilation échoue.
- **Nom affiché** : `android:label` dans `AndroidManifest.xml` (« IvoireQuiz »).
- **Version** : `version:` dans `pubspec.yaml` (`1.0.0+1`). Augmenter le
  nombre après `+` à chaque envoi sur le Play Store.
- **Journaux** : `debugPrint` est désactivé en release (`main.dart`).
- **HTTP en clair** : autorisé uniquement en debug
  (`android/app/src/debug/AndroidManifest.xml`), pour un serveur local.

### Avertissements de compilation

Flutter prévient que le support d'**Android Gradle Plugin 8.11.1** et de
**Kotlin 2.2.20** va bientôt s'arrêter. Il faudra passer à AGP ≥ 9.0.1 et
Kotlin ≥ 2.3.20 dans `android/settings.gradle.kts`.

## Icône et images

- Icône de l'app : générée par `flutter_launcher_icons` depuis
  `assets/icon/app_icon.png` (calque adaptatif
  `assets/icon/app_icon_foreground.png` sur fond blanc) :
  `dart run flutter_launcher_icons`.
- Mascotte : les PNG d'origine de `assets/` ont un **damier imprimé dans
  l'image** (faux fond transparent). Les versions de `assets/mascot/` sont
  détourées et réduites (`effobi_victoire`, `effobi_defaite`,
  `effobi_reflechit`). Toute nouvelle pose doit être détourée de la même façon
  avant d'être utilisée, sinon le damier s'affiche.
- Seuls les fichiers listés dans `pubspec.yaml` sont inclus dans l'APK :
  `avecfodn.jpeg`, `morel1.png`, `audio/` et `mascot/`. Une nouvelle image
  posée à la racine de `assets/` doit y être ajoutée, sinon `Image.asset`
  échoue à l'exécution.

## Audio

Les fichiers WAV originaux de l'application sont dans `assets/audio/` :

- `background.wav` : thème « quiz télé moderne » de 27,7 secondes, à 104 BPM,
  joué en boucle ;
- `correct.wav` et `incorrect.wav` : retour immédiat sur une réponse ;
- `victory.wav` et `defeat.wav` : arrivée sur l'écran de résultat.

Ils sont lus avec `audioplayers`. Pour remplacer un son, garder le même nom ou
mettre à jour `GameSound` dans
[`app_audio_controller.dart`](../lib/core/audio/app_audio_controller.dart), puis
faire un redémarrage complet de l'application : le hot reload ne recharge pas
toujours les assets.

Tous les sons actuels sont générés localement et reproductibles avec
`dart run tool/generate_quiz_audio.dart`. Aucun fichier tiers n'est redistribué
dans l'APK. Pixabay et SoundDino ont servi de références de recherche ; la
licence Pixabay autorise l'intégration de ses contenus dans une œuvre plus
large, mais le téléchargement automatisé de la piste envisagée était bloqué.

## Git

- `main` est la branche de référence ; le travail se fait sur des branches puis
  par Pull Request (historique : branches `codex/…`).
- **Ne pas faire `git reset --hard origin/main` avec du travail non poussé** :
  c'est ainsi que le mode Campagne a été effacé une première fois
  (27/10/2026), puis restauré depuis une branche.
- Après `flutter pub get`, vérifier les fichiers de plugins générés
  (`linux/flutter/…`, `macos/Flutter/…`, `windows/flutter/…`). Les changements
  qui enregistrent réellement un nouveau plugin — actuellement
  `audioplayers` — font partie de la fonctionnalité et doivent être conservés ;
  les différences limitées aux fins de ligne peuvent être ignorées.
