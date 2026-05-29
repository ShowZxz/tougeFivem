local players = {}
local tempPlayers = {}
local playerWords = {}
local words = {}
local banWords = {}
local guessedPlayers = {}
local playerCustomWords = {}
local coordsLobby = vector3(689.21887207031, 578.84558105469, 130.46127319336) -- remplacer par les coordonnées de l'emplacement où les joueurs peuvent rejoindre le jeu
local coordsArea = vector3(683.53985595703, 581.43017578125, 130.46133422852)  -- remplacer par les coordonnées spécifiques pour téléporter les joueurs lorsque le jeu commence
local coordsInitialposition = vector3(669.63983154297, 564.30389404297, 129.0463104248) -- remplacer par les coordonnées de l'emplacement où les joueurs sont téléportés lorsqu'ils quittent le jeu ou lorsque le jeu se termine

local gameState = "waiting" -- "waiting", "playing"



CreateThread(function()
    local file = LoadResourceFile(GetCurrentResourceName(), "words.json")
    words = json.decode(file)
end)

CreateThread(function()
    local file = LoadResourceFile(GetCurrentResourceName(), "banWords.json")
    banWords = json.decode(file)
end)

local function getCirclePositions(playerList, center, radius)
    local positions = {}
    local count = #playerList
    local angleStep = (2 * math.pi) / count

    for i, id in ipairs(playerList) do
        local angle = (i - 1) * angleStep

        local x = center.x + math.cos(angle) * radius
        local y = center.y + math.sin(angle) * radius
        local z = center.z

        positions[id] = vector3(x, y, z)
    end

    return positions
end

function endGame()
    for id, _ in pairs(players) do
        TriggerClientEvent("whoiam:addMessage", id, "La partie est terminée.")
        TriggerClientEvent("whoiam:teleportPlayers", id, coordsInitialposition) -- téléporte les joueurs à leur position hors du jeu
        TriggerClientEvent("whoiam:resetPlayer", id)
        TriggerClientEvent("whoiam:resetAllUI", id)
    end

    gameState = "waiting"
    playerWords = {}
    guessedPlayers = {}
    players = {}
    playerCustomWords = {}
end

function checkEndGame()
    local remainingPlayers = 0
    local guessedCount = 0

    for id, _ in pairs(players) do
        remainingPlayers = remainingPlayers + 1
        if guessedPlayers[id] then
            guessedCount = guessedCount + 1
        end
    end

    print("DEBUG : remaining:", remainingPlayers, "guessed:", guessedCount)

    if remainingPlayers == 2 and guessedCount >= 1 then
        endGame()
        return
    end

    if guessedCount >= remainingPlayers and remainingPlayers > 0 then
        endGame()
        return
    end

    if remainingPlayers <= 1 then
        endGame()
        return
    end
end

local function updateQueueForEveryone()

    local count = 0

    for _, _ in pairs(players) do
        count = count + 1
    end

    for id, _ in pairs(players) do
        TriggerClientEvent("whoiam:updateQueue", id, count)
    end

end

--Plus utile maintenant que les joueurs peuvent rejoindre la queue via le point de start
RegisterCommand("whoiam_join", function(source)
    if gameState == "playing" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Il y a déjà une partie en cours.")
        return
    end

    if players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Vous avez déjà rejoint le jeu.")
        return
    end

    -- vérifier le nombre maximum de joueurs
    local playerCount = 0

    for id, _ in pairs(players) do
        playerCount = playerCount + 1
    end

    if playerCount >= Config.MaxPlayers then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Le jeu est complet.")
        return
    end


    players[source] = true

    print("Player joined game: " .. GetPlayerName(source))

    for id, _ in ipairs(players) do
        TriggerClientEvent("whoiam:addMessage", id, GetPlayerName(source) .. " a rejoint le jeu.")
    end
end)

