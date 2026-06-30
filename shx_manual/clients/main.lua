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

local function message(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    ThefeedSetNextPostBackgroundColor(184)
    EndTextCommandThefeedPostTicker(false, true)
end

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)

            if GetPedInVehicleSeat(veh, -1) == ped then

                local speed = GetEntitySpeed(veh) * 3.6

                if speed > gearLimits[currentGear] then
                    -- réduire la puissance
                    SetVehicleMaxSpeed(veh,gearLimits[currentGear])
                    
                end

                if IsControlJustPressed(0, 38) then -- E key
                    currentGear = currentGear + 1

                    if currentGear > maxGear then
                        currentGear = maxGear
                    end

                    print("Changement de vitesse: " .. currentGear)
                end


                if IsControlJustPressed(0, 44) then -- Q
                    currentGear = currentGear - 1

                    if currentGear < minGear then
                        currentGear = minGear
                    end

                    print("Changement de vitesse: " .. currentGear)
                end
            end
        end
    end
end)
