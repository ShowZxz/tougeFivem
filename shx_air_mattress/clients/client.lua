local mattressModel = GetHashKey("prop_rub_matress_01")
local currentMattress = nil
local rescueActive = false



function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(184)
    EndTextCommandThefeedPostTicker(false, true)
end

function errorMsg(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(6)
    EndTextCommandThefeedPostTicker(true, true)
end

RegisterCommand("airmattress", function()
    if not IsModelInCdimage(mattressModel) then
        errorMsg("Modèle introuvable.")
        return
    end

    if currentMattress and DoesEntityExist(currentMattress) then
        errorMsg("Un matelas est déjà actif.")
        return
    end

    local playerPed = PlayerPedId()

    local spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.0, 0.0)
    local heading = GetEntityHeading(playerPed)

    RequestModel(mattressModel)
    while not HasModelLoaded(mattressModel) do
        Wait(100)
    end

    local obj = CreateObject(
        mattressModel,
        spawnCoords.x,
        spawnCoords.y,
        spawnCoords.z,
        true,
        true,
        true
    )

    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    -- Jouer une animation cohérente avec le placement d'un matelas
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_HAMMERING", 0, true)
    Wait(3000)
    ClearPedTasks(playerPed)

    currentMattress = obj

    message("Matelas déployé.")
end)


RegisterCommand("removeairmattress", function()
    if currentMattress and DoesEntityExist(currentMattress) then
        DeleteEntity(currentMattress)
        currentMattress = nil
        message("Matelas supprimé.")
    else
        errorMsg("Aucun matelas trouvé.")
    end
end)



CreateThread(function()
    while true do
        Wait(50)

        local ped = PlayerPedId()

        if currentMattress and DoesEntityExist(currentMattress) then
            local coords = GetEntityCoords(ped)
            local matCoords = GetEntityCoords(currentMattress)

            local model = GetEntityModel(currentMattress)
            local minDim, maxDim = GetModelDimensions(model)

            local sizeX = maxDim.x - minDim.x
            local sizeY = maxDim.y - minDim.y
            local sizeZ = maxDim.z - minDim.z

            local padding = 10.5
            local distThreshold = (math.max(sizeX, sizeY) / 2) + padding

            local dist = #(vector2(coords.x, coords.y) - vector2(matCoords.x, matCoords.y))
            local heightDiff = coords.z - matCoords.z

            if dist < distThreshold
                and heightDiff < (sizeZ + 2.0)
                and heightDiff > -2.0 then
                if (IsPedFalling(ped) or IsPedInParachuteFreeFall(ped)) and not rescueActive then
                    rescueActive = true

                    CreateThread(function()
                        SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
                        SetEntityVelocity(ped, 0.0, 0.0, 0.0)

                        --Wait(400)

                        ClearPedTasksImmediately(ped)
                        SetPedCanRagdoll(ped, false)

                        local coords = GetEntityCoords(ped)
                        SetEntityCoords(ped, coords.x, coords.y, coords.z + 0.2, false, false, false, true)

                        Wait(2000)

                        SetPedCanRagdoll(ped, true)

                        rescueActive = false
                    end)
                end
            end
        end
    end
end)
