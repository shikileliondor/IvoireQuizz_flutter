# Mission backend IvoireQuiz — sécurisation V1, payload de rétention, Redis

Tu interviens sur le backend **Laravel + MySQL + Redis + Sanctum** du jeu mobile IvoireQuiz
(quiz de culture ivoirienne, parcours guidé façon Duolingo : carte nationale → régions →
villes → niveaux → boss → passeport).

## 0. Avant toute chose : lis la doc existante

Le dossier `docs/` fait autorité. Lis-le **en entier** avant d'écrire une ligne :

| Fichier | Ce que tu y trouves |
| --- | --- |
| `docs/README.md` | Vision produit V1 |
| `docs/ARCHITECTURE.md` | Couches, dossiers, principes (contrôleurs minces, services métier, Resources) |
| `docs/DATABASE.md` | Schéma MySQL |
| `docs/GAMEPLAY.md` | Règles de jeu : vies, streak, ligues, coffres, collections, passeport |
| `docs/API_V1.md` | **Contrat API officiel** — la référence |
| `docs/SERVICES.md` | Services métier existants |
| `docs/SECURITY.md` | Règles de sécurité |
| `docs/REDIS_AND_QUEUES.md` | Conventions Redis/queues déjà décidées |
| `docs/TESTING.md` | Attentes de tests |
| `docs/DEPLOYMENT.md` | Contraintes de déploiement |

**Règles non négociables issues de cette doc :**

1. **MySQL est la source de vérité.** Redis accélère, ne remplace jamais. Un `redis-cli FLUSHALL`
   ne doit casser aucune donnée critique : comptes, sessions, réponses, progressions, coffres,
   récompenses. Tout doit être reconstructible depuis MySQL.
2. **N'invente aucun endpoint.** `docs/API_V1.md` se termine par une liste explicite de ce qui
   n'existe pas en V1 (boutique, amis, offline sync, reset progression, daily challenge, social
   feed). Si tu penses qu'un nouvel endpoint est nécessaire, **propose-le d'abord**, ne le code pas.
3. **Contrôleurs minces.** Règles métier dans `app/Services/Game`, validation dans les
   FormRequests, formatage dans les Resources.
4. **Le client Flutter n'est jamais digne de confiance.** Aucun score, XP, coin, gem ou
   `is_correct` envoyé par le mobile ne doit être accepté.

Commence par un **état des lieux** : quelles routes de `routes/api.php` existent réellement,
lesquelles sont documentées mais absentes, lesquelles existent mais ne sont pas documentées.
Rends-moi ce diff avant de coder.

---

## 1. PRIORITÉ CRITIQUE — Les bonnes réponses fuitent vers le client

### Le problème

L'app Flutter possède aujourd'hui **deux implémentations en parallèle** :

- `lib/features/quiz/data/quiz_api.dart` (récent, conforme à `docs/API_V1.md`) :
  `POST /levels/{level}/start` → `POST /game-sessions/{session}/answer` → `POST /game-sessions/{session}/finish`
- `lib/features/quiz/screens/quiz_screen.dart` (**celui réellement utilisé en production**) :
  `GET /quiz/questions?mode=&category_id=` puis `POST /sessions` avec toutes les réponses en lot

Le second chemin fait ceci, côté client :

```dart
final selected = options.firstWhere((o) => o['id'] == optionId);
isCorrect = selected['is_correct'] == true;   // ⚠️ calculé sur le téléphone
```

Cela signifie que **`GET /quiz/questions` sérialise `is_correct` pour chaque option**. Toutes les
bonnes réponses sont livrées au téléphone avant que le joueur ne réponde. Un simple proxy HTTP
(ou `adb logcat`) permet de tout voir.

`docs/API_V1.md` interdit explicitement ce comportement :
- ligne 186 : « ne pas attendre de bonnes réponses dans ce payload »
- lignes 205-214 : « Flutter ne doit **jamais** envoyer `score`, `xp`, `coins`, `gems`, `is_correct` »

