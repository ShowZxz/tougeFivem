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

function debugMsg(msg)
    print("[showzx_lift DEBUG] " .. msg)
end



function ShowZxLift.IsOnCooldown()
    local now = GetGameTimer()
    return Support.cooldownEnd and now < Support.cooldownEnd
end

function ShowZxLift.Start(data)
    if ShowZxLift.IsOnCooldown() then
        errorMsg("Veuillez attendre avant de relancer l'action.")
        return
    end

    Support.lastToggle = GetGameTimer()
    Support.cooldownEnd = Support.lastToggle + 1000 -- 1 seconde de cooldown
    TriggerServerEvent("showzx_lift:liftStart", data.owner)
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


