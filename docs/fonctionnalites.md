# Fonctionnalités

## Démarrage et présentation

- **Écran de démarrage** ([`ivoire_quiz_splash_screen.dart`](../lib/features/onboarding/screens/ivoire_quiz_splash_screen.dart)) :
  logo, titre et barre de progression animés sur fond blanc, puis
  redirection automatique (voir [Architecture › Navigation](architecture.md#navigation)).
- **Présentation** ([`onboarding_screen.dart`](../lib/features/onboarding/screens/onboarding_screen.dart)) :
  pages à faire défiler. « Commencer » enregistre `onboarding_done` et ouvre
  l'écran de connexion ; le lien « J'ai déjà un compte » y mène aussi.

## Connexion et inscription

[`auth_screen.dart`](../lib/features/auth/screens/auth_screen.dart), deux
onglets :

- **Inscription** : nom, email, mot de passe (8 caractères minimum) et
  confirmation, vérifiés dans l'app avant l'envoi.
- **Connexion** : email et mot de passe.
- **Google** : bouton « Continuer avec Google ». L'app obtient un `idToken`
  Google et l'envoie au backend, qui renvoie le jeton IvoireQuizz. Configuration
  dans [Développement › Google Sign-In](developpement.md#google-sign-in).

Dans les trois cas, le jeton reçu est enregistré (`auth_token`) et l'app ouvre
l'accueil. Les messages d'erreur du serveur (champ `message` ou première erreur
de `errors`) sont affichés sous le formulaire.

## Accueil

[`home_screen.dart`](../lib/features/home/screens/home_screen.dart) :

1. **En-tête** : initiales, nom et score total du joueur.
2. **Carte « Mode Campagne »** → carte Campagne.
3. **Choix du mode** : « Par catégorie » ou « Mode mixte » (bouton « Lancer le
   mode mixte »), plus le bouton « Questions du jour ».
4. **« Reprendre ma partie »** si une partie a été interrompue (question
   *n* sur *total*).
5. **Catégories** : grille des catégories ; « Voir tout » ouvre la liste complète
   ([`all_categories_screen.dart`](../lib/features/home/screens/all_categories_screen.dart)).
6. **Dernière partie** avec « Voir le détail → » qui rouvre son résultat.

L'accueil affiche d'abord le cache (`home_cache`) puis charge en parallèle
l'utilisateur et les catégories, et enfin la dernière partie. Un écran
squelette s'affiche tant qu'aucune donnée n'est disponible.

## Jouer une partie

Un seul écran gère tous les modes :
[`quiz_screen.dart`](../lib/features/quiz/screens/quiz_screen.dart).

### Les modes

| Mode | Lancement | Questions | Fin de partie |
|---|---|---|---|
| `category` | Accueil → une catégorie | `GET /quiz/questions?mode=category&category_id=…` | `POST /sessions` |
| `mixed` | « Lancer le mode mixte » | `GET /quiz/questions?mode=mixed` | `POST /sessions` |
| `daily` | « Questions du jour » : une série commune à tous les joueurs, renouvelée chaque jour | `GET /quiz/questions?mode=daily` | `POST /sessions` |
| `challenge` | Code de défi (Amis) | `GET /challenges/{code}` | `POST /challenges/{code}/submit` |
| `campaign` | Carte Campagne → un niveau | reçues au démarrage du niveau | chaque réponse validée par le serveur, puis `POST /v1/game-sessions/{id}/finish` |

### Déroulé

1. **Écran d'avant-partie** (sauf Campagne et reprise) : explication du mode et
   sélecteur « Temps par question » (10, 15, 20 ou 30 s). Les questions ne sont
   téléchargées qu'au moment où le joueur démarre.
2. **Question** : compteur « Question *n* sur *total* », badge de difficulté,
   minuteur, options de réponse. Le minuteur dure **20 s** ; en Campagne, il
   prend le `time_limit` de la question. Le choix fait à l'étape 1 n'est pas
   appliqué (voir [Problèmes connus](problemes-connus.md#bugs-ouverts)).
3. **Réponse** : la bonne option passe en vert, la mauvaise en rouge, et
   l'explication s'affiche avec un effet sonore correspondant. La question
   suivante arrive **2 secondes** plus tard. Si le temps s'écoule, la question
   compte comme « pas de réponse » et joue l'effet de mauvaise réponse.
4. **Fin** : « Calcul de votre score… » pendant l'envoi, puis l'écran de
   résultat.

Hors Campagne, l'app juge elle-même la réponse grâce au champ `is_correct` des
options reçues ; le serveur recalcule les points à l'envoi. En Campagne, chaque
réponse est envoyée au serveur, qui dit si elle est juste
(`POST /v1/game-sessions/{id}/answer`).

### Reprendre une partie interrompue

Après chaque réponse, la partie est sauvegardée dans `active_quiz_draft`
(questions, réponses, question courante, heure de début). Si l'app est fermée,
l'accueil propose « Reprendre ma partie », qui relance le quiz exactement à
cette question. Pas de sauvegarde pour les défis, la Campagne et les parties
hors ligne.

### Jouer hors ligne

Chaque série de questions reçue est gardée dans
`quiz_cache_<categorie>_<mode>`. Si le chargement échoue (pas de réseau, erreur
serveur, réponse vide), l'app rejoue la dernière série gardée pour ce mode et
cette catégorie. Le score est alors calculé sur le téléphone : **100 points par
bonne réponse**. Le résultat est stocké dans `offline_results` et l'écran de
résultat précise « Partie hors ligne : … non compté dans le classement ».

### Si l'envoi de la partie échoue

Un encadré rouge affiche le message du serveur et un bouton « Réessayer la fin
de partie ». La partie reste sauvegardée et peut être renvoyée.

## Campagne

[`campaign_map_screen.dart`](../lib/features/campaign/screens/campaign_map_screen.dart).

- **Carte** (`GET /v1/game/map`) : liste de **régions**, chacune avec ses
  **villes**, chacune avec ses **niveaux**. Chaque élément affiche sa
  progression (anneau en %) et son état : Verrouillée, Accessible ou Terminée.
- **Niveau** : icône (cadenas, drapeau, coche, ou couronne pour un niveau
  « boss »), nombre de questions, XP gagnée, barre de progression et étoiles
  (0 à 3).
- **Fiche du niveau** (au toucher) : scène d'arrivée animée avec la photo de la
  ville, objectifs, état et progression (`GET /v1/levels/{id}`), puis bouton
  « Je suis prêt ! ».
- **Démarrage** (`POST /v1/levels/{id}/start`) : le serveur crée une session et
  renvoie ses questions ; le quiz s'ouvre directement, sans écran d'avant-partie.
- **Fin** : le résultat affiche aussi l'XP, les pièces et les gemmes gagnées
  quand le serveur les renvoie. « Rejouer » ramène à la carte.

## Résultat

[`result_screen.dart`](../lib/features/result/screens/result_screen.dart) et
[`result_celebration.dart`](../lib/features/result/widgets/result_celebration.dart).

### Les chiffres affichés

Ils sont lus par [`ResultScore`](../lib/features/result/models/result_score.dart),
qui accepte des nombres envoyés en entier, en décimal ou en texte :

| Champ affiché | Clé lue | Si la clé manque |
|---|---|---|
| Bonnes réponses | `correct_answers` | 0 (borné entre 0 et le nombre de questions) |
| Nombre de questions | `total_questions` | nombre de réponses, sinon 10 |
| Points gagnés | `total_score` | `score` + `bonus_score` |
| Score de base | `score` | `total_score` − `bonus_score` (jamais négatif) |
| Bonus rapidité | `bonus_score` | 0 |

### Victoire ou défaite

Le palier dépend du **pourcentage** de bonnes réponses, pour fonctionner aussi
avec les niveaux qui n'ont pas 10 questions :

| Palier | Condition | Étoiles | Mascotte | Animation |
|---|---|---|---|---|
| **PARFAIT !** | toutes justes | 3 | Effobi qui saute | rayons dorés, gros jet de confettis, titre scintillant |
| **VICTOIRE !** | ≥ 70 % | 2 (3 dès 90 %) | Effobi qui saute | rayons dorés, confettis |
| **PAS MAL !** | ≥ 40 % | 1 | Effobi qui réfléchit et se balance | apparition douce |
| **DOMMAGE…** | < 40 % | 0 | Effobi qui tombe et secoue la tête | secousse d'impact, étoiles grises qui tremblent, fond gris-bleu |

Dans tous les cas, le nombre de bonnes réponses et les points défilent depuis
0, et le téléphone vibre à l'arrivée de la mascotte et de chaque étoile. Les
confettis sont aux couleurs orange, vert et or. Avec « Réduire les animations »,
tout s'affiche directement, sans mouvement ni confettis.

Un effet de victoire accompagne les paliers « PARFAIT » et « VICTOIRE » ; les
autres paliers utilisent l'effet de défaite. Ces effets respectent le réglage
« Effets sonores » du profil.

### Le reste de l'écran

- **Détail des réponses** : question, réponse donnée, bonne réponse,
  explication, points gagnés.
- **Défi** : un bandeau affiche les deux scores et se met à jour toutes les
  5 secondes jusqu'à ce que l'adversaire ait joué.
- **Boutons** : « Rejouer » (même mode et catégorie, ou la carte pour la
  Campagne) et « Retour à l'accueil ».

## Amis et défis

[`friends_screen.dart`](../lib/features/friends/screens/friends_screen.dart).

- **Code ami** : chaque joueur a un code (visible et copiable dans le profil).
  « Ajouter » envoie une demande avec le code d'un autre joueur.
- **Demandes reçues** : accepter ou refuser.
- **Défier un ami** : crée un défi ; son code (8 caractères) est copié dans le
  presse-papiers pour l'envoyer à l'ami, et la partie démarre aussitôt.
- **« Code défi »** : saisir le code reçu d'un ami pour jouer le même défi.
  Les deux joueurs ont les mêmes questions ; le vainqueur est connu quand les
  deux ont joué.

## Classement

[`leaderboard_screen.dart`](../lib/features/leaderboard/screens/leaderboard_screen.dart),
trois onglets :

| Onglet | Source | Remarques |
|---|---|---|
| Général | `GET /leaderboard/global?page=n` | bouton « Charger plus de joueurs » |
| Cette semaine | `GET /leaderboard/weekly?page=n` | bouton « Charger plus de joueurs » |
| Amis | `GET /leaderboard/friends` | si vide : `GET /friends`, trié par score |

La ligne du joueur connecté est mise en avant (identifié via `GET /auth/me`).

## Profil

[`profile_screen.dart`](../lib/features/profile/screens/profile_screen.dart) :

- **En-tête** : initiales, nom, email masqué, niveau et code ami (copiable).
- **Statistiques** (`GET /profile/stats`) et **progression par catégorie**.
- **Historique des parties** → écran complet
  ([`history_screen.dart`](../lib/features/profile/screens/history_screen.dart)).
- **Badges et objectifs** (`GET /achievements`).
- **Partager le jeu** : message d'invitation fourni par le serveur
  (`GET /friends/invite`), ou message de secours avec le code ami. Si le menu
  de partage échoue, le message est copié.
- **Réglages d'affichage** : taille du texte (×1 à ×1,4), contraste renforcé,
  réduire les animations.
- **Réglages audio** : musique d'ambiance globale et effets sonores, activables
  séparément. Les choix sont conservés après fermeture de l'application.
- **Déconnexion** : `POST /auth/logout`, suppression du jeton, retour à
  `/auth`.

Les données facultatives (statistiques, historique, badges) se chargent
séparément : si l'une échoue, le reste du profil s'affiche quand même.
