# Publication Google Play — IvoireQuiz

## Fiche Play Store

**Nom de l'application** : IvoireQuiz

**Description courte** (75 caractères) :

> Testez votre culture ivoirienne avec des quiz, défis et classements.

**Description complète** :

> Découvrez la Côte d'Ivoire en vous amusant avec IvoireQuiz.
>
> Répondez à des quiz de culture générale, progressez dans la campagne,
> comparez vos scores et défiez vos amis. Chaque partie vous aide à approfondir
> vos connaissances sur l'histoire, la géographie, la culture et les richesses
> de la Côte d'Ivoire.
>
> Fonctionnalités principales :
> - quiz par catégorie et quiz mixtes ;
> - campagne et progression ;
> - défis entre amis ;
> - classements et statistiques ;
> - notifications pour les défis et demandes d'ami ;
> - réglages d'accessibilité, du son et des animations.

**Catégorie suggérée** : Jeux > Culture générale.

**Coordonnées à compléter avant publication** :

- E-mail d'assistance : `[À RENSEIGNER]`
- URL du site : `https://laravelquizz.studiobeyam.net` ou `[URL PUBLIQUE]`
- URL publique de la politique de confidentialité : `[À PUBLIER]`
- URL publique de suppression de compte : `[À CRÉER]`

## Politique de confidentialité — projet de texte

Dernière mise à jour : 4 novembre 2026.

IvoireQuiz collecte les informations nécessaires au fonctionnement du compte et
du jeu : nom, adresse e-mail, identifiant de compte, résultats de parties,
progression, relations d'amitié et défis. Si l'utilisateur choisit la connexion
Google, l'application reçoit les informations de profil autorisées par Google.

L'application utilise également un identifiant d'installation Firebase afin
d'envoyer des notifications concernant les défis et les demandes d'ami. Les
préférences d'accessibilité et de son sont enregistrées localement sur
l'appareil. Le jeton de connexion est conservé dans le stockage sécurisé de
l'appareil.

Ces données servent uniquement à authentifier l'utilisateur, fournir les
fonctionnalités du jeu, synchroniser sa progression, afficher les classements,
gérer les interactions entre amis, prévenir la fraude et envoyer les
notifications demandées. Elles ne sont pas vendues.

Les données sont transmises sous forme chiffrée par HTTPS au serveur IvoireQuiz
et, pour l'authentification ou les notifications, aux services Google concernés.
Elles sont conservées pendant la durée nécessaire au fonctionnement du compte
et aux obligations légales applicables.

L'utilisateur peut demander l'accès, la correction ou la suppression de ses
données depuis `[MÉTHODE/URL À CRÉER]` ou en écrivant à `[E-MAIL À RENSEIGNER]`.
Une demande de suppression entraîne la suppression du compte et des données
associées, sous réserve des obligations légales de conservation.

Contact du responsable du traitement : `[NOM OU SOCIÉTÉ, ADRESSE, E-MAIL]`.

> Ce texte doit être validé par le responsable du produit et publié sur une URL
> accessible sans connexion. Il ne constitue pas un avis juridique.

## Formulaire « Sécurité des données » — réponses préparatoires

À confirmer avec le backend et les fournisseurs avant déclaration définitive :

| Type de données | Collecté | Finalité | Partagé avec |
|---|---:|---|---|
| Nom | Oui | Compte, profil, classement | Prestataire d'hébergement |
| Adresse e-mail | Oui | Compte et authentification | Hébergeur, Google si connexion Google |
| Identifiants utilisateur | Oui | Compte, amis, défis | Hébergeur |
| Activité dans l'application | Oui | Scores, progression, statistiques | Hébergeur |
| Identifiant d'installation | Oui | Notifications push | Firebase Cloud Messaging |
| Mot de passe | Oui, envoyé au serveur | Authentification | Hébergeur |
| Préférences de l'application | Localement | Accessibilité, audio | Non partagé |

- Chiffrement en transit : **Oui (HTTPS)**.
- Suppression des données : **à implémenter avant publication**.
- Compte requis : **Oui** pour les fonctionnalités synchronisées.
- Publicité : **aucun SDK publicitaire détecté dans l'application**.
- Achats intégrés : **aucun achat intégré détecté dans l'application**.

## Classification du contenu — éléments proposés

- Jeu de quiz/culture générale.
- Pas de violence graphique, contenu sexuel, jeu d'argent ou drogue identifié.
- Interactions entre utilisateurs limitées aux amis, défis, noms de profil et
  classements ; aucun chat libre n'est présent dans le client actuel.
- Répondre au questionnaire IARC selon le contenu réel de toutes les questions
  stockées sur le serveur.

## Captures à fournir

Minimum conseillé : téléphone Android, portrait, sans données personnelles.

1. Accueil avec les catégories.
2. Question de quiz et chronomètre.
3. Résultat de partie.
4. Carte de campagne.
5. Classement.
6. Écran amis/défis.
7. Profil et statistiques.

## Test interne obligatoire

- [ ] Installer depuis la piste de test Play, pas par USB.
- [ ] Créer un compte puis se reconnecter.
- [ ] Tester Google Sign-In avec la clé de signature Google Play.
- [ ] Terminer un quiz par catégorie et un quiz mixte.
- [ ] Vérifier une partie contenant moins de 10 questions.
- [ ] Créer, recevoir et terminer un défi entre deux comptes.
- [ ] Tester une demande d'ami et son acceptation.
- [ ] Recevoir une notification app ouverte, en arrière-plan et fermée.
- [ ] Vérifier la déconnexion et l'absence de notifications après déconnexion.
- [ ] Tester le lancement sans réseau puis la reprise du réseau.
- [ ] Vérifier les écrans avec une grande taille de texte.

## Empreintes OAuth Google

Les valeurs de la clé d'upload sont générées dans
`docs/google-signing-fingerprints.txt`. Ajouter dans Google Cloud/Firebase un
client OAuth Android pour le package `net.studiobeyam.ivoirequiz` avec ce SHA-1.

Après activation de Play App Signing, copier également les SHA-1 et SHA-256 de
**Play Console > Intégrité de l'application > Certificat de clé de signature de
l'application**, puis créer/vérifier un second client OAuth Android utilisant le
même package. Le certificat Play ne peut pas être déduit du keystore local.

## Blocages avant production

- Ajouter une suppression de compte dans l'application et une URL web publique.
- Corriger le refus serveur des sessions contenant moins de 10 questions.
- Remplacer tous les champs `[À RENSEIGNER]` de cette page.
- Valider le parcours complet depuis une piste de test Play.
