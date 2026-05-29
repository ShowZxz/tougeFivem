-- Commande pour afficher un checkpoint persistant à la position du joueur
local checkpointThread = nil
-- Protection anti-void : conserve la dernière position sûre et téléporte si le joueur tombe trop bas
local lastSafePos = nil

RegisterCommand("checkpoint", function()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local radius = 5.0
    local checkpointType = 47 -- Cône bleu
    local checkpointPos = vector3(coords.x, coords.y, coords.z - 1.0)
    print("Checkpoint persistant créé à ta position !")
    if checkpointThread then return end
    checkpointThread = Citizen.CreateThread(function()
        while true do
            local player = PlayerPedId()
            local pCoords = GetEntityCoords(player)
            local dist = #(pCoords - checkpointPos)
            if dist < 50.0 then
                DrawMarker(checkpointType, checkpointPos.x, checkpointPos.y, checkpointPos.z, 0, 0, 0, 0, 0, 0, radius, radius, 2.0, 0, 0, 255, 100, false, true, 2, nil, nil, false)
            end
            Wait(0)
        end
    end)
end)
RegisterCommand("hello", function()
    print("Hello world!")
end)

RegisterCommand("gps", function()
    local player = PlayerPedId()
    local playerCoords = GetEntityCoords(player)
    local heading = GetEntityHeading(player)
    print("Position: " .. playerCoords.x .. ", " .. playerCoords.y .. ", " .. playerCoords.z .. " | Heading: " .. heading)
end)

RegisterCommand("wp", function(command, args)
    local player = PlayerPedId()
    local blip = GetFirstBlipInfoId(8) 

    if DoesBlipExist(blip) then
        local coords = GetBlipInfoIdCoord(blip)

        if IsPedInAnyVehicle(player, false) then
            -- Le joueur est dans un véhicule
            local veh = GetVehiclePedIsIn(player, false)
            SetEntityCoords(veh, coords.x, coords.y, coords.z)
            print("Téléporté au waypoint avec le véhicule")
        else
            -- Le joueur est à pied
            SetEntityCoords(player, coords.x, coords.y, coords.z)
            print("Téléporté au waypoint à pied")
        end
    else
        print("Aucun waypoint trouvé")
    end
end)

RegisterCommand("damage", function()
    local player = PlayerPedId()
    local health = GetEntityHealth(player)
    local newHealth = health - 10
    SetEntityHealth(player, newHealth)
    print("Vous avez perdu 10 points de vie. Santé actuelle : " .. newHealth)
end)

RegisterCommand("heal", function()
    local player = PlayerPedId()
    SetEntityHealth(player, 200)
    print("Vous avez été soigné. Santé actuelle : 200")
end)

RegisterCommand("car", function(source, args, rawCommand)
    local player = PlayerPedId()
    -- supprimer le dernier vehicule si le joueur en a un
    local veh = GetVehiclePedIsIn(player, false)
    local lastVeh = GetLastDrivenVehicle()
    veh = lastVeh
    if veh and veh ~= 0 then
        DeleteEntity(veh)
    end
   

    local model = args[1] or "futo" -- Si aucun modèle n'est fourni, utilise "futo" par défaut

    -- Charger le modèle du véhicule
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end

    -- Obtenir la position du joueur
    local playerCoords = GetEntityCoords(player)

    -- Créer le véhicule à la position du joueur
    local vehicle = CreateVehicle(model, playerCoords.x, playerCoords.y, playerCoords.z, GetEntityHeading(player), true, false)

    -- Mettre le joueur dans le véhicule
    SetPedIntoVehicle(player, vehicle, -1) -- -1 pour le siège conducteur

    -- Libérer le modèle
    SetModelAsNoLongerNeeded(model)

    print("Véhicule " .. model .. " créé et vous êtes monté dedans.")

end)

RegisterCommand("dv", function()
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)

    if veh and veh ~= 0 then
        DeleteEntity(veh)
        print("Véhicule supprimé.")
    else
        print("Vous n'êtes pas dans un véhicule.")
    end
end)

RegisterCommand("fix", function()
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)

    if veh and veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, false)
        print("Véhicule réparé.")
    else
        print("Vous n'êtes pas dans un véhicule.")
    end
end)

RegisterCommand("fullc", function()
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)
        if veh and veh ~= 0 then
            SetVehicleModKit(veh, 0)
            -- Moteur max (modType 11)
            local engineMods = GetNumVehicleMods(veh, 11)
            if engineMods > 0 then
                SetVehicleMod(veh, 11, engineMods - 1, false)
            end
            -- Transmission max (modType 13)
            local transMods = GetNumVehicleMods(veh, 13)
            if transMods > 0 then
                SetVehicleMod(veh, 13, transMods - 1, false)
            end
            -- Suspension max (modType 15)
            local suspMods = GetNumVehicleMods(veh, 15)
            if suspMods > 0 then
                SetVehicleMod(veh, 15, suspMods - 1, false)
            end
            -- Turbo
            ToggleVehicleMod(veh, 18, true)
            -- Couleur rouge
            SetVehicleColours(veh, 27, 27) -- 27 = rouge
            print("Véhicule full custom rouge !")
        else
            print("Vous n'êtes pas dans un véhicule.")
    end
