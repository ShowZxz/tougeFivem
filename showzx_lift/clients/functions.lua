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


