local supporting = false
local busy = false

local lastLegsup = 0
local LEGSUP_COOLDOWN = 5000

local showCooldown = false
local cooldownEnd = 0

local dictJump = "jumplever@animation"
local animJump = "jumplever_clip"

local dictLift = "liftanim@animation"
local animLift = "liftanim_clip"

local dictIdle = "liftidle@pose"
local animIdle = "liftidle_clip"

local ANIM_FPS = 60
local BOOST_FRAME = 100
local TOTAL_FRAMES = 300

local BOOST_TIME = (BOOST_FRAME / ANIM_FPS) * 1000
local ANIM_DURATION = (TOTAL_FRAMES / ANIM_FPS) * 1000

local SUPPORT_OFFSET = 0.80 -- distance avec le joueur supportant
local HEIGHT_OFFSET = 0.0   -- et la hauteur

local ARC_UP_FORCE = 10.0
local ARC_FORWARD_FORCE = 3.0

local ARC_STEP_TIME = 40
local ARC_STEPS = 6

local MIN_WALL_DISTANCE = 2.0
local MIN_ROOF_HEIGHT = 3.0


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

function isNearWall(ped, distance)
    local coords   = GetEntityCoords(ped)
    local forward  = GetEntityForwardVector(ped)
    local z        = coords.z + 0.5

    local rayFront = StartShapeTestRay(
        coords.x, coords.y, z,
        coords.x + forward.x * distance,
        coords.y + forward.y * distance,
        z,
        1, ped, 0
    )

    local rayBack  = StartShapeTestRay(
        coords.x, coords.y, z,
        coords.x - forward.x * distance,
        coords.y - forward.y * distance,
        z,
        1, ped, 0
    )

    local hitFront = getRayHit(rayFront)
    local hitBack  = getRayHit(rayBack)

    print("Front:", hitFront, "Back:", hitBack)

    return hitFront or hitBack
end

function getRayHit(ray)
    local result, hit

    repeat
        result, hit = GetShapeTestResult(ray)
        Wait(0)
    until result ~= 0

    return hit == 1
end

function hasRoofAbove(ped, height)
    local coords = GetEntityCoords(ped)
    local z = coords.z + 0.5

    local ray = StartShapeTestRay(
        coords.x, coords.y, z,
        coords.x, coords.y, z + height,
        1, ped, 0
    )

    return getRayHit(ray)
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

RegisterCommand("legsup", function()
    local ped = PlayerPedId()
    if busy then return end

    supporting = not supporting

    if isNearWall(ped, MIN_WALL_DISTANCE) then
        errorMsg("❌ Trop proche d'un mur pour faire une courte échelle")
        busy = false
        return
    end
    if hasRoofAbove(ped, MIN_ROOF_HEIGHT) then
        errorMsg("❌ Pas assez de hauteur au-dessus")
        busy = false
        return
    end
    if not isSupportStateValid(ped) then
        errorMsg("❌ Position invalide pour faire une courte échelle")
        busy = false
        return
    end
    if supporting then
        RequestAnimDict(dictIdle)
        while not HasAnimDictLoaded(dictIdle) do Wait(10) end

        TaskPlayAnim(PlayerPedId(), dictIdle, animIdle, 8.0, -8.0, -1, 1, 0, false, false, false)
        TriggerServerEvent("legsup:setSupport", true)
        message("Vous êtes prêt à soutenir un joueur.")
    else
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent("legsup:setSupport", false)
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
                if dist < 1.5 and IsControlJustPressed(0, 38) and not supporting then
                    local now = GetGameTimer()
                    if now - lastLegsup < LEGSUP_COOLDOWN then
                        errorMsg("⏳ Attendez avant de refaire une courte échelle")
                        goto continue
                    end

                    if isNearWall(ped, MIN_WALL_DISTANCE) then
                        errorMsg("❌ Trop proche d'un mur pour faire une courte échelle")
                        goto continue
                    end

                    if hasRoofAbove(ped, MIN_ROOF_HEIGHT) then
                        errorMsg("❌ Pas assez de hauteur au-dessus")
                        goto continue
                    end

                    if not isSupportStateValid(ped) then
                        errorMsg("❌ Position invalide pour faire une courte échelle")
                        goto continue
                    end

                    
                    busy = true
                    lastLegsup = now
                    cooldownEnd = now + LEGSUP_COOLDOWN
                    showCooldown = true
                    TriggerServerEvent("legsup:tryLift", GetPlayerServerId(player))
                end
            end
        end

        ::continue::
    end
end)

