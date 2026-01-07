Support = {
    active = false,
    mode = nil,
    lastToggle = 0
}


local function canToggle()
    local now = GetGameTimer()
    if now - Support.lastToggle < Config.SupportToggleCooldown then
        return false
    end
    Support.lastToggle = now
    return true
end

function Support.IsActive()
    return Support.active, Support.mode
end


RegisterNetEvent("interaction_lift:support:enable", function(mode)
    local ped = PlayerPedId()
    local now = GetGameTimer()

    if not canToggle() then return end

    -- déjà actif avec un autre mode
    if Support.active and Support.mode ~= mode then
        errorMsg("❌ Vous êtes déjà en train de soutenir autrement")
        return
    end

    -- désactivation si même mode
    if Support.active and Support.mode == mode then
        TriggerEvent("interaction_lift:support:disable")
        return
    end

    -- ===== VALIDATIONS =====
    if mode == "legsup" then
        if isNearWall(ped, Config.Distances.MIN_WALL_DISTANCE) then
            errorMsg("❌ Trop proche d'un mur")
            return
        end
        if hasRoofAbove(ped, Config.Distances.MIN_ROOF_HEIGHT) then
            errorMsg("❌ Pas assez de hauteur")
            return
        end
        if not isSupportStateValid(ped) then
            errorMsg("❌ Position invalide")
            return
        end
    end

    if mode == "pullup" then
        if not isSupportStateValid(ped) then
            errorMsg("❌ Position invalide pour un pull-up")
            return
        end
    end

    -- ===== ACTIVATE =====
    Support.active = true
    Support.mode = mode

    FreezeEntityPosition(ped, true)

    local anim = Config.Animation[mode:upper()]
    RequestAnimDict(anim.DICTIDLE)
    while not HasAnimDictLoaded(anim.DICTIDLE) do
        Wait(10)
    end

    TaskPlayAnim(
        ped,
        anim.DICTIDLE,
        anim.ANIMIDLE,
        8.0, -8.0, -1,
        1, 0, false, false, false
    )

    TriggerServerEvent("interaction_lift:setSupport", true, mode)
    message(("Support %s activé"):format(mode))
end)

RegisterNetEvent("interaction_lift:support:disable", function()
    if not Support.active then return end

    local ped = PlayerPedId()

    Support.active = false
    Support.mode = nil

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)

    TriggerServerEvent("interaction_lift:setSupport", false)
    message("❌ Support désactivé")
end)
