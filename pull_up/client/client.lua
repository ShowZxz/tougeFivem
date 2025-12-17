local supporting = false
local busy = false

local lastPullup = 0
local lastPullup_COOLDOWN = 5000

local showCooldown = false
local cooldownEnd = 0

local ANIM_FPS = 60
local BOOST_FRAME = 10
local TOTAL_FRAMES = 100

local BOOST_TIME = (BOOST_FRAME / ANIM_FPS) * 1000
local ANIM_DURATION = (TOTAL_FRAMES / ANIM_FPS) * 1000

local dictPullUp = "pullupanimation@anim"
local animPullUp = "pullupanimation_clip"

local dictPullUpAnim = "pupanim@animation"
local animPullUpAnim = "pupanim_clip"

local dictPullUpPose = "idlepulluppose@pose"
local animPullUpPose = "idlepulluppose_clip"

local FRONT_OFFSET = 1.5   
local SIDE_OFFSET  = 0.0  
local Z_OFFSET     = 0.0 

local PULLING_DURATION = 1200
local PULLING_HEIGHT = 5.0



function alignPlayers(supportPed, liftedPed)
    local supportCoords = GetEntityCoords(supportPed)
    local liftedCoords  = GetEntityCoords(liftedPed)

    local heading = GetEntityHeading(supportPed) + 180.0

    local forward = GetEntityForwardVector(supportPed)
    local right   = GetRightVectorFromForward(forward)

  

    local targetX = supportCoords.x + forward.x * FRONT_OFFSET + right.x * SIDE_OFFSET
    local targetY = supportCoords.y + forward.y * FRONT_OFFSET + right.y * SIDE_OFFSET
    local targetZ = liftedCoords.z + Z_OFFSET

    SetEntityCoordsNoOffset(
        liftedPed,
        targetX,
        targetY,
        targetZ,
        false, false, false
    )

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

function GetRightVectorFromForward(forward)
    return vector3(-forward.y, forward.x, 0.0)
end

function getWallNormal(fromCoords, toCoords, ped)
    local ray = StartShapeTestRay(
        fromCoords.x, fromCoords.y, fromCoords.z + 0.3,
        toCoords.x,   toCoords.y,   toCoords.z + 0.3,
        1, ped, 0
    )

    local _, hit, _, _, normal = GetShapeTestResult(ray)
    return hit == 1, normal
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
        print(dictPullUpPose, animPullUpPose)
            RequestAnimDict(dictPullUpPose)
        while not HasAnimDictLoaded(dictPullUpPose) do Wait(10) end
        TaskPlayAnim(ped, dictPullUpPose, animPullUpPose, 8.0, -8.0, -1, 2, 0, false, false, false)
        
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
                if dist < PULLING_HEIGHT and IsControlJustPressed(0, 38) and not supporting then
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
                    print("Demande de pull up envoyée au serveur")
                    TriggerServerEvent("pullup:tryPullUp", GetPlayerServerId(player))
                end
            end
        end

        ::continue::
    end
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

RegisterNetEvent("pullup:align", function(supportServerId)
    local liftedPed = PlayerPedId()
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId))

    alignPlayers(supportPed, liftedPed)
end)

RegisterNetEvent("pullup:playUpBoost", function()
    local ped = PlayerPedId()
    --Animation de boost
    RequestAnimDict(dictPullUp)
    while not HasAnimDictLoaded(dictPullUp) do Wait(10) end
    TaskPlayAnim(ped, dictPullUp, animPullUp, 8.0, -8.0, BOOST_TIME, 2, 0, false, false, false)
end)

RegisterNetEvent("pullup:playJump", function()
    local ped = PlayerPedId()
    print("Playing jump animation")
    --Animation de saut
    RequestAnimDict(dictPullUpAnim)
    while not HasAnimDictLoaded(dictPullUpAnim) do Wait(10) end
    TaskPlayAnim(ped, dictPullUpAnim, animPullUpAnim, 8.0, -8.0, BOOST_TIME, 2, 0, false, false, false)
    print(dictPullUpAnim, animPullUpAnim)
end)

