# Base de données

MySQL est la source de vérité de IvoireQuiz. Redis n’est utilisé que comme accélérateur.

## Tables principales

### `users`
- **Rôle** : compte joueur et agrégats globaux.
- **Champs** : `name`, `email`, `password`, `google_id`, `friend_code`, `avatar`, `avatar_id`, `current_level`, `xp_total`, `total_score`, `coins`, `gems`, `games_played`, `games_won`, `current_region_id`, `current_city_id`, `current_game_level_id`, `last_login_at`.
- **Relations** : sessions, réponses indirectes, progressions, vies, streak, ligues, coffres, collections, passeports, transactions.
- **Règles** : ne jamais mettre à jour XP/coins/gems depuis Flutter ; passer par `RewardService`.

### `regions`
- **Rôle** : mondes géographiques du parcours.
- **Champs** : `name`, `slug`, `description`, `image`, `map_image`, `order`, `required_xp`, `is_active`.
- **Relations** : possède plusieurs `cities`, progressions `user_region_progress`, passeports.
- **Règles** : l’ordre pilote le déblocage de la région suivante.

### `cities`
- **Rôle** : villes ou communes d’une région.
- **Champs** : `region_id`, `name`, `slug`, `description`, `image`, `order`, `required_xp`, `is_active`.
- **Relations** : appartient à une région, possède plusieurs niveaux, collectibles et progressions ville.
- **Règles** : `slug` unique par région.

### `levels`
- **Rôle** : unité jouable contenant les questions.
- **Champs** : `city_id`, `title`, `slug`, `difficulty`, `order`, `required_xp`, `questions_count`, `passing_score`, `xp_reward`, `coins_reward`, `gems_reward`, `is_boss`, `is_active`.
- **Relations** : appartient à une ville, possède des questions, sessions et progressions niveau.
- **Règles** : un niveau verrouillé ne peut pas être lancé ; un boss peut valider une région.

### `categories`
- **Rôle** : classifier les questions.
- **Champs** : `name`, `slug`, `icon`, `color`, `is_active`.
- **Relations** : questions.
- **Règles** : permet du filtrage ou de l’affichage thématique.

### `questions`
- **Rôle** : contenu du quiz.
- **Champs** : `level_id`, `category_id`, `question_text`, `type`, `difficulty`, `image`, `audio`, `explanation`, `points`, `xp_reward`, `time_limit`, `is_active`.
- **Relations** : appartient à un niveau, a plusieurs réponses et signalements.
- **Règles** : seules les questions actives du niveau de la session sont acceptées.

### `answers`
- **Rôle** : propositions de réponse.
- **Champs** : `question_id`, `answer_text`, `is_correct`, `order`.
- **Relations** : appartient à une question, utilisée par `game_session_answers`.
- **Règles** : Flutter ne doit pas recevoir ou exploiter `is_correct` avant soumission.

### `game_sessions`
- **Rôle** : partie lancée par un utilisateur.
- **Champs** : `user_id`, `region_id`, `city_id`, `level_id`, `mode`, `status`, `score`, `points_earned`, `xp_earned`, `coins_earned`, `gems_earned`, `correct_answers`, `wrong_answers`, `total_questions`, `accuracy`, `started_at`, `finished_at`.
- **Relations** : appartient à un utilisateur, région, ville, niveau ; possède des `game_session_answers`.
- **Règles** : statuts `started`, `completed`, `abandoned`, `failed`; une session expirée ou terminée n’est plus jouable.

### `game_session_answers`
- **Rôle** : trace serveur de chaque réponse donnée pendant une session.
- **Champs** : `game_session_id`, `question_id`, `answer_id`, `is_correct`, `response_time`, `points_earned`, `xp_earned`.
- **Relations** : appartient à une session, une question, une réponse nullable.
- **Règles** : unicité session/question ; empêche de répondre deux fois à la même question.

### `user_region_progress`
- **Rôle** : progression du joueur par région.
- **Champs** : `user_id`, `region_id`, `progress_percent`, `stars`, `is_unlocked`, `is_completed`, `completed_at`.
- **Relations** : utilisateur, région.
- **Règles** : unique par utilisateur/région.

### `user_city_progress`
- **Rôle** : progression du joueur par ville/commune.
- **Champs** : `user_id`, `city_id`, `progress_percent`, `stars`, `is_unlocked`, `is_completed`, `completed_at`.
- **Relations** : utilisateur, ville.
- **Règles** : unique par utilisateur/ville.

### `user_level_progress`
- **Rôle** : progression fine par niveau.
- **Champs** : `user_id`, `level_id`, `best_score`, `best_accuracy`, `stars`, `attempts`, `is_unlocked`, `is_completed`, `completed_at`.
- **Relations** : utilisateur, niveau.
- **Règles** : unique par utilisateur/niveau ; stocke les meilleurs résultats.

