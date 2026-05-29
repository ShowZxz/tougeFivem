# interaction_lift

interaction_lift est un script 100% standalone permettant aux joueurs d’interagir physiquement entre eux pour aider à monter ou se hisser grâce à deux mécaniques réalistes (Legs Up & Pull Up).

## Mon Discord : https://discord.gg/cumGDjwz

#### Legs Up permet :

Réaliser une courte échelle a l'aide d'un autre joueur pour aider a atteindre des hauteurs qui sont impossible via l'escalade de base de GTA V

#### Pull up  permet : 

Hisser un joueur pour l'aider un obstacle dur a atteindre

Ces deux mécanique combiné permet d'avoir un niveau de mobilité plus important que le jeu offre de base en restant le plus réaliste possible 

Le script est conçu pour être immersif, optimisé, et totalement indépendant de tout framework (ox_target / ContexMenu / etc.).

Il a été conçus pour être utilisable dans les serveurs RP et les serveurs PVP pour offrir une meilleur exploitation de la map gta V de façon RP

## Information

#### Requis

- Aucune le script fonctionne 100% standalone

#### Facultatif mais nécessaire pour du RP ( détection automatique )

- ox_target (option 1)

- ContextMenu (option 2)

- Le script détecte automatiquement les ressources disponibles et s’adapte sans configuration supplémentaire.


## Caractéristiques

### 🦵 Legs Up (Courte échelle)

- Un joueur peut servir de support pour permettre à un autre de monter

- Vérifications de position, hauteur et de l'environnement

- Animation synchronisée

- Interaction via ox_target ou ContextMenu (Facultatif)

### 🧗 Pull Up (Aide à la montée)

- Aide un joueur à se hisser depuis un rebord

- Distance minimale et maximale configurable + Durée de l'animation réglable via Config.lua

- Gestion physique propre (pas de glitch / boost)

### Support activable via :

- ox_target (Third Eye)

- ContextMenu

- Touches clavier (fallback) Standalone

### Proxy Ped System (Third Eye Compatible)

#### Pour contourner les limitations de targeting sur les peds en animation :

Le script crée un ped proxy pour pouvoir target les joueurs en mode support afin de contourner les limitations dues au script qui permet "Alt + Click" l'identifiant (netId) est partagé sur le réseau + une suppression synchronisée coté serveur /  Gestion des crashs et déconnections inattendu.

## Securité

#### Le support est automatiquement supprimé si :

- Le joueur prend des dégâts

- Le joueur est tazé

- Le joueur meurt

- Le joueur tombe / ragdoll

- Le joueur quitte le serveur ou crash

- Nettoyage serveur + client garanti (aucun proxy ped fantôme)

## Configuration

#### Toutes les options sont centralisées dans config.lua :

- Distances min / max par mode

- Cooldowns

- Touches clavier

- Animations

- etc...

## Performance

- Aucun thread lourd permanent

- Threads actifs uniquement en interaction

- Proxy peds créés uniquement quand nécessaire

- Impact CPU quasi nul en repos

- Compatible sur tout type de serveur


## Support

Pour toute question, bug ou suggestion :

Mon Discord : https://discord.gg/cumGDjwz

Merci d’éviter les messages privés, utilisez les canaux dédiés

## Patchnotes

#### v1.0.0

#### Release initiale

- Legs Up & Pull Up

- ox_target support

- ContextMenu support

- Proxy ped system