RegisterNetEvent("pullup:pullingUp", function(supportServerId)
 
    local ped = PlayerPedId()

    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId))

    if not DoesEntityExist(supportPed) then
        errorMsg("Support introuvable")
        return
    end


    local startCoords = GetEntityCoords(ped)
    local supportCoords = GetEntityCoords(supportPed)
    local forward = GetEntityForwardVector(supportPed)


    local targetCoords =
        supportCoords +
        (forward * 0.4) +
        vector3(0.0, 0.0, -0.2)

    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)


    local startTime = GetGameTimer()

    CreateThread(function()
    while true do
        local now = GetGameTimer()
        local t = (now - startTime) / PULLING_DURATION
        if t >= 1.0 then break end

        local wantedPos = startCoords + (targetCoords - startCoords) * t
        local currentPos = GetEntityCoords(ped)

        local hit, normal = getWallNormal(currentPos, wantedPos, ped)

        if hit then

            wantedPos = vector3(
                currentPos.x,
                currentPos.y,
                wantedPos.z
            )
        end

        SetEntityCoordsNoOffset(
            ped,
            wantedPos.x, wantedPos.y, wantedPos.z,
            true, false, false
        )

        Wait(0)
    end

    FreezeEntityPosition(ped, false)
end)
end)


RegisterNetEvent("pullup:clearSupport", function()
    Wait(ANIM_DURATION)
    supporting = false
    busy = false
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
end)    

RegisterNetEvent("pullup:notifyNoSupport", function(msg)
    errorMsg(msg)
    busy = false
end)

--################################################################ TEST COMMAND ##################################################################

RegisterCommand("testPullUp", function()
    local supportServerId = 2

    local ped = PlayerPedId()
    local myId = GetPlayerServerId(PlayerId())
    print(myId .. " demande un pull up à " .. supportServerId)
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId))

    if not DoesEntityExist(supportPed) then
        print("Support introuvable")
        return
    end

    -- Positions
    local startCoords = GetEntityCoords(ped)
    local supportCoords = GetEntityCoords(supportPed)
    local forward = GetEntityForwardVector(supportPed)

    -- Position finale : devant + un peu plus bas que le support
    local targetCoords =
        supportCoords +
        (forward * 0.4) +
        vector3(0.0, 0.0, -0.2)

    -- Préparation
    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    -- Durée du pull up (ms)
    local duration = 1200
    local startTime = GetGameTimer()

    CreateThread(function()
    while true do
        local now = GetGameTimer()
        local t = (now - startTime) / duration
        if t >= 1.0 then break end

        local wantedPos = startCoords + (targetCoords - startCoords) * t
        local currentPos = GetEntityCoords(ped)

        local hit, normal = getWallNormal(currentPos, wantedPos, ped)

        if hit then
            -- 🚧 Mur détecté → on bloque X/Y mais on laisse Z
            wantedPos = vector3(
                currentPos.x,
                currentPos.y,
                wantedPos.z
            )
        end

        SetEntityCoordsNoOffset(
            ped,
            wantedPos.x, wantedPos.y, wantedPos.z,
            false, false, false
        )

        Wait(0)
    end

    FreezeEntityPosition(ped, false)
end)

end)

RegisterCommand("testemote", function()
    local ped = PlayerPedId()
    --local dictName = "jumplever@animation"
    --local animName = "jumplever_clip"

    --local dictName = "pullupanimation@anim"
    --local animName = "pullupanimation_clip"

    --local dictName = "liftidle@pose"
    --local animName = "liftidle_clip"

    --local dictName = "idlepulluppose@pose"
    --local animName = "idlepulluppose_clip"

    local dictName = "pupanim@animation"
    local animName = "pupanim_clip"

    RequestAnimDict(dictName)
    while not HasAnimDictLoaded(dictName) do Wait(10) end


    TaskPlayAnim(ped, dictName, animName, 8.0, -8.0, -1, 2, 0, false, false, false)
end)

RegisterCommand("clearemote", function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end)