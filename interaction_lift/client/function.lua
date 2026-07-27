--Notify normal message
function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(184)
    EndTextCommandThefeedPostTicker(false, true)
end

-- Notify error message
function errorMsg(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(6)
    EndTextCommandThefeedPostTicker(true, true)
end

-- Check if the player is in a valid state to support/lift
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

--Check if there is a void in front of the player to perform a pullup
function checkVoidFront(ped)
    local pos = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local offset = 2.0

    local lineX = pos.x + forward.x * offset
    local lineY = pos.y + forward.y * offset

    local found, groundZ = GetGroundZFor_3dCoord(
        lineX,
        lineY,
        pos.z,
        false
    )

    if not found then
        errorMsg("Impossible de trouver le sol.")
        return false
    end

        local lineLengthCheck = pos.z - groundZ
    if lineLengthCheck < 1.0 then
        errorMsg("Pas de vide devant vous.")
        Support.active = false
        return false
    end
    
    if lineLengthCheck > 3.0 then return true end
    
end

function canSetSupportForPullup(ped)
    return (
        checkVoidFront(ped)
    )
end

-- Draw text on the HUD
function DrawHudText(text, x, y)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function DrawHudInfo(msg)
    AddTextEntry('HelpMsg', msg)
    BeginTextCommandDisplayHelp('HelpMsg')
    EndTextCommandDisplayHelp(0, false, false, -1)
end

function displayHelpText(mode)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Pour faire un "..mode)
    EndTextCommandDisplayHelp(0, false, true, -1)
end