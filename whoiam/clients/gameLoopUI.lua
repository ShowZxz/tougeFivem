local guessUIOpened = false
local isPlaying = false
local guessWord = false


local function resetVariables()
    isPlaying = false
    guessUIOpened = false
    guessWord = false
end

local function displayHelpText()
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ Pour deviner le mot")
    EndTextCommandDisplayHelp(0, false, true, -1)
end


CreateThread(function()
    while true do
        Wait(5)

        if not isPlaying then
            goto continue
        end

        if guessWord then
            goto continue
        end
        displayHelpText()
        if IsControlJustPressed(0, 38) and not guessUIOpened then
            SetNuiFocus(true, true)

            SendNUIMessage({
                action = "openGuessUI"
            })
            guessUIOpened = true
        end

        ::continue::
    end
end)

RegisterNUICallback("closeGuessUI", function(_, cb)
    print("Closing Guess UI from NUI callback")
    SetNuiFocus(false, false)



    SendNUIMessage({
        action = "closeGuessUI"
    })

    guessUIOpened = false

    cb("ok")
end)


RegisterNetEvent("whoiam:startGame")
AddEventHandler("whoiam:startGame", function()
    isPlaying = true
end)

RegisterNetEvent("whoiam:blockGuessUI")
AddEventHandler("whoiam:blockGuessUI", function()
    print("Received blockGuessUI event from server, closing Guess UI if open")

    if guessUIOpened then
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = "closeGuessUI"
        })

        guessUIOpened = false
        guessWord = true
    end
end)

RegisterNetEvent("whoiam:resetAllUI")
AddEventHandler("whoiam:resetAllUI", function()

    resetVariables()

    SetNuiFocus(false, false)

    -- Close both UIs to ensure everything is reset
    SendNUIMessage({
        action = "closeUI"
    })
    SendNUIMessage({
        action = "closeGuessUI"
    })
    
    print("All UI reset and variables cleared")

end)
