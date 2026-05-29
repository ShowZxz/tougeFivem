RegisterNetEvent("whoiam:openWordUI")
AddEventHandler("whoiam:openWordUI", function()

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "open"
    })

end)



RegisterNUICallback("submitWord", function(data, cb)

    --SetNuiFocus(false, false)

    print("Received word from NUI: " .. data.word)
    TriggerServerEvent("whoiam:setWord", data.word)

    cb("ok")

end)

RegisterNetEvent("whoiam:updateQueue")
AddEventHandler("whoiam:updateQueue", function(count)

    SendNUIMessage({
        action = "updateQueue",
        count = count
    })

end)

RegisterNUICallback("closeUI", function(_, cb)

    SetNuiFocus(false, false)

    cb("ok")

end)

RegisterNUICallback("showRules", function(_, cb)

    TriggerServerEvent("whoiam:showRules")

    cb("ok")

end)

RegisterNetEvent("whoiam:closeUI")
AddEventHandler("whoiam:closeUI", function()    

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = "closeUI"
    })

end)

RegisterNUICallback("submitGuess", function(data, cb)

    TriggerServerEvent("whoiam:guessWord", data.guess)

    cb("ok")

end)