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
local POS_INTERVAL_MIN = 250         -- ms : ignore updates plus rapides
local MAX_SPEED_THRESHOLD = 120      -- m/s (valeur conservatrice pour détecter teleport)
local MAX_DIST = 200                 -- mètres -> escape threshold distance
local ESCAPE_THRESHOLD = 6000        -- ms -> si distance > MAX_DIST pendant cette durée -> lead gagne
local CATCH_DIST = 2                 -- m -> si chaser à moins de CATCH_DIST -> chaser gagne
local CATCH_HOLD = 400               -- ms -> (optionnel) ms à rester proche pour valider catch
local USE_HORIZONTAL_ONLY = true   -- true = ignore dz dans la distance (utile pour ponts/hauteur)
local POS_RECENT_THRESHOLD = 3000  -- ms : qu'on juge une pos "récente"
local OVERTAKE_DISTANCE = 2.0   -- mètres devant pour considérer "en avant"
local OVERTAKE_HOLD = 5000      -- ms que le chaser doit rester devant pour valider l'overtake


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
    -- Utilise le heading pour reculer de 2 mètres derrière le lead
    local offset = -8.0
    local rad = math.rad(track.start.heading or 0)
    local chaserCoords = {
        x = track.start.x - math.sin(rad) * offset,
        y = track.start.y + math.cos(rad) * offset,
        z = track.start.z,
        heading = track.start.heading
    }

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
    local offset = -8.0
    local rad = math.rad(match.track.start.heading or 0)
    local chaserCoords = {
        x = match.track.start.x - math.sin(rad) * offset,
        y = match.track.start.y + math.cos(rad) * offset,
        z = match.track.start.z,
        heading = match.track.start.heading
    }
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

local function handleRoundWin(match, winnerSid, reason)
    if not match or not winnerSid then return end
    -- update score
    match.scores[winnerSid] = (match.scores[winnerSid] or 0) + 1

    -- notify all players round end
    for _, sid in ipairs(match.players) do
        TriggerClientEvent("tougue:client:roundEnd", sid, match.id, { winner = winnerSid, reason = reason, scores = match.scores })
    end

    -- decide next: next round or match end (reuse existing logic)
    if match.round < match.maxRounds then
        -- start next round after small delay to let clients see roundEnd
        Citizen.CreateThread(function()
            Wait(2500)
            startNextRound(match)
        end)
    else
        -- compute final winner
        local p1, p2 = match.players[1], match.players[2]
        local s1 = match.scores[p1] or 0
        local s2 = match.scores[p2] or 0
        local finalWinner = nil
        if s1 > s2 then finalWinner = p1
        elseif s2 > s1 then finalWinner = p2
        end
        for _, sid in ipairs(match.players) do
            TriggerClientEvent("tougue:client:matchEnd", sid, match.id, { scores = match.scores, winner = finalWinner })
        end
        -- cleanup
        Citizen.CreateThread(function()
            Wait(3000)
            matches[match.id] = nil
        end)
    end
end

local function vecLength(x,y,z)
    return math.sqrt((x*x) + (y*y) + ((z and z*z) or 0))
end

local function getForwardVecForPlayerOnTrack(match, sid)
    local track = match.track
    if not track then return nil end
    local cpIndex = match.currentCheckpoint[sid] or 1

    local prevPos = nil
    if cpIndex > 1 and track.checkpoints[cpIndex-1] then
        prevPos = track.checkpoints[cpIndex-1].pos
    else
        prevPos = track.start
    end

    local nextPos = track.checkpoints[cpIndex] and track.checkpoints[cpIndex].pos
    if not prevPos or not nextPos then
        if track.checkpoints[1] and track.start then
            prevPos = track.start
            nextPos = track.checkpoints[1].pos
        else
            return nil
        end
    end

    local fx = nextPos.x - prevPos.x
    local fy = nextPos.y - prevPos.y
    local fz = (nextPos.z or 0) - (prevPos.z or 0)
    local mag = vecLength(fx, fy, fz)
    if mag == 0 then return nil end
    return fx/mag, fy/mag, fz/mag
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

