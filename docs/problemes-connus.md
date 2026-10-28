# Problèmes connus

État au 28 octobre 2026.

## Bugs ouverts

### Parties de moins de 10 questions refusées

**Côté backend.** Quand une catégorie compte moins de 10 questions actives,
`GET /quiz/questions` en sert moins (3, 5, 8…), mais `POST /sessions` répond
**422** à l'envoi de la partie. La partie de 10 questions passe, les autres
sont refusées : la règle de validation exige vraisemblablement 10 réponses (le
message exact du serveur n'a pas encore été relevé).

- **Effet** : pas de résultat, pas de points, pas d'entrée au classement.
  Depuis le 28/10, l'app affiche le message du serveur avec « Réessayer la fin
  de partie » au lieu de rester bloquée en silence.
- **Correction** : dans Laravel, valider que le nombre de réponses correspond
  aux questions servies (au lieu de 10), ou garantir au moins 10 questions
  actives par catégorie.
- **Effet secondaire** : la partie refusée reste sauvegardée, et « Reprendre ma
  partie » la renvoie, refusée à nouveau, tant que le serveur n'est pas corrigé.

### Le temps par question choisi est ignoré

L'écran d'avant-partie propose 10, 15, 20 ou 30 s, mais `_startTimer`
([`quiz_screen.dart`](../lib/features/quiz/screens/quiz_screen.dart)) remet
toujours 20 s hors Campagne.

### Toutes les questions affichent « Facile »

L'API envoie `difficulty` en texte (`"easy"`, `"medium"`…), alors que l'app
attend un nombre (1, 2, 3) : la valeur retombe sur 1, donc « Facile ».

### Détail des réponses vide après un niveau de Campagne

Après un niveau, l'écran de résultat reçoit les réponses locales (identifiants
seulement) : les questions s'affichent vides avec « Pas de réponse ».

### Petits défauts

- « Voir le détail » d'une ancienne partie rejoue les animations et les
  vibrations de victoire ou de défaite.
- `/auth?mode=login` : le paramètre est ignoré ; l'écran de connexion s'ouvre
  toujours sur l'onglet « Connexion », même après « Commencer » (nouveau
  joueur).

## Sécurité

- **Bonnes réponses visibles** : `GET /quiz/questions` envoie `is_correct` pour
  chaque option, pour que l'app corrige instantanément. Un joueur peut les lire
  et tricher. Le serveur recalcule bien les points, mais ne peut pas empêcher
  ce type de triche. Le mode Campagne, qui fait valider chaque réponse par le
  serveur, n'a pas ce problème.
- **Jeton dans les journaux (corrigé le 28/10)** : l'écran de quiz écrivait le
  jeton Bearer en clair (`TOKEN: …`). Révoquer côté serveur les jetons émis
  avant cette date.
- **Journaux en production** : `debugPrint` reste actif dans les versions
  release. L'app y écrit encore les questions reçues, avec leurs bonnes
  réponses (`DATA: …`), et les réponses du serveur.
- **HTTP en clair autorisé** : `android:usesCleartextTraffic="true"` dans
  `AndroidManifest.xml`. L'API de production est en HTTPS : limiter cette
  option au debug.
- **Version release signée avec la clé de debug** : voir
  [Développement › Avant une publication](developpement.md#avant-une-publication).

## Dette technique

- **Code mort** :
  - `lib/features/quiz/screens/result_screen.dart`, ancien écran de résultat,
    remplacé par `lib/features/result/screens/result_screen.dart` ;
  - `lib/core/network/dio_client.dart`, client Dio jamais utilisé ;
  - dossiers vides `core/models`, `core/repositories`, `features/quiz/providers`.
- **Dépendances inutilisées** : `riverpod_annotation`, `lottie`,
  `percent_indicator`, `fluttertoast`, `intl`, `equatable`,
  `freezed_annotation`, `json_annotation`, `vibration`. En développement :
  `riverpod_generator`, `freezed`, `json_serializable`, `build_runner`.
- **Images inutilisées incluses dans l'APK (~15 Mo)** : la vidéo
  `WhatsApp Video 2026-04-07 at 14.36.53.mp4`, les PNG d'origine de la mascotte
  (`effobi *.png`, `Effobi *.png`), `ivoire Quizz.png`, `kwame.png`. Le dossier
  `assets/` est déclaré en entier dans `pubspec.yaml`.
- **Pas de modèles typés** : tout passe en `Map<String, dynamic>`, et la lecture
  défensive des réponses est recopiée d'un écran à l'autre (`_normalizeMap`,
  `_extractName`… dans Amis et Classement).
- **Couleurs** redéclarées dans chaque écran au lieu d'utiliser `AppColors`.
- **`withOpacity` déprécié** : à remplacer par `withValues(alpha: …)`.
- **Tests** : uniquement des tests unitaires ; aucun test d'écran ni
  d'intégration.
- **Outils Android** : AGP 8.11.1 et Kotlin 2.2.20 bientôt plus supportés par
  Flutter (voir [Développement](developpement.md#avertissements-de-compilation)).
