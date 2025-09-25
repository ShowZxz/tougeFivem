-- server.lua (ajouts / remplacements pour match creation + ready/countdown)

local queue = {}
local maxPlayers = 2
local matchTimeoutReady = 8000 -- ms pour attendre les ready

local matches = {} -- table des matchs actifs, indexée par matchId

-- helper : est-ce qu'un joueur serverId est connecté ?
local function isPlayerConnected(serverId)
    if not serverId then return false end
    local name = GetPlayerName(serverId)
    return name ~= nil and name ~= ""
end

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

-- création du match (remplace ton ancien RegisterNetEvent("tougue:server:matchCreated"))
RegisterNetEvent("tougue:server:matchCreated")
AddEventHandler("tougue:server:matchCreated", function(playersInMatch)
    if not playersInMatch or #playersInMatch < 2 then
        print("matchCreated: joueurs insuffisants.")
        return
    end

    local lead = playersInMatch[1].id
    local chaser = playersInMatch[2].id

    if not isPlayerConnected(lead) then
        print("Lead non connecté, annulation du match.")
        TriggerClientEvent("tougue:client:notify", chaser, "Le match a été annulé : adversaire déconnecté.")
        return
    end
    if not isPlayerConnected(chaser) then
        print("Chaser non connecté, annulation du match.")
        TriggerClientEvent("tougue:client:notify", lead, "Le match a été annulé : adversaire déconnecté.")
        return
    end

    print("Création match entre " .. playersInMatch[1].name .. " et " .. playersInMatch[2].name)

    local leadModel = "adder"
    local chaserModel = "zentorno"
    local leadCoords = { x = 471.362640, y = 892.613464, z = 197.687119, heading = 345.2146 }
    local chaserCoords = { x = 469.560150, y = 882.534973, z = 197.787552, heading = 345.0 }

    -- créer un matchId unique
    local matchId = tostring(os.time()) .. "_" .. tostring(lead)

    -- objet match côté serveur pour suivre les ready
    local match = {
        id = matchId,
        players = { lead, chaser },
        ready = {}, -- table serverId -> true/false
        createdAt = GetGameTimer()
    }

    -- initialisation ready
    for _, sid in ipairs(match.players) do match.ready[sid] = false end

    -- stocker le match globalement pour pouvoir y accéder depuis playerReady
    matches[matchId] = match

    -- envoyer l'event de préparation (spawn + freeze) à chaque joueur, en incluant matchId
    TriggerClientEvent("tougue:client:prepareRound", lead, matchId, "lead", leadModel, leadCoords)
    TriggerClientEvent("tougue:client:prepareRound", chaser, matchId, "chaser", chaserModel, chaserCoords)

    -- attente active des ready avec timeout
    local startWait = GetGameTimer()
    local allReady = false
    while (GetGameTimer() - startWait) < matchTimeoutReady do
        -- vérifier si tous prêts
        allReady = true
        for _, sid in ipairs(match.players) do
            if not match.ready[sid] then
                allReady = false
                break
            end
        end
        if allReady then break end
        Wait(200)
    end

    if not allReady then
        -- timeout : annulation ou décision (ici : notification et fin)
        for _, sid in ipairs(match.players) do
            if isPlayerConnected(sid) then
                TriggerClientEvent("tougue:client:notify", sid, "Match annulé : un joueur n'a pas chargé à temps.")
            end
        end
        print("match " .. match.id .. " annulé (timeout ready).")
        -- cleanup
        matches[matchId] = nil
        return
    end

    -- Si on arrive ici, tous sont prêts : on lance le countdown (serveur ordonne)
    for _, sid in ipairs(match.players) do
        TriggerClientEvent("tougue:client:startCountdown", sid, 3) -- countdown 3 secondes
    end

    print("match " .. match.id .. " démarré (countdown envoyé).")

    -- tu peux garder le match stocké (matches[matchId]) pour la suite (rounds, checkpoints, etc.)
end)

-- Endpoint : joueur signale qu'il est prêt après spawn/freeze/chargement client-side
-- Maintenant on attend matchId en paramètre
RegisterNetEvent("tougue:server:playerReady")
AddEventHandler("tougue:server:playerReady", function(matchId)
    local src = source
    print("Server received ready from " .. tostring(src) .. " for matchId=" .. tostring(matchId))

    if not matchId then
        print("playerReady reçu sans matchId de la part de " .. tostring(src))
        return
    end

    local match = matches[matchId]
    if not match then
        print("playerReady: match introuvable pour matchId=" .. tostring(matchId))
        return
    end

    -- vérifier que le joueur fait bien partie du match
    local isParticipant = false
    for _, sid in ipairs(match.players) do
        if sid == src then isParticipant = true; break end
    end
    if not isParticipant then
        print("playerReady: joueur " .. tostring(src) .. " n'est pas dans le match " .. tostring(matchId))
        return
    end

    match.ready[src] = true
    TriggerClientEvent("tougue:client:notify", src, "Prêt confirmé par le serveur.")
end)