RegisterNetEvent("tougue:server:posUpdate")
AddEventHandler("tougue:server:posUpdate", function(matchId, clientPos, clientTs)
    local src = source
    if not matchId or not clientPos then return end

    local match = matches[matchId]
    if not match then return end

    -- verifier participant
    local isParticipant = false
    for _, sid in ipairs(match.players) do
        if sid == src then isParticipant = true; break end
    end
    if not isParticipant then return end

    -- rate-limit server-side
    match._lastPosUpdate = match._lastPosUpdate or {}
    local last = match._lastPosUpdate[src] or 0
    local now = GetGameTimer()
    if (now - last) < POS_INTERVAL_MIN then
        return
    end
    match._lastPosUpdate[src] = now

    -- anti-teleport (vitesse impossible) : on compare avec la dernière pos stockée
    match.lastPos = match.lastPos or {}
    local prev = match.lastPos[src]
    local prevServerTs = prev and prev.serverTs or nil
    local dt_ms = 0
    if prevServerTs then
        dt_ms = now - prevServerTs
    elseif prev and prev.ts and clientTs and clientTs > prev.ts then
        dt_ms = clientTs - prev.ts
    else
        dt_ms = 0
    end

    if prev and dt_ms > 0 then
        local dx = clientPos.x - prev.pos.x
        local dy = clientPos.y - prev.pos.y
        local dz = (clientPos.z or 0) - (prev.pos.z or 0)
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
        local dt = math.max(1, dt_ms) / 1000.0
        local speed = dist / dt
        if speed > MAX_SPEED_THRESHOLD then
            print(("[tougue] [ANTI-CHEAT] ignore posUpdate %d : speed=%.1f m/s dist=%.1f dt=%dms"):format(src, speed, dist, dt_ms))
            match._antiCheatCount = match._antiCheatCount or {}
            match._antiCheatCount[src] = (match._antiCheatCount[src] or 0) + 1
            return
        end
    end

    -- stocker la pos (avec serverTs)
    match.lastPos[src] = { pos = clientPos, ts = clientTs or now, serverTs = now }

    -- récupérer other joueur
    local otherSid = nil
    for _, sid in ipairs(match.players) do
        if sid ~= src then otherSid = sid; break end
    end
    if not otherSid then return end

    local other = match.lastPos[otherSid]
    if not other then
        print(("[tougue] posUpdate: otherSid=%s other=nil (first pos) src=%d"):format(tostring(otherSid), src))
        return
    end

    -- récence via serverTs (plus fiable)
    if (now - (other.serverTs or other.ts or 0)) > POS_RECENT_THRESHOLD then
        print(("[tougue] posUpdate: other pos trop ancienne (age=%dms) src=%d other=%d"):format(now - (other.serverTs or other.ts or 0), src, otherSid))
        return
    end

    -- calcul distance (horizontale si souhaité)
    local a = match.lastPos[match.players[1]].pos
    local b = match.lastPos[match.players[2]].pos
    if not a or not b then return end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    local dist = 0
    if USE_HORIZONTAL_ONLY then
        dist = math.sqrt(dx*dx + dy*dy)
    else
        dist = math.sqrt(dx*dx + dy*dy + dz*dz)
    end

    -- DEBUG (supprime ou commente pour prod)
    print(("[tougue] posUpdate: match=%s src=%d other=%d dist=%.2f (dx=%.2f dy=%.2f dz=%.2f)"):format(tostring(matchId), src, otherSid, dist, dx, dy, dz))

    -- déterminer lead / chaser
    local leadSid, chaserSid
    for sid, role in pairs(match.roles) do
        if role == "lead" then leadSid = sid end
        if role == "chaser" then chaserSid = sid end
    end
    if not leadSid or not chaserSid then return end

    -- -------- OVERTAKE : si chaser devant le long de l'axe et tient la position --------
    local forwardFx, forwardFy, forwardFz = getForwardVecForPlayerOnTrack(match, leadSid)
    if forwardFx and forwardFy then
        local lp = match.lastPos[leadSid].pos
        local cp = match.lastPos[chaserSid].pos
        local vx = cp.x - lp.x
        local vy = cp.y - lp.y
        local vz = (cp.z or 0) - (lp.z or 0)
        local proj = vx * forwardFx + vy * forwardFy + vz * (forwardFz or 0)
        -- debug
        -- print(("overtake proj=%.2f"):format(proj))
        if proj >= OVERTAKE_DISTANCE then
            match._overtakeStart = match._overtakeStart or {}
            if not match._overtakeStart[chaserSid] then
                match._overtakeStart[chaserSid] = now
            elseif (now - match._overtakeStart[chaserSid]) >= OVERTAKE_HOLD then
                print(("[tougue] Match %s: chaser %d overtook lead %d (proj=%.2f)"):format(matchId, chaserSid, leadSid, proj))
                handleRoundWin(match, chaserSid, "overtake")
                return
            end
        else
            if match._overtakeStart then match._overtakeStart[chaserSid] = nil end
        end
    end

    -- -------- CATCH : si chaser très proche (collision) --------
    if dist <= CATCH_DIST then
        match._catchStart = match._catchStart or {}
        if not match._catchStart[chaserSid] then
            match._catchStart[chaserSid] = now
        elseif (now - match._catchStart[chaserSid]) >= CATCH_HOLD then
            print(("[tougue] Match %s: chaser %d caught lead %d (dist=%.2f)"):format(matchId, chaserSid, leadSid, dist))
            handleRoundWin(match, chaserSid, "catch")
            return
        end
    else
        if match._catchStart then match._catchStart[chaserSid] = nil end
    end

    -- -------- ESCAPE : si lead trop loin pendant assez longtemps --------
    match._escapeStart = match._escapeStart or {}
    if dist > MAX_DIST then
        if not match._escapeStart[leadSid] then
            match._escapeStart[leadSid] = now
        elseif (now - match._escapeStart[leadSid]) >= ESCAPE_THRESHOLD then
            print(("[tougue] Match %s: lead %d escaped from chaser %d (dist=%.2f)"):format(matchId, leadSid, chaserSid, dist))
            handleRoundWin(match, leadSid, "escape")
            return
        end
    else
        if match._escapeStart then match._escapeStart[leadSid] = nil end
    end

    -- rien de décisif pour le moment
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
