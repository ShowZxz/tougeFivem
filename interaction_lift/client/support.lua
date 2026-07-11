Support = {
    active = false,
    mode = nil,
    lastToggle = 0,
    cooldownEnd = 0,
    proxy = nil,
    netId = nil,
    position = nil
}

ListOfSupport = {}

-- Cooldown management for support toggling
function Support.CanToggle()
    local now = GetGameTimer()
    local elapsed = now - Support.lastToggle
    local cd = Config.SupportToggleCooldown


    if elapsed < cd then
        return false
    end
    Support.lastToggle = now
    Support.lastToggle = GetGameTimer()
    Support.cooldownEnd = Support.lastToggle + Config.SupportToggleCooldown
    return true, 0
end

function Support.IsOnCooldown()
    local now = GetGameTimer()
    return Support.cooldownEnd and now < Support.cooldownEnd
end

-- Force disable support mode if the get hit/ragdoll/tazed/death/killed -- Note : call this if a miss a RP event
function Support.ForceDisable(reason)
    if not Support.active then return end

    print("[interaction_lift] Support forcé OFF :", reason)

    TriggerEvent("interaction_lift:support:disable")
    if not Config.EnableOxIntegration and not Config.EnableContextMenuIntegration then return end

    TriggerServerEvent("interaction_lift:removeProxy")
end

function Support.ClearCurrentSupportData(owner)
    if not CurrentSupportData then return end
    if owner and CurrentSupportData.supportId ~= owner then return end
    CurrentSupportData = nil
end

function Support.GetNearestSupportData(ped, maxDistance)
    local coords = GetEntityCoords(ped)
    local supportInfo = nil
    local nearestDist = maxDistance

    for owner, supportData in pairs(ListOfSupport) do
        if type(supportData) == "table" and supportData.pos then
            local supportPos = supportData.pos

            local dist = Vdist(
                coords.x,
                coords.y,
                coords.z,
                supportPos.x,
                supportPos.y,
                supportPos.z
            )


            if dist < nearestDist then
                nearestDist = dist
                supportInfo = {
                    position = supportPos,
                    nearestDist = nearestDist,
                    typeMode = supportData.mode,
                    supportId = supportData.owner
                }
            end
        end
    end

    return supportInfo
end

function Support.GetInteractionDistance(mode)
    if mode == "pullup" then
        return Config.Distances.PULLUP_MAX
    elseif mode == "legsup" then
        return Config.Distances.LEGSUP_MAX
    end

    return 0.0
end

function Support.CanUseForMode(ped, mode, dist)
    local maxDist = Support.GetInteractionDistance(mode)
    return maxDist > 0 and dist <= maxDist and isSupportStateValid(ped)
end

function Support.CanUse(ped, dist)
    return Support.CanUseForMode(ped, "legsup", dist)
end

function Support.CanUsePullup(ped, dist)
    return Support.CanUseForMode(ped, "pullup", dist)
end

function Support.Start(data)
    if Support.IsOnCooldown() then
        errorMsg("Veuillez attendre avant de relancer l'action.")
        return
    end

    Support.lastToggle = GetGameTimer()
    Support.cooldownEnd = Support.lastToggle + 3000 -- 3 secondes de cooldown

    local mode = data.typeMode

    if mode == "legsup" then
        Legsup.Start(data.supportId)
        print("Tente un legsup sur "..data.supportId)
    end
    if mode == "pullup" then
        PullUp.Start(data.supportId)
        print("Tente un pullup sur :"..data.supportId)
    end
end

-- Enable support mode
RegisterNetEvent("interaction_lift:support:enable")
AddEventHandler("interaction_lift:support:enable",  function(mode)
    local ped = PlayerPedId()

    local ok = Support.CanToggle()
    if not ok then
        return
    end


    if Support.active and Support.mode ~= mode then
        errorMsg("❌ Vous êtes déjà en train de soutenir autrement")
        return
    end


    if Support.active and Support.mode == mode then
        TriggerEvent("interaction_lift:support:disable")
        return
    end


    if mode == "legsup" then
        if isNearWall(ped, Config.Distances.MIN_WALL_DISTANCE) then
            errorMsg("❌ Too close to a wall")
            return
        end
        if hasRoofAbove(ped, Config.Distances.MIN_ROOF_HEIGHT) then
            errorMsg("❌ Not enough height above")
            return
        end
        if not isSupportStateValid(ped) then
            errorMsg("❌ Invalid position for legsup")
            return
        end
    end

    if mode == "pullup" then
        if not isSupportStateValid(ped) or not canSetSupportForPullup(ped) then
            errorMsg("❌ Invalid position for pullup")
            return
        end
    end

    Support.active = true
    Support.mode = mode
    --Support.CreateProxy(mode)

    FreezeEntityPosition(ped, true) -- A Voir

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

    local pos = GetEntityCoords(ped)
    Support.position = pos

    TriggerServerEvent("interaction_lift:setSupport", true, mode)

    TriggerServerEvent("interaction_lift:addPosition", pos, mode)

    message(("Support %s enabled"):format(mode))
end)


