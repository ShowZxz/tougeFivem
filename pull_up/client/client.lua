local supporting = false
local busy = false

local lastPullup = 0
local lastPullup_COOLDOWN = 5000

local showCooldown = false
local cooldownEnd = 0

local dictIdle = "liftidle@pose"
local animIdle = "liftidle_clip"


function alignPlayers(supportPed, liftedPed)
    local supportCoords = GetEntityCoords(supportPed)
    local heading = GetEntityHeading(supportPed)
    heading = heading + 180.0

    local forward = GetEntityForwardVector(supportPed)

    local targetPos = supportCoords +
        (forward * SUPPORT_OFFSET) +
        vector3(0.0, 0.0, HEIGHT_OFFSET)

    SetEntityCoordsNoOffset(liftedPed, targetPos.x, targetPos.y, targetPos.z, false, false, false)
    SetEntityHeading(liftedPed, heading)

    FreezeEntityPosition(liftedPed, true)
end


function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(184)
    EndTextCommandThefeedPostTicker(false, true)
end

function errorMsg(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(6)
    EndTextCommandThefeedPostTicker(true, true)
end

function isSupportStateValid(ped)
    return not (
        IsPedInAnyVehicle(ped, true) or
        IsPedFalling(ped) or
        IsPedRagdoll(ped) or
        IsPedSwimming(ped) or
        IsPedClimbing(ped) or
        IsPedInCombat(ped) or
        IsPedShooting(ped) or
        IsPedJumping(ped)


    )
end



RegisterCommand("pullup", function()

    local ped = PlayerPedId()
    if busy then return end

    supporting = not supporting


    if not isSupportStateValid(ped) then
        errorMsg("❌ Position invalide pour faire une courte échelle")
        busy = false
        return
    end

    if supporting then
        --Animation de maintien
        TriggerServerEvent("pullup:setSupport", true)
        message("Vous êtes prêt à soutenir un joueur.")
    else
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent("pullup:setSupport", false)
    end
end)



CreateThread(function()
    while true do
        Wait(0)

        if busy then goto continue end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, player in ipairs(GetActivePlayers()) do
            local targetPed = GetPlayerPed(player)
            if targetPed ~= ped then
                local dist = #(coords - GetEntityCoords(targetPed))
                if dist < 10.5 and IsControlJustPressed(0, 38) and not supporting then
                    local now = GetGameTimer()
                    if now - lastPullup < lastPullup_COOLDOWN then
                        errorMsg("⏳ Attendez avant de refaire un pull up")
                        goto continue
                    end

                    
                    if not isSupportStateValid(ped) then
                        errorMsg("❌ Position invalide pour faire une courte échelle")
                        goto continue
                    end

                    
                    busy = true
                    lastPullup = now
                    cooldownEnd = now + lastPullup_COOLDOWN 
                    showCooldown = true

                    TriggerServerEvent("pullup:tryPullup", GetPlayerServerId(player))
                end
            end
        end

        ::continue::
    end
end)

RegisterNetEvent("pullup:pullingUp", function(supportServerId)
    local ped = PlayerPedId()
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId))

    if not DoesEntityExist(supportPed) then return end

    local startCoords = GetEntityCoords(ped)
    local supportCoords = GetEntityCoords(supportPed)
    local forward = GetEntityForwardVector(supportPed)

    -- Position finale (devant + légèrement en dessous)
    local targetCoords = supportCoords + forward * 0.4 + vector3(0.0, 0.0, -0.1)

    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    local duration = 1200
    local startTime = GetGameTimer()

    CreateThread(function()
        while true do
            local now = GetGameTimer()
            local t = (now - startTime) / duration
            if t >= 1.0 then break end

            local pos = startCoords + (targetCoords - startCoords) * t
            SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
            Wait(0)
        end

        SetEntityCoordsNoOffset(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
        FreezeEntityPosition(ped, false)
        busy = false
    end)
end)


CreateThread(function()
    while true do
        Wait(0)

        if showCooldown then
            local now = GetGameTimer()
            local remaining = (cooldownEnd - now) / 1000

            if remaining <= 0 then
                showCooldown = false
            else
                SetTextFont(4)
                SetTextScale(0.45, 0.45)
                SetTextColour(255, 255, 255, 215)
                SetTextOutline()
                SetTextCentre(true)

                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(
                    ("PullUp disponible dans ~y~%.1fs"):format(remaining)
                )
                EndTextCommandDisplayText(0.5, 0.92)
            end
        end
    end
end)


RegisterNetEvent("pullup:clearSupport", function()
    supporting = false
    busy = false
    ClearPedTasks(PlayerPedId())
end)    

RegisterCommand("testPullUp", function()
    local supportServerId = 1 
    local ped = PlayerPedId()
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId))

    if not DoesEntityExist(supportPed) then return end

    local startCoords = GetEntityCoords(ped)
    local supportCoords = GetEntityCoords(supportPed)
    local forward = GetEntityForwardVector(supportPed)

    -- Position finale (devant + légèrement en dessous)
    local targetCoords = supportCoords + forward * 0.4 + vector3(0.0, 0.0, -0.1)

    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    local duration = 1200
    local startTime = GetGameTimer()

    CreateThread(function()
        while true do
            local now = GetGameTimer()
            local t = (now - startTime) / duration
            if t >= 1.0 then break end

            local pos = startCoords + (targetCoords - startCoords) * t
            SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
            Wait(0)
        end

        SetEntityCoordsNoOffset(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
        FreezeEntityPosition(ped, false)
        busy = false
    end)
   
end)