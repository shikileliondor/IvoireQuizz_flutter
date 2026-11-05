# API V1

Base URL : `/api/v1`

Authentification Bearer pour toutes les routes sauf `POST /auth/register` et `POST /auth/login`.

```http
Authorization: Bearer TOKEN
Accept: application/json
Content-Type: application/json
```

## Format standard

Succès :

```json
{
  "success": true,
  "message": "...",
  "data": {}
}
```

Erreur :

```json
{
  "success": false,
  "message": "...",
  "errors": {}
}
```

> Les exemples ci-dessous documentent les routes présentes dans `routes/api.php`. Les champs exacts de `data` peuvent évoluer selon les Resources Laravel ; Flutter doit parser seulement ce dont il a besoin.

## AUTH

### POST `/auth/register`
- **Auth** : non.
- **Headers** : `Accept: application/json`, `Content-Type: application/json`.
- **Body** :
```json
{
  "name": "Awa Kouadio",
  "email": "awa@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```
- **Succès** :
```json
{
  "success": true,
  "message": "Inscription réussie.",
  "data": {
    "token": "1|...",
    "user": { "id": 1, "name": "Awa Kouadio", "email": "awa@example.com" }
  }
}
```
- **Erreur** : `422` si email déjà utilisé ou validation invalide.
- **Notes Flutter** : sauvegarder le token dans un stockage sécurisé, puis appeler `/me` pour hydrater le profil.

### POST `/auth/login`
- **Auth** : non.
- **Body** :
```json
{
  "email": "awa@example.com",
  "password": "password123"
}
```
- **Succès** :
```json
{
  "success": true,
  "message": "Connexion réussie.",
  "data": { "token": "1|...", "user": { "id": 1, "name": "Awa Kouadio" } }
}
```
- **Erreur** : `422` identifiants invalides, `429` trop de tentatives.
- **Notes Flutter** : ne jamais logger le token en production.

### POST `/auth/logout`
- **Auth** : oui.
- **Body** : aucun.
- **Succès** :
```json
{ "success": true, "message": "Déconnexion réussie.", "data": {} }
```
- **Erreur** : `401` token invalide.
- **Notes Flutter** : supprimer le token local même si l’appel échoue avec `401`.

### GET `/me`
- **Auth** : oui.
- **Succès** :
```json
{
  "success": true,
  "message": "Profil utilisateur.",
  "data": { "id": 1, "name": "Awa Kouadio", "xp_total": 120, "coins": 30, "gems": 2 }
}
```
- **Erreur** : `401`.
- **Notes Flutter** : endpoint de resynchronisation profil au démarrage.

## GAME MAP

### GET `/game/map`
- **Auth** : oui.
- **Succès** :
```json
{
  "success": true,
  "message": "Carte du jeu.",
  "data": {
    "regions": [
      {
        "id": 1,
        "name": "Abidjan",
        "cities": [
          { "id": 1, "name": "Cocody", "levels": [ { "id": 1, "title": "Niveau 1", "is_boss": false } ] }
        ]
      }
    ]
  }
}
```
- **Erreur** : `401`.
- **Notes Flutter** : utiliser pour construire l’écran carte ; cache local autorisé pour l’affichage, puis resynchronisation.

### GET `/regions`
- **Auth** : oui.
- **Succès** : liste de régions.
- **Erreur** : `401`.
- **Notes Flutter** : écran liste de mondes.

### GET `/regions/{region}`
- **Auth** : oui.
- **Paramètre** : `{region}` id route model binding.
- **Succès** : détail région avec villes/progression.
- **Erreur** : `404` région introuvable.
- **Notes Flutter** : afficher les villes et états verrouillés.

### GET `/cities/{city}`
- **Auth** : oui.
- **Succès** : détail ville avec niveaux.
- **Erreur** : `404`.
- **Notes Flutter** : afficher les niveaux dans l’ordre.

### GET `/levels/{level}`
- **Auth** : oui.
- **Succès** : détail niveau, difficulté, récompenses, état de déblocage.
- **Erreur** : `404`.
- **Notes Flutter** : afficher bouton Jouer uniquement si déverrouillé, mais le serveur revérifie.

## GAME SESSION

### POST `/levels/{level}/start`
- **Auth** : oui.
- **Rate limit** : `start-game`.
- **Body** : optionnel selon Request ; mode par défaut `level`.
```json
{ "mode": "level" }
```
- **Succès** :
```json
{
  "success": true,
  "message": "Session démarrée.",
  "data": {
    "session": { "id": 50, "status": "started", "total_questions": 10 },
    "questions": [
      {
        "id": 100,
        "question_text": "Quelle commune abrite... ?",
        "time_limit": 20,
        "answers": [ { "id": 501, "answer_text": "Cocody" } ]
      }
    ]
  }
}
```
- **Erreur** : `403` niveau verrouillé ou pas de vie, `429` trop de démarrages.
- **Notes Flutter** : ne pas attendre de bonnes réponses dans ce payload ; lancer le timer local uniquement pour l’UX.

### GET `/game-sessions/{session}`
- **Auth** : oui.
- **Succès** : session, niveau, réponses déjà données et éventuellement questions.
- **Erreur** : `403` si autre utilisateur, `404` si introuvable.
- **Notes Flutter** : utile pour reprendre ou rafraîchir une session.