RegisterNetEvent("legsup:applyForce", function()
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, false)
    local coords = GetEntityCoords(ped)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + 0.15, false, false, false)
    SetPedCanRagdoll(ped, false)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    Wait(BOOST_TIME)
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.10)
    ApplyForceToEntity(
        ped,
        3,
        0.0, 0.0, ARC_UP_FORCE,
        0.0, 0.0, 0.0,
        0,
        true,
        true,
        true,
        false,
        true
    )



    Wait(150)
    ClearPedTasks(ped)
    for i = 1, ARC_STEPS do
        ApplyForceToEntity(
            ped,
            3,
            0.0, ARC_FORWARD_FORCE, 0.0,
            0.0, 0.0, 0.0,
            0,
            true,
            true,
            true,
            false,
            true
        )
        Wait(ARC_STEP_TIME)
    end
    SetPedCanRagdoll(ped, true)
end)


RegisterNetEvent("legsup:playJump", function()
    local ped = PlayerPedId()

    RequestAnimDict(dictJump)
    while not HasAnimDictLoaded(dictJump) do Wait(10) end

    TaskPlayAnim(ped, dictJump, animJump, 8.0, -8.0, -1, 0, 0, false, false, false)
end)

RegisterNetEvent("legsup:playBoost", function()
    local ped = PlayerPedId()

    RequestAnimDict(dictLift)
    while not HasAnimDictLoaded(dictLift) do Wait(10) end

    TaskPlayAnim(ped, dictLift, animLift, 8.0, -8.0, -1, 0, 0, false, false, false)
end)

RegisterNetEvent("legsup:clearSupport", function()
    Wait(ANIM_DURATION)
    ClearPedTasks(PlayerPedId())
    supporting = false
    busy = false
    FreezeEntityPosition(PlayerPedId(), false)
end)

RegisterNetEvent("legsup:align", function(supportServerId)
    local liftedPed = PlayerPedId()
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId))

    alignPlayers(supportPed, liftedPed)
end)

RegisterNetEvent("legsup:notifyNoSupport", function(msg)
    errorMsg(msg)
    busy = false
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
                    ("Legsup disponible dans ~y~%.1fs"):format(remaining)
                )
                EndTextCommandDisplayText(0.5, 0.92)
            end
        end
    end
end)



-- ############################################################################ TEST CODE ######################################################################################################################

RegisterCommand("testemote", function()
    --local dictName = "jumplever@animation"
    --local animName = "jumplever_clip"

    local dictName = "liftanim@animation"
    local animName = "liftanim_clip"

    --local dictName = "liftidle@pose"
    --local animName = "liftidle_clip"

    RequestAnimDict(dictName)
    while not HasAnimDictLoaded(dictName) do Wait(10) end
    Wait(0)

    local ped = PlayerPedId()
    TaskPlayAnim(ped, dictName, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
end)

RegisterCommand("clearemote", function()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end)

RegisterCommand("aforce", function()
    local ped = PlayerPedId()
    if isNearWall(ped, MIN_WALL_DISTANCE) then
        errorMsg("❌ Trop proche d'un mur pour faire une courte échelle")
        return
    end
    if hasRoofAbove(ped, MIN_ROOF_HEIGHT) then
        errorMsg("❌ Pas assez de hauteur au-dessus")
        return
    end
    if not isSupportStateValid(ped) then
        errorMsg("❌ Position invalide pour faire une courte échelle")
        return
    end

    FreezeEntityPosition(ped, false)

    local coords = GetEntityCoords(ped)

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + 0.15, false, false, false)
    SetPedCanRagdoll(ped, false)

    Wait(0)
    
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    ApplyForceToEntity(
        ped,
        3,
        0.0, 0.0, 10.0,
        0.0, 0.0, 0.0,
        0,
        true,
        true,
        true,
        false,
        true
    )
    Wait(250)
    for i = 1, 6 do
        ApplyForceToEntity(
            ped,
            3,
            0.0, 3.0, 0.0, -- Y positif = propulsion en avant le ped
            0.0, 0.0, 0.0,
            0,
            true,
            true,
            true,
            false,
            true
        )
        Wait(40)
    end
    SetPedCanRagdoll(ped, true)
end)

RegisterCommand("ragdoll", function()
    local ped = PlayerPedId()
    SetPedToRagdoll(ped, 3000, 3000, 0, false, false, false)
end)



-- ############################################################################ TEST CODE END ######################################################################################################################