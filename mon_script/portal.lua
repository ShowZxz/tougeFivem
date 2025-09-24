function teleport(player, destination)

    -- Animation de salutation
    RequestAnimDict("anim@mp_player_intcelebrationmale@salute")
    while not HasAnimDictLoaded("anim@mp_player_intcelebrationmale@salute") do
        Wait(100)
    end
    TaskPlayAnim(player, "anim@mp_player_intcelebrationmale@salute", "salute", 8.0, -8, 1500, 0, 0, false, false, false)

    -- Particule et son
    RequestNamedPtfxAsset("scr_rcbarry2")
    while not HasNamedPtfxAssetLoaded("scr_rcbarry2") do
        Wait(10)
    end
    UseParticleFxAssetNextCall("scr_rcbarry2")
    local fx = StartParticleFxLoopedOnEntity("scr_clown_appears", player, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, false,
        false, false)

    PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS", true)
    Wait(1500)

    -- Screen fade
    DoScreenFadeOut(1000)
    Wait(1000)
    SetEntityCoords(player, destination)
    Wait(500)
    DoScreenFadeIn(1000)

    -- particule
    StopParticleFxLooped(fx, 0)

end

function message(msg)
    AddTextEntry('HelpMsg', msg)
    BeginTextCommandDisplayHelp('HelpMsg')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

Citizen.CreateThread(function()
    -- Définition des portails dans une table
    local portails = {{
        name = "Portail Ville → Île",
        from = vector3(229.5554, -797.7112, 30.59146), -- Entrée
        to = vector3(54.707916, 7238.718750, 2.704340), -- Sortie
        blipColor = 5
    }, {
        name = "Portail Île → Ville",
        from = vector3(54.707916, 7238.718750, 2.704340), -- Entrée
        to = vector3(229.5554, -797.7112, 30.59146), -- Sortie
        blipColor = 6
    }, {
        name = "Portail Secret",
        from = vec3(205.145050, 197.972290, 105.147591),
        to = vector3(-500.0, 300.0, 100.0),
        blipColor = 2
    } -- AUtre portails ⬇
    }

    -- Création automatique des blips
    for _, portal in ipairs(portails) do
        local blip = AddBlipForCoord(portal.from)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, portal.blipColor)
        SetBlipScale(blip, 0.8)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(portal.name)
        EndTextCommandSetBlipName(blip)
        portal.inZone = false -- état interne pour éviter le spam
    end

    -- Boucle principale
    while true do
        Wait(0)
        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)

        for _, portal in ipairs(portails) do
            local distance = #(playerCoords - portal.from)

            if distance < 10 then
                if not portal.inZone then
                    message("Appuie sur ~INPUT_CONTEXT~ pour utiliser " .. portal.name)
                    portal.inZone = true
                end

                if IsControlJustPressed(0, 38) then
                    if IsPedInAnyVehicle(player, false) then
                        local veh = GetVehiclePedIsIn(player, false)
                        teleport(veh, portal.to)
                    else
                        teleport(player, portal.to)
                    end
                end
            else
                if portal.inZone then
                    portal.inZone = false
                end
            end
        end
    end
end)
