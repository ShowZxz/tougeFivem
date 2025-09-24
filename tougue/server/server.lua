-- server.lua

local queue = {}
local maxPlayers = 2 -- 1v1
local matchInfo = {}

-- Commande de test (exécutée côté serveur)
RegisterCommand("testq", function(source, args, rawCommand)
    -- source = 0 si console ; si joueur, source = server id
    if source == 0 then
        print("Commande testq lancée depuis la console.")
    else
        TriggerClientEvent("tougue:client:notify", source, "TEST Début du jeu !")
    end
end)

-- Un joueur rejoint la queue. On reçoit le playerName depuis le client.
RegisterNetEvent("tougue:server:joinQueue")
AddEventHandler("tougue:server:joinQueue", function(playerName)
    local src = source -- source = server player id
    if not src then return end

    -- Vérifier s'il est déjà dans la queue (pour éviter les doublons)
    for _,p in ipairs(queue) do
        if p.id == src then
            -- Déjà dans la queue
            TriggerClientEvent("tougue:client:notify", src, "Vous êtes déjà dans la file d'attente.")
            return
        end
    end

    table.insert(queue, {name = playerName, id = src})
    print(string.format("%s a rejoint la file d'attente. (ServerID: %d)", tostring(playerName), src))
    TriggerClientEvent("tougue:client:notify", src, "Vous avez rejoint la queue, en attente d'autres joueurs...")

    -- Si on a assez de joueurs, on crée le match
    if #queue >= maxPlayers then
        local playersInMatch = {}

        for i = 1, maxPlayers do
            table.insert(playersInMatch, queue[i])
        end

        -- remove the first maxPlayers from queue
        for i = 1, maxPlayers do
            table.remove(queue, 1)
        end

        -- Notif les joueurs du début du match
        for _, player in ipairs(playersInMatch) do
            TriggerClientEvent("tougue:client:notify", player.id, "Début du jeu ! Préparez-vous...")
        end

        -- Créer le match côté serveur (simple)
        TriggerEvent("tougue:server:matchCreated", playersInMatch)
    end
end)

-- Création du match (serveur)
RegisterNetEvent("tougue:server:matchCreated")
AddEventHandler("tougue:server:matchCreated", function(playersInMatch)
    if not playersInMatch or #playersInMatch < 2 then
        print("matchCreated: joueurs insuffisants.")
        return
    end

    print("Le jeu commence maintenant ! Match entre " .. tostring(playersInMatch[1].name) .. " et " .. tostring(playersInMatch[2].name))

    local lead = playersInMatch[1].id
    local chaser = playersInMatch[2].id

    local modelLead = "adder"     -- modèle (string)
    local modelChaser = "zentorno" -- modèle (string)

    -- Spawn coordinates (tu peux externaliser dans config)
    local leadCoords = { x = 471.362640, y = 892.613464, z = 197.687119, heading = 345.2146 }
    local chaserCoords = { x = 469.560150, y = 882.534973, z = 197.787552, heading = 345.0 }

    -- Envoi event aux clients pour spawn des véhicules (utilise TriggerClientEvent vers chaque joueur)
    TriggerClientEvent("tougue:client:spawnCarLead", lead, modelLead, leadCoords)
   TriggerClientEvent("tougue:client:spawnCarChaser", chaser, modelChaser, chaserCoords)

    -- Notif pour démarrage du match (pourrait attendre le "ready")
    TriggerClientEvent("tougue:client:startMatch", lead, chaser, { some = "info" })
    TriggerClientEvent("tougue:client:startMatch", chaser, lead, { some = "info" })
end)
