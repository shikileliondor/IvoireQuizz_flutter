# Problèmes connus

État au 4 novembre 2026.

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
- **Clé de publication pas encore créée** : la configuration est prête, mais
  tant que `android/key.properties` n'existe pas, la release est signée avec
  la clé de debug. Voir
  [Développement › Signer la version de publication](developpement.md#signer-la-version-de-publication).

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
- **Fichiers d'origine dans `assets/`** : la vidéo WhatsApp, les PNG d'origine
  de la mascotte (`effobi *.png`, `Effobi *.png`) et `ivoire Quizz.png` restent
  dans le dossier mais ne sont plus inclus dans l'APK : `pubspec.yaml` liste
  maintenant les fichiers utilisés un par un. Penser à y ajouter toute nouvelle
  image placée à la racine de `assets/`.
- **Pas de modèles typés** : tout passe en `Map<String, dynamic>`, et la lecture
  défensive des réponses est recopiée d'un écran à l'autre (`_normalizeMap`,
  `_extractName`… dans Amis et Classement).
- **Couleurs** redéclarées dans chaque écran au lieu d'utiliser `AppColors`.
- **`withOpacity` déprécié** : à remplacer par `withValues(alpha: …)`.
- **Tests** : uniquement des tests unitaires ; aucun test d'écran ni
  d'intégration.
- **Outils Android** : AGP 8.11.1 et Kotlin 2.2.20 bientôt plus supportés par
  Flutter (voir [Développement](developpement.md#avertissements-de-compilation)).
