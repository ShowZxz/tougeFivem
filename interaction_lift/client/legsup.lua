Legsup = {}



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

