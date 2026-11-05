# Sécurité

## Principes

- Authentification par Laravel Sanctum.
- Routes gameplay protégées par `auth:sanctum`.
- Rate limiting sur auth, start game, answer, open chest et report question.
- Ownership checks sur sessions et coffres.
- Validation via FormRequests.
- Anti-triche côté services.
- Flutter n’est jamais une source fiable.

## Ne jamais faire confiance à Flutter

Flutter peut envoyer des actions utilisateur, pas des résultats financiers ou gameplay. Le backend doit refuser ou ignorer tout champ client qui prétend définir :

- score ;
- XP ;
- coins ;
- gems ;
- `is_correct` ;
- statut final ;
- progression ;
- classement.

## Protections implémentées ou attendues

- Impossible de répondre deux fois à une question grâce à `game_session_answers` et à l’index unique session/question.
- Impossible de finir une session déjà terminée : seul le statut `started` est jouable.
- Impossible d’ouvrir deux fois un coffre : statut `opened` bloquant et transaction verrouillée.
- Impossible de jouer un niveau verrouillé : vérification de progression avant démarrage.
- Impossible de jouer sans vie : vérification serveur via `LifeService`.
- Impossible d’accéder à la session d’un autre utilisateur : ownership dans `GameSessionService` et `AnswerQuestionService`.
- Impossible d’utiliser une question hors session : la question doit appartenir au niveau de la session.
- Impossible d’utiliser une réponse hors question : `answer.question_id` doit correspondre.

## Validation FormRequests

Les FormRequests doivent contrôler :

- types (`integer`, `string`, `nullable`) ;
- existence en base (`exists`) ;
- bornes (`response_time >= 0`) ;
- longueur de messages ;
- raisons de signalement autorisées.

Les erreurs de validation retournent le format JSON standard avec statut HTTP `422`.

## Rate limiting

Les routes sensibles utilisent des limiters dédiés :

- `throttle:auth` pour login/register ;
- `throttle:start-game` pour démarrer une session ;
- `throttle:quiz-answer` pour répondre ;
- `throttle:open-chest` pour ouvrir un coffre ;
- `throttle:report-question` pour signaler une question.

## Logs suspects

Les services doivent journaliser les événements anormaux :

- double réponse à une même question ;
- tentative d’ouverture de coffre déjà ouvert ;
- session invalide, expirée ou appartenant à un autre joueur ;
- question hors session ;
- réponse hors question ;
- réponse trop rapide ou temps invalide ;
- tentative de niveau verrouillé ;
- lancement sans vie.

## Réponses recommandées

- `401` : token absent ou invalide.
- `403` : action interdite ou ressource non propriétaire.
- `404` : ressource introuvable.
- `422` : payload invalide.
- `429` : rate limit atteint.
- `500` : erreur serveur non prévue.
