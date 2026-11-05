# Services métier

Les services de `app/Services/Game` concentrent les règles de jeu. Ils doivent être appelés depuis les contrôleurs, jobs ou commandes, pas remplacés par de la logique dupliquée.

## `GameSessionService`
- **Rôle** : démarrer et contrôler une session.
- **Méthodes** : `start(User, Level, mode)`, `assertSessionOwner(User, GameSession)`, `getQuestionsForSession(GameSession)`, `abandon(GameSession)`.
- **Entrées** : utilisateur authentifié, niveau, mode.
- **Sorties** : `GameSession` ou collection de questions.
- **Règles** : vérifie vies, niveau débloqué, mode supporté, session jouable.
- **Erreurs** : niveau verrouillé, vies insuffisantes, session invalide.

## `AnswerQuestionService`
- **Rôle** : soumettre une réponse et calculer points/XP de question.
- **Méthodes** : `submitAnswerForUser`, `submitAnswer`.
- **Entrées** : utilisateur, session, question, réponse nullable, `response_time`.
- **Sorties** : `GameSessionAnswer`.
- **Règles** : ownership, session commencée, question dans le niveau, réponse liée à la question, temps valide, pas de double réponse.
- **Erreurs** : session invalide, question hors session, réponse invalide, question déjà répondue.

## `FinishGameSessionService`
- **Rôle** : orchestrer la fin de partie.
- **Méthodes** : `finish(GameSession)`.
- **Entrées** : session commencée.
- **Sorties** : session mise à jour avec statut final, précision, récompenses.
- **Règles** : toutes les questions attendues doivent être répondues ; calcule réussite, XP, coins, gems ; met à jour progression, streak, ligue, coffres, collections, passeport.
- **Erreurs** : session déjà terminée, expirée ou incomplète.

## `RewardService`
- **Rôle** : centraliser tous les gains/pertes.
- **Méthodes** : `addXp`, `addPoints`, `addCoins`, `addGems`, `addLife`, `removeLife`.
- **Entrées** : utilisateur, montant, source, description.
- **Sorties** : mise à jour utilisateur/vies + ligne `reward_transactions`.
- **Règles** : toute modification de récompense doit être tracée ; les montants négatifs ne sont pas autorisés pour les opérations d’ajout.
- **Erreurs** : montant invalide, exceptions de transaction.

## `LifeService`
- **Rôle** : gérer vies et régénération.
- **Méthodes** : `getOrCreate`, `canPlay`, `loseLife`, `addLife`, `regenerate`.
- **Entrées** : utilisateur, montant.
- **Sorties** : `UserLife`.
- **Règles** : bornage à `max_lives`, calcul de `next_life_at` côté serveur.
- **Erreurs** : aucune erreur métier si bornage possible ; transaction DB possible.

## `StreakService`
- **Rôle** : gérer la série quotidienne.
- **Méthodes** : `getOrCreate`, `updateAfterGame`.
- **Entrées** : utilisateur.
- **Sorties** : `UserStreak`.
- **Règles** : une mise à jour par jour, continuation si joué hier, reset ou freeze si jour manqué.
- **Erreurs** : transaction DB possible.

## `ProgressionService`
- **Rôle** : initialiser et débloquer le parcours.
- **Méthodes** : `initializeForUser`, `isLevelUnlocked`, `completeLevel`, `unlockNextAfterLevel`, `completeRegionIfBoss`.
- **Entrées** : utilisateur, niveau, score, précision.
- **Sorties** : lignes de progression mises à jour.
- **Règles** : déblocage niveau → ville → région ; étoiles selon précision ; boss régional complète la région.
- **Erreurs** : données de parcours manquantes ou transaction DB.

## `LeagueService`
- **Rôle** : gérer saison active, membres, XP hebdomadaire et classement.
- **Méthodes** : `getCurrentSeasonForUser`, `addXp`, `incrementWeeklyXpInRedis`, `getTopPlayersFromRedis`, `refreshRanks`, `refreshActiveSeasonRanks`, `rankingRedisKey`.
- **Entrées** : utilisateur, XP, saison.
- **Sorties** : membres de ligue, classement DB/Redis.
- **Règles** : XP hebdomadaire ajouté après partie réussie ; Redis accélère le ranking.
- **Erreurs** : indisponibilité Redis ou DB.

## `ChestService`
- **Rôle** : attribuer et ouvrir des coffres.
- **Méthodes** : `grantChest`, `openChest`.
- **Entrées** : utilisateur, type de coffre, `UserChest`.
- **Sorties** : récompenses `xp`, `coins`, `gems`, collectible éventuel.
- **Règles** : ownership obligatoire ; un coffre ouvert ne doit jamais être ouvert deux fois.
- **Erreurs** : coffre déjà ouvert, coffre non propriétaire, coffre catalogue introuvable.

## `CollectionService`
- **Rôle** : débloquer collectibles.
- **Méthodes** : `unlock`, `unlockRandom`.
- **Entrées** : utilisateur, collectible ou filtres région/ville, source.
- **Sorties** : `UserCollectible` ou `null`.
- **Règles** : ne pas dupliquer un collectible déjà possédé.
- **Erreurs** : aucune si plus rien à débloquer ; retourne `null`.

## `PassportService`
- **Rôle** : tamponner une région complétée.
- **Méthodes** : `stampRegion`.
- **Entrées** : utilisateur, région.
- **Sorties** : `UserPassport`.
- **Règles** : un seul tampon par utilisateur/région.
- **Erreurs** : transaction DB possible.

## `GameCacheService`
- **Rôle** : cacher la carte régions → villes → niveaux.
- **Méthodes** : `cacheRegionsMap`, `getRegionsMap`, `clearRegionsMapCache`.
- **Entrées** : aucune entrée utilisateur critique.
- **Sorties** : tableau de carte de jeu.
- **Règles** : cache reconstruit depuis MySQL ; TTL de plusieurs heures.
- **Erreurs** : cache indisponible, mais MySQL peut reconstruire.

## Points d’attention

- `RewardService` centralise tous les gains/pertes.
- `FinishGameSessionService` orchestre la fin de partie et ne doit pas être contourné.
- `ProgressionService` est responsable des déblocages.
- `LeagueService` gère l’XP hebdomadaire et le ranking.
- `ChestService` doit empêcher toute double ouverture.
