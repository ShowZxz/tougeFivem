print("Loading interaction_lift client main.lua")
local activeAction = nil
local targetServerId = nil
local supporting = false
local supportMode = nil

local ANIM_DURATION = (Config.Frame.TOTAL_FRAMES / Config.Frame.ANIM_FPS) * 1000

local lastUse = {
    legsup = 0,
    pullup = 0
}

CreateThread(function()
    while true do
        Wait(200)

        activeAction = nil
        targetServerId = nil

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, player in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(player)
            if targetPed ~= ped then
                local dist = #(coords - GetEntityCoords(targetPed))

                if Legsup.CanUse(ped, targetPed, dist) then
                    activeAction = "legsup"
                    targetServerId = GetPlayerServerId(player)
                    break

                elseif PullUp.CanUse(ped, targetPed, dist) then
                    activeAction = "pullup"
                    targetServerId = GetPlayerServerId(player)
                    break
                end
            end
        end
    end
end)


CreateThread(function()
    while true do
        Wait(0)
        --print("Action:", activeAction, "TargetServerId:", targetServerId)
        if not activeAction then goto continue end
        if not IsControlJustPressed(0, Config.Keys.INTERACT) then goto continue end

        local now = GetGameTimer()

        
        local cd = Config.Cooldowns.INTERACTION[activeAction:upper()]
        local last = lastUse[activeAction]

        if now - last < cd then
            local remaining = math.ceil((cd - (now - last)) / 1000)
            errorMsg(("⏳ %s disponible dans %ds"):format(activeAction, remaining))
            goto continue
        end

        lastUse[activeAction] = now
        
        if activeAction == "legsup" then
            print("Starting legsup on targetServerId:", targetServerId)
            Legsup.Start(targetServerId)
        elseif activeAction == "pullup" then
            PullUp.Start(targetServerId)
            print("Starting pullup on targetServerId:", targetServerId)
        end

        ::continue::
    end
end)






RegisterCommand("pullup", function()
    local ped = PlayerPedId()

    if supporting and supportMode ~= "pullup" then
        errorMsg("❌ Vous êtes déjà en train de soutenir autrement")
        return
    end

    supporting = not supporting
    supportMode = supporting and "pullup" or nil


    if not isSupportStateValid(ped) then
        errorMsg("❌ Position invalide pour faire un pullup")
        return
    end

    if supporting then
        FreezeEntityPosition(ped, true)
        RequestAnimDict(Config.Animation.PULLUP.DICTIDLE)
        print("Loading anim dict:", Config.Animation.PULLUP.ANIMIDLE , Config.Animation.PULLUP.DICTIDLE)
        while not HasAnimDictLoaded(Config.Animation.PULLUP.DICTIDLE) do Wait(10) end

        TaskPlayAnim(PlayerPedId(), Config.Animation.PULLUP.DICTIDLE, Config.Animation.PULLUP.ANIMIDLE, 8.0, -8.0, -1, 1, 0, false, false, false)
        TriggerServerEvent("interaction_lift:setSupport", true)
        message("Vous êtes prêt à hisser un joueur.")
    else
        ClearPedTasks(PlayerPedId())
        FreezeEntityPosition(ped, false)
        TriggerServerEvent("interaction_lift:setSupport", false)
    end
end)

RegisterCommand("legsup", function()
    local ped = PlayerPedId()

    if supporting and supportMode ~= "legsup" then
        errorMsg("❌ Vous êtes déjà en train de soutenir autrement")
        return
    end

    supporting = not supporting

    supportMode = supporting and "legsup" or nil

    if isNearWall(ped, Config.Distances.MIN_WALL_DISTANCE) then
        errorMsg("❌ Trop proche d'un mur pour faire une courte échelle")
        return
    end
    if hasRoofAbove(ped, Config.Distances.MIN_ROOF_HEIGHT) then
        errorMsg("❌ Pas assez de hauteur au-dessus")
        return
    end
    if not isSupportStateValid(ped) then
        errorMsg("❌ Position invalide pour faire une courte échelle")
        return
    end
    if supporting then
        FreezeEntityPosition(ped, true)
        RequestAnimDict(Config.Animation.LEGSUP.DICTIDLE)
        print("Loading anim dict:", Config.Animation.LEGSUP.ANIMIDLE)
        while not HasAnimDictLoaded(Config.Animation.LEGSUP.DICTIDLE) do Wait(10) end

        TaskPlayAnim(PlayerPedId(), Config.Animation.LEGSUP.DICTIDLE, Config.Animation.LEGSUP.ANIMIDLE, 8.0, -8.0, -1, 1, 0, false, false, false)
        TriggerServerEvent("interaction_lift:setSupport", true)
        message("Vous êtes prêt à soutenir un joueur.")
    else
        ClearPedTasks(PlayerPedId())
        FreezeEntityPosition(ped, false)
        TriggerServerEvent("interaction_lift:setSupport", false)
    end
end)


RegisterNetEvent("interaction_lift:clearSupport", function()
    Wait(ANIM_DURATION)
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
    supporting = false
    supportMode = nil
end)