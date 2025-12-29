PullUp = {}



function PullUp.CanUse(ped, targetPed, dist)
    return dist >= Config.PullUpMinDistance
        and dist <= Config.PullUpDistance
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