-- Plus utile maintenant que les joueurs peuvent quitter le jeu via le point de sortie
RegisterCommand("whoiam_leave", function(source)
    if not players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Vous n'avez pas rejoint de jeu pour quitter.")
        return
    end

    if gameState == "waiting" then
        players[source] = nil
        playerWords[source] = nil
        TriggerClientEvent("whoiam:addMessage", source, " Tu as quitté le jeu.")
        TriggerClientEvent("whoiam:teleportPlayers", source, coordsLobby) -- téléporte le joueur à l'emplacement de la queue
        TriggerClientEvent("whoiam:resetPlayer", source)                  -- réinitialise les variables du joueur côté client / A TEST

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:addMessage", id, GetPlayerName(source) .. " a quitté le jeu.")
        end
        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:addMessage", id, GetPlayerName(source) .. " a quitté le jeu.")
        end
    end

    if gameState == "playing" then
        local word = playerWords[source]
        players[source] = nil
        playerWords[source] = nil

        local message = GetPlayerName(source) .. " a quitté le jeu. Son mot était : " .. word
        print(message)
        TriggerClientEvent("whoiam:teleportPlayers", source, coordsLobby) -- téléporte le joueur à l'emplacement de la queue
        TriggerClientEvent("whoiam:resetPlayer", source)                  -- réinitialise les variables du joueur côté client / A TEST

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:addMessage", id, message)
            TriggerClientEvent("whoiam:removePlayer", id, source)
        end

        if guessedPlayers[source] then
            local guessMessage = GetPlayerName(source) .. " avait déjà deviné son mot : " .. word
            print(guessMessage)

            for id, _ in pairs(players) do
                TriggerClientEvent("whoiam:addMessage", id, guessMessage)
            end
        end

        local remainingPlayers = 0
        local guessedCount = 0

        for id, _ in pairs(players) do
            remainingPlayers = remainingPlayers + 1
            if guessedPlayers[id] then
                guessedCount = guessedCount + 1
            end
        end

        if remainingPlayers <= 2 or guessedCount >= remainingPlayers then
            endGame()
        end
    end
end)

-- plus utile maintenant que les joueurs peuvent écrire leur mot via le NUI
RegisterCommand("whoiam_word", function(source, args)
    if gameState == "playing" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "La partie a déjà commencé.")
        return
    end

    if not players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu dois rejoindre la queue.")
        return
    end

    local word = table.concat(args, " ")

    if word == "" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu dois écrire un mot.")
        return
    end

    if string.len(word) > 20 then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Mot trop long (20 max).")
        return
    end

    if string.len(word) < 3 then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Mot trop court (3 min).")
        return
    end

    for id, customWord in pairs(playerCustomWords) do
        if string.lower(customWord) == string.lower(word) then
            TriggerClientEvent("whoiam:addErrorMessage", source, "Ce mot est déjà utilisé par un autre joueur.")
            return
        end
    end

    for _, banWord in ipairs(banWords) do
        if string.lower(word) == string.lower(banWord) then
            TriggerClientEvent("whoiam:addErrorMessage", source, "Ce mot est interdit. Choisissez-en un autre.")
            return
        end
    end

    playerCustomWords[source] = word

    TriggerClientEvent("whoiam:addMessage", source, "Mot enregistré : " .. word)
end)

-- Plus utile maintenant les joueurs peuvent lancer la game via le point de start
RegisterCommand("whoiam_start", function(source)
    if gameState == "playing" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Une partie est déjà en cours.")
        return
    end

    if not players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu dois être dans la queue pour lancer la partie.")
        return
    end

    local playerList = {}
    for id, _ in pairs(players) do
        table.insert(playerList, id)
        table.insert(tempPlayers, id)
    end

    if #playerList < 2 then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Pas assez de joueurs.")
        return
    end

    for i = #playerList, 2, -1 do
        local j = math.random(i)
        playerList[i], playerList[j] = playerList[j], playerList[i]
    end

    local shuffledWords = {}
    for i = 1, #words do
        shuffledWords[i] = words[i]
    end

    for i = #shuffledWords, 2, -1 do
        local j = math.random(i)
        shuffledWords[i], shuffledWords[j] = shuffledWords[j], shuffledWords[i]
    end

    local neededRandomWords = 0
    for _, id in ipairs(playerList) do
        if not playerCustomWords[id] then
            neededRandomWords = neededRandomWords + 1
        end
    end

    if neededRandomWords > #shuffledWords then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Pas assez de mots pour compléter la partie.")
        return
    end

    local tempWords = {}
    local randomIndex = 1

    for _, id in ipairs(playerList) do
        if playerCustomWords[id] then
            tempWords[id] = playerCustomWords[id]
        else
            tempWords[id] = shuffledWords[randomIndex]
            randomIndex = randomIndex + 1
        end
    end

    for i, id in ipairs(playerList) do
        local nextIndex = i + 1
        if nextIndex > #playerList then nextIndex = 1 end

        local nextPlayer = playerList[nextIndex]
        playerWords[id] = tempWords[nextPlayer]
    end

    gameState = "playing"

    local positions = getCirclePositions(playerList, coordsArea, 3.0)

    for id, _ in pairs(players) do
        TriggerClientEvent("whoiam:startGame", id, playerWords)
        TriggerClientEvent("whoiam:teleportPlayers", id, positions[id])
    end
end)

