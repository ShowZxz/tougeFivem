PullUp = {}

local BOOST_TIME = (Config.Frame.BOOST_FRAME / Config.Frame.ANIM_FPS) * 1000

function PullUp.CanUse(ped, targetPed, dist)
    return dist >= Config.Distances.PULLUP_MIN
        and dist <= Config.Distances.PULLUP_MAX
        and isSupportStateValid(targetPed)
end

function PullUp.Start(targetServerId)
    TriggerServerEvent("interaction_lift:pullup", targetServerId)
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

function alignPullupPlayers(supportPed, liftedPed)
    local supportCoords = GetEntityCoords(supportPed)
    local liftedCoords  = GetEntityCoords(liftedPed)

    local heading = GetEntityHeading(supportPed) + 180.0

    local forward = GetEntityForwardVector(supportPed)
    local right   = GetRightVectorFromForward(forward)

  

    local targetX = supportCoords.x + forward.x * Config.OffsetPullup.FRONT_OFFSET + right.x * Config.OffsetPullup.SIDE_OFFSET
    local targetY = supportCoords.y + forward.y * Config.OffsetPullup.FRONT_OFFSET + right.y * Config.OffsetPullup.SIDE_OFFSET
    local targetZ = liftedCoords.z + Config.OffsetPullup.Z_OFFSET

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



RegisterNetEvent("pullup:align", function(supportServerId)
    local liftedPed = PlayerPedId()
    local supportPed = GetPlayerPed(GetPlayerFromServerId(supportServerId))

    alignPullupPlayers(supportPed, liftedPed)

end)

RegisterNetEvent("pullup:playUpBoost", function()
    local ped = PlayerPedId()
    --Animation de boost
    RequestAnimDict(Config.Animation.PULLUP.DICTLIFT)
    while not HasAnimDictLoaded(Config.Animation.PULLUP.DICTLIFT) do Wait(10) end
    TaskPlayAnim(ped, Config.Animation.PULLUP.DICTLIFT, Config.Animation.PULLUP.ANIMLIFT, 8.0, -8.0, BOOST_TIME, 2, 0, false, false, false)
end)

RegisterNetEvent("pullup:playJump", function()
    local ped = PlayerPedId()
    --Animation de saut
    RequestAnimDict(Config.Animation.PULLUP.DICTJUMP)
    while not HasAnimDictLoaded(Config.Animation.PULLUP.DICTJUMP) do Wait(10) end
    TaskPlayAnim(ped, Config.Animation.PULLUP.DICTJUMP, Config.Animation.PULLUP.ANIMJUMP, 8.0, -8.0, BOOST_TIME, 2, 0, false, false, false)
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
        local t = (now - startTime) / Config.Pulling.PULLING_DURATION
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
