# Intégration Flutter — API IvoireQuiz V1

## Source de vérité

Flutter construit l’accueil uniquement avec `GET /api/v1/game/map`. Le serveur décide du monde courant, du prochain niveau, des verrouillages, des récompenses et de l’ordre du chemin.

Le client ne doit jamais proposer une navigation principale par ville, chapitre ou catégorie. Les chapitres sont uniquement des métadonnées éditoriales.

## Contrat de la carte

Le payload utile contient :

- `first_time_intro` : affiche l’introduction post-inscription ;
- `current_region` : monde visible et progression ;
- `next_playable_level` : unique source pour le prochain nœud ;
- `stats` : vies, streak, XP, pièces, gemmes et ligue ;
- `path_nodes` : nœuds triés par `order`.

Types acceptés : `level`, `review`, `chest`, `boss`, et `unknown` en tolérance future. Un coffre est visuel et ne démarre jamais une session. Un nœud inconnu reste non jouable.

## Premier lancement serveur

Si `first_time_intro` vaut `true`, afficher : bienvenue, carte nationale, puis introduction du `current_region`. À la fin :

```http
POST /api/v1/me/intro-seen
```

Recharger ensuite `/game/map`. Le stockage local n’est pas la source officielle de cet état.

## Session de jeu

```text
POST /levels/{levelId}/start
POST /game-sessions/{sessionId}/answer
POST /game-sessions/{sessionId}/finish
POST /game-sessions/{sessionId}/abandon
```

Flutter envoie uniquement `question_id`, `answer_id` et `response_time`. Il n’envoie jamais score, XP, pièces, gemmes, précision ou `is_correct`.

Les questions initiales ne doivent jamais contenir `is_correct`. Après `finish`, afficher le résultat serveur, invalider la carte et rappeler `/game/map`.

## Sécurité et erreurs

- Token Sanctum dans `flutter_secure_storage`.
- `401` : supprimer le token et retourner à la connexion.
- `422` : afficher le message métier sans simuler de progression.
- `429` : bloquer temporairement la nouvelle tentative.
- réseau/`500` : proposer de réessayer sans récompense locale.
- désactiver la réponse dès le premier tap pour éviter une double soumission.

## Implémentation actuelle

- `GameMapApi` décode l’enveloppe `ApiResponse<T>`.
- `GameMapNotifier` expose les états Riverpod et valide l’introduction.
- `GameMap` accepte les champs nulls et les types de nœuds inconnus.
- `GameMapScreen` ne calcule aucune règle de progression.
- `QuizNotifier` invalide la carte après une partie terminée.

