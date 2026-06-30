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
    if not ShowZxLiftConfig.Debug.ENABLED then return end
    print("[showzx_lift DEBUG] " .. msg)
end

function displayHelpTextForRope()
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Utiliser la corde")
    EndTextCommandDisplayHelp(0, false, true, -1)
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

function displayHelpText()
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Pour placer la corde\nAppuie sur ~INPUT_VEH_DUCK~ pour ~r~stop~s~ la preview")
    EndTextCommandDisplayHelp(0, false, true, -1)
end