RegisterNetEvent("interaction_lift:notifyClientPosition")
AddEventHandler("interaction_lift:notifyClientPosition", function(owner, pos, mode)
    if not owner or not pos or not mode then
        print("Incomplete Data for Support position")
        return
    end

    local playerId = GetPlayerServerId(PlayerId())
    if owner == playerId then return end


    ListOfSupport[owner] = {
        mode = mode,
        pos = pos,
        owner = owner
    }

end)

RegisterNetEvent("interaction_lift:notifyClientRemovePos")
AddExport("interaction_lift:notifyClientRemovePos", function(owner, supportPosition)
    if not owner or not supportPosition then
        print("Incomplete Data for remove Support position")
        return
    end

    local playerId = GetPlayerServerId(PlayerId())
    if owner == playerId then return end
    if not ListOfSupport[owner] then
        print("No support position found for player")
        return
    end

    ListOfSupport[owner] = nil
    Support.ClearCurrentSupportData(owner)
end)

--Disable support mode
RegisterNetEvent("interaction_lift:support:disable")
AddEventHandler("interaction_lift:support:disable", function()
    if not Support.active then return end

    local ped = PlayerPedId()

    Support.active = false
    Support.mode = nil

    CurrentSupportData = nil
    Support.RemoveProxy()

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)

    TriggerServerEvent("interaction_lift:setSupport", false)
    TriggerServerEvent("interaction_lift:removePosition", Support.position)
    Support.position = nil

    message("❌ Support disabled")
end)


AddEventHandler("baseevents:onPlayerDied", function()
    Support.ForceDisable("death")
end)

AddEventHandler("baseevents:onPlayerKilled", function() 
    Support.ForceDisable("killed")
end)


-- Display support cooldown on HUD
CreateThread(function()
    while true do
        Wait(0)

        if Support.cooldownEnd == 0 then
            goto continue
        end

        local now = GetGameTimer()
        local remaining = (Support.cooldownEnd - now) / 1000

        if remaining <= 0 then
            Support.cooldownEnd = 0
            goto continue
        end

        DrawHudText(
            ("Support available in ~y~%.1fs"):format(remaining),
            0.5, 0.88
        )

        ::continue::
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if not Support.active then
            goto continue
        end

        DrawHudInfo("~b~Support~s~ enable\nPress ~INPUT_VEH_DUCK~ to ~r~stop~s~ supporting")

        ::continue::
    end
end)

-- Force disable support on damage
CreateThread(function()
    local ped = PlayerPedId()
    local lastHealth = GetEntityHealth(ped)

    while true do
        Wait(200)

        if not Support.active then
            lastHealth = GetEntityHealth(ped)
            goto continue
        end

        local currentHealth = GetEntityHealth(ped)

        if currentHealth < lastHealth then
            Support.ForceDisable("damage")
        end

        lastHealth = currentHealth

        ::continue::
    end
end)

--Force disable support mode if tazed
CreateThread(function()
    while true do
        Wait(100)

        if Support.active and IsPedBeingStunned(PlayerPedId()) then
            Support.ForceDisable("tazed")
        end
    end
end)

-- Force disable support mode if ragdoll
CreateThread(function()
    while true do
        Wait(150)

        if Support.active and IsPedRagdoll(PlayerPedId()) then
            Support.ForceDisable("ragdoll")
        end
    end
end)

-- Gestion des points pour utiliser les supports
CreateThread(function()
    while true do
        Wait(0)

        CurrentSupportData = nil

        if next(ListOfSupport) == nil then
            Wait(200)
            goto continue
        end

        if next(ListOfSupport) ~= nil then
            local ped = PlayerPedId()
            local supportInfo = Support.GetNearestSupportData(ped, 10.0)
            if supportInfo == nil then goto continue end

            local supportCoords = supportInfo.position
            local supportDist = supportInfo.nearestDist
            local mode = supportInfo.typeMode

            local canUse = Support.CanUseForMode(ped, mode, supportDist)

            if supportCoords and canUse then
                CurrentSupportData = supportInfo
                Wait(250)
            else
                Wait(1000)
            end
        end

        ::continue::
    end
end)


CreateThread(function()
    while true do
        if CurrentSupportData then
            local mode = CurrentSupportData.typeMode
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local supportCoords = CurrentSupportData.position
            local distance = #(coords - supportCoords)

            local maxDist = Support.GetInteractionDistance(mode)
            if maxDist > 0 and distance <= maxDist then
                displayHelpText(mode)

                if IsControlJustPressed(0, 38) then
                    if Support.IsOnCooldown() then
                        errorMsg("Cooldown actif.")
                    else
                        Support.Start(CurrentSupportData)
                    end
                end
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)
