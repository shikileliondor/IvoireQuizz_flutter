# IvoireQuiz V1 officielle — parcours guidé

## 1. Décision produit

IvoireQuiz devient un jeu à progression linéaire. Après connexion, le joueur arrive directement sur **Parcours**, voit le prochain nœud jouable et lance une partie. Il ne choisit ni région, ni ville, ni commune.

Boucle principale :

```text
Ouvrir → voir le prochain défi → jouer → gagner → débloquer → continuer
```

Une région est un **monde visible** (Abidjan, Yamoussoukro…). Les communes deviennent des **chapitres éditoriaux internes**. Elles servent au classement des questions et à l’administration, mais ne constituent plus une étape de navigation.

Le chemin visible contient trois types de nœuds :

- `level` : session de quiz ;
- `chest` : récompense de jalon ;
- `boss` : validation finale du monde et déblocage du suivant.

Le serveur est seul responsable de l’ordre, du nœud courant, des verrouillages et des récompenses. Flutter rend une projection prête à afficher.

## 2. Analyse et impacts

### État avant refonte

Le client modélisait `regions → cities → levels`, affichait le nom de chaque commune comme une unité et conservait des écrans de sélection `RegionScreen` et `CityScreen`. La progression était stockée aux trois niveaux région, ville et niveau. `/game/map` renvoyait une arborescence que Flutter devait interpréter.

### Impacts

| Couche | Changement V1 |
|---|---|
| Produit | Suppression de tout choix géographique dans la boucle principale |
| Base | `cities` devient `chapters`; ajout de jalons ordonnés pour les coffres |
| Modèles backend | `Region/World`, `Chapter`, `Level`, `PathMilestone`; règles dans un service de progression |
| Progression | Curseur calculé par ordre, jamais choisi par le client |
| API | `/game/map` renvoie une vue plate de nœuds et `next_playable` |
| Flutter | Un seul écran principal; aucun identifiant de chapitre nécessaire |
| Administration | Les chapitres restent filtrables et réordonnables dans le CMS |

## 3. Base de données recommandée

### `cities` ou `chapters` ?

Conserver `cities` réduit le coût immédiat de migration et garde les relations existantes. En revanche, le nom impose une géographie qui n’est plus vraie : un futur chapitre peut être « Musique ivoirienne » ou « Indépendance ». Il encourage aussi le retour accidentel d’une navigation par ville.

Renommer en `chapters` clarifie le domaine, permet des regroupements non géographiques et aligne le vocabulaire produit, backend et administration. Le coût est une migration contrôlée des clés étrangères, modèles, policies et fixtures.

**Recommandation finale : adopter `chapters`.** En V1, effectuer un renommage sans perte d’identifiants plutôt qu’une recréation. Exposer temporairement des alias internes si le backend existant doit être migré en plusieurs livraisons.

### Schéma cible

```text
worlds (anciennement regions)
  └── chapters (anciennement cities, invisibles au joueur)
        └── levels
              └── questions
                    └── answers

worlds
  └── path_milestones (coffres et autres jalons intercalés)
```

Pour limiter le risque, `regions` peut garder son nom SQL en V1 et être nommé `World` dans le domaine/API. Le renommage `cities → chapters` est prioritaire car il corrige une ambiguïté fonctionnelle réelle.

Champs structurants :

- `chapters`: `id`, `region_id`, `name`, `slug`, `position`, `is_active`;
- `levels`: remplacer `city_id` par `chapter_id`; conserver `position`, `is_boss`, seuils et récompenses;
- `path_milestones`: `id`, `region_id`, `type`, `position`, `chest_id`, `is_active`;
- `user_level_progress`: progression fine et résultats;
- `user_region_progress`: monde débloqué/terminé;
- `user_chapter_progress`: optionnel et interne; supprimer si aucune règle métier ou statistique ne l’utilise;
- `users.current_city_id`: remplacer par `current_level_id` uniquement; le chapitre se déduit du niveau;
- `game_sessions.city_id`: remplacer par `chapter_id` seulement si l’audit historique par chapitre est utile, sinon le déduire de `level_id`.

Contraintes recommandées :

- unicité `(region_id, position)` pour les chapitres;
- unicité `(chapter_id, position)` pour les niveaux;
- unicité `(user_id, level_id)` pour la progression;
- un seul boss actif par monde;
- aucune progression vers un niveau inactif;
- journal de récompenses idempotent avec une clé unique de source.

### Migration sans interruption

1. Ajouter `chapter_id` nullable et les nouveaux modèles.
2. Copier `city_id` vers `chapter_id` en conservant les IDs.
3. Faire lire/écrire les deux champs pendant une courte période.
4. Basculer `/game/map` vers le nouveau projecteur.
5. Migrer les sessions et progressions historiques.
6. Rendre `chapter_id` obligatoire, retirer `city_id` et les endpoints publics de ville.

