Legsup = {
    isClimbing = false
}

local BOOST_TIME = (Config.Frame.BOOST_FRAME / Config.Frame.ANIM_FPS) * 1000

--Check if legsup can be used
function Legsup.CanUse(ped, targetPed, dist)
    return dist <= Config.Distances.LEGSUP_MAX
        and isSupportStateValid(ped)
        and not isNearWall(ped, Config.Distances.MIN_WALL_DISTANCE)
        and not hasRoofAbove(ped, Config.Distances.MIN_ROOF_HEIGHT)
end


--Start legsup interaction
function Legsup.Start(targetServerId)
    TriggerServerEvent("interaction_lift:legsup", targetServerId)
end

--Check if ped near wall
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

    --print("Front:", hitFront, "Back:", hitBack)

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

--Check if the ray hit the roof above the ped
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

--Align legsup players
function alignLegsupPlayers(supportPed, liftedPed)
    local supportCoords = GetEntityCoords(supportPed)
    local heading = GetEntityHeading(supportPed)
    heading = heading + 180.0 -- face the supporter

    local forward = GetEntityForwardVector(supportPed)

    local targetPos = supportCoords +
        (forward * Config.OffsetLegsup.SUPPORT_OFFSET) +
        vector3(0.0, 0.0, Config.OffsetLegsup.HEIGHT_OFFSET)

    SetEntityCoordsNoOffset(liftedPed, targetPos.x, targetPos.y, targetPos.z, false, false, false)
    SetEntityHeading(liftedPed, heading)

    FreezeEntityPosition(liftedPed, true)
end

-- Align legsup players
RegisterNetEvent("legsup:align")
AddEventHandler("legsup:align", function(supportServerId)
    local liftedPed = PlayerPedId()
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId)) -- a test

    alignLegsupPlayers(supportPed, liftedPed)
end)

-- Play legsup animations
RegisterNetEvent("legsup:playBoost")
AddEventHandler("legsup:playBoost", function()
    local ped = PlayerPedId()

    RequestAnimDict(Config.Animation.LEGSUP.DICTLIFT)
    while not HasAnimDictLoaded(Config.Animation.LEGSUP.DICTLIFT) do Wait(10) end

    TaskPlayAnim(ped, Config.Animation.LEGSUP.DICTLIFT, Config.Animation.LEGSUP.ANIMLIFT, 8.0, -8.0, -1, 0, 0, false,
        false, false)
end)

-- Play legsup jump animation
RegisterNetEvent("legsup:playJump")
AddEventHandler("legsup:playJump", function()
    local ped = PlayerPedId()

    RequestAnimDict(Config.Animation.LEGSUP.DICTJUMP)
    while not HasAnimDictLoaded(Config.Animation.LEGSUP.DICTJUMP) do Wait(10) end

    TaskPlayAnim(ped, Config.Animation.LEGSUP.DICTJUMP, Config.Animation.LEGSUP.ANIMJUMP, 8.0, -8.0, -1, 0, 0, false,
        false, false)
end)

--Apply legsup force -- Fully Reworked
RegisterNetEvent("legsup:applyForce")
AddEventHandler("legsup:applyForce", function()
    local ped = PlayerPedId()

    FreezeEntityPosition(ped, false)
    local coords = GetEntityCoords(ped)

    Wait(BOOST_TIME)
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.05) -- c'est un peu goofy mais j'aime bien !

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + 0.15, false, false, false)
    SetPedCanRagdoll(ped, false)

    Wait(0)

    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    local BOOST_HEIGHT = Config.Arc.ARC_HEIGHT or 2.50
    local FORWARD_DISTANCE = Config.Arc.ARC_FORWARD_DISTANCE or 4.6
    local GRAVITY = 9.8

    local vZ = math.sqrt(2 * GRAVITY * BOOST_HEIGHT)
    local apexTime = vZ / GRAVITY
    local totalAirTime = 2 * apexTime
    local forwardSpeed = FORWARD_DISTANCE / totalAirTime
    local forward = GetEntityForwardVector(ped)

    Legsup.isClimbing = true

    CreateThread(function()
        while Legsup.isClimbing do
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            Wait(0)
        end
    end)

    -- Phase de décollage vertical 
    local maxAttempts = 15
    local attempts = 0
    while not IsEntityInAir(ped) and attempts < maxAttempts do
        SetEntityVelocity(ped, 0.0, 0.0, vZ)
        attempts = attempts + 1
        Wait(0)
    end

    -- Phase de force de la vélocité horizontale ET verticale À CHAQUE FRAME
    local startTime = GetGameTimer()
    local flightDurationMs = math.floor(totalAirTime * 1000)

    while (GetGameTimer() - startTime) < flightDurationMs do
        local elapsed = (GetGameTimer() - startTime) / 1000.0
        local currentZ = vZ - (GRAVITY * elapsed) -- vitesse verticale calculée manuellement (gravité simulée nous-même)

        SetEntityVelocity(ped,
            forward.x * forwardSpeed,
            forward.y * forwardSpeed,
            currentZ
        )
        Wait(0)
    end

    Legsup.isClimbing = false

    Wait(200)

    SetPedCanRagdoll(ped, true)
end)




-- Debug command to test legsup force application --Here for testing
RegisterCommand("aforce", function()
    if not Config.debug then
        errorMsg("❌ Commande désactivée")
        return
    end 

    local MIN_WALL_DISTANCE = 2.0
    local MIN_ROOF_HEIGHT = 3.0
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
    Wait(BOOST_TIME)

    -- Réglages de la trajectoire (à ajuster selon la hauteur type d'un mur RP)
    local BOOST_HEIGHT = 7.8      -- hauteur max atteinte, en mètres
    local FORWARD_DISTANCE = 3.4  -- distance parcourue vers l'avant pendant le saut
    local GRAVITY = 9.8

    -- Calcul physique d'une trajectoire de saut naturelle (comme un vrai saut)
    local vZ = math.sqrt(2 * GRAVITY * BOOST_HEIGHT)
    local airTime = (2 * vZ) / GRAVITY
    local forwardSpeed = FORWARD_DISTANCE / airTime

    local forward = GetEntityForwardVector(ped)

    SetPedCanRagdoll(ped, false)
    SetEntityVelocity(ped,
        forward.x * forwardSpeed,
        forward.y * forwardSpeed,
        vZ
    )

    -- Réactive le ragdoll une fois la trajectoire terminée (retombée au sol)
    Wait(math.floor(airTime * 1000) + 200)
    SetPedCanRagdoll(ped, true)
end)