end)

local checkpointThread = nil
RegisterCommand("checkpoint", function()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local radius = 10.0
    local checkpointType = 6 
    local checkpointPos = vector3(coords.x, coords.y, coords.z - 1.0)
    print("Checkpoint persistant créé à ta position !")
    if checkpointThread then return end
    checkpointThread = Citizen.CreateThread(function()
        while true do
            local player = PlayerPedId()
            local pCoords = GetEntityCoords(player)
            local dist = #(pCoords - checkpointPos)
            if dist < 200.0 then
                DrawMarker(checkpointType, checkpointPos.x, checkpointPos.y, checkpointPos.z+3, 0, 0, 0, 0, 0, 0, radius, radius, radius, 0, 0, 255, 100, false, true, 2, nil, nil, false)  
                end
                if dist < radius then
                    -- Le joueur est dans le checkpoint
                    print("Checkpoint atteint !")
                    -- supprimer le checkpoint
                    checkpointThread = nil
                    return
                end
            Wait(0)
        end
    end)
end)

RegisterCommand("kill", function()
    local player = PlayerPedId()
    SetEntityHealth(player, 0)
    message("Vous êtes mort.")
end)

RegisterCommand("break", function()
    local player = PlayerPedId()
    local veh = GetVehiclePedIsIn(player, false)
    if veh and veh ~= 0 then
        SetVehicleEngineHealth(veh, 100.0)
        SetVehiclePetrolTankHealth(veh, 100.0)
        print("Le véhicule est maintenant en panne.")
    else
        print("Vous n'êtes pas dans un véhicule.")
    end
end)

-- Command to delete all ped proxies in areaSize radius around the player
RegisterCommand("delprox", function(source, args, rawCommand)
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local areaSize = tonumber(args[1]) or 10.0

    local deletedCount = 0
    for proxyId, proxyData in pairs(Support.Proxies) do
        local proxyEntity = proxyData.entity
        if DoesEntityExist(proxyEntity) then
            local proxyCoords = GetEntityCoords(proxyEntity)
            local dist = #(coords - proxyCoords)
            if dist <= areaSize then
                DeleteEntity(proxyEntity)
                Support.Proxies[proxyId] = nil
                deletedCount = deletedCount + 1
            end
        end
    end

    print("Supprimé " .. deletedCount .. " proxys dans un rayon de " .. areaSize .. " mètres.")
end)

RegisterCommand("gun", function()
    local player = PlayerPedId()
    local weaponHash = GetHashKey("WEAPON_PISTOL")
    GiveWeaponToPed(player, weaponHash, 250, false, true)
    message("Pistolet donné.")
end)

-- change player model to the specified model name
RegisterCommand("model", function(source, args, rawCommand)
    local modelName = args[1]
    if not modelName then
        print("Usage: /model [modelName]")
        return
    end

    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end

    SetPlayerModel(PlayerId(), modelHash)
    SetModelAsNoLongerNeeded(modelHash)
    print("Modèle changé en " .. modelName)
end)

-- teleport to player id
RegisterCommand("tp",function (source,args,rawCommand)
    local player = PlayerPedId()
    local target = GetPlayerPed(args)

    local targetCoords = NetworkGetPlayerCoords(target)
    SetEntityCoords(player, targetCoords.x, targetCoords.y, targetCoords.z)


    
end)

RegisterCommand("cl", function()
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(),false)
end)


function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(ControlButton)
    N_0xe83a3e3557a56640(ControlButton)
end

function setupScaleform(scaleform)

    local scaleform = RequestScaleformMovie(scaleform)

    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(1)
    end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(5)
    Button(GetControlInstructionalButton(2, config.controls.openKey, true))
    ButtonMessage("Disable Noclip")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(4)
    Button(GetControlInstructionalButton(2, config.controls.goUp, true))
    ButtonMessage("Go Up")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(3)
    Button(GetControlInstructionalButton(2, config.controls.goDown, true))
    ButtonMessage("Go Down")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(2)
    Button(GetControlInstructionalButton(1, config.controls.turnRight, true))
    Button(GetControlInstructionalButton(1, config.controls.turnLeft, true))
    ButtonMessage("Turn Left/Right")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    Button(GetControlInstructionalButton(1, config.controls.goBackward, true))
    Button(GetControlInstructionalButton(1, config.controls.goForward, true))
    ButtonMessage("Go Forwards/Backwards")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    Button(GetControlInstructionalButton(2, config.controls.changeSpeed, true))
    ButtonMessage("Change Speed ("..config.speeds[index].label..")")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(config.bgR)
    PushScaleformMovieFunctionParameterInt(config.bgG)
    PushScaleformMovieFunctionParameterInt(config.bgB)
    PushScaleformMovieFunctionParameterInt(config.bgA)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

