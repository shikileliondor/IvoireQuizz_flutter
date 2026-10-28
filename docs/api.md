# API

Ce document décrit ce que **l'application envoie et lit**. Il n'a pas été écrit
à partir du code Laravel : il ne constitue donc pas un contrat exhaustif du
backend. Les formats de réponse marqués « observé » viennent de vraies réponses
du serveur de production (octobre 2026).

## Généralités

- **Base** : `<API_BASE_URL>/api`, soit `https://laravelquizz.studiobeyam.net/api`
  par défaut. Les chemins ci-dessous sont relatifs à cette base.
- **Authentification** : en-tête `Authorization: Bearer <auth_token>` sur tous
  les appels sauf inscription, connexion et Google.
- **Enveloppe** : `{ "success": bool, "data": ..., "message": "..." }`.
- **Erreurs** : la gestion de `401` varie selon l'écran ; certains suppriment le
  jeton et renvoient à la connexion, d'autres restent sur place. Une réponse
  `422` suit généralement la forme
  `{ "message": "...", "errors": { "champ": ["..."] } }`.

## Vue d'ensemble

| Méthode | Chemin | Utilisé par |
|---|---|---|
| POST | `/auth/register` | Inscription |
| POST | `/auth/login` | Connexion |
| POST | `/v1/auth/google` | Connexion Google |
| POST | `/auth/logout` | Profil |
| GET | `/auth/me` | Accueil, Classement |
| GET | `/v1/me` | Profil |
| GET | `/categories` | Accueil |
| GET | `/quiz/questions` | Quiz |
| POST | `/sessions` | Quiz (fin de partie) |
| GET | `/sessions` | Accueil (dernière partie), Profil (historique) |
| GET | `/profile/stats` | Profil |
| GET | `/achievements` | Profil |
| GET | `/friends` | Amis, Classement |
| GET | `/friends/requests` | Amis |
| POST | `/friends/add` | Amis |
| PUT | `/friends/{id}/accept` | Amis |
| DELETE | `/friends/{id}` | Amis (refuser / supprimer) |
| GET | `/friends/invite` | Profil (partage) |
| GET | `/leaderboard/global` | Classement |
| GET | `/leaderboard/weekly` | Classement |
| GET | `/leaderboard/friends` | Classement |
| POST | `/challenges` | Amis (créer un défi) |
| GET | `/challenges/{code}` | Quiz (défi), Résultat (suivi) |
| POST | `/challenges/{code}/submit` | Quiz (fin de défi) |
| GET | `/v1/game/map` | Campagne |
| GET | `/v1/levels/{id}` | Campagne (fiche du niveau) |
| POST | `/v1/levels/{id}/start` | Campagne |
| POST | `/v1/game-sessions/{id}/answer` | Quiz (Campagne) |
| POST | `/v1/game-sessions/{id}/finish` | Quiz (Campagne) |

## Authentification

### `POST /auth/register`

Envoi : `{ name, email, password, password_confirmation }`.
Succès attendu : **201**, jeton lu dans `data.token`.

### `POST /auth/login`

Envoi : `{ email, password }`. Succès attendu : **200**, jeton dans
`data.token`.

### `POST /v1/auth/google`

Envoi : `{ id_token }` (jeton d'identité Google obtenu avec l'ID client Web en
`serverClientId`). L'app exige **200**, `success: true`, `data.token` non vide et
`data.token_type` = `bearer` (casse ignorée).

### `POST /auth/logout`

Sans corps. Le jeton local est supprimé quelle que soit la réponse.

### `GET /auth/me` et `GET /v1/me`

L'utilisateur est lu dans `data.user`, ou directement dans `data`. Champs
utilisés : `id`, `name`, `email`, `total_score`, `friend_code`, `level`.

## Catégories et questions

### `GET /categories`

`data` : liste de catégories (`id`, `name`, plus icône et couleur si présentes).

### `GET /quiz/questions`

Paramètres : `mode` (`category`, `mixed` ou `daily`) et `category_id` en mode
catégorie.

Réponse observée :

```json
{
  "success": true,
  "data": [
    {
      "id": 65,
      "category_id": 8,
      "question_text": "Quelle association entre une culture et son produit est correcte ?",
      "difficulty": "medium",
      "explanation": "Les cabosses du cacaoyer contiennent les fèves…",
      "points": 15,
      "time_limit": 20,
      "options": [
        { "id": 253, "option_text": "Caféier — régimes de palme", "is_correct": false },
        { "id": 255, "option_text": "Cacaoyer — fèves de cacao", "is_correct": true }
      ]
    }
  ]
}
```

L'app accepte aussi la liste dans `data.questions` ou `data.data`
([`question_payload.dart`](../lib/features/quiz/utils/question_payload.dart)),
et des textes d'option dans `option_text`, `text` ou `label`. Le nombre de
questions renvoyé dépend de la catégorie : il peut être inférieur à 10.

