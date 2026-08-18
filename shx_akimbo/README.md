# Akimbo Weapons (Standalone)

Script standalone pour FiveM permettant le tir en akimbo (pistolets + SMG légères).
Conçu pour être plug-and-play sur n'importe quel serveur, puis adaptable à ESX/QBCore/autre.

## Installation

1. Copie le dossier `akimbo` dans `resources/`
2. Ajoute `ensure akimbo` dans ton `server.cfg`
3. En jeu, équipe une arme autorisée (voir `config.lua`) et appuie sur **K** (remappable dans les paramètres FiveM)

## Fonctionnement

- **Prop attaché** : l'arme secondaire est un simple objet attaché à la main gauche, pas un ped fantôme
- **Sync automatique** : utilise les *state bags* FiveM (`Entity(ped).state`), donc aucun event serveur n'est nécessaire pour que les autres joueurs voient ton arme secondaire
- **Tir scripté** : chaque pression de tir déclenche un raycast pour la main secondaire (dégâts + munitions séparées de l'arme principale, qui continue de fonctionner nativement)
- **Dégâts réseau** : les dégâts sur un autre joueur passent par le serveur (`akimbo:requestDamage` → `akimbo:receiveDamage`) pour éviter qu'un client applique directement des dégâts à un autre client

## Configuration

Tout se passe dans `config.lua` :
- `Config.AllowedWeapons` — armes autorisées et leur catégorie (offsets d'attache)
- `Config.AttachOffsets` — position/rotation du prop secondaire par catégorie d'arme
- `Config.OffhandDefaultAmmo` / `Config.FixedOffhandDamage` — munitions et dégâts de la main secondaire
- `Config.DisallowInVehicle` / `InWater` / `Ragdoll` — restrictions d'activation

## Adapter à un framework (ESX, QBCore, etc.)

Le script est volontairement neutre. Deux points d'accroche côté serveur :

### 1. Restreindre l'usage (permission / item d'inventaire)

Crée un petit script bridge (ex: `akimbo_bridge`) qui s'exécute après `akimbo` :

```lua
-- exemple ESX : nécessite l'item "akimbo_kit" dans l'inventaire
exports['akimbo']:SetPermissionCheck(function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.getInventoryItem('akimbo_kit').count > 0
end)
```

```lua
-- exemple QBCore
exports['akimbo']:SetPermissionCheck(function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player.Functions.GetItemByName('akimbo_kit') ~= nil
end)
```

Par défaut (sans bridge), tout le monde peut utiliser l'akimbo — comportement standalone.

### 2. Vérifier la permission côté client avant activation

Si tu veux bloquer l'activation localement (pas juste les dégâts), ajoute dans `client.lua`,
au début de `EnableAkimbo()` :

```lua
local canUse = lawaitexports['akimbo']:CanUseAkimbo(...) -- à adapter : ceci nécessite un export client
```

Le plus simple en pratique : fait un `TriggerServerCallback` (ESX/QBCore ont ça nativement,
ou utilise `ox_lib`) qui appelle `exports['akimbo']:CanUseAkimbo(source)` côté serveur avant
de laisser le client activer l'akimbo.

## ⚠️ Sécurité / anti-cheat

Le tir scripté de la main secondaire fait confiance au client tireur pour le relai de dégâts
(`server.lua`, event `akimbo:requestDamage`). C'est le même modèle que beaucoup de systèmes
FiveM, mais reste exploitable par un client modifié. Pour un serveur PvP sérieux, ajoute côté
serveur :
- une vérification de distance entre les deux joueurs
- un cap strict sur les dégâts (déjà présent, basique)
- idéalement, une détection d'anomalies (fréquence de tir, distance incohérente, etc.)

## Limites connues

- Aucune animation "vraie" de dual-wield (le jeu n'en a pas nativement) : le rendu repose sur
  l'arme principale (animation normale du jeu) + l'arme secondaire visible mais sans anim de tir
  dédiée. Si tu veux une pose bras gauche plus convaincante, il faudra soit un anim dict custom
  soit accepter ce compromis.
- Les dégâts sur véhicules sont volontairement simples (moteur uniquement) — à étoffer si besoin.
