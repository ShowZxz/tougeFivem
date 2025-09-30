-- server.lua (version complète — match manager, rounds, checkpoints, timeout)
-- Remplace ton server.lua par ce fichier

-- Charger les tracks (fichier server/tracks.lua attendu)
local tracks = assert(load(LoadResourceFile(GetCurrentResourceName(), "server/tracks.lua")))()

-- Config
local queue = {}
local maxPlayers = 2
local matchTimeoutReady = 8000 -- ms pour attendre les ready
local matches = {}             -- table des matchs actifs, indexée par matchId

-- Validation params
local CHECKPOINT_MARGIN = 1.5        -- tolérance en mètres
local MIN_TIME_BETWEEN_CHECKPOINTS = 800 -- ms

-- Helpers ---------------------------------------------------------
local function isPlayerConnected(serverId)
    if not serverId then return false end
    local name = GetPlayerName(serverId)
    return name ~= nil and name ~= ""
end

local function chooseRandom(list)
    if not list or #list == 0 then return nil end
    return list[math.random(#list)]
end

-- Initialise seed random
math.randomseed(os.time())
math.random(); math.random(); math.random()

-- Create match with random track & vehicle ------------------------
local function createMatchWithRandomTrack(playersInMatch)
    local track = chooseRandom(tracks)
    if not track then
        print("[tougue] createMatch: aucune track disponible")
        return nil
    end

    local allowed = track.meta and track.meta.allowedVehicles or {}
    local chosenVehicle = nil
    if allowed and #allowed > 0 then
        chosenVehicle = chooseRandom(allowed)
    else
        chosenVehicle = "adder"
    end

    -- Shuffle players to randomize roles
    for i = #playersInMatch, 2, -1 do
        local j = math.random(i)
        playersInMatch[i], playersInMatch[j] = playersInMatch[j], playersInMatch[i]
    end

    local lead = playersInMatch[1].id
    local chaser = playersInMatch[2].id

    local matchId = tostring(os.time()) .. "_" .. tostring(lead)

    local match = {
        id = matchId,
        trackId = track.id,
        track = track,
        players = { lead, chaser },
        ready = {},                 -- ready flags per player
        currentCheckpoint = {},     -- per player idx
        scores = {},                -- per player score
        lastCheckpointTime = {},    -- per player last cp timestamp
        createdAt = GetGameTimer(),
        timeout = track.meta and track.meta.timeLimit or 0,
        round = 1,
        maxRounds = track.meta and (track.meta.maxRounds or 2) or 2,
        roles = { [lead] = "lead", [chaser] = "chaser" },
        chosenVehicle = chosenVehicle
    }

    for _, sid in ipairs(match.players) do
        match.ready[sid] = false
        match.scores[sid] = 0
        match.currentCheckpoint[sid] = 1
        match.lastCheckpointTime[sid] = 0
    end

    matches[matchId] = match

    local leadCoords = track.start
    local chaserCoords = { x = track.start.x + 2.0, y = track.start.y + 2.0, z = track.start.z, heading = track.start.heading }

    -- Send prepareRound with full track data to clients
    TriggerClientEvent("tougue:client:prepareRound", lead, matchId, "lead", chosenVehicle, leadCoords, track)
    TriggerClientEvent("tougue:client:prepareRound", chaser, matchId, "chaser", chosenVehicle, chaserCoords, track)

    print(("[tougue] Match %s créé sur la track %s avec véhicule %s"):format(matchId, track.id, tostring(chosenVehicle)))
    return matchId
end

-- Start next round (swap roles) ---------------------------------
function startNextRound(match)
    if not match then return end

    -- Inverse ordre des players (lead <-> chaser)
    local oldP1, oldP2 = match.players[1], match.players[2]
    match.players = { oldP2, oldP1 }

    -- Update roles table
    local p1, p2 = match.players[1], match.players[2]
    match.roles = { [p1] = "lead", [p2] = "chaser" }

    -- Reset checkpoints / ready / lastCheckpointTime
    match.currentCheckpoint = {}
    match.lastCheckpointTime = {}
    match.ready = {}
    for _, sid in ipairs(match.players) do
        match.currentCheckpoint[sid] = 1
        match.lastCheckpointTime[sid] = 0
        match.ready[sid] = false
    end

    match.round = match.round + 1

    local leadCoords = match.track.start
    local chaserCoords = { x = match.track.start.x + 2.0, y = match.track.start.y + 2.0, z = match.track.start.z, heading = match.track.start.heading }
    local model = match.chosenVehicle or "adder"

    -- Re-prepare clients for the new round
    TriggerClientEvent("tougue:client:prepareRound", match.players[1], match.id, "lead", model, leadCoords, match.track)
    TriggerClientEvent("tougue:client:prepareRound", match.players[2], match.id, "chaser", model, chaserCoords, match.track)

    -- Wait for playerReady (same pattern as initial match creation)
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
        for _, sid in ipairs(match.players) do
            if isPlayerConnected(sid) then
                TriggerClientEvent("tougue:client:notify", sid, "Round annulé : un joueur n'a pas chargé à temps.")
            end
        end
        print(("[tougue] match %s : timeout ready au startNextRound, annulation."):format(match.id))
        matches[match.id] = nil
        return
    end

    -- Start countdown and race timer on clients
    for _, sid in ipairs(match.players) do
        TriggerClientEvent("tougue:client:startCountdown", sid, 3)
        TriggerClientEvent("tougue:client:startRaceTimer", sid, match.timeout or 100000)
    end

    print(("[tougue] match %s : round %d démarré."):format(match.id, match.round))
end

-- Queue handling & match creation --------------------------------
RegisterNetEvent("tougue:server:joinQueue")
AddEventHandler("tougue:server:joinQueue", function(playerName)
    local src = source
    if not src then return end

    for _, p in ipairs(queue) do
        if p.id == src then
            TriggerClientEvent("tougue:client:notify", src, "Vous êtes déjà dans la file d'attente.")
            return
        end
    end

    table.insert(queue, { name = playerName, id = src })
    print(("[tougue] %s a rejoint la file d'attente. (ServerID: %d)"):format(tostring(playerName), src))
    TriggerClientEvent("tougue:client:notify", src, "Vous avez rejoint la queue, en attente d'autres joueurs...")

    if #queue >= maxPlayers then
        local playersInMatch = {}
        for i = 1, maxPlayers do
            table.insert(playersInMatch, queue[i])
        end
        for i = 1, maxPlayers do table.remove(queue, 1) end

        for _, player in ipairs(playersInMatch) do
            TriggerClientEvent("tougue:client:notify", player.id, "Début du jeu ! Préparez-vous...")
        end

        -- crée le match (émet prepareRound)
        TriggerEvent("tougue:server:matchCreated", playersInMatch)
    end
end)

-- Match creation handler -----------------------------------------
RegisterNetEvent("tougue:server:matchCreated")
AddEventHandler("tougue:server:matchCreated", function(playersInMatch)
    if not playersInMatch or #playersInMatch < 2 then
        print("[tougue] matchCreated: joueurs insuffisants.")
        return
    end

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

    print(("[tougue] Création match entre %s et %s"):format(tostring(playersInMatch[1].name), tostring(playersInMatch[2].name)))

    local matchId = createMatchWithRandomTrack(playersInMatch)
    if not matchId then
        for _, p in ipairs(playersInMatch) do
            if isPlayerConnected(p.id) then
                TriggerClientEvent("tougue:client:notify", p.id, "Erreur interne : impossible de créer le match.")
            end
        end
        return
    end

    local match = matches[matchId]
    if not match then
        print(("[tougue] matchCreated: match non trouvé après createMatchWithRandomTrack (matchId=%s)"):format(tostring(matchId)))
        return
    end

    -- Attendre les ready (client enverra tougue:server:playerReady(matchId))
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
        for _, sid in ipairs(match.players) do
            if isPlayerConnected(sid) then
                TriggerClientEvent("tougue:client:notify", sid, "Match annulé : un joueur n'a pas chargé à temps.")
            end
        end
        print(("[tougue] match %s annulé (timeout ready)."):format(matchId))
        matches[matchId] = nil
        return
    end

    -- Tous prêts -> start countdown + race timer
    for _, sid in ipairs(match.players) do
        TriggerClientEvent("tougue:client:startCountdown", sid, 3)
        TriggerClientEvent("tougue:client:startRaceTimer", sid, match.timeout or 100000)
    end

    print(("[tougue] match %s démarré (countdown envoyé)."):format(matchId))
end)

-- PlayerReady handler --------------------------------------------
RegisterNetEvent("tougue:server:playerReady")
AddEventHandler("tougue:server:playerReady", function(matchId)
    local src = source
    if not matchId then
        print(("[tougue] playerReady reçu sans matchId de %s"):format(tostring(src)))
        return
    end
    local match = matches[matchId]
    if not match then
        print(("[tougue] playerReady: match introuvable (%s) de %s"):format(tostring(matchId), tostring(src)))
        return
    end

    local isParticipant = false
    for _, sid in ipairs(match.players) do
        if sid == src then isParticipant = true; break end
    end
    if not isParticipant then
        print(("[tougue] playerReady: %s n'est pas participant du match %s"):format(tostring(src), tostring(matchId)))
        return
    end

    match.ready[src] = true
    -- ack client
    TriggerClientEvent("tougue:client:notify", src, "Prêt confirmé par le serveur.")
end)

-- Checkpoint validation ------------------------------------------
RegisterNetEvent("tougue:server:checkpointPassed")
AddEventHandler("tougue:server:checkpointPassed", function(matchId, checkpointIndex, clientPos, clientTs)
    local src = source
    if not matchId or not checkpointIndex or not clientPos then
        print(("[tougue] checkpointPassed: mauvaise requete de %s"):format(tostring(src)))
        return
    end

    local match = matches[matchId]
    if not match then
        print(("[tougue] checkpointPassed: match introuvable (%s) from %s"):format(tostring(matchId), tostring(src)))
        return
    end

    -- verify participant
    local isParticipant = false
    for _, sid in ipairs(match.players) do
        if sid == src then isParticipant = true; break end
    end
    if not isParticipant then
        TriggerClientEvent("tougue:client:notify", src, "Vous n'êtes pas participant de ce match.")
        return
    end

    -- expected index
    local expectedIndex = match.currentCheckpoint[src] or 1
    if checkpointIndex ~= expectedIndex then
        TriggerClientEvent("tougue:client:notify", src, ("Checkpoint rejeté : ordre incorrect (attendu %d)").format(expectedIndex))
        return
    end

    -- server-side check: distance
    local cp = match.track.checkpoints[checkpointIndex]
    if not cp then
        print(("[tougue] checkpointPassed: checkpoint introuvable index=%s"):format(tostring(checkpointIndex)))
        return
    end

    local dx = clientPos.x - cp.pos.x
    local dy = clientPos.y - cp.pos.y
    local dz = (clientPos.z or 0) - cp.pos.z
    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    if dist > (cp.radius + CHECKPOINT_MARGIN) then
        TriggerClientEvent("tougue:client:notify", src, "Checkpoint rejeté : position invalide.")
        return
    end

    -- anti-spam / anti-teleport
    local lastTime = match.lastCheckpointTime[src] or 0
    if clientTs and (clientTs - lastTime) < MIN_TIME_BETWEEN_CHECKPOINTS then
        TriggerClientEvent("tougue:client:notify", src, "Checkpoint rejeté : trop rapide.")
        return
    end

    -- VALID -> update server state
    match.currentCheckpoint[src] = (match.currentCheckpoint[src] or 1) + 1
    match.lastCheckpointTime[src] = clientTs or GetGameTimer()

    print(("[tougue] Match %s: joueur %d validé checkpoint %d (next=%d)"):format(matchId, src, checkpointIndex, match.currentCheckpoint[src]))

    -- notify client (server confirmation)
    TriggerClientEvent("tougue:client:checkpointValidated", src, matchId, checkpointIndex)

    -- if last checkpoint -> round finished for that player
    local totalCp = #match.track.checkpoints
    if checkpointIndex >= totalCp then
        match.scores[src] = (match.scores[src] or 0) + 1

        -- notify all players round end
        for _, sid in ipairs(match.players) do
            TriggerClientEvent("tougue:client:roundEnd", sid, matchId, { winner = src, scores = match.scores })
        end

        -- decide next: another round or match end
        if match.round < match.maxRounds then
            -- small delay to allow clients to see roundEnd & cleanup
            Citizen.CreateThread(function()
                Wait(2500)
                startNextRound(match)
            end)
        else
            -- match finished: compute winner
            local p1, p2 = match.players[1], match.players[2]
            local s1 = match.scores[p1] or 0
            local s2 = match.scores[p2] or 0
            local winner = nil
            if s1 > s2 then winner = p1
            elseif s2 > s1 then winner = p2
            else winner = nil -- tie
            end

            for _, sid in ipairs(match.players) do
                TriggerClientEvent("tougue:client:matchEnd", sid, matchId, { scores = match.scores, winner = winner })
            end

            -- cleanup match after short delay
            Citizen.CreateThread(function()
                Wait(3000)
                matches[matchId] = nil
                print(("[tougue] match %s cleaned up (finished)."):format(matchId))
            end)
        end
    end
end)

-- Race timeout handler -------------------------------------------
RegisterNetEvent("tougue:server:raceTimeout")
AddEventHandler("tougue:server:raceTimeout", function(matchId)
    local src = source
    if not matchId then
        print(("[tougue] raceTimeout: aucun matchId fourni de %s"):format(tostring(src)))
        return
    end

    local match = matches[matchId]
    if not match then
        print(("[tougue] raceTimeout: match introuvable %s"):format(tostring(matchId)))
        return
    end

    -- check participant
    local isParticipant = false
    for _, sid in ipairs(match.players) do
        if sid == src then isParticipant = true; break end
    end
    if not isParticipant then
        print(("[tougue] raceTimeout: %s n'est pas participant du match %s"):format(tostring(src), tostring(matchId)))
        return
    end

    -- give win to other if present
    local other = nil
    for _, sid in ipairs(match.players) do
        if sid ~= src then other = sid; break end
    end

    if other and isPlayerConnected(other) then
        match.scores[other] = (match.scores[other] or 0) + 1
        for _, sid in ipairs(match.players) do
            TriggerClientEvent("tougue:client:roundEnd", sid, matchId, { winner = other, reason = "timeout", scores = match.scores })
        end
        print(("[tougue] Match %s: timeout - joueur %d remporte la manche (opposant %d a expiré)"):format(matchId, other, src))
    else
        for _, sid in ipairs(match.players) do
            if isPlayerConnected(sid) then
                TriggerClientEvent("tougue:client:notify", sid, "Match annulé (timeout, adversaire absent).")
            end
        end
        print(("[tougue] Match %s: timeout - annulation (opposant introuvable)"):format(matchId))
    end

    matches[matchId] = nil
end)

-- Optional: client-reported race finished (fallback) -------------
RegisterNetEvent("tougue:server:raceFinished")
AddEventHandler("tougue:server:raceFinished", function(matchId)
    local src = source
    if not matchId then return end
    local match = matches[matchId]
    if not match then return end

    match.scores[src] = (match.scores[src] or 0) + 1
    for _, sid in ipairs(match.players) do
        TriggerClientEvent("tougue:client:roundEnd", sid, matchId, { winner = src, reason = "client_finish", scores = match.scores })
    end
    matches[matchId] = nil
end)

-- End of server.lua
