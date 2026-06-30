# ShowZx Lift

Un script FiveM qui permet aux joueurs de déployer une corde pour se lever et descendre de manière fluide et réaliste.

## Description

ShowZx Lift est un système de levage par corde complet qui permet aux joueurs de :
- Déployer une corde depuis leur position
- Se lever en utilisant la corde avec des animations personnalisées
- Descendre de manière contrôlée
- Interagir avec plusieurs joueurs sur différentes cordes

## Caractéristiques

- Système de corde dynamique avec détection du sol
- Animations personnalisées de déploiement et rétractation
- Contrôle du cooldown entre les actions
- Système de validation de la longueur de corde (min 10m, max 50m)
- Support multi-joueurs
- Mode debug intégré
- Commandes faciles à utiliser

## Utilisation

### Commandes

```
/rope    - Active le mode levage (déploie la corde)
/lower   - Désactive le mode levage (rétracte la corde)
```

### ox_target ou ContextMenu (détection automatique)

effectuer un alt click pour voir le menu de la rope

### Contrôles

- **E** - Interagir avec la corde
- **X** - Sortir de la preview

## Configuration

Éditez `config.lua` pour personnaliser le script :

```lua
-- Touches de clavier
ShowZxLiftConfig.Keys = {
    INTERACT = 38,      -- E
    TOGGLE_SUPPORT = 73 -- X
}

-- Distance minimale d'interaction
ShowZxLiftConfig.Distances = {
    MIN_DISTANCE = 1.5,
}

-- Cooldown entre les actions (millisecondes)
ShowZxLiftConfig.Cooldown = 3000

-- Animations
ShowZxLiftConfig.Animation = {
    SUPP = {
        DICTJUMP = "deployrope@animation",
        ANIMJUMP = "deployrope_clip",
    },
    LIFT = {
        DICTIDLE = "ropelift@animation",
        ANIMIDLE = "ropelift_clip",
    }
}

-- Durée des animations (millisecondes)
ShowZxLiftConfig.Lifting = {
    LIFT_DURATION = 7000,    -- Durée du levage
    DESCENT_DURATION = 6500, -- Durée de la descente
    HORIZ_DURATION = 800,    -- Durée du mouvement horizontal
}

-- Règles additionnelles
ShowZxLiftConfig.Rules = {
}
```

## Structure des fichiers

```
showzx_lift/
├── config.lua              # Configuration du script
├── fxmanifest.lua         # Manifest FiveM
├── clients/               # Scripts côté client
│   ├── main.lua          # Logique principale du client
│   ├── support.lua       # Gestion du mode support
│   ├── functions.lua     # Fonctions utilitaires
│   ├── event.lua         # Gestion des événements (lecture des animations)
│   ├── threads.lua       # Boucles de jeu (tout les thread et leurs gestions)
    └── integrations/     # Gestions des ALT+ Click
        ├── ox_target.lua         # Troisième oeil 
        └── shx_contextmenu.lua   # le célèbre ALT+ Click de Flashback WL         
├── server/              # Scripts côté serveur
│   └── main.lua         # Logique serveur
└── stream/              # Fichiers de streaming (animation, etc.)
```

## Installation

1. Télécharge le dossier `showzx_lift` dans ton dossier `resources`
2. Ajoute `ensure showzx_lift` dans ton `server.cfg`
3. Redémarre ton serveur ou utilise `/refresh`

## Fonctionnement technique

### Côté Client
- Gère le déploiement et la rétractation de la corde
- Lance les animations personnalisées
- Gère l'interaction du joueur avec la corde
- Synchronise les positions de la corde pour tous les joueurs

### Côté Serveur
- Valide les demandes de levage
- Gère les propriétaires de corde
- Synchronise les états entre les joueurs
- Enregistre les logs des actions
- Notifie le client que une personne est sur sa rope

### Validation
- Détection automatique du sol sous la corde
- Vérification de la longueur minimale (10m) et maximale (50m)
- Système de cooldown pour éviter les abus

### Nettoyage Automatique
- Le serveur gére les crash ou les déconnexions pour clean tout les client

## Debug

Pour activer le mode debug, modifie `config.lua` :

```lua
ShowZxLiftConfig.Debug = {
    ENABLED = true,  -- Affiche les messages de debug
}
```

## Notes

- La corde se génère toujours devant le joueur
- La position d'atterrissage est légèrement décalée du joueur pour éviter les clipping
- Le système supporte plusieurs cordes simultanément
- Les animations utilisent le dictionnaire d'animation personnalisé "deployrope@animation" et "ropelift@animation"

## Notes des choses à rajouter

- Je me questionne sur comment je peux faire pour que la corde ne reste pas suspendu dans les airs
- Meilleur animation
- La corde traverse les wall et prends du temps a être complétement droit

## Auteur

**ShowZx**

## Licence

Vérifiez si une licence est fournie avec le script (LICENSE.md)

---

**Support** : Pour des questions ou des bugs, mon discord : https://discord.gg/KRecJhw3mn

