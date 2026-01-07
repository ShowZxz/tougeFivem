Support = {
    active = false,
    mode = nil, -- "legsup" | "pullup"
    lastToggle = 0
}

function Support.CanToggle()
    local now = GetGameTimer()
    return now - Support.lastToggle >= Config.SupportToggleCooldown
end

function Support.Toggle(mode)
    local ped = PlayerPedId()
    local now = GetGameTimer()

    if not Support.CanToggle() then
        errorMsg("⏳ Action indisponible")
        return
    end

    -- Désactivation
    if Support.active and (mode == nil or mode ~= Support.mode) then
        ClearPedTasks(ped)
        FreezeEntityPosition(ped, false)
        TriggerServerEvent("interaction_lift:setSupport", false)

        Support.active = false
        Support.mode = nil
        Support.lastToggle = now

        message("Support désactivé")
        return
    end

    -- Validation commune
    if not isSupportStateValid(ped) then
        errorMsg("❌ Position invalide")
        return
    end

    -- Validations spécifiques
    if mode == "legsup" then
        if isNearWall(ped, Config.Distances.MIN_WALL_DISTANCE) then
            errorMsg("❌ Trop proche d'un mur")
            return
        end
        if hasRoofAbove(ped, Config.Distances.MIN_ROOF_HEIGHT) then
            errorMsg("❌ Pas assez de hauteur")
            return
        end
    end

    -- Activation
    Support.active = true
    Support.mode = mode
    Support.lastToggle = now

    FreezeEntityPosition(ped, true)

    local anim = Config.Animation[mode:upper()]
    RequestAnimDict(anim.DICTIDLE)
    while not HasAnimDictLoaded(anim.DICTIDLE) do Wait(10) end

    TaskPlayAnim(
        ped,
        anim.DICTIDLE,
        anim.ANIMIDLE,
        8.0, -8.0, -1,
        1, 0, false, false, false
    )

    TriggerServerEvent("interaction_lift:setSupport", true, mode)

    message(("✅ Support %s activé"):format(mode))
end

RegisterNetEvent("interaction_lift:clearSupport", function()
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    Support.active = false
    Support.mode = nil
end)