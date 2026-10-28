# Son global — conception

## Intention

Donner une identité sonore à IvoireQuizz avec une musique d'ambiance continue
dans toute l'application et des effets courts pendant le jeu, sans voix.

## Choix retenus

- Utiliser `audioplayers` avec un service audio unique partagé par l'app.
- Lire uniquement des fichiers locaux afin de fonctionner hors ligne.
- Jouer la musique en boucle à volume discret et les effets sur un canal séparé.
- Ajouter deux réglages persistants : « Musique » et « Effets sonores ».
- Mettre la musique en pause lorsque l'app passe en arrière-plan et la reprendre
  au retour si elle est activée.
- Jouer des effets pour bonne réponse, mauvaise réponse/temps écoulé, victoire
  et défaite.
- Créer des sons originaux simples dans le dépôt, sans contenu tiers.

## Direction musicale validée

La musique suit une esthétique **quiz télé moderne français** : claire,
élégante et immédiatement identifiable comme un jeu de culture générale, sans
sonorités arcade ni identité traditionnelle marquée.

- Boucle de 25 à 30 secondes, à tempo modéré.
- Marimba doux ou son percussif mélodique proche, basse ronde et discrète.
- Accords lumineux et petites percussions électroniques légères.
- Arrangement peu chargé pour rester agréable dans toute l'application et
  pendant la lecture des questions.
- Boucle sans coupure perceptible et volume inférieur aux effets.

Les effets suivent la même identité :

- bonne réponse : confirmation lumineuse et brève ;
- mauvaise réponse / temps écoulé : signal doux, sans son agressif ;
- victoire : courte montée élégante ;
- défaite : descente sobre, sans tonalité comique.

## Non-objectifs

- Pas de lecture vocale des questions.
- Pas de lecture audio lorsque l'application est fermée.
- Pas de contrôle depuis l'écran verrouillé ni de streaming.
- Pas de jingle enfantin, de son rétro 8-bit ou d'effet de casino.

## Contraintes

- Android et iOS sont prioritaires.
- Les erreurs audio ne doivent jamais bloquer le jeu.
- Les préférences existantes et les changements non commités doivent être
  préservés.

## Approches considérées

- `audioplayers` avec service central : retenue pour sa simplicité et la lecture
  simultanée de musique et d'effets.
- `just_audio` avec plusieurs lecteurs : plus puissant, mais inutilement lourd
  pour des assets locaux simples.
- Lecteurs créés dans chaque écran : écarté, car la musique redémarrerait à la
  navigation et les réglages seraient dupliqués.

## Source finale

La recherche a étudié SoundDino et Pixabay. Pixabay autorise l'utilisation et
l'adaptation de ses contenus dans une œuvre plus large, mais interdit leur
redistribution autonome. La piste « Quiz Master » de BackgroundMusicMaster a
servi de référence de direction ; son téléchargement automatisé étant bloqué,
elle n'est pas incluse dans le dépôt.

La livraison finale utilise donc une composition originale générée localement
par `tool/generate_quiz_audio.dart`. Elle ne nécessite ni attribution ni
licence tierce et peut être régénérée à l'identique.

