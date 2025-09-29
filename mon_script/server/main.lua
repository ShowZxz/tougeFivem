
local tracks = {
    {
        id = "vinewood_antenna",
        name = "Montée l'antenne de Vinewood",
        description = "Course courte et technique jusqu'à l'antenne de Vinewood.",
        start = { x = 472.0, y = 884.0, z = 197.6, heading = 345.21 },
        finish = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 },
        blip = { sprite = 1, color = 5 },
        checkpoints = {
            { pos = { x = 495.57968139648, y = 975.55279541016, z = 206.3720703125 }, radius = 6.0 },
            { pos = { x = 475.71682739258, y = 1100.7467041016, z = 230.4866790771 }, radius = 6.0 },
            { pos = { x = 493.63165283203, y = 1310.4053955078, z = 281.3562011718 }, radius = 6.0 },
            { pos = { x = 667.21203613281, y = 1369.6392822266, z = 325.96502685547 }, radius = 6.0 },
            { pos = { x = 853.21496582031, y = 1332.9610595703, z = 353.5494995117 }, radius = 6.0 },
            { pos = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 }, radius = 8.0}-- finish
        },
        meta = {
            maxPlayers = 2,
            minPlayers = 1,
            laps = 1,
            timeLimit = 100000, 
            allowedVehicles = {"adder","zentorno"}, -- empty = any
            reward = { money = 500, points = 10 }
        }
    },

    -- Add more tracks as needed
}





RegisterCommand("testclient", function()
    print("Commande testclient utilisée")
    TriggerClientEvent("mon_script:client:clientPrint", -1)
end)

RegisterNetEvent("mon_script:server:serverPrint", function()
    local playerName = GetPlayerName(PlayerId())
    print(playerName .. " a utilisé la commande testserver")

end)


-- Table pour suivre la progression de chaque joueur (clé = source, valeur = dernier checkpoint atteint)
local playerProgress = {}

RegisterNetEvent("mon_script:server:checkpointPassed", function(checkpointIndex)
    local src = source
    local playerName = GetPlayerName(src)
    local lastCheckpoint = playerProgress[src] or 0
    -- Sécurité : le joueur ne peut valider que le checkpoint suivant
    if checkpointIndex == lastCheckpoint + 1 then
        playerProgress[src] = checkpointIndex
        print(playerName .. " a passé le checkpoint " .. checkpointIndex)
        if checkpointIndex == #tracks[1].checkpoints then
            print(playerName .. " a terminé la course " .. tracks[1].name)
            -- Ici, vous pouvez ajouter du code pour récompenser le joueur, enregistrer son temps, etc.
            playerProgress[src] = nil -- reset pour une prochaine course
        end
    else
        print("[SECURITE] " .. playerName .. " a tenté de valider un checkpoint hors ordre !")
        -- Optionnel : sanction, message, etc.
    end
end)

RegisterNetEvent("mon_script:server:raceTimeout", function()
    local src = source
    local playerName = GetPlayerName(src)
    print(playerName .. " n'a pas terminé la course à temps.")
    playerProgress[src] = nil -- reset pour une prochaine course
end)

RegisterNetEvent("mon_script:server:raceFinished", function()
    local src = source
    local playerName = GetPlayerName(src)
    print(playerName .. " a terminé la course avec succès.")
    end)



RegisterCommand("race1", function (source)
    local track = tracks[1] -- Choisir la première course pour cet exemple
    TriggerClientEvent("mon_script:client:startRace",source, track)

end)

