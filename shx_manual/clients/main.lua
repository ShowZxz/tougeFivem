local currentGear = 1
local maxGear = 6
local minGear = -1

local gearLimits = {
    [1] = 30,
    [2] = 60,
    [3] = 90,
    [4] = 130,
    [5] = 180,
    [6] = 250
}

local gearMinLimits = {
    [-1] = 0, -- Reverse gear
    [1] = 0,
    [2] = 20,
    [3] = 40,
    [4] = 70,
    [5] = 100,
    [6] = 140
}

local function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(184)
    EndTextCommandThefeedPostTicker(false, true)
end

CreateThread(function()
    while true do
        local threadWait = 10 -- Default wait time
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h

            if IsControlJustPressed(0, 38) then -- E key
                if currentGear < maxGear and speed >= gearMinLimits[currentGear + 1] then
                    currentGear = currentGear + 1
                    message("Shifted up to gear " .. currentGear)
                end
            elseif IsControlJustPressed(0, 44) then -- Q key
                if currentGear > minGear and speed <= gearMinLimits[currentGear - 1] then
                    currentGear = currentGear - 1
                    message("Shifted down to gear " .. currentGear)
                end
            end

            if currentGear > 0 and speed > gearLimits[currentGear] then
                message("You are over the speed limit for gear " .. currentGear)
            end
        end

        -- limiter la vitesse max en fonction du rapport actuel
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h

            if currentGear > 0 and speed > gearLimits[currentGear] then
                SetEntityMaxSpeed(vehicle, gearLimits[currentGear] / 3.6) -- Convert back to m/s
            else
                SetEntityMaxSpeed(vehicle, 999.0) -- Reset max speed when not over the limit
            end
        end
        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            currentGear = 1 -- Reset gear when exiting vehicle
            threadWait = 2000 -- Increase wait time when not in a vehicle

        end
        Wait(threadWait)
    end
end)
