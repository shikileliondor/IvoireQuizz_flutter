# Déploiement VPS

## Prérequis

- PHP 8.3+ avec extensions Laravel usuelles.
- Composer.
- MySQL.
- Redis.
- Nginx.
- Supervisor pour les queue workers.
- Cron pour Laravel Scheduler.
- SSL/TLS via Let’s Encrypt ou équivalent.
- `.env` production sécurisé.

## Variables `.env` importantes

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.example.com
DB_CONNECTION=mysql
CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=database
SANCTUM_STATEFUL_DOMAINS=
```

## Commandes de déploiement

```bash
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan db:seed --force
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan queue:restart
```

## Nginx

Pointer le vhost vers le dossier `public/` de Laravel. Forcer HTTPS et transmettre les headers usuels `X-Forwarded-*`.

## Supervisor

Commande worker :

```bash
php artisan queue:work redis
```

Exemple de programme Supervisor :

```ini
[program:ivoirequiz-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/ivoirequiz-worker.log
stopwaitsecs=3600
```

## Scheduler Laravel

Ajouter au cron du serveur :

```cron
* * * * * php /path/artisan schedule:run >> /dev/null 2>&1
```

## Checklist production

- `APP_DEBUG=false`.
- Base migrée et seedée.
- Redis disponible.
- Workers Supervisor actifs.
- Cron scheduler actif.
- Certificat SSL valide.
- Sauvegardes MySQL configurées.
- Logs Laravel surveillés.
- Rate limiting testé.