function DisableControls()
    DisableControlAction(0, 30, true)
    DisableControlAction(0, 31, true)
    DisableControlAction(0, 32, true)
    DisableControlAction(0, 33, true)
    DisableControlAction(0, 34, true)
    DisableControlAction(0, 35, true)
    DisableControlAction(0, 266, true)
    DisableControlAction(0, 267, true)
    DisableControlAction(0, 268, true)
    DisableControlAction(0, 269, true)
    DisableControlAction(0, 44, true)
    DisableControlAction(0, 20, true)
    DisableControlAction(0, 74, true)
end








--==--==--==--
-- Config
--==--==--==--

config = {
    controls = {
        -- [[Controls, list can be found here : https://docs.fivem.net/game-references/controls/]]
        openKey = 288, -- [[F2]]
        goUp = 85, -- [[Q]]
        goDown = 48, -- [[Z]]
        turnLeft = 34, -- [[A]]
        turnRight = 35, -- [[D]]
        goForward = 32,  -- [[W]]
        goBackward = 33, -- [[S]]
        changeSpeed = 21, -- [[L-Shift]]
    },

    speeds = {
        -- [[If you wish to change the speeds or labels there are associated with then here is the place.]]
        { label = "Very Slow", speed = 0},
        { label = "Slow", speed = 0.5},
        { label = "Normal", speed = 2},
        { label = "Fast", speed = 4},
        { label = "Very Fast", speed = 6},
        { label = "Extremely Fast", speed = 10},
        { label = "Extremely Fast v2.0", speed = 20},
        { label = "Max Speed", speed = 25}
    },

    offsets = {
        y = 0.5, -- [[How much distance you move forward and backward while the respective button is pressed]]
        z = 0.2, -- [[How much distance you move upward and downward while the respective button is pressed]]
        h = 3, -- [[How much you rotate. ]]
    },

    -- [[Background colour of the buttons. (It may be the standard black on first opening, just re-opening.)]]
    bgR = 0, -- [[Red]]
    bgG = 0, -- [[Green]]
    bgB = 0, -- [[Blue]]
    bgA = 80, -- [[Alpha]]
}

--==--==--==--
-- End Of Config
--==--==--==--

noclipActive = false -- [[Wouldn't touch this.]]

index = 1 -- [[Used to determine the index of the speeds table.]]

Citizen.CreateThread(function()

    buttons = setupScaleform("instructional_buttons")

    currentSpeed = config.speeds[index].speed

    while true do
        Citizen.Wait(1)

        if IsControlJustPressed(1, config.controls.openKey) then
            noclipActive = not noclipActive

            if IsPedInAnyVehicle(PlayerPedId(), false) then
                noclipEntity = GetVehiclePedIsIn(PlayerPedId(), false)
            else
                noclipEntity = PlayerPedId()
            end

            SetEntityCollision(noclipEntity, not noclipActive, not noclipActive)
            FreezeEntityPosition(noclipEntity, noclipActive)
            SetEntityInvincible(noclipEntity, noclipActive)
            SetVehicleRadioEnabled(noclipEntity, not noclipActive) -- [[Stop radio from appearing when going upwards.]]
        end

        if noclipActive then
            DrawScaleformMovieFullscreen(buttons)

            local yoff = 0.0
            local zoff = 0.0

            if IsControlJustPressed(1, config.controls.changeSpeed) then
                if index ~= 8 then
                    index = index+1
                    currentSpeed = config.speeds[index].speed
                else
                    currentSpeed = config.speeds[1].speed
                    index = 1
                end
                setupScaleform("instructional_buttons")
            end
				
				DisableControls()

			if IsDisabledControlPressed(0, config.controls.goForward) then
                yoff = config.offsets.y
			end
			
            if IsDisabledControlPressed(0, config.controls.goBackward) then
                yoff = -config.offsets.y
			end
			
            if IsDisabledControlPressed(0, config.controls.turnLeft) then
                SetEntityHeading(noclipEntity, GetEntityHeading(noclipEntity)+config.offsets.h)
			end
			
            if IsDisabledControlPressed(0, config.controls.turnRight) then
                SetEntityHeading(noclipEntity, GetEntityHeading(noclipEntity)-config.offsets.h)
			end
			
            if IsDisabledControlPressed(0, config.controls.goUp) then
                zoff = config.offsets.z
			end
			
            if IsDisabledControlPressed(0, config.controls.goDown) then
                zoff = -config.offsets.z
			end
			
            local newPos = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, yoff * (currentSpeed + 0.3), zoff * (currentSpeed + 0.3))
            local heading = GetEntityHeading(noclipEntity)
            SetEntityVelocity(noclipEntity, 0.0, 0.0, 0.0)
            SetEntityRotation(noclipEntity, 0.0, 0.0, 0.0, 0, false)
            SetEntityHeading(noclipEntity, heading)
            SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, noclipActive, noclipActive, noclipActive)
        end
    end
end)

--==--==--==--
-- End Of Script
--==--==--==--