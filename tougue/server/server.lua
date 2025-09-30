-- server.lua
local tracks = assert(load(LoadResourceFile(GetCurrentResourceName(), "server/tracks.lua")))()


local queue = {}
local maxPlayers = 2
local matchTimeoutReady = 8000 -- ms pour attendre les ready

local matches = {} -- table des matchs actifs, indexée par matchId
local playerProgress = {} -- pour suivre la progression des joueurs dans les courses
local CHECKPOINT_MARGIN = 1.5        -- tolérance en mètres
local MIN_TIME_BETWEEN_CHECKPOINTS = 800 -- ms

-- helper : est-ce qu'un joueur serverId est connecté ?
local function isPlayerConnected(serverId)
    if not serverId then return false end
    local name = GetPlayerName(serverId)
    return name ~= nil and name ~= ""
end

local function chooseRandom(list)
    if not list or #list == 0 then return nil end
    return list[math.random(#list)]
end

local function createMatchWithRandomTrack(playersInMatch)
    -- Choix de la track (ici aléatoire ; pour forcer vinewood tu peux chercher par id)
    local track = chooseRandom(tracks) -- ou: track = tracks[1]
    if not track then
        print("Aucune track disponible !")
        return nil
    end

    -- Choix du véhicule : si allowedVehicles non vide -> choisir dedans, sinon fallback
    local allowed = track.meta and track.meta.allowedVehicles or {}
    local chosenVehicle = nil
    if allowed and #allowed > 0 then
        chosenVehicle = chooseRandom(allowed)
    else
        chosenVehicle = "adder" -- fallback si aucune restriction
    end

    -- playersInMatch : table contenant { {id=serverid, name=...}, ... } Shuffle pour randomiser les rôles
    math.randomseed(os.time())
    for i = #playersInMatch, 2, -1 do
        local j = math.random(i)
        playersInMatch[i], playersInMatch[j] = playersInMatch[j], playersInMatch[i]
    end
    -- rôles : 1er = lead, 2e = chaser
    local lead = playersInMatch[1].id
    local chaser = playersInMatch[2].id

    -- créer l'objet match
    local matchId = tostring(os.time()) .. "_" .. tostring(lead)
    local match = {
        id = matchId,
        trackId = track.id,
        track = track, -- copie utile pour la suite
        players = { lead, chaser },
        ready = {},
        currentCheckpoint = {}, -- pour stocker par joueur si besoin
        scores = {},
        createdAt = GetGameTimer(),
        timeout = track.meta and track.meta.timeLimit or 0,
        round = 1,         -- numéro du round en cours
        maxRounds = 2,     -- nombre total de rounds (lead/chaser inversés)
        roles = { [lead] = "lead", [chaser] = "chaser" } -- pour savoir qui est quoi
    }

    -- init ready & scores & currentCheckpoint
    for _, sid in ipairs(match.players) do
        match.ready[sid] = false
        match.scores[sid] = 0
        match.currentCheckpoint[sid] = 1
    end

    -- stocker match
    matches[matchId] = match

    -- préparer les données d'envoi : start coords dépend du rôle
    local leadCoords = track.start

    local chaserCoords = { x = track.start.x + 2.0, y = track.start.y + 2.0, z = track.start.z, heading = track.start.heading }

    -- envoyer prepareRound à chaque joueur, avec le même modèle choisi
    TriggerClientEvent("tougue:client:prepareRound", lead, matchId, "lead", chosenVehicle, leadCoords, track)
    TriggerClientEvent("tougue:client:prepareRound", chaser, matchId, "chaser", chosenVehicle, chaserCoords, track)

    print(("Match %s créé sur la track %s avec vehicule %s"):format(matchId, track.id, tostring(chosenVehicle)))
    return matchId
end

function startNextRound(match)
    -- Inverser les rôles
    print("Démarrage du round " .. tostring(match.round + 1) .. " du match " .. tostring(match.id) .. ", inversion des rôles.")
    local lead, chaser = match.players[2], match.players[1]
    match.players = { lead, chaser }
    match.roles = { [lead] = "lead", [chaser] = "chaser" }
    match.currentCheckpoint = { [lead] = 1, [chaser] = 1 }
    match.ready = { [lead] = false, [chaser] = false }
    match.round = match.round + 1
    print("startNextRound : currentCheckpoint reset, ready reset" ..match.currentCheckpoint[lead].." "..match.currentCheckpoint[chaser])
    -- reset lastCheckpointTime
    -- Envoyer prepareRound aux deux joueurs
    local leadCoords = match.track.start
    local chaserCoords = { x = match.track.start.x + 2.0, y = match.track.start.y + 2.0, z = match.track.start.z, heading = match.track.start.heading }
    TriggerClientEvent("tougue:client:prepareRound", lead, match.id, "lead", "adder", leadCoords, match.track)
    TriggerClientEvent("tougue:client:prepareRound", chaser, match.id, "chaser", "adder", chaserCoords, match.track)
    Wait(1000)
    -- Attendre les ready avec timeout
        for _, sid in ipairs(match.players) do
        TriggerClientEvent("tougue:client:startCountdown", sid, 3) -- countdown 3 secondes
        TriggerClientEvent("tougue:client:startRaceTimer", sid, match.timeout or 100000) -- start
    end
end

-- n'oublie pas d'initialiser le seed random (au démarrage du script)
math.randomseed(os.time())

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

-- création du match et envoi des données aux clients
RegisterNetEvent("tougue:server:matchCreated")
AddEventHandler("tougue:server:matchCreated", function(playersInMatch)
    if not playersInMatch or #playersInMatch < 2 then
        print("matchCreated: joueurs insuffisants.")
        return
    end

    -- Vérification rapide de connexion côté serveur
    local lead = playersInMatch[1].id
    local chaser = playersInMatch[2].id
    if not isPlayerConnected(lead) then
        TriggerClientEvent("tougue:client:notify", chaser, "Le match a été annulé : adversaire déconnecté.")
        return
    end
    if not isPlayerConnected(chaser) then
        TriggerClientEvent("tougue:client:notify", lead, "Le match a été annulé : adversaire déconnecté.")
        return
    end

    print("Création match entre " .. playersInMatch[1].name .. " et " .. playersInMatch[2].name)

    -- Appel de ta fonction qui crée le match, choisit la track et le véhicule, envoie prepareRound et stocke matches[matchId]
    local matchId = createMatchWithRandomTrack(playersInMatch)
    if not matchId then
        print("Erreur lors de la création du match (createMatchWithRandomTrack).")
        for _, p in ipairs(playersInMatch) do
            if isPlayerConnected(p.id) then
                TriggerClientEvent("tougue:client:notify", p.id, "Erreur interne : impossible de créer le match.")
            end
        end
        return
    end

    -- Récupère le match (qui a été stocké par createMatchWithRandomTrack)
    local match = matches[matchId]
    if not match then
        print("matchCreated: match non trouvé après createMatchWithRandomTrack (matchId=" .. tostring(matchId) .. ")")
        return
    end

    -- Attente active des ready avec timeout (même logique que précédemment)
    local startWait = GetGameTimer()
    local allReady = false
    while (GetGameTimer() - startWait) < matchTimeoutReady do
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
        -- timeout : annulation
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

    -- Tous prêts → lance le countdown pour chaque joueur
    for _, sid in ipairs(match.players) do
        TriggerClientEvent("tougue:client:startCountdown", sid, 3) -- countdown 3 secondes
        TriggerClientEvent("tougue:client:startRaceTimer", sid, match.timeout or 100000) -- start
    end

    print("match " .. match.id .. " démarré (countdown envoyé).")
    -- match reste stocké dans matches[matchId] pour la suite (checkpoints / rounds / scoring)
end)

-- Un joueur indique qu'il est prêt (après avoir chargé la track et le véhicule)
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

RegisterNetEvent("tougue:server:checkpointPassed")
AddEventHandler("tougue:server:checkpointPassed", function(matchId, checkpointIndex, clientPos, clientTs)
    local src = source
    if not matchId or not checkpointIndex or not clientPos then
        print("checkpointPassed: mauvaise requete de " .. tostring(src))
        return
    end

    local match = matches[matchId]
    if not match then
        print("checkpointPassed: match introuvable (" .. tostring(matchId) .. ") from " .. tostring(src))
        return
    end

    -- vérifier participant
    local isParticipant = false
    for _, sid in ipairs(match.players) do
        if sid == src then isParticipant = true; break end
    end
    if not isParticipant then
        print("checkpointPassed: joueur " .. tostring(src) .. " n'est pas participant du match " .. tostring(matchId))
        return
    end

    -- vérifie l'ordre attendu
    local expectedIndex = match.currentCheckpoint[src] or 1
    print("Checkpoint expecté = "..tostring(expectedIndex).."currentCheckpoint = "..tostring(checkpointIndex))
    if checkpointIndex ~= expectedIndex then
        print(("[SECURITE] %s essayé de valider checkpoint %d (attendu %d)"):format(tostring(src), checkpointIndex, expectedIndex))
        TriggerClientEvent("tougue:client:notify", src, "Checkpoint rejeté : ordre incorrect.")
        return
    end

    -- récupérer checkpoint serveur
    local cp = match.track.checkpoints[checkpointIndex]
    if not cp then
        print("checkpointPassed: checkpoint introuvable index=" .. tostring(checkpointIndex))
        return
    end

    -- vérifier la distance serveur < radius + margin
    local dx = clientPos.x - cp.pos.x
    local dy = clientPos.y - cp.pos.y
    local dz = (clientPos.z or 0) - cp.pos.z
    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    if dist > (cp.radius + CHECKPOINT_MARGIN) then
        print(("SECURITE: joueur %d trop loin du checkpoint (dist=%.2f, allowed=%.2f)"):format(src, dist, cp.radius + CHECKPOINT_MARGIN))
        TriggerClientEvent("tougue:client:notify", src, "Checkpoint rejeté : position invalide.")
        return
    end

    -- anti-spam / anti-teleport (min time)
    local lastTime = match.lastCheckpointTime and match.lastCheckpointTime[src] or 0
    if clientTs and (clientTs - lastTime) < MIN_TIME_BETWEEN_CHECKPOINTS then
        print(("SECURITE: joueur %d validate checkpoint trop vite (delta=%dms)"):format(src, (clientTs - lastTime)))
        TriggerClientEvent("tougue:client:notify", src, "Checkpoint rejeté : trop rapide.")
        return
    end

    -- Tout OK -> valider
    match.currentCheckpoint[src] = (match.currentCheckpoint[src] or 1) + 1
    match.lastCheckpointTime = match.lastCheckpointTime or {}
    match.lastCheckpointTime[src] = clientTs or GetGameTimer()

    print(("Match %s: joueur %d validé checkpoint %d (next=%d)"):format(matchId, src, checkpointIndex, match.currentCheckpoint[src]))

    -- notifier client
    TriggerClientEvent("tougue:client:checkpointValidated", src, matchId, checkpointIndex)

    -- si c'était le dernier checkpoint -> round finished pour ce joueur
    local totalCp = #match.track.checkpoints
    if checkpointIndex >= totalCp then
        print(("Match %s: joueur %d a terminé la course !"):format(matchId, src))
        -- update scores
        match.scores[src] = (match.scores[src] or 0) + 1
        -- notifier tous les joueurs du round end
        for _, sid in ipairs(match.players) do
            TriggerClientEvent("tougue:client:roundEnd", sid, matchId, { winner = src, scores = match.scores })
        end

        if match.round < match.maxRounds then
    -- Relancer un round avec inversion des rôles
        startNextRound(match)
        else
    -- Fin du match, calcul du vainqueur
            local scoreLead = match.scores[match.players[1]] or 0
            local scoreChaser = match.scores[match.players[2]] or 0
            local winner
            if scoreLead > scoreChaser then
                winner = match.players[1]
            elseif scoreChaser > scoreLead then
                winner = match.players[2]
            else
                winner = nil -- égalité
            end
            for _, sid in ipairs(match.players) do
                TriggerClientEvent("tougue:client:matchEnd", sid, match.id, { scores = match.scores, winner = winner })
            end
            matches[match.id] = nil -- cleanup
        end
        -- gestion round/next steps (reset, swap roles, etc.) à implémenter ici
        -- pour le moment on fait cleanup simplifié
        -- matches[matchId] = nil -- si tu veux nettoyer tout de suite
    end
end)

RegisterNetEvent("tougue:server:raceTimeout")
AddEventHandler("tougue:server:raceTimeout", function(matchId)
    local src = source
    print(("raceTimeout reçu de %s pour matchId=%s"):format(tostring(src), tostring(matchId)))

    if not matchId then
        print("raceTimeout: aucun matchId fourni, ignore.")
        return
    end

    local match = matches[matchId]
    if not match then
        print("raceTimeout: match introuvable pour matchId=" .. tostring(matchId))
        return
    end

    -- Vérifier que src est participant
    local isParticipant = false
    for _, sid in ipairs(match.players) do
        if sid == src then isParticipant = true; break end
    end
    if not isParticipant then
        print("raceTimeout: joueur " .. tostring(src) .. " n'est pas participant du match " .. tostring(matchId))
        return
    end

    -- Donne la victoire à l'autre joueur si possible
    local other = nil
    for _, sid in ipairs(match.players) do
        if sid ~= src then other = sid; break end
    end

    if other and isPlayerConnected(other) then
        match.scores[other] = (match.scores[other] or 0) + 1
        for _, sid in ipairs(match.players) do
            TriggerClientEvent("tougue:client:roundEnd", sid, matchId, { winner = other, reason = "timeout", scores = match.scores })
        end
        print(("Match %s: timeout - joueur %d remporte la manche (opposant %d a expiré)"):format(matchId, other, src))
    else
        -- pas d'adversaire valide -> annule
        for _, sid in ipairs(match.players) do
            if isPlayerConnected(sid) then
                TriggerClientEvent("tougue:client:notify", sid, "Match annulé (timeout, adversaire absent).")
            end
        end
        print(("Match %s: timeout - annulation (opposant introuvable)"):format(matchId))
    end

    -- Cleanup du match
    matches[matchId] = nil
end)

RegisterNetEvent("tougue:server:raceFinished")
AddEventHandler("tougue:server:raceFinished", function(matchId)
    local src = source
    print(("raceFinished reçu de %s pour matchId=%s"):format(tostring(src), tostring(matchId)))
    if not matchId then return end
    local match = matches[matchId]
    if not match then return end

    -- si tu veux traiter fin de course venant du client, fais la validation serveur ici
    -- pour l'instant on considère que le client envoie raceFinished quand il a terminé.
    match.scores[src] = (match.scores[src] or 0) + 1
    for _, sid in ipairs(match.players) do
        print(("Notifying player %d of round end, winner is %d"):format(sid, src))
        TriggerClientEvent("tougue:client:roundEnd", sid, matchId, { winner = src, reason = "client_finish", scores = match.scores })
    end
    matches[matchId] = nil -- cleanup
end)