### POST `/game-sessions/{session}/answer`
- **Auth** : oui.
- **Rate limit** : `quiz-answer`.
- **Body autorisé côté Flutter uniquement** :
```json
{
  "question_id": 100,
  "answer_id": 501,
  "response_time": 8
}
```
- **Flutter ne doit jamais envoyer** :
```json
{
  "score": 9999,
  "xp": 9999,
  "coins": 9999,
  "gems": 9999,
  "is_correct": true
}
```
- **Succès** :
```json
{
  "success": true,
  "message": "Réponse enregistrée.",
  "data": {
    "question_id": 100,
    "answer_id": 501,
    "is_correct": true,
    "points_earned": 12,
    "xp_earned": 5,
    "explanation": "..."
  }
}
```
- **Erreur** : `422` payload invalide, `403` session non propriétaire, `409` ou `422` question déjà répondue selon mapping d’exception, `429` trop rapide.
- **Notes Flutter** : afficher le résultat retourné par le serveur. Ne pas calculer localement la justesse.

### POST `/game-sessions/{session}/finish`
- **Auth** : oui.
- **Body** : aucun score envoyé.
- **Succès** :
```json
{
  "success": true,
  "message": "Session terminée.",
  "data": {
    "session": { "id": 50, "status": "completed", "accuracy": 80, "score": 120 },
    "rewards": { "xp": 70, "coins": 10, "gems": 0 },
    "unlocks": { "chest": true, "collectible": true, "passport": false }
  }
}
```
- **Erreur** : session incomplète, expirée ou déjà terminée.
- **Notes Flutter** : après succès, rafraîchir `/lives`, `/streak`, `/league/current`, `/me`, et éventuellement `/chests`, `/collection`, `/passport`.

### POST `/game-sessions/{session}/abandon`
- **Auth** : oui.
- **Body** : aucun.
- **Succès** : session statut `abandoned`.
- **Erreur** : session non jouable ou non propriétaire.
- **Notes Flutter** : demander confirmation utilisateur avant abandon.

### GET `/game-sessions/history`
- **Auth** : oui.
- **Succès** : liste paginée ou récente des sessions du joueur.
- **Erreur** : `401`.
- **Notes Flutter** : historique profil/statistiques.

## LIVES

### GET `/lives`
- **Auth** : oui.
- **Succès** :
```json
{ "success": true, "message": "Vies.", "data": { "lives": 4, "max_lives": 5, "next_life_at": "2026-06-19T12:30:00Z" } }
```
- **Notes Flutter** : calculer un compte à rebours visuel, mais resynchroniser avec le serveur.

## STREAK

### GET `/streak`
- **Auth** : oui.
- **Succès** :
```json
{ "success": true, "message": "Streak.", "data": { "current_streak": 3, "longest_streak": 7, "streak_freezes": 1 } }
```
- **Notes Flutter** : afficher l’état quotidien.

## LEAGUE

### GET `/league/current`
- **Auth** : oui.
- **Succès** : saison active, ligue, XP du joueur, rang.
- **Notes Flutter** : carte de ligue sur l’accueil.

### GET `/league/ranking`
- **Auth** : oui.
- **Succès** : top joueurs classés par XP de saison.
- **Notes Flutter** : prévoir état vide si Redis vient d’être vidé et avant resync.

## CHESTS

### GET `/chests`
- **Auth** : oui.
- **Succès** : coffres utilisateur avec statut `locked`, `available` ou `opened`.
- **Notes Flutter** : bouton ouvrir seulement pour `available`, mais le serveur revérifie.

### POST `/chests/{userChest}/open`
- **Auth** : oui.
- **Rate limit** : `open-chest`.
- **Body** : aucun.
- **Succès** :
```json
{
  "success": true,
  "message": "Coffre ouvert.",
  "data": { "xp": 20, "coins": 15, "gems": 1, "collectible": null }
}
```
- **Erreur** : coffre déjà ouvert ou appartenant à un autre utilisateur.
- **Notes Flutter** : désactiver immédiatement le bouton après tap, puis resynchroniser `/chests` et `/me`.

## COLLECTION

### GET `/collection`
- **Auth** : oui.
- **Succès** : tous les collectibles du joueur et/ou catalogue avec statut.
- **Notes Flutter** : écran collection global.

### GET `/collection/personalities`
- **Auth** : oui.
- **Succès** : personnalités.
- **Notes Flutter** : filtrage côté backend déjà disponible.

### GET `/collection/monuments`
- **Auth** : oui.
- **Succès** : monuments.
- **Notes Flutter** : idem.

## PASSPORT

### GET `/passport`
- **Auth** : oui.
- **Succès** : régions tamponnées et progression passeport.
- **Notes Flutter** : afficher les régions complétées.

## QUESTION REPORT

### POST `/questions/{question}/report`
- **Auth** : oui.
- **Rate limit** : `report-question`.
- **Body** :
```json
{
  "reason": "wrong_answer",
  "message": "La bonne réponse semble incorrecte."
}
```
- **Succès** :
```json
{ "success": true, "message": "Signalement enregistré.", "data": { "status": "pending" } }
```
- **Erreur** : `422` validation, `429` signalements répétés.
- **Notes Flutter** : proposer depuis l’écran correction, après réponse.

## Endpoints absents à ne pas inventer

La V1 actuelle ne déclare pas d’endpoints publics pour achat boutique, amis, offline sync, reset de progression, daily challenge ou social feed. Les ajouter nécessite d’abord des routes, contrôleurs, FormRequests, Resources, services et tests.