-- Plus utile maintenant que les joueurs devine son mot via le NUI
RegisterCommand("whoiam", function(source, args)
    if guessedPlayers[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu as déjà deviné ton mot.")
        return
    end

    local guess = table.concat(args, " ")
    local word = playerWords[source]

    if not word then return end

    if string.lower(guess) == string.lower(word) then
        guessedPlayers[source] = true

        local message = GetPlayerName(source) .. " a deviné son mot : " .. word
        print(message)
        triggerClientEvent("whoiam:playAnimation", source, "valid")

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:addMessage", id, message)
        end

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:playerGuessed", id, source, word)
        end
        checkEndGame()
    else
        local message = GetPlayerName(source) .. " tu as fais un mauvais guess : " .. guess
        print(message)
        TriggerClientEvent("whoiam:addErrorMessage", source, message)
        TriggerClientEvent("whoiam:playAnimation", source, "invalid")
    end
end)

--Plus utile maintenant que les joueurs peuvent afficher via le NUI les règles du jeu, mais je laisse l'option d'une commande pour les afficher dans le chat
RegisterCommand("whoiam_rules", function(source)
    local rules = "Règles du jeu WhoIAm :\n" ..
        "1. Rejoins la queue pour participer.\n" ..
        "2. Lorsque le jeu commence, tu recevras un mot à deviner.\n" ..
        "3. Devine ton mot en utilisant la commande /whoiam suivi de ton guess.\n" ..
        "4. Si tu devines correctement, ton mot sera révélé aux autres joueurs.\n" ..
        "5. Si tu quittes la zone de jeu pendant la partie, tu seras disqualifié et ton mot sera révélé.\n" ..
        "6. Le jeu se termine lorsque tous les joueurs ont deviné leur mot ou s'il ne reste plus que 2 joueurs et que l'un d'eux a deviné son mot."

    TriggerClientEvent("whoiam:addMessage", source, rules)
end)

RegisterNetEvent("whoiam:join")
AddEventHandler("whoiam:join", function()
    print("Player requested to join queue: " .. GetPlayerName(source))

    if gameState == "playing" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Il y a déjà une partie en cours.")
        return
    end

    if players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Vous avez déjà rejoint le jeu.")
        return
    end

    -- vérifier le nombre maximum de joueurs
    local playerCount = 0

    for id, _ in pairs(players) do
        playerCount = playerCount + 1
    end

    if playerCount >= Config.MaxPlayers then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Le jeu est complet.")
        return
    end


    players[source] = true

    print("Player joined game: " .. GetPlayerName(source))

    TriggerClientEvent("whoiam:teleportPlayers", source, coordsLobby,true) -- téléporte le joueur à l'emplacement de la queue
    updateQueueForEveryone()
    TriggerClientEvent("whoiam:openWordUI", source)

    for id, _ in ipairs(players) do
        TriggerClientEvent("whoiam:addMessage", id, GetPlayerName(source) .. " a rejoint le jeu.")
    end
end)

RegisterNetEvent("whoiam:leave")
AddEventHandler("whoiam:leave", function()
    if not players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Vous n'avez pas rejoint de jeu pour quitter.")
        return
    end

    if gameState == "waiting" then
        players[source] = nil
        playerWords[source] = nil
        TriggerClientEvent("whoiam:addMessage", source, " Tu as quitté le jeu.")
        TriggerClientEvent("whoiam:teleportPlayers", source, coordsInitialposition) -- téléporte le joueur à l'emplacement de la queue
        TriggerClientEvent("whoiam:resetPlayer", source)                  -- réinitialise les variables du joueur côté client / A TEST

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:addMessage", id, GetPlayerName(source) .. " a quitté le jeu.")
        end
        updateQueueForEveryone()
    end

    if gameState == "playing" then
        local word = playerWords[source]
        players[source] = nil
        playerWords[source] = nil

        local message = GetPlayerName(source) .. " a quitté le jeu. Son mot était : " .. word
        print(message)
        TriggerClientEvent("whoiam:teleportPlayers", source, coordsInitialposition) -- téléporte le joueur à l'emplacement de la queue
        TriggerClientEvent("whoiam:resetPlayer", source)
        TriggerClientEvent("whoiam:resetAllUI", source)

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:addMessage", id, message)
            TriggerClientEvent("whoiam:removePlayer", id, source)
        end

        if guessedPlayers[source] then
            local guessMessage = GetPlayerName(source) .. " avait déjà deviné son mot : " .. word
            print(guessMessage)

            for id, _ in pairs(players) do
                TriggerClientEvent("whoiam:addMessage", id, guessMessage)
            end
        end

        local remainingPlayers = 0
        local guessedCount = 0

        for id, _ in pairs(players) do
            remainingPlayers = remainingPlayers + 1
            if guessedPlayers[id] then
                guessedCount = guessedCount + 1
            end
        end

        if remainingPlayers <= 2 or guessedCount >= remainingPlayers then
            endGame()
        end
    end
end)

RegisterNetEvent("whoiam:startGame")
AddEventHandler("whoiam:startGame", function()
    if gameState == "playing" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Une partie est déjà en cours.")
        return
    end

    if not players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu dois être dans la queue pour lancer la partie.")
        return
    end

    local playerList = {}
    for id, _ in pairs(players) do
        table.insert(playerList, id)
    end

    if #playerList < 1 then -- ###################################################################################################################################################
        TriggerClientEvent("whoiam:addErrorMessage", source, "Pas assez de joueurs.")
        return
    end

    for i = #playerList, 2, -1 do
        local j = math.random(i)
        playerList[i], playerList[j] = playerList[j], playerList[i]
    end

    local shuffledWords = {}
    for i = 1, #words do
        shuffledWords[i] = words[i]
    end

    for i = #shuffledWords, 2, -1 do
        local j = math.random(i)
        shuffledWords[i], shuffledWords[j] = shuffledWords[j], shuffledWords[i]
    end

    local neededRandomWords = 0
    for _, id in ipairs(playerList) do
        if not playerCustomWords[id] then
            neededRandomWords = neededRandomWords + 1
        end
    end

    if neededRandomWords > #shuffledWords then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Pas assez de mots pour compléter la partie.")
        return
    end

    local tempWords = {}
    local randomIndex = 1

    for _, id in ipairs(playerList) do
        if playerCustomWords[id] then
            tempWords[id] = playerCustomWords[id]
        else
            tempWords[id] = shuffledWords[randomIndex]
            randomIndex = randomIndex + 1
        end
    end

    for i, id in ipairs(playerList) do
        local nextIndex = i + 1
        if nextIndex > #playerList then nextIndex = 1 end

        local nextPlayer = playerList[nextIndex]
        playerWords[id] = tempWords[nextPlayer]
    end

    gameState = "playing"

    local positions = getCirclePositions(playerList, coordsArea, 3.0)

    for id, _ in pairs(players) do
        TriggerClientEvent("whoiam:startGame", id, playerWords)
        TriggerClientEvent("whoiam:teleportPlayers", id, positions[id])
    end
end)

RegisterNetEvent("whoiam:outOfZone")
AddEventHandler("whoiam:outOfZone", function()


    if not players[source] then return end
    if gameState ~= "playing" then return end

    local word = playerWords[source]

    players[source] = nil
    playerWords[source] = nil
    guessedPlayers[source] = nil

    local message = GetPlayerName(source) .. " a quitté la zone et est disqualifié ! Son mot était : " .. word
    print(message)

    for id, _ in pairs(players) do
        TriggerClientEvent("whoiam:addMessage", id, message)
        TriggerClientEvent("whoiam:removePlayer", id, source)
    end

    TriggerClientEvent("whoiam:resetPlayer", source)
    TriggerClientEvent("whoiam:resetAllUI", source)

    checkEndGame()

end)

RegisterNetEvent("whoiam:outOfZoneLobby")
AddEventHandler("whoiam:outOfZoneLobby", function()
    if not players[source] then return end
    if gameState ~= "waiting" then return end

    players[source] = nil
    playerWords[source] = nil
    playerCustomWords[source] = nil

    local message = GetPlayerName(source) .. " a quitté la zone du lobby !"
    print(message)

    TriggerClientEvent("whoiam:addMessage", source, "Tu as quitté la zone du lobby ! Rejoins la queue pour pouvoir jouer.")
    TriggerClientEvent("whoiam:resetAllUI", source)
    for id, _ in pairs(players) do
        TriggerClientEvent("whoiam:addMessage", id, message)
    end
end)

RegisterNetEvent("whoiam:setWord")
AddEventHandler("whoiam:setWord", function(word)

    if gameState == "playing" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "La partie a déjà commencé.")
        return
    end

    if not players[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu dois rejoindre la queue.")
        return
    end

    local word = word or ""

    if word == "" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu dois écrire un mot.")
        return
    end

    if string.len(word) > 20 then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Mot trop long (20 max).")
        return
    end

    if string.len(word) < 3 then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Mot trop court (3 min).")
        return
    end

    for id, customWord in pairs(playerCustomWords) do
        if string.lower(customWord) == string.lower(word) then
            TriggerClientEvent("whoiam:addErrorMessage", source, "Ce mot est déjà utilisé par un autre joueur.")
            return
        end
    end

    for _, banWord in ipairs(banWords) do
        if string.lower(word) == string.lower(banWord) then
            TriggerClientEvent("whoiam:addErrorMessage", source, "Ce mot est interdit. Choisissez-en un autre.")
            return
        end
    end

    playerCustomWords[source] = word

    TriggerClientEvent("whoiam:addMessage", source, "Mot enregistré : " .. word)
    TriggerClientEvent("whoiam:closeUI", source)
end)

RegisterNetEvent("whoiam:showRules")
AddEventHandler("whoiam:showRules", function()
    local rules = "Règles du jeu WhoIAm :\n" ..
        "1. Rejoins la queue pour participer.\n" ..
        "2. Lorsque le jeu commence, tu recevras un mot à deviner.\n" ..
        "3. Devine ton mot en utilisant la commande /whoiam suivi de ton guess.\n" ..
        "4. Si tu devines correctement, ton mot sera révélé aux autres joueurs.\n" ..
        "5. Si tu quittes la zone de jeu pendant la partie, tu seras disqualifié et ton mot sera révélé.\n" ..
        "6. Le jeu se termine lorsque tous les joueurs ont deviné leur mot ou s'il ne reste plus que 2 joueurs et que l'un d'eux a deviné son mot."

    TriggerClientEvent("whoiam:addMessage", source, rules)
end)

RegisterNetEvent("whoiam:guessWord")
AddEventHandler("whoiam:guessWord", function(guess)

 if guessedPlayers[source] then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu as déjà deviné ton mot.")
        return
    end

    local guess = guess or ""

     if guess == "" then
        TriggerClientEvent("whoiam:addErrorMessage", source, "Tu dois écrire un mot.")
        return
    end

    local word = playerWords[source]

    if not word then return end

    if string.lower(guess) == string.lower(word) then
        guessedPlayers[source] = true

        local message = GetPlayerName(source) .. " a deviné son mot : " .. word
        print(message)
        TriggerClientEvent("whoiam:playAnimation", source, "valid")
        TriggerClientEvent("whoiam:blockGuessUI", source)

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:addMessage", id, message)
        end

        for id, _ in pairs(players) do
            TriggerClientEvent("whoiam:playerGuessed", id, source, word)
        end
        checkEndGame()
    else
        local message = GetPlayerName(source) .. " tu as fais un mauvais guess : " .. guess
        print(message)
        TriggerClientEvent("whoiam:addErrorMessage", source, message)
        TriggerClientEvent("whoiam:playAnimation", source, "invalid")
    end
end)
-- ajouter une commande pour quitter le jeu *****

-- afficher le mot du joueur qui a quitté le jeu ****

-- afficher le sur sa tête qui l'a deviné + le mot du joueur qui a été deviné ***

-- mettre fin au jeu si tout le monde a deviné son mot ou si il ne reste plus que 2 joueurs et que l'un des deux a deviné son mot****

-- déclancher un événement pour réinitialiser le jeu et les variables lorsque le jeu est terminé*****

-- déclancher un événement pour teleporté les joueurs à un endroit spécifique lorsque le jeu commence**** et les ramener à leur position initiale lorsque le jeu se termine******

-- Dans la queue ajouter la possibilité d'écrire un mot personnalisé pour les joueurs qui rejoignent le jeu, sinon leur attribuer un mot aléatoire comme actuellement. *****

-- Nombre maximum de joueurs a fixer ***

-- Remplacer les RegisterCommand par des événements pour que les joueurs puissent faire les actions via un menu ou des interactions dans le monde plutôt que par des commandes textuelles*********

-- Optionnel: Ajouter une animation ou un effet visuel lorsque les joueurs devinent leur mot ou lorsqu'ils sont téléportés*****

-- si un joueur sort de la zone de jeu pendant la partie, il est disqualifié et son mot est révélé aux autres joueurs****

-- outOfZone dans le lobby ?

-- Optionnel : ajouter une commande pour afficher les règles du jeu*****

-- display les régles du jeu directement dans le lobby avec un texte 3d et display dans nui