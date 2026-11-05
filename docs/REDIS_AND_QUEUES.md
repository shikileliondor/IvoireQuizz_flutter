# Redis et queues

## Utilisations Redis

Redis peut être utilisé pour :

- cache du parcours régions/villes/niveaux ;
- queues Laravel ;
- classement rapide des ligues ;
- rate limiting si le cache Laravel est configuré sur Redis.

## MySQL reste la source de vérité

Redis accélère, mais ne remplace jamais MySQL. Si Redis est vidé :

- les comptes utilisateurs restent valides ;
- les sessions et réponses restent en base ;
- les progressions restent en base ;
- les coffres ouverts restent en base ;
- les classements peuvent être resynchronisés depuis `league_members`.

## Cache Laravel

Exemple de cache de carte de jeu :

```php
use Illuminate\Support\Facades\Cache;

$map = Cache::remember('game:regions:map', 21600, function () {
    return Region::query()
        ->with('cities.levels')
        ->where('is_active', true)
        ->orderBy('order')
        ->get();
});
```

## Classement Redis

Exemple de sorted set pour ligues :

```php
use Illuminate\Support\Facades\Redis;

Redis::zincrby('league:1:season:10:ranking', 50, (string) $user->id);

$top = Redis::zrevrange('league:1:season:10:ranking', 0, 49, ['withscores' => true]);
```

## Queues Laravel

Lancer un worker Redis :

```bash
php artisan queue:work redis
```

Commandes utiles :

```bash
php artisan queue:work
php artisan queue:failed
php artisan queue:retry all
php artisan queue:restart
```

## Bonnes pratiques

- Ne pas stocker de récompense critique uniquement dans Redis.
- Prévoir une commande de resynchronisation des classements depuis MySQL si nécessaire.
- Utiliser Supervisor en production pour relancer les workers.
- Redémarrer les workers après déploiement avec `php artisan queue:restart`.
