# Tests

## Lancer les tests

Depuis le dossier Laravel :

```bash
php artisan test
php artisan test --filter=AuthTest
php artisan test --filter=GameSessionTest
```

## Tests Feature API

Les tests Feature doivent couvrir les routes `/api/v1` avec headers JSON et authentification Sanctum si nécessaire.

Cas existants ou prioritaires :

- register ;
- login ;
- logout ;
- `/me` ;
- récupération carte ;
- démarrage session ;
- soumission réponse ;
- fin de session.

## Tests services à ajouter plus tard

Ajouter des tests unitaires ou intégration pour :

- `RewardService` : transaction créée pour chaque gain/perte ;
- `LifeService` : régénération, perte, gain, max lives ;
- `ProgressionService` : étoiles, completion, déblocage suivant ;
- `FinishGameSessionService` : réussite/échec, récompenses, boss, passeport ;
- `ChestService` : ouverture unique et ownership ;
- `LeagueService` : XP hebdomadaire, rang DB, Redis ranking.

## Cas critiques obligatoires

- login/register.
- start session.
- answer.
- double answer refusée.
- finish session.
- finish session incomplète refusée.
- coffre déjà ouvert refusé.
- niveau verrouillé refusé.
- manque de vies refusé.
- accès session d’un autre utilisateur refusé.
- question hors session refusée.
- réponse hors question refusée.
- response_time invalide refusé.

## Conseils

- Préférer des factories pour créer users, régions, villes, niveaux, questions et réponses.
- Tester les réponses JSON `success`, `message`, `data`/`errors`.
- Vérifier les effets DB avec `assertDatabaseHas` et `assertDatabaseMissing`.
- Tester les erreurs anti-triche autant que les chemins heureux.