### `user_lives`
- **Rôle** : état des vies d’un joueur.
- **Champs** : `user_id`, `lives`, `max_lives`, `next_life_at`.
- **Relations** : utilisateur.
- **Règles** : une ligne par utilisateur ; régénération calculée côté serveur.

### `user_streaks`
- **Rôle** : régularité quotidienne.
- **Champs** : `user_id`, `current_streak`, `longest_streak`, `last_played_date`, `streak_freezes`.
- **Relations** : utilisateur.
- **Règles** : mise à jour après une partie terminée.

### `leagues`
- **Rôle** : niveaux de ligue, par exemple Bronze.
- **Champs** : `name`, `slug`, `rank_order`, `icon`, `color`, `is_active`.
- **Relations** : saisons.
- **Règles** : sert de catalogue.

### `league_seasons`
- **Rôle** : saison temporelle d’une ligue.
- **Champs** : `league_id`, `starts_at`, `ends_at`, `status`.
- **Relations** : ligue, membres.
- **Règles** : une saison active reçoit l’XP hebdomadaire.

### `league_members`
- **Rôle** : inscription d’un joueur à une saison.
- **Champs** : `league_season_id`, `user_id`, `xp_earned`, `rank`, `promoted`, `demoted`.
- **Relations** : saison, utilisateur.
- **Règles** : unique par saison/utilisateur ; classement trié par XP.

### `chests`
- **Rôle** : catalogue des coffres.
- **Champs** : `name`, `type`, `image`, `min_xp`, `max_xp`, `min_coins`, `max_coins`, `min_gems`, `max_gems`, `is_active`.
- **Relations** : `user_chests`.
- **Règles** : définit les bornes de récompense.

### `user_chests`
- **Rôle** : coffre attribué à un joueur.
- **Champs** : `user_id`, `chest_id`, `source_type`, `source_id`, `status`, `opened_at`.
- **Relations** : utilisateur, coffre.
- **Règles** : ne doit jamais être ouvert deux fois.

### `collectibles`
- **Rôle** : personnalités et monuments à collectionner.
- **Champs** : `type`, `name`, `slug`, `description`, `image`, `rarity`, `region_id`, `city_id`, `is_active`.
- **Relations** : région, ville, `user_collectibles`.
- **Règles** : type `personality` ou `monument`.

### `user_collectibles`
- **Rôle** : collectible débloqué par un joueur.
- **Champs** : `user_id`, `collectible_id`, `source_type`, `source_id`, `unlocked_at`.
- **Relations** : utilisateur, collectible.
- **Règles** : unique par utilisateur/collectible.

### `user_passports`
- **Rôle** : tampons régionaux du passeport joueur.
- **Champs** : `user_id`, `region_id`, `stamp_image`, `completed_at`.
- **Relations** : utilisateur, région.
- **Règles** : unique par utilisateur/région ; obtenu après boss de région réussi.

### `reward_transactions`
- **Rôle** : journal d’audit des gains/pertes.
- **Champs** : `user_id`, `type`, `amount`, `source_type`, `source_id`, `description`.
- **Relations** : utilisateur ; référence polymorphe logique via `source_type/source_id`.
- **Règles** : toute modification XP/points/coins/gems/life doit être traçable.

### `question_reports`
- **Rôle** : signalement de question par les joueurs.
- **Champs** : `user_id`, `question_id`, `reason`, `message`, `status`, `reviewed_at`.
- **Relations** : utilisateur, question.
- **Règles** : éviter les signalements répétés abusifs.

## Pourquoi `reward_transactions` est important

`reward_transactions` sert d’audit financier gameplay. Il permet de répondre à : pourquoi ce joueur a-t-il reçu 50 XP ? Quelle session a donné ce coffre ? Une récompense a-t-elle déjà été comptabilisée ? Sans cette table, les totaux `users.xp_total`, `coins` ou `gems` seraient difficiles à expliquer et à corriger.

## Pourquoi `game_session_answers` empêche la triche

Chaque réponse est enregistrée avec la question, la réponse choisie, le temps, les points et l’XP calculés côté serveur. L’unicité session/question bloque la double réponse. Le backend peut vérifier que la question appartient au niveau de la session et que la réponse appartient à la question.

## Pourquoi séparer les progressions région/ville/niveau

Les trois granularités répondent à des besoins différents :

- niveau : score, précision, étoiles, tentatives ;
- ville : pourcentage et déblocage de la prochaine ville ;
- région : fin de monde, boss, passeport et région suivante.

Cette séparation évite les calculs coûteux à chaque écran Flutter et rend les règles de déblocage plus lisibles.
