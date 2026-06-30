local function isSupportStateValid(ped)
    return not (
        IsPedInAnyVehicle(ped, true) or
        IsPedFalling(ped) or
        IsPedRagdoll(ped) or
        IsPedSwimming(ped) or
        IsPedClimbing(ped) or
        IsPedInCombat(ped) or
        IsPedShooting(ped) or
        IsPedJumping(ped)


    )
end

CreateThread(function()
    -- Check if ox_target is available if not disable the integration
    if not GetResourceState("ox_target"):find("start") then return end

    print("[showzx_lift] ox_target detected")



    exports.ox_target:addGlobalOption({

        {
            name = "showzx_lift_target_rope",
            icon = "fa-solid fa-caret-right",
            label = "Déployer une corde",



            canInteract = function()
                if isSupportStateValid(PlayerPedId()) and not Support.active and not Support.isOnRope then  -- Support.isOnRope is a useless check i think
                    return true
                end

                return false
            end,

            onSelect = function()
                TriggerEvent("showzx_lift:previewMode")
            end
        },

                {
            name = "showzx_lift_untarget_rope",
            icon = "fa-solid fa-caret-right",
            label = "Retirer la corde",



            canInteract = function()
                if isSupportStateValid(PlayerPedId()) and Support.active and not Support.isOnRope and next(PlayersOnRope) == nil then -- Support.isOnRope is a useless check i think
                    return true
                end

                return false
            end,

            onSelect = function()
                TriggerServerEvent("showzx_lift:setMode", false)
            end
        },

    })
end)
