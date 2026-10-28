# Documentation IvoireQuizz

IvoireQuizz est une application mobile Flutter de quiz sur la culture
ivoirienne. Le joueur répond à des séries de questions par catégorie, en mode
mixte, aux questions du jour, en défi contre un ami ou en mode Campagne (une
carte de la Côte d'Ivoire à parcourir région par région). La mascotte est
**Effobi**, un éléphanteau coiffé d'un chapeau traditionnel.

L'application parle à une API Laravel :
`https://laravelquizz.studiobeyam.net/api`.

## Sommaire

| Document | Contenu |
|---|---|
| [Architecture](architecture.md) | Organisation du code, navigation, réseau, stockage local, thème |
| [Fonctionnalités](fonctionnalites.md) | Chaque écran et chaque mode de jeu, règles de score et animations |
| [API](api.md) | Tous les appels au backend, avec les données envoyées et lues |
| [Développement](developpement.md) | Installer, lancer sur un téléphone, tester, configurer, publier |
| [Problèmes connus](problemes-connus.md) | Bugs ouverts, dette technique, points de sécurité |

## Démarrage rapide

```bash
flutter pub get
flutter test
flutter run            # ou : flutter run -d <appareil>
```

Sur le téléphone de test (Samsung), passer par le Wi-Fi : voir
[Développement › Lancer sur un téléphone](developpement.md#lancer-sur-un-téléphone).

## Fiche technique

| | |
|---|---|
| Flutter / Dart | Flutter 3.47 (stable), Dart ≥ 3.0 |
| Nom du package Dart | `ivoire_quiz` |
| Identifiant Android | `com.example.ivoire_quizz` |
| Identifiant iOS | `com.example.ivoireQuizz` |
| Version | `1.0.0+1` (`pubspec.yaml`) |
| Plateformes visées | Android (principale), iOS (Google Sign-In non configuré) |
| Backend | Laravel, authentification par jeton Bearer (Sanctum) |
