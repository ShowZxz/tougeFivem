
CreateThread(function()
    if not GetResourceState("es_extended"):find("start") then return end
    print("[interaction_lift] ESX detected")
    --InteractionLift.Framework = "esx"
end)