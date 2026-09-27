function vaultTask(targetCoords)
        local playerPed = PlayerPedId()
        if not IsEntityPlayingAnim(playerPed, "skydive@parachute@first_person", "chute_idle_lookright", 3) then

        RequestAnimDict("skydive@parachute@first_person")
        while not HasAnimDictLoaded("skydive@parachute@first_person") do
            Wait(10)
        end

        TaskPlayAnim(playerPed, "skydive@parachute@first_person", "chute_idle_lookright", 8.0, -8.0, -1, 0, 0, false, false, false)

        while GetEntityAnimCurrentTime(playerPed, "skydive@parachute@first_person", "chute_idle_lookright") < 0.98 do
            Wait(0)
        end
        FreezeEntityPosition(PlayerPedId(), false)
        playerState = "IDLE"
    end
end









RegisterCommand("shx_climb:reset", function()
    playerState = "IDLE"
    FreezeEntityPosition(PlayerPedId(), true)
    print("Player state reset to IDLE")
end, false)

RegisterCommand("testanim", function()
    local ped = PlayerPedId()
    local dict = "move_climb" -- change ici pour tester chaque anim
    local anim = "runclimbup_180_high_angled_20"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
end, false)

RegisterCommand("testanim1", function()
    local ped = PlayerPedId()
    local dict = "skydive@parachute@first_person" -- change ici pour tester chaque anim
    local anim = "chute_idle_lookright"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
end, false)

RegisterCommand("testanim2", function()
    local ped = PlayerPedId()
    local dict = "ladders" -- change ici pour tester chaque anim
    local anim = "slide_get_off_bottom"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
end, false)

RegisterCommand("testanim3", function()
    local ped = PlayerPedId()
    local dict = "anim@sports@ballgame@handball@" -- change ici pour tester chaque anim
    local anim = "ball_rstop_r_slide"

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
end, false)