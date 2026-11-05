# Gameplay

## Boucle principale

1. Le joueur ouvre l’application.
2. Il voit ses vies, son streak, sa ligue, son XP, ses coins/gems.
3. Il choisit une région.
4. Il choisit une ville ou commune.
5. Il lance un niveau déverrouillé.
6. Il répond aux questions.
7. Il termine la session.
8. Le backend calcule XP, points, coins et gems.
9. Sa progression est mise à jour.
10. Il peut débloquer coffre, collection ou passeport.
11. Il revient le lendemain pour conserver son streak.

## Monde / région

Une région est un monde de jeu. Elle contient des villes/communes et se complète généralement via un boss final. La région suivante est débloquée après réussite des conditions serveur.

## Ville / commune

Une ville organise les niveaux d’une zone. Exemple : dans Abidjan, Cocody peut contenir plusieurs niveaux progressifs.

## Niveau

Un niveau est une session de quiz. Il possède une difficulté, un nombre de questions, un score minimal de réussite, des récompenses et éventuellement le flag `is_boss`.

## Boss final

Un niveau boss représente la validation d’une région. S’il est réussi, le backend peut :

- compléter la région ;
- tamponner le passeport ;
- débloquer la région suivante ;
- attribuer un coffre plus intéressant.

## Déblocage

Le joueur commence avec le premier niveau de la première ville de la première région active. Après réussite, `ProgressionService` débloque le niveau suivant, puis la ville suivante, puis la région suivante selon l’ordre configuré.

## Vies

Une vie est requise pour lancer une session. La disponibilité est vérifiée côté serveur. Les vies se régénèrent avec `next_life_at`; Flutter doit seulement afficher l’état retourné.

## Streak

Le streak récompense la régularité. Après une partie terminée, le serveur met à jour la série quotidienne. Les freezes peuvent limiter la casse après une journée manquée.

## Ligues

Les ligues utilisent l’XP gagnée pendant la saison courante. Le classement peut être accéléré par Redis, mais MySQL conserve les membres et l’XP officielle.

## Coffres

Les coffres sont gagnés après certains événements, par exemple boss ou excellente précision. Un coffre utilisateur passe de `available` à `opened` et ne peut pas être rouvert.

## Collections

Les collectibles représentent des personnalités ou monuments. Ils peuvent être liés à une région ou une ville et se débloquent par session ou coffre.

## Passeport

Le passeport affiche les régions complétées. Un tampon est attribué après réussite du boss régional.

## Exemple concret

```text
Abidjan → Cocody → Niveau 1 → Niveau 2 → Boss Abidjan → Passeport Abidjan
```

Le joueur lance `Niveau 1` à Cocody. Il répond à toutes les questions, termine la session, obtient XP/coins si la précision atteint le seuil, puis débloque le niveau suivant. Après le boss Abidjan, il reçoit le tampon Abidjan dans son passeport.