En prime, `POST /sessions` accepte un lot de réponses avec des `response_time_seconds` calculés
par le client : le classement est falsifiable trivialement.

### Ce que tu dois faire

1. **Audite** `routes/api.php` : est-ce que `GET /quiz/questions` et `POST /sessions` existent
   encore ? Si oui, ce sont des routes legacy à traiter.
2. **Corrige la fuite immédiatement**, même avant toute migration : retire `is_correct` (et tout
   champ équivalent : `correct`, `is_right`, `answer_key`…) de **toute** Resource qui sérialise
   des options/réponses **avant** que le joueur ait répondu. Vérifie chaque Resource, pas
   seulement celle du quiz.
3. **La justesse ne doit être révélée que par** `POST /game-sessions/{session}/answer`, après
   que la réponse a été enregistrée.
4. **Valide le temps de réponse côté serveur.** Ne fais pas confiance à `response_time` envoyé
   par le client : compare-le à l'horodatage serveur entre la livraison de la question et la
   réception de la réponse. Applique un plafond (`min(client, serveur)`) et rejette les valeurs
   aberrantes (négatives, supérieures au `time_limit` + marge réseau).
5. **Rends la soumission de réponse idempotente** : répondre deux fois à la même question dans
   une session doit renvoyer `409` (ou `422` selon le mapping d'exception déjà en place), jamais
   créditer deux fois des points.
6. **Plan de dépréciation** des routes legacy : garde-les temporairement mais neutralisées
   (sans `is_correct`, avec calcul serveur), logge leur usage, et documente une date de retrait.
   Ne les supprime pas d'un coup — l'app en production les utilise encore.

Livre cette partie **en premier**, isolée, avec ses tests.

---

## 2. Payload de fin de partie — objectif rétention

### Le contexte produit

L'écran de résultat Flutter est aujourd'hui un cul-de-sac : score, détail des réponses, puis
« Rejouer » / « Accueil ». Rien ne donne au joueur une raison de revenir demain.

On veut y afficher, juste après le score :

- **Streak** : « 🔥 4 jours d'affilée — reviens demain pour 5 »
- **Ligue** : « Tu gagnes 3 places → 7e sur 240 »
- **Progression** : « Encore 350 XP pour débloquer Yamoussoukro »
- **Vies** : état + `next_life_at`

### Le problème technique

`docs/API_V1.md` ligne 249 demande aujourd'hui à Flutter de rappeler `/lives`, `/streak`,
`/league/current`, `/me` (et parfois `/chests`, `/collection`, `/passport`) **après** le finish.
Soit 4 à 7 allers-retours sur un réseau mobile ivoirien, pendant que le joueur regarde un écran
incomplet. C'est la pire seconde pour faire attendre quelqu'un.

### Ce que tu dois faire

Enrichis la réponse de `POST /game-sessions/{session}/finish` pour qu'elle contienne, **en un
seul appel**, tout ce qu'il faut pour peindre cet écran. Proposition de structure — discute-la
avec moi avant de l'implémenter :

```json
{
  "success": true,
  "message": "Session terminée.",
  "data": {
    "session": { "id": 50, "status": "completed", "accuracy": 80, "score": 120 },
    "rewards": { "xp": 70, "coins": 10, "gems": 0 },
    "unlocks": { "chest": true, "collectible": true, "passport": false },

    "streak": {
      "current": 4,
      "longest": 7,
      "freezes": 1,
      "extended_today": true,
      "next_milestone": 7,
      "xp_bonus_applied": 10
    },
    "league": {
      "league_id": 1,
      "season_id": 10,
      "rank_before": 10,
      "rank_after": 7,
      "delta": 3,
      "total_players": 240,
      "xp_to_next_rank": 45
    },
    "progression": {
      "next_level": { "id": 12, "title": "Niveau 3", "unlocked": true },
      "region_progress": { "completed": 4, "total": 10 },
      "xp_to_next_unlock": 350
    },
    "lives": { "lives": 3, "max_lives": 5, "next_life_at": "2026-07-20T12:30:00Z" }
  }
}
```

**Contraintes :**

- **Rétrocompatibilité** : les clés existantes (`session`, `rewards`, `unlocks`) gardent leur
  forme actuelle. On ajoute, on ne casse pas.
- `rank_before` doit être capturé **avant** l'application des gains XP de la session, sinon le
  delta est toujours nul. Attention à l'ordre des opérations dans `FinishGameSessionService`.
- Tout ce bloc doit rester correct si Redis est vide (voir §3).
- Mets à jour `docs/API_V1.md` en conséquence, y compris la note ligne 249 qui devient obsolète.

---

## 3. Redis — cache, classements, queues

`docs/REDIS_AND_QUEUES.md` pose déjà les conventions. Étends-les proprement.

### 3.1 Cache

Établis une **table des clés** documentée : nom, contenu, TTL, événement d'invalidation.
Convention de nommage `domaine:entité:identifiant`.

Base de départ déjà décidée :

```php
Cache::remember('game:regions:map', 21600, fn () => /* … */);
```

À traiter :

- **Séparer le statique du personnel.** La carte de contenu (régions/villes/niveaux) est commune
  à tous et se cache 6 h. La progression du joueur est personnelle et volatile — ne la mets pas
  dans la même clé, sinon tu sers la progression d'un joueur à un autre. Compose les deux à la
  lecture.
- **Invalidation explicite** à chaque modification de contenu (seeder, back-office, migration).
  Pas d'attente passive de l'expiration du TTL.
- **Protection anti-stampede** : si la clé de carte expire à une heure de pointe, des centaines
  de requêtes vont reconstruire la même donnée simultanément. Utilise `Cache::lock()`.
- **Ne cache jamais** : soldes (coins/gems/XP), état des vies, statut des coffres. Trop volatil,
  trop critique.

### 3.2 Classements de ligue

Le §2 a besoin de `rank_before` / `rank_after` **rapidement**. Un `ORDER BY xp` sur toute la
table à chaque fin de partie ne tiendra pas la charge.

Utilise les sorted sets, comme déjà prévu dans la doc :

```php
Redis::zincrby("league:{$leagueId}:season:{$seasonId}:ranking", $xpGained, (string) $user->id);
$rank = Redis::zrevrank("league:{$leagueId}:season:{$seasonId}:ranking", (string) $user->id);
$top  = Redis::zrevrange("league:{$leagueId}:season:{$seasonId}:ranking", 0, 49, ['withscores' => true]);
```

**Impératif :** l'XP de saison officielle reste en MySQL (`league_members`). Le ZSET est une
projection. Écris une commande Artisan de resynchronisation :

```bash
php artisan league:resync {--season=} {--league=}
```

Et un **fallback** : si le ZSET est absent ou vide (Redis vidé, saison neuve), la lecture retombe
sur MySQL et reconstruit le ZSET au passage. `docs/API_V1.md` ligne 294 prévoit déjà l'état vide
côté Flutter, mais le backend doit se réparer tout seul.

### 3.3 Queues

Worker Redis (`php artisan queue:work redis`), Supervisor en production, `queue:restart` après
déploiement — déjà documenté.

**Décision importante à respecter :** la fin de partie a des effets de bord (génération de
coffre, déblocage de collectible, tampon de passeport, sync du ZSET de ligue). Tu peux en
déporter certains en queue, **mais tout ce que l'écran de résultat affiche doit être calculé et
retourné de façon synchrone.** Un joueur ne doit jamais voir « 0 XP » parce qu'un worker était en
retard. Concrètement :

- **Synchrone** : XP, coins, gems, streak, rang, progression, déblocage du niveau suivant.
- **Asynchrone acceptable** : notifications push, agrégats analytiques, recalcul de statistiques
  globales, warm-up de caches.

Prévois les jobs comme idempotents (rejouables sans double crédit) et gère `queue:failed`.

### 3.4 Rate limiting

Les limiteurs nommés sont déjà référencés dans `docs/API_V1.md` : `start-game`, `quiz-answer`,
`open-chest`, `report-question`. Vérifie qu'ils sont tous réellement déclarés, adossés au store
Redis, et **calibre `quiz-answer` avec soin** : trop strict, un joueur rapide et honnête se fait
bloquer en plein quiz.

### 3.5 Dégradation gracieuse

**Redis en panne ne doit pas rendre le jeu injouable.** Enveloppe les accès Redis pour qu'une
exception de connexion retombe sur MySQL avec un log d'alerte, plutôt que de renvoyer un 500.
Teste ce scénario explicitement.

---

## 4. Outillage

Propose et justifie avant d'installer quoi que ce soit :

| Outil | Usage | Note |
| --- | --- | --- |
| **Laravel Horizon** | Supervision des queues Redis | Cohérent, on est déjà sur Redis. Protège le dashboard en prod. |
| **Laravel Telescope** | Debug requêtes/queries/jobs | **Environnement local uniquement.** Jamais en prod : il logge des données sensibles. |
| **Larastan / PHPStan** | Analyse statique | Commence à un niveau atteignable, monte progressivement. |
| **Laravel Pint** | Formatage PSD-12 | À brancher en CI. |
| **Pest ou PHPUnit** | Tests | Suis ce que `docs/TESTING.md` impose déjà. |
| **Sentry** | Suivi des erreurs en production | Filtre les tokens et données personnelles avant envoi. |
| **Scribe** | Génération OpenAPI depuis le code | Optionnel, mais éviterait la dérive entre `docs/API_V1.md` et la réalité. |

Vérifie aussi les **index MySQL** sur les colonnes chaudes : `game_sessions.user_id`,
`session_answers.session_id`, `league_members.(season_id, xp)`, `user_progressions.user_id`.
Mesure avec `EXPLAIN` avant d'ajouter, ne devine pas.

---

## 5. Tests attendus

Aucune livraison sans tests. Au minimum :

- **Sécurité** : une réponse de `/levels/{id}/start` ne contient **jamais** d'indication de la
  bonne réponse. Test explicite, qui échoue si quelqu'un réintroduit le champ.
- **Anti-triche** : un payload avec `score`, `xp`, `is_correct` est ignoré, pas appliqué.
- **Idempotence** : double réponse à la même question → pas de double crédit.
- **Temps de réponse** : valeur client aberrante (négative, énorme) → normalisée côté serveur.
- **Finish** : le payload enrichi contient bien streak/league/progression/lives, et `rank_before`
  ≠ `rank_after` quand le joueur gagne des places.
- **Redis vidé** : `FLUSHALL` puis parcours complet du jeu → aucune erreur, données correctes,
  classements reconstruits.
- **Redis injoignable** : le jeu reste jouable.

---

## 6. Méthode de travail

1. Rends-moi d'abord l'**état des lieux** du §0 (diff routes réelles / documentées) et ton
   diagnostic sur le §1. **Ne code rien avant qu'on en ait parlé.**
2. Puis livre par lots, dans cet ordre : §1 (sécurité) → §2 (payload) → §3 (Redis) → §4 (outils).
3. Un lot = migrations réversibles + service + Resource + FormRequest + tests + mise à jour de
   `docs/`.
4. Si une décision te semble ambiguë ou si tu penses qu'il faut sortir du cadre de
   `docs/API_V1.md`, **demande**. Ne tranche pas seul sur le contrat d'API : une app mobile
   déjà déployée en dépend, et les utilisateurs ne mettent pas tous à jour.

## 7. Contexte client à garder en tête

Le client Flutter :
- pointe sur `/api/v1` (`ApiConfig.apiBaseUrl`), en dev `http://10.0.2.2:8000`
- timeouts à 10 s en connect/receive/send → **aucun endpoint ne doit dépasser ça**, en
  particulier le finish enrichi
- traite tout `401` par une purge du token et une redirection vers l'écran de connexion :
  ne renvoie jamais `401` pour autre chose qu'un problème d'authentification réel
  (utilise `403` pour un niveau verrouillé ou une absence de vie, comme la doc le prévoit déjà)
- parse `{ success, message, data }` — respecte ce format partout, y compris sur les erreurs
