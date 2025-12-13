local supporting = false
local busy = false

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

local SUPPORT_OFFSET = 0.80   -- distance avec le joueur supportant
local HEIGHT_OFFSET = 0.0 -- et la hauteur

local UP_FORCE = 850.0
local FORWARD_FORCE = 3000.0


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

RegisterCommand("legsup", function()
    if busy then return end

    supporting = not supporting

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
                    busy = true
                    TriggerServerEvent("legsup:tryLift", GetPlayerServerId(player))
                end
            end
        end

        ::continue::
    end
end)

RegisterNetEvent("legsup:applyForce", function()
    local ped = PlayerPedId()

    local forward = GetEntityForwardVector(ped)

    FreezeEntityPosition(ped, false)
    Wait(BOOST_TIME)

    ApplyForceToEntity(
        ped,
        1,

        forward.x * FORWARD_FORCE,
        forward.y * FORWARD_FORCE,
        UP_FORCE,

        0.0, 0.0, 0.0,
        true, true, true, false, true
    )

    busy = false
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