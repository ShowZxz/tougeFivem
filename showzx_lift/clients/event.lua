RegisterNetEvent("showzx_lift:playLiftAnim", function()
    local playerPed = PlayerPedId()

    if not IsEntityPlayingAnim(playerPed, ShowZxLiftConfig.Animation.LIFT.DICTIDLE, ShowZxLiftConfig.Animation.LIFT.ANIMIDLE, 3) then

        RequestAnimDict(ShowZxLiftConfig.Animation.LIFT.DICTIDLE)
        while not HasAnimDictLoaded(ShowZxLiftConfig.Animation.LIFT.DICTIDLE) do
            Wait(10)
        end

        TaskPlayAnim(playerPed, ShowZxLiftConfig.Animation.LIFT.DICTIDLE, ShowZxLiftConfig.Animation.LIFT.ANIMIDLE, 8.0, -8.0, -1, 50, 0, false, false, false)
    end
end)

RegisterNetEvent("showzx_lift:playDeployAnim", function()
    local playerPed = PlayerPedId()

    if not IsEntityPlayingAnim(playerPed, ShowZxLiftConfig.Animation.SUPP.DICTJUMP, ShowZxLiftConfig.Animation.SUPP.ANIMJUMP, 3) then

        RequestAnimDict(ShowZxLiftConfig.Animation.SUPP.DICTJUMP)
        while not HasAnimDictLoaded(ShowZxLiftConfig.Animation.SUPP.DICTJUMP) do
            Wait(10)
        end

        TaskPlayAnim(playerPed, ShowZxLiftConfig.Animation.SUPP.DICTJUMP, ShowZxLiftConfig.Animation.SUPP.ANIMJUMP, 8.0, -8.0, -1, 50, 0, false, false, false)
    end
end)