Config = {}


Config.KeyMapping = {
    defaultKey  = 'K',
    description = 'Activer/Désactiver le mode Akimbo'
}


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



Config.OffhandStartAmmo   = false -- true = copie le chargeur actuel au moment de l'activation
Config.OffhandDefaultAmmo = 12    -- utilisé si OffhandStartAmmo = false


Config.FixedOffhandDamage = 15.0


Config.MaxShootDistance = 100.0

Config.OffhandFireCooldown = 80


Config.DisallowInVehicle = true
Config.DisallowInWater   = true
Config.DisallowRagdoll   = true

-- Désactive automatiquement l'akimbo si le joueur change d'arme ou meurt
Config.AutoDisableOnWeaponSwitch = true

-- Effet visuel de tir (flash au canon) pour la main secondaire
Config.MuzzleFlash = true
