function errorMsg(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(6)
    EndTextCommandThefeedPostTicker(true, true)
end

function DrawText3D(coords, text)
    local camCoords = GetGameplayCamCoords()
    local dist = #(coords - camCoords)

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)

    ClearDrawOrigin()
end

function displayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end


function climb()
    local ped = PlayerPedId()
    TaskClimb(ped, true)
    Wait(1000) -- Wait for a moment to ensure the climb task has started
    playerState = "IDLE"
end

