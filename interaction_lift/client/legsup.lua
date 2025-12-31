Legsup = {}

local BOOST_TIME = (Config.Frame.BOOST_FRAME / Config.Frame.ANIM_FPS) * 1000


function Legsup.CanUse(ped, targetPed, dist)
    return dist <= Config.Distances.LEGSUP_MAX
        and isSupportStateValid(ped)
        and not isNearWall(ped, Config.Distances.MIN_WALL_DISTANCE)
        and not hasRoofAbove(ped, Config.Distances.MIN_ROOF_HEIGHT)
end


function Legsup.Start(targetServerId)
    TriggerServerEvent("interaction_lift:legsup", targetServerId)
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

function alignLegsupPlayers(supportPed, liftedPed)
    local supportCoords = GetEntityCoords(supportPed)
    local heading = GetEntityHeading(supportPed)
    heading = heading + 180.0

    local forward = GetEntityForwardVector(supportPed)

    local targetPos = supportCoords +
        (forward * Config.OffsetLegsup.SUPPORT_OFFSET) +
        vector3(0.0, 0.0, Config.OffsetLegsup.HEIGHT_OFFSET)

    SetEntityCoordsNoOffset(liftedPed, targetPos.x, targetPos.y, targetPos.z, false, false, false)
    SetEntityHeading(liftedPed, heading)

    FreezeEntityPosition(liftedPed, true)
end




RegisterNetEvent("legsup:align", function(supportServerId)
    local liftedPed = PlayerPedId()
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId)) -- a test

    alignLegsupPlayers(supportPed, liftedPed)
end)

RegisterNetEvent("legsup:playBoost", function()
    local ped = PlayerPedId()

    RequestAnimDict(Config.Animation.LEGSUP.DICTLIFT)
    while not HasAnimDictLoaded(Config.Animation.LEGSUP.DICTLIFT) do Wait(10) end

    TaskPlayAnim(ped, Config.Animation.LEGSUP.DICTLIFT, Config.Animation.LEGSUP.ANIMLIFT, 8.0, -8.0, -1, 0, 0, false, false, false)
end)

RegisterNetEvent("legsup:playJump", function()
    local ped = PlayerPedId()

    RequestAnimDict(Config.Animation.LEGSUP.DICTJUMP)
    while not HasAnimDictLoaded(Config.Animation.LEGSUP.DICTJUMP) do Wait(10) end

    TaskPlayAnim(ped, Config.Animation.LEGSUP.DICTJUMP, Config.Animation.LEGSUP.ANIMJUMP, 8.0, -8.0, -1, 0, 0, false, false, false)
end)

RegisterNetEvent("legsup:applyForce", function()
    local ped = PlayerPedId()


    local coords = GetEntityCoords(ped)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + 0.35, true, false, false)
    SetPedCanRagdoll(ped, false)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    Wait(BOOST_TIME)
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.05) -- retirer maybe
    FreezeEntityPosition(ped, false)
    ApplyForceToEntity(
        ped,
        3,
        0.0, 0.0, Config.Arc.ARC_UP_FORCE,
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
    for i = 1, Config.Arc.ARC_STEPS do
        ApplyForceToEntity(
            ped,
            3,
            0.0, Config.Arc.ARC_FORWARD_FORCE, 0.0,
            0.0, 0.0, 0.0,
            0,
            true,
            true,
            true,
            false,
            true
        )
        Wait(Config.Arc.ARC_STEP_TIME)
    end
    SetPedCanRagdoll(ped, true)
end)

