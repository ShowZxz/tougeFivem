Config = {}

-- ============================================================
-- TOUCHE D'ACTIVATION
-- Utilise RegisterKeyMapping -> le joueur peut la remapper lui-même
-- dans Paramètres FiveM > Touches > Ressources
-- ============================================================
Config.KeyMapping = {
    defaultKey  = 'K',
    description = 'Activer/Désactiver le mode Akimbo'
}

-- ============================================================
-- ARMES AUTORISÉES (pistolets + SMG légères)
-- category détermine les offsets d'attache du prop secondaire
-- Ajoute/retire des lignes selon ton pack d'armes (armes custom incluses)
-- ============================================================
Config.AllowedWeapons = {
    [`WEAPON_PISTOL`]        = { category = 'pistol' },
    [`WEAPON_PISTOL_MK2`]    = { category = 'pistol' },
    [`WEAPON_COMBATPISTOL`]  = { category = 'pistol' },
    [`WEAPON_APPISTOL`]      = { category = 'pistol' },
    [`WEAPON_PISTOL50`]      = { category = 'pistol' },
    [`WEAPON_VINTAGEPISTOL`] = { category = 'pistol' },
    [`WEAPON_SNSPISTOL`]     = { category = 'pistol_small' },
    [`WEAPON_SNSPISTOL_MK2`] = { category = 'pistol_small' },
    [`WEAPON_MICROSMG`]      = { category = 'smg' },
    [`WEAPON_MACHINEPISTOL`] = { category = 'smg' },
}

-- ============================================================
-- OFFSETS D'ATTACHE DU PROP SECONDAIRE (main gauche)
-- boneId 18905 = SKEL_L_Hand
-- À ajuster à l'oeil selon ton style (pos en mètres, rot en degrés)
-- ============================================================
Config.AttachOffsets = {
    pistol = {
        bone = 18905,
        pos  = vector3(0.135, 0.02, -0.002),
        rot  = vector3(-90.0, 8.0, -5.0)
    },
    pistol_small = {
        bone = 18905,
        pos  = vector3(0.12, 0.015, -0.002),
        rot  = vector3(-90.0, 8.0, -5.0)
    },
    smg = {
        bone = 18905,
        pos  = vector3(0.14, 0.035, 0.01),
        rot  = vector3(-90.0, 4.0, -8.0)
    }
}

-- ============================================================
-- MUNITIONS DE LA MAIN SECONDAIRE
-- Séparées du chargeur principal (le jeu gère l'arme principale nativement)
-- ============================================================
Config.OffhandStartAmmo   = false -- true = copie le chargeur actuel au moment de l'activation
Config.OffhandDefaultAmmo = 12    -- utilisé si OffhandStartAmmo = false

-- ============================================================
-- DÉGÂTS DU TIR SCRIPTÉ (main secondaire)
-- Pas de native fiable cross-version pour lire le dégât natif d'une arme,
-- donc valeur fixe ici. Tu peux la remplacer par une table par arme si besoin :
-- Config.OffhandDamage = { [`WEAPON_PISTOL`] = 15.0, [`WEAPON_MICROSMG`] = 10.0, default = 12.0 }
-- ============================================================
Config.FixedOffhandDamage = 15.0

-- Distance max du raycast de tir (mètres)
Config.MaxShootDistance = 100.0

-- Cadence minimale entre deux tirs de la main secondaire (ms)
-- Évite le spam si le joueur martèle la touche de tir
Config.OffhandFireCooldown = 80

-- ============================================================
-- RESTRICTIONS D'ACTIVATION
-- ============================================================
Config.DisallowInVehicle = true
Config.DisallowInWater   = true
Config.DisallowRagdoll   = true

-- Désactive automatiquement l'akimbo si le joueur change d'arme ou meurt
Config.AutoDisableOnWeaponSwitch = true

-- Effet visuel de tir (flash au canon) pour la main secondaire
Config.MuzzleFlash = true
