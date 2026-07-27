print("Loading interaction_lift client main.lua")


local ANIM_DURATION = (Config.Frame.TOTAL_FRAMES / Config.Frame.ANIM_FPS) * 1000


-- Support toggle handling
CreateThread(function()
    while true do
        Wait(0)
        -- disable control if ox_target or ContextMenu is used
        if Config.EnableOxIntegration or Config.EnableContextMenuIntegration then goto continue end
        if IsControlJustPressed(0, Config.Keys.LEGSUP_SUPPORT) then
            TriggerEvent("interaction_lift:support:enable", "legsup")
        end

        if IsControlJustPressed(0, Config.Keys.PULLUP_SUPPORT) then
            TriggerEvent("interaction_lift:support:enable", "pullup")
        end

        ::continue::
        if IsControlJustPressed(0, Config.Keys.TOGGLE_SUPPORT) then
            TriggerEvent("interaction_lift:support:disable")
        end
    end
end)

-- Clear support after being lifted and the end of the animation
RegisterNetEvent("interaction_lift:clearSupport")
AddEventHandler("interaction_lift:clearSupport", function()
    Wait(ANIM_DURATION)
    ClearPedTasks(PlayerPedId())
    message("Support Cleared")
    FreezeEntityPosition(PlayerPedId(), false)
    if Support then
        Support.active = false
        Support.mode = nil
        Support.position = nil
        CurrentSupportData = nil
    end
end)

-- Information about denial reason
RegisterNetEvent("interaction_lift:denied")
AddEventHandler("interaction_lift:denied", function(reason)
    errorMsg(reason)
end)

-- Information about successful interaction
RegisterNetEvent("interaction_lift:info")
AddEventHandler("interaction_lift:info", function(info)
    message(info)
end)



--DEBUG COMMANDS
RegisterCommand("testc", function()
    if not Config.debug then
        errorMsg("❌ Commande désactivée")
        return
    end

    RequestAnimDict(Config.Animation.LEGSUP.DICTLIFT)
    while not HasAnimDictLoaded(Config.Animation.LEGSUP.DICTLIFT) do Wait(10) end
    TaskPlayAnim(PlayerPedId(), Config.Animation.LEGSUP.DICTLIFT, Config.Animation.LEGSUP.ANIMLIFT, 8.0, -8.0, -1, 1, 0,
        false, false, false)
end)

RegisterCommand("stopemote", function()
    if not Config.debug then
        errorMsg("❌ Commande désactivée")
        return
    end

    ClearPedTasks(PlayerPedId())
end)