## Parties

### `POST /sessions` (fin de partie)

Envoi :

```json
{
  "category_id": 8,
  "mode": "category",
  "duration_seconds": 38,
  "answers": [
    { "question_id": 6, "selected_option_id": 21, "response_time_seconds": 1 }
  ]
}
```

`selected_option_id` vaut `null` si le temps s'est écoulé.

Réponse observée (**201**) :

```json
{
  "success": true,
  "data": {
    "id": 6,
    "category": { "id": 8, "name": "Agriculture" },
    "mode": "category",
    "score": 65,
    "bonus_score": 0,
    "total_score": 65,
    "correct_answers": 3,
    "total_questions": 10,
    "duration_seconds": 38,
    "completed_at": "2026-10-28T10:48:23.000000Z",
    "answers": [
      {
        "question_id": 6,
        "selected_option_id": 21,
        "is_correct": false,
        "response_time_seconds": 1,
        "question": { "question_text": "…", "explanation": "…" },
        "selected_option": { "option_text": "…" },
        "correct_option": { "id": 22, "option_text": "Le coton" },
        "points_earned": 0
      }
    ]
  }
}
```

`data` est passé tel quel à l'écran de résultat.

> **Problème ouvert** : le serveur répond **422** quand la partie compte moins
> de 10 réponses, alors que `/quiz/questions` peut servir moins de 10 questions.
> Voir [Problèmes connus](problemes-connus.md#parties-de-moins-de-10-questions-refusées).

### `GET /sessions`

`data` : liste des parties, la plus récente en premier, au même format que
ci-dessus.

## Profil

- `GET /profile/stats` : statistiques du joueur ; la progression par catégorie
  est lue dans `data.by_category` (liste).
- `GET /achievements` : `data.badges` et `data.objectives`. Chaque objectif a
  un nom, une progression et une cible.
- `GET /friends/invite` : `data.message`, texte d'invitation prêt à partager.

## Amis

- `GET /friends` : liste d'amis. L'app cherche la liste dans `data`,
  `data.friends`, `friends`, `items`, `results` ou `users`.
- `GET /friends/requests` : demandes reçues, cherchées dans
  `received_requests`, `received`, `incoming_requests`, `incoming`, `requests`
  ou `friend_requests`.
- `POST /friends/add` : `{ friend_code }`, code mis en majuscules par l'app.
- `PUT /friends/{id}/accept` et `DELETE /friends/{id}` : sans corps.

Noms lus dans `name`, `username`, `full_name` ou `display_name`.

## Classements

- `GET /leaderboard/global?page=n` et `GET /leaderboard/weekly?page=n` :
  paginés ; le bouton « Charger plus de joueurs » demande la page suivante.
- `GET /leaderboard/friends` : si la liste est vide, l'app se rabat sur
  `GET /friends` et trie elle-même par score.

## Défis

### `POST /challenges`

Envoi : `{ opponent_id }`. Lu : `data.code` (8 caractères).

### `GET /challenges/{code}`

Questions du défi dans `data.questions` (format repris dans
`question_payload_test.dart`), ainsi que `code`, `status`, `challenger_score` et
`opponent_score`.

### `POST /challenges/{code}/submit`

Envoi : `{ answers: [{ question_id, answer_id, response_time }] }`.
Lu : `data.your_correct`, `data.your_score`, `data.status`,
`data.challenger_score`, `data.opponent_score`, `data.winner_id`.

Le défi est terminé quand `status` vaut `completed`.

## Campagne

### `GET /v1/game/map`

```
data
├── regions[]            id, name, is_unlocked, is_completed, progress_percent
│   └── cities[]         id, name, image_url, is_unlocked, is_completed, progress_percent
│       └── levels[]     id, name, order, is_unlocked, is_completed, is_boss,
│                        stars (0–3), progress_percent, questions_count, xp_reward
└── current_position
```

`image_url` peut être relatif : l'app le complète avec `API_BASE_URL`.

### `GET /v1/levels/{id}`

Détail du niveau dans `data.level`, ou directement dans `data`, avec
éventuellement `city.name` et `city.image_url`.

### `POST /v1/levels/{id}/start`

Envoi : `{ mode: "level" }`. Lu : `data.id` (identifiant de session) et
`data.questions`.

### `POST /v1/game-sessions/{id}/answer`

Envoi : `{ question_id, answer_id, response_time }` (`answer_id` = `null` si
le temps est écoulé). L'app exige **200**, `success: true` et un booléen
`data.is_correct`. Lu aussi : `data.correct_answer_id`, `data.explanation`.

### `POST /v1/game-sessions/{id}/finish`

Sans corps. Lu : `data.correct_answers`, `data.score`, `data.accuracy`,
`data.xp_earned`, `data.coins_earned`, `data.gems_earned`, `data.rewards`.