## 4. Progression serveur

`ProgressionService` construit une séquence déterministe par monde : niveaux triés par chapitre/position, jalons intercalés, puis boss. Après une session réussie, une transaction atomique :

1. verrouille la progression du joueur ;
2. marque le niveau terminé et conserve le meilleur résultat ;
3. attribue les récompenses une seule fois ;
4. rend le jalon suivant réclamable ou débloque le niveau suivant ;
5. si le boss est réussi, termine le monde, tamponne le passeport et débloque le premier niveau du monde suivant ;
6. invalide le cache de `/game/map`.

Un niveau rejoué peut améliorer score et étoiles, mais ne doit pas redonner les récompenses de première complétion. Les prérequis et le nombre de vies sont revérifiés au démarrage de session, même si la carte affichée est ancienne.

## 5. Contrat API cible

### `GET /game/map`

La réponse est spécifique à l’utilisateur et directement affichable :

```json
{
  "success": true,
  "data": {
    "world": {
      "id": 1,
      "number": 1,
      "name": "Abidjan",
      "subtitle": "La perle des lagunes",
      "is_completed": false
    },
    "progress": {
      "percent": 38,
      "completed_levels": 3,
      "total_levels": 8
    },
    "next_playable_level_id": 104,
    "nodes": [
      { "node_id": "level-101", "type": "level", "order": 1, "level_id": 101, "title": "Niveau 1", "state": "completed", "stars": 3 },
      { "node_id": "chest-12", "type": "chest", "order": 4, "title": "Coffre", "state": "claimable", "rewards": { "preview": "mystery" } },
      { "node_id": "level-104", "type": "level", "order": 5, "level_id": 104, "title": "Niveau 4", "state": "current", "total_questions": 10 },
      { "node_id": "boss-109", "type": "boss", "order": 10, "level_id": 109, "title": "Boss Abidjan", "state": "locked" }
    ]
  }
}
```

États autorisés : `completed`, `current`, `unlocked`, `locked`, `claimable`, `claimed`. Un seul nœud doit normalement être `current`. Aucun `chapter_id` ou nom de commune n’est requis par Flutter.

Endpoints conservés :

- `POST /game-sessions` avec uniquement `level_id`;
- endpoints de réponse et fin de session existants;
- `POST /chests/{userChest}/open`, l’identifiant réclamable pouvant être inclus dans le nœud coffre;
- `GET /levels/{id}` uniquement si le détail ne tient pas dans la carte.

Endpoints à déprécier côté application joueur : `GET /regions/{id}`, `GET /cities/{id}` et toute route permettant de sélectionner manuellement une commune. Ils peuvent rester privés pour l’administration.

Le backend doit appliquer cache privé par utilisateur/ETag, pagination inutile pour le monde courant, contrôle d’accès, rate limiting des sessions et sérialisation versionnée. La carte est une projection de lecture; MySQL reste la source de vérité.

## 6. Flutter

Architecture recommandée :

```text
game_map/
  data/game_map_api.dart
  models/game_map.dart
  providers/game_map_provider.dart
  screens/game_map_screen.dart
```

Le modèle client consomme `GameMap`, `GameWorld` et une liste plate de `GameMapNode`. Il ne calcule ni déblocage ni passage de chapitre. L’écran :

- affiche vies, XP et streak dans une barre compacte;
- affiche le monde et sa progression;
- place les nœuds sur un chemin vertical;
- met en évidence `current` avec « Continuer »;
- refuse localement le tap sur `locked`, puis laisse le serveur revérifier au lancement;
- rafraîchit carte, profil, vies et streak après une session terminée.

Les anciens modèles et écrans ville/région peuvent rester le temps de la migration, sans route depuis la navigation principale, puis être supprimés quand le backend n’en dépend plus. L’onglet principal doit être nommé **Parcours**. Classement, amis et profil restent secondaires et ne doivent jamais interrompre la boucle principale.

## 7. Structure V1 finale

```text
Joueur → Parcours → niveau courant → session serveur → résultat
                      ↑                         ↓
                GET /game/map ← ProgressionService
                                      ↓
             monde → chapitres internes → niveaux → boss
```

La V1 officielle retient donc : mondes visibles, chapitres invisibles, niveaux linéaires, coffres explicites, boss final et carte entièrement projetée par le backend. Cette séparation permet d’ajouter de nouveaux mondes, réordonner du contenu, expérimenter des jalons et mettre en cache la lecture sans complexifier l’application mobile.

