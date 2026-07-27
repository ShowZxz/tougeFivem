WhoIAm
======

Description
-----------
`WhoIAm` est un petit mini-jeu RP pour FiveM où chaque joueur reçoit (ou choisit) un mot à faire deviner aux autres joueurs. Le script gère une file d'attente (lobby), le démarrage de la partie, la téléportation des joueurs dans une zone circulaire, et la logique de devinette.

Installation
------------
- Copier le dossier `whoiam` dans votre dossier `resources/` du serveur.
- Dans `server.cfg`, ajoutez :

```
ensure whoiam
```

- Le `fxmanifest.lua` expose une UI NUI située dans `html/` (index.html). Assurez-vous que les fichiers listés dans `fxmanifest.lua` sont présents.

Fichiers importants
-------------------
- [fxmanifest.lua](resources/whoiam/fxmanifest.lua): manifest de la ressource.
- [config.lua](resources/whoiam/config.lua): configuration (coordonnées, limites, etc.).
- [clients/](resources/whoiam/clients): code client (affichage 3D, UI, animations).
- [server/](resources/whoiam/server): logique serveur (queue, assignation des mots, état du jeu).
- [words.json](resources/whoiam/words.json) et [banWords.json](resources/whoiam/banWords.json): lexiques utilisés.


Événements réseau (server -> client)
-----------------------------------
- `whoiam:startGame` — démarre la partie et envoie la table des mots.
- `whoiam:addMessage` / `whoiam:addErrorMessage` — messages utilisateurs.
- `whoiam:teleportPlayers` — téléporte un joueur (coords, isJoin).
- `whoiam:playerGuessed` — notifie qu'un joueur a deviné.
- `whoiam:resetPlayer`, `whoiam:removePlayer` — gestion des états clients.
- `whoiam:playAnimation` — joue une animation côté client (`valid`/`invalid`).

Événements (client -> server / NUI)
----------------------------------
- `whoiam:join`, `whoiam:leave`, `whoiam:startGame` — actions déclenchées côté client (utilisées aussi par commandes).
- `whoiam:setWord` / `whoiam:guessWord` — utilisés par le NUI pour envoyer le mot choisi ou la tentative.

Configuration
-------------
Toutes les options principales sont dans [config.lua](resources/whoiam/config.lua).
- `Config.MaxPlayers` : nombre maximum de joueurs en file.
- Coordonnées : `Config.Coords.lobby`, `Config.Coords.game`, `Config.Coords.initialPosition` — ajustez pour votre map.
- `Config.Locations` : points interactifs (join/leave/start) avec `pos`, `message`, `marker`, etc.
- Divers : `Config.MaxLengthWord`, `Config.MinLengthWord`, `Config.DrawDistance`, `Config.AreaRadius`.

Dépannage
---------
- Si la ressource ne démarre pas, consultez la console du serveur pour les erreurs liées à `whoiam`.
- Vérifiez que `html/index.html`, `html/script.js` et `html/style.css` existent si l'UI ne s'affiche pas.
- Confirmez que `words.json` et `banWords.json` sont valides JSON (sinon la ressource peut planter au chargement).

Bonnes améliorations possibles
-----------------------------
- Ajouter une interface d'administration pour ajuster `MaxPlayers` et positions sans redéployer.

Contribuer
----------
- Ouvrez une issue ou proposez une pull request avec une description claire des changements.

Crédits
-----------------
- Auteur: ShowZx

